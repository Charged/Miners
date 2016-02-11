// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for http connections.
 */
module charge.net.http;

import std.c.string : memset;

import std.string : format;
import std.socket : TcpSocket, SocketSet, SocketShutdown,
                    SocketOption, SocketOptionLevel,
                    Address, InternetAddress, TimeVal;

import uri = std.uri;

import stdx.conv : toInt;
import stdx.string : find;
import stdx.regexp : RegExp;

import charge.sys.logger;
import charge.net.threaded;
import charge.util.memory;


class HttpConnection
{
protected:
	TcpSocket s;

	/// Return code for the latest request.
	int lastReturnCode;

private:
	// Server details
	string hostname;
	ushort port;

	// For async
	SocketSet sSetRead;
	SocketSet sSetWrite;
	SocketSet sSetError;
	bool connecting;

	/// Collected data from server
	cMemoryArray!(char) data;
	/// Amount of data read
	size_t dataRead;
	/// Start of body in data, also where header stops.
	size_t pageBodyStart;

	/// Length of body to be recieved
	ptrdiff_t contentLength;

	InternetAddress addr;

	mixin Logging;


public:
	this(string hostname, ushort port)
	{
		this.contentLength = -1;
		this.hostname = hostname;
		this.port = port;
	}

	~this()
	{
		data.free();
	}


	/*
	 *
	 * Socket functions.
	 *
	 */


	void close()
	{
		if (s is null)
			return;

		s.shutdown(SocketShutdown.BOTH);
		s.close();
		s = null;
		sSetRead = null;
		sSetWrite = null;
		sSetError = null;
	}

	void doTick()
	{
		if (s is null)
			if (!doConnect())
				return;

		sSetRead.reset();
		sSetRead.add(s);
		sSetWrite.reset();
		sSetWrite.add(s);
		sSetError.reset();
		sSetError.add(s);

		try {
			TimeVal tv;
			int ret = s.select(sSetRead, sSetWrite, sSetError, &tv);
			if (ret < 0)
				throw new Exception("Error on select");
			if (ret == 0)
				return;

			// Have we connected to a server
			if (connecting && sSetWrite.isSet(s)) {
				connecting = false;
				handleConnected();
			}

			// Let the receive function deal with errors
			if (sSetRead.isSet(s) || sSetError.isSet(s)) {
				if (contentLength < 0)
					getHeader();
				else
					getBody();
			}

		} catch (DisconnectedException de) {
			handleDisconnect();
		} catch(Exception e) {
			handleError(e);
		}
	}


protected:
	/*
	 *
	 * Http functions.
	 *
	 */


	void httpGet(string url)
	{
		httpSend("GET", url, "");
	}

	void httpPost(string url, string bdy)
	{
		httpSend("POST", url, bdy);
	}

	void httpSend(string cmd, string url, string bdy)
	{
		const string http =
		"%s %s HTTP/1.0\r\n"
		"User-Agent: Charge Game Engine\r\n"
		"Host: %s\r\n"
		"\r\n"
		"%s";

		auto req = format(http, cmd, url, hostname, bdy);
		s.send(req);
	}


	/*
	 *
	 * Abstract functions.
	 *
	 */


	abstract void handleError(Exception e);
	abstract void handleConnected();
	abstract void handleUpdate(int percentage);
	abstract void handleResponse(char[] header, char[] res);
	abstract void handleDisconnect();


private:
	/*
	 *
	 * Internal functions.
	 *
	 */


	bool doConnect()
	{
		try {
			if (addr is null)
				addr = new InternetAddress(hostname, port);

			connecting = true;

			s = new TcpSocket();
			s.setOption(SocketOptionLevel.TCP, SocketOption.TCP_NODELAY, 1);
			s.blocking = false;

			s.connect(addr);

		} catch (Exception e) {
			version(darwin) {
				if (e.toString != "Unable to connect socket: Operation now in progress") {
					handleError(e);
					return false;
				}
			} else {
				handleError(e);
				return false;
			}
		}

		sSetRead = new SocketSet();
		sSetWrite = new SocketSet();
		sSetError = new SocketSet();

		return true;
	}

	final int receive()
	{
		data.ensure(dataRead + 4096);

		auto n = s.receive(data[dataRead .. data.length]);
		if (n < 0) {
			if (s.isAlive())
				return 0;
			else
				throw new ReceiveException(n);
		} else if (n == 0) {
			throw new DisconnectedException();
		}

		dataRead += cast(size_t)n;

		return cast(int)n;
	}

	void getHeader()
	{
		// Read data.
		int n = receive();
		assert(n >= 0);
		if (n == 0)
			return;

		auto pos = cast(size_t)find(data[0 .. dataRead], "\r\n\r\n");
		// HTTP header end not found, need more data.
		if (pos == size_t.max)
			return;

		pageBodyStart = pos + 4;
		scope(failure)
			resetOffsets();

		char[] pageHeader = cast(char[])data[0 .. pageBodyStart];

		lastReturnCode = getReturnCode(pageHeader);
		contentLength = getContentLength(pageHeader);

		size_t end = pageBodyStart + contentLength;
		int percentage = cast(int)((dataRead * 100f) / end);
		if (dataRead == end)
			doHandleResponse();
		else
			handleUpdate(percentage);
	}

	void getBody()
	{
		auto n = receive();
		assert(n >= 0);
		if (n == 0)
			return;

		size_t end = pageBodyStart + contentLength;
		int percentage = cast(int)((dataRead * 100f) / end);
		if (dataRead < end)
			return handleUpdate(percentage);
		else if (dataRead == end)
			doHandleResponse();
		else {
			resetOffsets();
			throw new Exception("Read too much data!");
		}
	}


private:
	void resetOffsets()
	{
		dataRead = 0;
		pageBodyStart = 0;
		contentLength = -1;
	}

	void doHandleResponse()
	{
		auto pageHeader = data[0 .. pageBodyStart - 2];
		auto pageBody = data[pageBodyStart .. dataRead];

		resetOffsets();

		handleResponse(pageHeader, pageBody);
	}
}


/**
 * A threaded HTTP connection. 
 */
class ThreadedHttpConnection : ThreadedTcpConnection
{
protected:
	int lastReturnCode;


private:
	// Server details
	string hostname;
	ushort port;

	// Collected data from server
	char[] saved;
	ptrdiff_t contentLength;
	char[] pageBody;
	char[] pageHeader;


public:
	this(string hostname, ushort port)
	{
		this.contentLength = -1;
		this.hostname = hostname;
		this.port = port;

		super();
	}


protected:
	/*
	 *
	 * Http functions.
	 *
	 */


	void httpGet(string url)
	{
		httpSend("GET", url, "");
	}

	void httpPost(string url, string bdy)
	{
		httpSend("POST", url, bdy);
	}

	void httpSend(string cmd, string url, string bdy)
	{
		const string http =
		"%s %s HTTP/1.0\r\n"
		"User-Agent: Charge Game Engine\r\n"
		"Host: %s\r\n"
		"\r\n"
		"%s";

		auto req = format(http, cmd, url, hostname, bdy);
		s.send(req);
	}


	/*
	 *
	 * Abstract functions.
	 *
	 */


	abstract void handleError(Exception e);
	abstract void handleResponse(char[] header, char[] res);
	abstract void handleConnected();
	abstract void handleDisconnect();


	/*
	 *
	 * Socket functions.
	 *
	 */


	/**
	 * Called at start.
	 */
	override void run()
	{
		try {
			connect(hostname, port);

			handleConnected();

			while(true)
				loop();

		} catch (ReceiveException re) {
			if (re.status == 0)
				handleDisconnect();
			else
				handleError(re);
		} catch (Exception e) {
			handleError(e);
		}
	}

	/**
	 * Main loop for receiving data.
	 */
	void loop()
	{
		char[1024] data;
		int n;

		// Wait for any data.
		n = receive(data);
		if (n <= 0)
			throw new ReceiveException(n);

		saved ~= data[0 .. n];

		if (contentLength < 0) {
			auto pos = cast(size_t)find(saved, "\r\n\r\n");
			// HTTP header end not found, need more data.
			if (pos == size_t.max)
				return;

			pageHeader = saved[0 .. pos + 2].dup;
			saved = saved[pos + 4 .. $].dup;

			lastReturnCode = getReturnCode(pageHeader);
			contentLength = getContentLength(pageHeader);
		}

		// Need more data.
		if (contentLength > saved.length)
			return;

		pageBody = saved[0 .. cast(size_t)contentLength].dup;
		saved = saved[cast(size_t)contentLength .. $].dup;

		handleResponse(pageHeader, pageBody);

		// Reset to wait for another page.
		contentLength = -1;
	}
}

class DisconnectedException : Exception
{
	this() { super("Disconnected"); }
}

class ReceiveException : Exception
{
	ptrdiff_t status;

	this(ptrdiff_t status)
	{
		this.status = status;
		super(format("ReceiveException (%s)", status));
	}
}

static RegExp headerReg;

static this()
{
	headerReg = RegExp(`^HTTP/\d\.\d\s+(\d+)`);
}

static int getReturnCode(char[] header)
{
	auto m = headerReg.match(cast(string)header);
	if (m.length < 2)
		throw new Exception("Invalid HTTP resonse");

	return toInt(m[1]);
}

static ptrdiff_t getContentLength(char[] header)
{
	const tag = "Content-Length: ";
	auto start = cast(size_t)find(header, tag);
	if (start == size_t.max)
		throw new Exception("Can't handle http with no Content-Length.");

	start += tag.length;
	auto stop = cast(size_t)find(header[start .. $], "\r\n");
	if (stop == size_t.max)
		throw new Exception("Invalid Content-Length entry in header.");

	return toInt(header[start .. start + stop]);
}

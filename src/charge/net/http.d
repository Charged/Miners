// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.net.http;

import std.string;
import std.conv;
import std.socket;
import uri = std.uri;

import lib.sdl.sdl;
import std.c.string;

import charge.sys.logger;
import charge.net.threaded;
import charge.util.memory;


class HttpConnection
{
protected:
	TcpSocket s;


private:
	// Server details
	char[] hostname;
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
	this(char[] hostname, ushort port)
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

		auto outerThen = SDL_GetTicks();
		try {
			// Ugh work around silly Phobos bug
			version (Posix) {
				struct TimeVal {
					size_t sec;
					size_t micro;
				}
				TimeVal tv;
			} else {
				timeval tv;
			}
			auto tvPtr = cast(timeval*)&tv;
			memset(tvPtr, 0, tv.sizeof);

			int ret = s.select(sSetRead, sSetWrite, sSetError, tvPtr);
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


	void httpGet(char[] url)
	{
		httpSend("GET", url, "");
	}

	void httpPost(char[] url, char[] bdy)
	{
		httpSend("POST", url, bdy);
	}

	void httpSend(char[] cmd, char[] url, char[] bdy)
	{
		const char[] http =
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

			sSetRead = new SocketSet();
			sSetWrite = new SocketSet();
			sSetError = new SocketSet();

			return true;
		} catch (Exception e) {
			handleError(e);
			return false;
		}
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

		contentLength = getContentLength(data[0 .. pageBodyStart]);

		size_t end = pageBodyStart + contentLength;
		if (dataRead == end)
			doHandleResponse();
	}

	void getBody()
	{
		auto n = receive();
		assert(n >= 0);
		if (n == 0)
			return;

		size_t end = pageBodyStart + contentLength;
		if (dataRead < end)
			return;
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
class ThreadedHttpConnection : public ThreadedTcpConnection
{
private:
	// Server details
	char[] hostname;
	ushort port;

	// Collected data from server
	char[] saved;
	ptrdiff_t contentLength;
	char[] pageBody;
	char[] pageHeader;

public:
	this(char[] hostname, ushort port)
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


	void httpGet(char[] url)
	{
		httpSend("GET", url, "");
	}

	void httpPost(char[] url, char[] bdy)
	{
		httpSend("POST", url, bdy);
	}

	void httpSend(char[] cmd, char[] url, char[] bdy)
	{
		const char[] http =
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
	int run()
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

		return 0;
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

class DisconnectedException : public Exception
{
	this() { super("Disconnected"); }
}

class ReceiveException : public Exception
{
	ptrdiff_t status;

	this(ptrdiff_t status)
	{
		this.status = status;
		super(format("ReceiveException (%s)", status));
	}
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

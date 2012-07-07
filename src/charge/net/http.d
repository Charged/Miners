// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.net.http;

import charge.net.threaded;

import std.string;
import std.conv;
import std.socket;
import uri = std.uri;


class HttpConnection
{
protected:
	TcpSocket s;


private:
	// Server details
	char[] hostname;
	ushort port;

	// Collected data from server
	char[] saved;
	ptrdiff_t contentLength;
	char[] pageBody;
	char[] pageHeader;
	size_t pageBodyPos;


public:
	this(char[] hostname, ushort port)
	{
		this.contentLength = -1;
		this.hostname = hostname;
		this.port = port;
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
	}

	void doTick()
	{
		if (s is null)
			if (!doConnect())
				return;

		try {
			if (contentLength < 0) {
				getHeader();
			} else {
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
	 * Abstract functions.
	 *
	 */


	abstract void handleError(Exception e);
	abstract void handleResponse(char[] header, char[] res);
	abstract void handleConnected();
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
			auto a = new InternetAddress(hostname, port);

			s = new TcpSocket(a);
			s.blocking = false;

			handleConnected();

			return true;
		} catch (Exception e) {
			handleError(e);
			return false;
		}
	}

	ptrdiff_t receive(void[] data)
	{
		auto n = s.receive(data);
		if (n < 0) {
			if (s.isAlive())
				return 0;
			else
				throw new ReceiveException(n);
		} else if (n == 0) {
			throw new DisconnectedException();
		}
		return n;
	}

	void getHeader()
	{
		char[4096] data;
		ptrdiff_t n;

		// Wait for any data.
		n = receive(data);
		assert(n >= 0);
		if (n == 0)
			return;

		if (saved.length == 0)
			saved = data[0 .. cast(size_t)n].dup;
		else
			saved ~= data[0 .. cast(size_t)n];

		auto pos = cast(size_t)find(saved, "\r\n\r\n");
		// HTTP header end not found, need more data.
		if (pos == size_t.max)
			return;

		pageHeader = saved[0 .. pos + 4].dup;
		saved = saved[pos + 4 .. $];

		contentLength = getContentLength(pageHeader);
		pageBody = new char[cast(size_t)contentLength];
		pageBody[0 .. saved.length] = saved;
		pageBodyPos = saved.length;
	}

	void getBody()
	{
		auto n = receive(pageBody[pageBodyPos .. $]);
		assert(n >= 0);
		if (n == 0)
			return;

		pageBodyPos += n;

		if (pageBodyPos < pageBody.length) {
			return;
		} else if (pageBodyPos == pageBody.length) {
			handleResponse(pageHeader, pageBody);
		} else {
			throw new Exception("Read too much data!");
		}
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

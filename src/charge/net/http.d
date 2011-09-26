// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.net.http;

import charge.net.threaded;

import std.string;
import std.conv;
import uri = std.uri;


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

	static class ReceiveException : public Exception
	{
		int status;

		this(int status)
		{
			this.status = status;
			super(format("ReceiveException (%s)", status));
		}
	}
}

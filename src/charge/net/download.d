// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.net.download;

import std.string : format;

import charge.net.http;


/**
 * Receive events from async webpage getter.
 */
interface DownloadListener
{
	/**
	 * Connection esstablished.
	 */
	void connected();

	/**
	 * Percentage done of download.
	 */
	void percentage(int p);

	/**
	 * Downloaded data.
	 */
	void downloaded(void[] data);

	/**
	 * Called on error.
	 */
	void error(Exception e);

	/**
	 * Called when the server closed the connection.
	 */
	void disconnected();
}

/**
 * A http connection that downloads files. 
 */
class DownloadConnection : HttpConnection
{
private:
	/// Receiver of packages
	DownloadListener l;

	/// Current file to download
	string curPath;

public:
	this(DownloadListener l, string hostname, ushort port)
	{
		this.l = l;

		super(hostname, port);
	}


	/*
	 *
	 * Http GET functions.
	 *
	 */


	void getDownload(string path)
	{
		if (curPath !is null)
			throw new Exception("Can't handle more then one request");

		curPath = path;

		httpGet(path);
	}


	/*
	 *
	 * Event handling.
	 *
	 */


protected:
	void handleError(Exception e)
	{
		curPath = null;
		close();
		l.error(e);
	}

	void handleResponse(char[] header, char[] res)
	{
		curPath = null;
		l.downloaded(res);
	}

	void handleUpdate(int percentage)
	{
		l.percentage(percentage);
	}

	void handleConnected()
	{
		l.connected();
	}

	void handleDisconnect()
	{
		if (curPath is null) {
			l.disconnected();
		} else {
			curPath = null;
			auto e = new Exception("Connection lost!");
			handleError(e);
		}
	}
}

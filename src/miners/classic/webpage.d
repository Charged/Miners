// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.webpage;

import std.stdio;

import std.string : format, find;
import std.conv : toInt;
import uri = std.uri;

import charge.charge;

import miners.types;
import miners.importer.classicinfo;


alias charge.net.util.ntoh ntoh;

/**
 * Receive events from async webpage getter.
 */
interface ClassicWebpageListener
{
	/**
	 * Connection esstablished.
	 */
	void connected();

	/**
	 * Authenticated with the webpage.
	 */
	void authenticated();

	/**
	 * Percentage done of download.
	 */
	void percentage(int p);

	/**
	 * Parsed the server list webpage.
	 */
	void serverList(ClassicServerInfo[] csis);

	/**
	 * Parsed the server play webpage.
	 */
	void serverInfo(ClassicServerInfo csi);

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
 * A threaded TCP connection to the minecraft.net servers. 
 */
class WebpageConnection : public NetHttpConnection
{
private:
	// Server details
	const char[] hostname = "www.minecraft.net";
	const ushort port = 80;

	enum Op {
		NO_OP,
		CONNECTING,
		POST_LOGIN,
		GET_SERVER_LIST,
		GET_SERVER_INFO,
		ERROR,
		DISCONNECTED,
	}

	/// What is this connection currently doing
	Op curOp;

	/// Receiver of packages
	ClassicWebpageListener l;

	/// Session id
	char[] playSession;
	/// Retrived list of server info
	ClassicServerInfo[] csis;
	/// Info to retrive and return
	ClassicServerInfo csi;


public:
	this(ClassicWebpageListener l)
	{
		this.l = l;
		this.curOp = Op.CONNECTING;

		super(hostname, port);
	}

	this(ClassicWebpageListener l, char[] playSession)
	{
		this.playSession = playSession;
		this(l);
	}


	/*
	 *
	 * Http GET functions.
	 *
	 */


	void getServerList()
	{
		const char[] http =
		"GET /classic/list HTTP/1.1\r\n"
		"User-Agent: Charged-Miners\r\n"
		"Host: %s\r\n"
		"Cookie: PLAY_SESSION=%s\r\n"
		"\r\n";

		if (curOp != Op.NO_OP)
			throw new Exception("Can't handle more then one request");

		if (playSession is null)
			throw new Exception("Not authenticated");

		auto req = format(http, hostname, playSession);

		s.send(req);

		curOp = Op.GET_SERVER_LIST;
	}

	void getServerInfo(ClassicServerInfo csi)
	{
		const char[] http =
		"GET /classic/play/%s HTTP/1.1\r\n"
		"User-Agent: Charged-Miners\r\n"
		"Host: %s\r\n"
		"Cookie: PLAY_SESSION=%s\r\n"
		"\r\n";

		if (curOp != Op.NO_OP)
			throw new Exception("Can't handle more then one request");

		if (playSession is null)
			throw new Exception("Not authenticated");

		auto req = format(http, csi.webId, hostname, playSession);

		s.send(req);

		this.csi = csi;
		curOp = Op.GET_SERVER_INFO;
	}


	/*
	 *
	 * Http POST functions.
	 *
	 */


	/**
	 * Login to login.minecraft.net and retrive the PLAY_SESSION cookie.
	 *
	 * XXX: This method is insecure, should only be used for debugging purposes.
	 */
	void postLogin(char[] username, char[] password)
	{
		const char[] http =
		"POST /login HTTP/1.1\r\n"
		"User-Agent: Charged-Miners\r\n"
		"Host: %s\r\n"
		"Content-Length: %s\r\n"
		"Content-Type: application/x-www-form-urlencoded\r\n"
		"\r\n"
		"%s";
		const char[] content =
		"username=%s&password=%s";

		if (curOp != Op.NO_OP)
			throw new Exception("Can't handle more then one request");

		auto bdy = format(content,
				  uri.encode(username),
				  uri.encode(password));
		auto req = format(http, hostname, bdy.length, bdy);

		s.send(req);
		curOp = Op.POST_LOGIN;
	}


	/*
	 *
	 * Event handling.
	 *
	 */


	void doEvents()
	{
		doTick();
	}

protected:
	void handleError(Exception e)
	{
		l.error(e);
	}

	void handleResponse(char[] header, char[] res)
	{
		auto tmp = curOp;
		curOp = Op.NO_OP;

		switch(tmp) {
		case Op.POST_LOGIN:
			playSession = getPlaySession(header);
			l.authenticated();
			break;
		case Op.GET_SERVER_LIST:
			auto csis = getClassicServerList(res);
			l.serverList(csis);
			break;
		case Op.GET_SERVER_INFO:
			getClassicServerInfo(csi, res);
			l.serverInfo(csi);
			break;
		default:
			auto str = format("Unhandled operation %s", curOp);
			throw new Exception(str);
		}
	}

	void handleUpdate(int percentage)
	{
		l.percentage(percentage);
	}

	void handleConnected()
	{
		curOp = Op.NO_OP;
		l.connected();
	}

	void handleDisconnect()
	{
		Op set;

		// This becomes an error if we are trying to do something.
		if (curOp == Op.NO_OP) {
			l.disconnected();
		} else {
			auto e = new Exception("Connection lost!");
			handleError(e);
		}
	}


	/*
	 *
	 * Helper Functions.
	 *
	 */


	char[] getPlaySession(char[] header)
	{
		const startTag = "Set-Cookie: PLAY_SESSION=";
		auto start = cast(size_t)find(header, startTag);
		if (start == size_t.max)
			throw new Exception("Can't find PLAY_SESSION cookie");

		start += startTag.length;

		const stopTag = ";";
		auto stop = cast(size_t)find(header[start .. $], stopTag);
		if (stop == size_t.max)
			throw new Exception("Malformed HTTP header");

		// No cookie given
		if (stop == 0)
			throw new Exception("Failed to authenticate!");

		return header[start .. start + stop].dup;
	}
}

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
class WebpageConnection : public NetThreadedHttpConnection
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
	/// List of completed operations, protected by this
	Op[] opList;

	/// Receiver of packages
	ClassicWebpageListener l;

	/// Session id
	char[] playSession;
	/// Retrived list of server info
	ClassicServerInfo[] csis;
	/// Info to retrive and return
	ClassicServerInfo csi;
	/// Error exception raised
	Exception e;


public:
	this(ClassicWebpageListener l)
	{
		this.l = l;
		this.curOp = Op.CONNECTING;

		super(hostname, port);
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
		auto ops = getOps();
		foreach(op; ops) {
			// Which op was done.
			switch(op) {
			case Op.CONNECTING:
				l.connected();
				break;
			case Op.POST_LOGIN:
				l.authenticated();
				break;
			case Op.GET_SERVER_LIST:
				l.serverList(csis);
				break;
			case Op.GET_SERVER_INFO:
				l.serverInfo(csi);
				break;
			case Op.ERROR:
				l.error(e);
				break;
			case Op.DISCONNECTED:
				l.disconnected();
				break;
			default:
				assert(false);
			}
		}
	}

protected:
	void handleError(Exception e)
	{
		this.e = e;
		pushOp(Op.ERROR, Op.ERROR);
	}

	void handleResponse(char[] header, char[] res)
	{
		switch(curOp) {
		case Op.POST_LOGIN:
			playSession = getPlaySession(header);
			break;
		case Op.GET_SERVER_LIST:
			csis = getClassicServerList(res);
			break;
		case Op.GET_SERVER_INFO:
			getClassicServerInfo(csi, res);
			break;
		case Op.NO_OP:
			writefln("GAH");
		default:
			throw new Exception("Unhandled operation");
		}

		pushOp(curOp, Op.NO_OP);
	}

	void handleConnected()
	{
		pushOp(curOp, Op.NO_OP);
	}

	void handleDisconnect()
	{
		Op set;

		// This becomes an error if we are trying to do something.
		if (curOp == Op.NO_OP) {
			set = Op.DISCONNECTED;
		} else {
			e = new Exception("Connection lost!");
			set = Op.ERROR;
		}
		pushOp(set, set);
	}


	/*
	 *
	 * Helper Functions.
	 *
	 */


	synchronized void pushOp(Op op, Op set)
	{
		curOp = set;
		opList ~= op;
	}

	synchronized Op[] getOps()
	{
		auto ret = opList;
		opList = null;
		return ret;
	}

	char[] getPlaySession(char[] header)
	{
		const startTag = "Set-Cookie: PLAY_SESSION=";
		auto start = cast(size_t)find(header, startTag);
		if (start == size_t.max)
			throw new Exception("Can't find PLAY_SESSION cookie");

		start += startTag.length;

		const stopTag = ";Path=/";
		auto stop = cast(size_t)find(header[start .. $], stopTag);
		if (stop == size_t.max)
			throw new Exception("Malformed HTTP header");

		return header[start .. start + stop].dup;
	}
}

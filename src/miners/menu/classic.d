// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.classic;

import std.string : format;

import charge.charge;
import charge.game.gui.textbased;

import miners.types;
import miners.interfaces;
import miners.menu.base;
import miners.classic.webpage;
import miners.classic.message;
import miners.classic.interfaces;
import miners.classic.connection;


const char[] header = `Classic`;
const uint childWidth = 424;
const uint childHeight = 9*16;


class CenteredText : public Container
{
public:
	Text text;

	this(Container p, int x, int y, uint minW, uint minH, char[] text)
	{
		super(p, x, x, minW, minH);

		this.text = new Text(this, 0, 0, text);
	}

	void repack()
	{
		text.x = (w - text.w) / 2;
		text.y = (h - text.h) / 2;
	}
}


/*
 *
 * Connecting to a server.
 *
 */


/**
 * Displays connection status for a Classic connection.
 */
class ClassicConnectingMenu : public MenuBase, public ClientListener
{
private:
	ClientConnection cc;
	MessageLogger ml;
	Button ca;
	Text text;

public:
	/**
	 * Create a connection from the server info give, displaying
	 * the connection status as it is made finally creating the
	 * ClassicRunner once a level is loaded.
	 */
	this(Router r, ClassicServerInfo csi)
	{
		super(r, header, Buttons.CANCEL);
		ml = new MessageLogger();
		cc = new ClientConnection(this, ml, csi);

		r.menu.setTicker(&cc.doPackets);

		auto ct = new CenteredText(null, 0, 0,
					   childWidth, childHeight,
					   "Connecting");
		replacePlane(ct);
		text = ct.text;

		repack();
	}

	/**
	 * This constructor is used we change world, the server
	 * does this by sending levelInitialize packet.
	 */
	this(Router r, ClassicConnection cc)
	{
		super(r, header, Buttons.CANCEL);
		this.cc = cast(ClientConnection)cc;

		r.menu.setTicker(&(this.cc).doPackets);
		this.cc.setListener(this);

		auto ct = new CenteredText(null, 0, 0,
					   childWidth, childHeight,
					   "Changing World");
		replacePlane(ct);
		text = ct.text;

		repack();
	}

	~this()
	{
		assert(cc is null);
	}

	void breakApart()
	{
		super.breakApart();

		if (cc !is null) {
			r.menu.unsetTicker(&cc.doPackets);
			cc.close();
			cc = null;
		}
	}


	/*
	 *
	 * Classic Connection Callbacks
	 *
	 */


protected:
	void indentification(ubyte ver, char[] name, char[] motd, ubyte type)
	{
	}

	void levelInitialize()
	{
		auto t = format("Loading level 0%%");
		text.setText(t);
		repack();
	}

	void levelLoadUpdate(ubyte precent)
	{
		auto t = format("Loading level %s%%", precent);
		text.setText(t);
		repack();
	}

	void levelFinalize(uint x, uint y, uint z, ubyte data[])
	{
		auto t = format("Done!");
		text.setText(t);
		repack();

		r.menu.unsetTicker(&cc.doPackets);

		// Make sure cc is null before breakApart gets called.
		auto tmp = cc;
		cc = null;

		r.connectedTo(tmp, x, y, z, data);
	}

	void setBlock(short x, short y, short z, ubyte type) {}

	void playerSpawn(byte id, char[] name, double x, double y, double z,
			 double heading, double pitch) {}

	void playerMoveTo(byte id, double x, double y, double z,
			  double heading, double pitch) {}
	void playerMove(byte id, double x, double y, double z,
			double heading, double pitch) {}
	void playerMove(byte id, double x, double y, double z) {}
	void playerMove(byte id, double heading, double pitch) {}
	void playerDespawn(byte id) {}
	void playerType(ubyte type) {}

	void ping() {}
	void message(byte id, char[] message) {}
	void disconnect(char[] reason)
	{
		r.menu.displayError(["Disconnected", reason], false);
	}
}


/*
 *
 * Webpage
 *
 */


class WebpageInfoMenu : public MenuBase, public ClassicWebpageListener
{
private:
	ClassicServerInfo csi;
	WebpageConnection wc;
	Text text;

	/// Cookie used for authentication.
	char[] playSession;
	/// Username used for authentication
	char[] username;
	/// Password used for authentication
	char[] password;

public:
	/**
	 * Retrive the server list, using a new connection
	 * authenticating with the given credentials.
	 */
	this(Router r, char[] playSession)
	{
		auto wc = new WebpageConnection(this, playSession);

		this.playSession = playSession;
		this(r, wc, null, false);
	}

	/**
	 * Retrive information about a server,
	 * the connection has allready be authenticated.
	 */
	this(Router r, WebpageConnection wc, ClassicServerInfo csi)
	{
		this(r, wc, csi, true);
	}

	/**
	 * Retrive information about a server, using a new connection
	 * authenticating with the given credentials.
	 */
	this(Router r, char[] playSession, ClassicServerInfo csi)
	{
		auto wc = new WebpageConnection(this, playSession);

		this.playSession = playSession;
		this(r, wc, csi, false);
	}

	/**
	 * Retrive information about a server, using a new connection
	 * authenticating with the given credentials.
	 *
	 * Should not use this versions.
	 */
	this(Router r, char[] username, char[] password, ClassicServerInfo csi)
	{
		auto wc = new WebpageConnection(this);

		this.username = username;
		this.password = password;
		this(r, wc, csi, false);
	}

	~this()
	{
		assert(wc is null);
	}

	void breakApart()
	{
		super.breakApart();

		shutdownConnection();
	}


private:
	this(Router r, WebpageConnection wc,
	     ClassicServerInfo csi,
	     bool idle)
	{
		super(r, header, Buttons.CANCEL);
		this.csi = csi;
		this.wc = wc;

		if (idle)
			wc.getServerInfo(csi);

		r.menu.setTicker(&wc.doEvents);

		auto ct = new CenteredText(null, 0, 0,
					   childWidth, childHeight,
					   "Connecting");
		replacePlane(ct);
		text = ct.text;

		repack();
	}

	void shutdownConnection()
	{
		if (wc !is null) {
			r.menu.unsetTicker(&wc.doEvents);

			try {
				wc.close();
			} catch (Exception e) {
				cast(void)e;
			}

			wc = null;
		}
	}

protected:
	void authenticate()
	{
		wc.postLogin(username, password);

		text.setText("Authenticating");
		repack();
	}

	void getServerList()
	{
		wc.getServerList();

		text.setText("Retriving server list");
		repack();
	}

	void getServerInfo(ClassicServerInfo csi)
	{
		wc.getServerInfo(csi);

		text.setText("Retriving server info");
		repack();
	}


	/*
	 *
	 * Webpage connection callbacks
	 *
	 */


	void connected()
	{
		if (playSession is null)
			authenticate();
		else if (csi !is null)
			getServerInfo(csi);
		else
			getServerList();
	}

	void authenticated()
	{
		getServerInfo(csi);
	}

	void serverList(ClassicServerInfo[] csis)
	{
		shutdownConnection();

		r.menu.displayClassicList(csis);
	}

	void serverInfo(ClassicServerInfo csi)
	{
		shutdownConnection();

		r.menu.connectToClassic(csi);
	}

	void error(Exception e)
	{
		shutdownConnection();

		r.menu.displayError(["Disconnected", e.toString()], false);
	}

	void disconnected()
	{
		// The server closed the connection peacefully.
		shutdownConnection();

		r.menu.displayError(["Disconnected"], false);
	}
}

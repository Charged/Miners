// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.classic;

import std.string : format;

import charge.charge;
import charge.game.gui.textbased;

import miners.types;
import miners.options;
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
class ClassicConnectingMenu : public MenuRunnerBase, public ClientListener
{
private:
	ClientConnection cc;
	MessageLogger ml;
	MenuBase mb;
	Text text;
	Router r;


public:
	/**
	 * Create a connection from the server info give, displaying
	 * the connection status as it is made finally creating the
	 * ClassicRunner once a level is loaded.
	 */
	this(Router r, Options opts, ClassicServerInfo csi)
	{
		ml = new MessageLogger();
		cc = new ClientConnection(this, ml, csi);

		this(r, opts, cc, "Connecting");
	}

	/**
	 * This constructor is used we change world, the server
	 * does this by sending levelInitialize packet.
	 */
	this(Router r, Options opts, ClassicConnection cc)
	{
		this.cc = cast(ClientConnection)cc;

		this(r, opts, this.cc, "Changing Worlds");
	}


protected:
	this(Router r, Options opts,
	     ClientConnection cc, char[] startText)
	{
		this.r = r;
		this.cc = cc;
		cc.setListener(this);

		mb = new MenuBase(header, MenuBase.Buttons.CANCEL);
		mb.button.pressed ~= &cancel;

		auto ct = new CenteredText(null, 0, 0,
					   childWidth, childHeight,
					   startText);
		mb.replacePlane(ct);
		text = ct.text;

		mb.repack();

		super(r, opts, mb);
	}


public:
	~this()
	{
		assert(cc is null);
	}

	void close()
	{
		mb.button.pressed -= &cancel;

		super.close();

		if (cc !is null) {
			cc.close();
			cc = null;
		}
	}

	void logic()
	{
		if (cc !is null)
			cc.doPackets();
	}

protected:
	void cancel(Button b)
	{
		r.displayMainMenu();
		r.deleteMe(this);
	}


	/*
	 *
	 * Classic Connection Callbacks
	 *
	 */


	void indentification(ubyte ver, char[] name, char[] motd, ubyte type)
	{
	}

	void levelInitialize()
	{
		auto t = format("Loading level 0%%");
		text.setText(t);
		mb.repack();
	}

	void levelLoadUpdate(ubyte precent)
	{
		auto t = format("Loading level %s%%", precent);
		text.setText(t);
		mb.repack();
	}

	void levelFinalize(uint x, uint y, uint z, ubyte data[])
	{
		auto t = format("Done!");
		text.setText(t);
		mb.repack();

		// Make sure cc is null before breakApart gets called.
		auto tmp = cc;
		cc = null;

		r.connectedTo(tmp, x, y, z, data);
		r.deleteMe(this);
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
		r.displayError(["Disconnected", reason], false);
		r.deleteMe(this);
	}
}


/*
 *
 * Webpage
 *
 */


class WebpageInfoMenu : public MenuRunnerBase, public ClassicWebpageListener
{
private:
	ClassicServerInfo csi;
	WebpageConnection wc;
	MenuBase mb;
	Text text;
	Router r;

	/// Cookie used for authentication.
	char[] playSession;
	/// Username used for authentication
	char[] username;
	/// Password used for authentication
	char[] password;
	/// Current displayed text
	char[] curText = "Error: %s%%";

public:
	/**
	 * Retrive the server list, using a new connection
	 * authenticating with the given credentials.
	 */
	this(Router r, Options opts, char[] playSession)
	{
		auto wc = new WebpageConnection(this, playSession);

		this.playSession = playSession;
		this(r, opts, wc, null, false);
	}

	/**
	 * Retrive information about a server,
	 * the connection has allready be authenticated.
	 */
	this(Router r, Options opts, WebpageConnection wc, ClassicServerInfo csi)
	{
		this(r, opts, wc, csi, true);
	}

	/**
	 * Retrive information about a server, using a new connection
	 * authenticating with the given credentials.
	 */
	this(Router r, Options opts, char[] playSession, ClassicServerInfo csi)
	{
		auto wc = new WebpageConnection(this, playSession);

		this.playSession = playSession;
		this(r, opts, wc, csi, false);
	}

	/**
	 * Retrive information about a server, using a new connection
	 * authenticating with the given credentials.
	 *
	 * Should not use this versions.
	 */
	this(Router r, Options opts, char[] username, char[] password, ClassicServerInfo csi)
	{
		auto wc = new WebpageConnection(this);

		this.username = username;
		this.password = password;
		this(r, opts, wc, csi, false);
	}

	~this()
	{
		assert(wc is null);
	}

	void close()
	{
		super.close();

		shutdownConnection();
	}

	void logic()
	{
		if (wc !is null)
			wc.doTick();
	}


private:
	this(Router r, Options opts,
	     WebpageConnection wc,
	     ClassicServerInfo csi,
	     bool idle)
	{
		this.mb = new MenuBase(header, MenuBase.Buttons.CANCEL);
		this.csi = csi;
		this.wc = wc;
		this.r = r;

		if (idle)
			wc.getServerInfo(csi);

		auto ct = new CenteredText(null, 0, 0,
					   childWidth, childHeight,
					   "Connecting");
		mb.replacePlane(ct);
		mb.button.pressed ~= &cancel;
		text = ct.text;

		mb.repack();

		super(r, opts, mb);
	}

	void shutdownConnection()
	{
		if (wc !is null) {
			try {
				wc.close();
			} catch (Exception e) {
				cast(void)e;
			}

			wc = null;
		}
	}

protected:
	void cancel(Button b)
	{
		r.displayMainMenu();
		r.deleteMe(this);
	}

	void authenticate()
	{
		wc.postLogin(username, password);

		curText = "Authenticating: %s%%";
		percentage(0);
	}

	void getServerList()
	{
		wc.getServerList();

		curText = "Retriving server list: %s%%";
		percentage(0);
	}

	void getServerInfo(ClassicServerInfo csi)
	{
		wc.getServerInfo(csi);

		curText = "Retriving server info: %s%%";
		percentage(0);
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

	void percentage(int p)
	{
		text.setText(format(curText, p));
		mb.repack();
	}

	void authenticated()
	{
		getServerInfo(csi);
	}

	void serverList(ClassicServerInfo[] csis)
	{
		shutdownConnection();

		r.displayClassicList(csis);
		r.deleteMe(this);
	}

	void serverInfo(ClassicServerInfo csi)
	{
		shutdownConnection();

		r.connectToClassic(csi);
		r.deleteMe(this);
	}

	void error(Exception e)
	{
		shutdownConnection();

		r.displayError(["Disconnected", e.toString()], false);
		r.deleteMe(this);
	}

	void disconnected()
	{
		// The server closed the connection peacefully.
		shutdownConnection();

		r.displayError(["Disconnected"], false);
		r.deleteMe(this);
	}
}

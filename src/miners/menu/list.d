// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.list;

import std.math;
import std.string;

import charge.charge;
import charge.game.gui.textbased;
import charge.game.gui.input;

import miners.types;
import miners.interfaces;
import miners.menu.base;
import miners.menu.runner;
import miners.classic.runner;
import miners.classic.webpage;
import miners.classic.connection;
import miners.importer.classicinfo;


const char[] header = `Classic`;
const uint childHeight = 424;
const uint childWidth = 9*16;


class ClassicServerListMenu : public MenuBase
{
private:
	Connector c;
	Button ca;

	const char[] header = `Classic`;

public:
	this(Router r, char[] playCookie)
	{
		super(r, header, Buttons.QUIT);

		c = new Connector(this, 0, 0, playCookie);
		replacePlane(c);

		repack();

		r.menu.setTicker(&logic);
	}

	this(Router r, char[] playCookie, ClassicServerInfo[] csi)
	{
		super(r, header, Buttons.QUIT);

		c = new Connector(this, 0, 0, playCookie, csi);
		replacePlane(c);

		repack();

		r.menu.setTicker(&logic);
	}

	void breakApart()
	{
		auto m = r.menu();

		// Work around shutdown bug.
		if (m !is null)
			m.unsetTicker(&logic);

		super.breakApart();
	}

	void logic()
	{
		if (c.wc !is null)
			c.wc.doEvents();
	}
}

class Connector : public Container, public ClassicWebpageListener
{
private:
	Router r;
	WebpageConnection wc;
	Text text;

	int start;
	ClassicServerInfo[] csis;

	char[] playCookie;
	char[] username;
	char[] password;

private:
	this(Router r, int x, int y, char[] playCookie)
	{
		// Parent needs to be null
		super(null, x, y, 424, 9*16);
		this.r = r;
		this.playCookie = playCookie;
		this.text = new Text(this, 0, 0, "");
	}

public:
	this(ClassicServerListMenu cm, int x, int y, char[] playCookie)
	{
		this(cm.r, x, y, playCookie);

		wc = new WebpageConnection(this, playCookie);
		text.setText("Connecting");

		repack();
	}

	this(ClassicServerListMenu cm, int x, int y,
	     char[] playCookie, ClassicServerInfo[] csis)
	{
		this(cm.r, x, y, playCookie);

		serverList(csis);
	}

	~this()
	{
		assert(wc is null);
	}

	void repack()
	{
		text.x = (w - text.w) / 2;
		text.y = (h - text.h) / 2;
	}

	void breakApart()
	{
		shutdownConnection();
		super.breakApart();
	}

protected:
	void shutdownConnection()
	{
		if (wc !is null) {
			if (wc.connected()) {
				wc.shutdown();
				wc.close();
			}
			wc.wait();
			delete wc;
			wc = null;
		}
	}

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
	 * WebpageConnection handlers.
	 *
	 */


	void connected()
	{
		if (playCookie is null)
			authenticate();
		else
			getServerList();
	}

	void authenticated()
	{
		getServerList();
	}

	void serverList(ClassicServerInfo[] csis)
	{
		shutdownConnection();
		this.csis = csis;

		//foreach(int i, c; csis) {
		//	const string = "fCraft.net Freebuild [ENG]";
		//
		//	if (c.webName.length != string.length)
		//		continue;
		//
		//	if (c.webName != string)
		//		continue;
		//
		//	r.menu.getClassicServerInfoAndConnect(c);
		//}

		string t;
		foreach(int i, c; csis) {
			if (i > 7)
				break;

			t ~= c.webName ~ "\n\n";
		}

		text.setText(t.dup);
		repack();
	}

	void serverInfo(ClassicServerInfo csi)
	{
		shutdownConnection();

		r.menu.connectToClassic(csi);
	}

	void error(Exception e)
	{
		shutdownConnection();

		auto t = format("Connection error!\n%s", e);
		text.setText(t);
		repack();
	}

	void disconnected()
	{
		shutdownConnection();

		auto t = format("Disconnected");
		text.setText(t);
		repack();
	}
}

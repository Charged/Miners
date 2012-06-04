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

public:
	this(ClassicServerListMenu cm, int x, int y, char[] playCookie)
	{
		// Parent needs to be null
		super(null, x, y, 424, 9*16);
		this.r = cm.r;
		this.playCookie = playCookie;

		text = new Text(this, 0, 0, "Connecting");
		wc = new WebpageConnection(this, playCookie);

		repack();
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
		if (wc !is null) {
			wc.shutdown();
			wc.close();
			wc.wait();
			delete wc;
			wc = null;
		}
		super.breakApart();
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
		//	return getServerInfo(c);
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
		wc.shutdown();
		wc.close();
		wc.wait();
		delete wc;
		wc = null;

		r.menu.connectToClassic(csi);
	}

	void error(Exception e)
	{
		wc.shutdown();
		wc.close();
		wc.wait();
		delete wc;
		wc = null;

		auto t = format("Connection error!\n%s", e);
		text.setText(t);
		repack();
	}

	void disconnected()
	{
		// The server closed the connection peacefully.
		delete wc;
		wc = null;
		auto t = format("Disconnected");
		text.setText(t);
		repack();
	}
}

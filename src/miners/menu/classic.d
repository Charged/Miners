// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.classic;

import std.string : format;

import charge.charge;
import charge.game.gui.textbased;

import miners.types;
import miners.menu.base;
import miners.menu.runner;
import miners.classic.runner;
import miners.classic.connection;

const char[] header = `Classic`;
const uint childHeight = 424;
const uint childWidth = 9*16;


/**
 * Displays connection status for a Classic connection.
 */
class ClassicConnectingMenu : public MenuBase
{
private:
	ClientConnector cc;
	Button ca;

public:
	this(MenuRunner mr, ClassicServerInfo csi)
	{
		super(mr, header);
		uint pos;

		pos += 24;
		cc = new ClientConnector(this, 0, pos, csi);
		pos += cc.x + cc.h + 24;
		ca = new Button(this, 0, pos, "Cancel", 8);
		ca.pressed ~= &mr.commonMenuBack;

		repack();

		auto center = plane.w / 2;

		// Center the children
		foreach(c; getChildren) {
			c.x = center - c.w/2;
		}

		mr.ticker = &cc.logic;
	}

public:
	void breakApart()
	{
		if (mr.ticker is &cc.logic)
			mr.ticker = null;
		super.breakApart();
	}
}

class ClientConnector : public Container, public ClientListener
{
private:
	MenuRunner mr;
	ClientConnection cc;
	Text text;

	ClassicServerInfo csi;

public:
	this(ClassicConnectingMenu ccm, int x, int y, ClassicServerInfo csi)
	{
		this.mr = ccm.mr;
		this.csi = csi;
		super(ccm, x, y, childHeight, childWidth);

		text = new Text(this, 0, 0, "Connecting");
		cc = new ClientConnection(this, csi);

		repack();
	}

	~this()
	{
		assert(cc is null);
	}

	void logic()
	{
		if (cc !is null)
			cc.doPackets();
	}

	void repack()
	{
		text.x = (w - text.w) / 2;
		text.y = (h - text.h) / 2;
	}

	void breakApart()
	{
		if (cc !is null) {
			cc.shutdown();
			cc.close();
			cc.wait();
			delete cc;
			cc = null;
		}
		super.breakApart();
	}

protected:

	/*
	 *
	 *
	 *
	 */

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

		auto cr = new ClassicRunner(mr.router, mr.opts,
					    cc, x, y, z, data);
		mr.manageThis(cr);
		cc = null;
		mr.commonMenuClose(null);
	}

	void setBlock(short x, short y, short z, ubyte type) {}

	void playerSpawn(byte id, char[] name, double x, double y, double z,
			 ubyte yaw, ubyte pitch) {}

	void playerMoveTo(byte id, double x, double y, double z,
			  ubyte yaw, ubyte pitch) {}
	void playerMove(byte id, double x, double y, double z,
			ubyte yaw, ubyte pitch) {}
	void playerMove(byte id, double x, double y, double z) {}
	void playerMove(byte id, ubyte yaw, ubyte pitch) {}
	void playerDespawn(byte id) {}
	void playerType(ubyte type) {}

	void ping() {}
	void message(byte id, char[] message) {}
	void disconnect(char[] reason)
	{
		auto f = format("Disconnected: %s", reason);
		mr.displayError([f], false);
	}
}

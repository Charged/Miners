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
	Button ca;
	Text text;

public:
	this(MenuRunner mr, ClassicServerInfo csi)
	{
		super(mr, header, Buttons.CANCEL);
		cc = new ClientConnection(this, csi);
		mr.ticker = &cc.doPackets;

		auto ct = new CenteredText(null, 0, 0,
					   childWidth, childHeight,
					   "Connecting");
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
			disconnectTicker();
			cc.shutdown();
			cc.close();
			cc.wait();
			delete cc;
			cc = null;
		}
	}


private:
	void disconnectTicker()
	{
		if (mr.ticker is &cc.doPackets)
			mr.ticker = null;
	}


	/*
	 *
	 *
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

		auto cr = new ClassicRunner(mr.router, mr.opts,
					    cc, x, y, z, data);
		mr.manageThis(cr);
		disconnectTicker();
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
		mr.displayError(["Disconnected", reason], false);
	}
}

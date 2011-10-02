// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.runner;

import charge.charge;

import miners.types;
import miners.runner;
import miners.viewer;
import miners.options;
import miners.classic.world;
import miners.classic.connection;
import miners.importer.network;


/**
 * Classic runner
 */
class ClassicRunner : public ViewerRunner, public ClientListener
{
private:
	mixin SysLogging;

protected:
	ClientConnection c;
	ClassicWorld w;

public:
	this(Router r, Options opts)
	{
		w = new ClassicWorld(opts);

		super(r, opts, w);
	}

	this(Router r, Options opts,
	     char[] filename)
	{
		w = new ClassicWorld(opts, filename);

		super(r, opts, w);
	}

	this(Router r, Options opts, ClassicServerInfo csi)
	{
		w = new ClassicWorld(opts);

		l.info("Connecting to mc://%s:%s/%s/<redacted>",
		       csi.hostname, csi.port, csi.username);

		c = new ClientConnection(this, csi);
		super(r, opts, w);
	}

	this(Router r, Options opts, ClientConnection c,
	     uint xSize, uint ySize, uint zSize, ubyte[] data)
	{
		this.c = c;
		this.w = new ClassicWorld(opts);
		super(r, opts, w);

		c.setListener(this);
		w.newLevelFromClassic(xSize, ySize, zSize, data);
	}

	~this()
	{
	}

	void close()
	{
		if (c is null)
			return;

		c.shutdown();
		c.close();
		c.wait();
		delete c;
		c = null;
	}

	void logic()
	{
		super.logic();
		if (c !is null)
			c.doPackets();
	}


	/*
	 *
	 * Network functions.
	 *
	 */


	void ping()
	{
	}

	void indentification(ubyte ver, char[] name, char[] motd, ubyte type)
	{
		name = removeColorTags(name);
		motd = removeColorTags(motd);

		l.info("Connected:\n\t%s\n\t%s", name, motd);
	}

	void levelInitialize()
	{
		l.info("levelInitialize: Starting to load level");
	}

	void levelLoadUpdate(ubyte percent)
	{
		//writefln("levelLoadUpdate: %s%%", percent);
	}

	void levelFinalize(uint xSize, uint ySize, uint zSize, ubyte[] data)
	{
		l.info("levelFinalize (%sx%sx%s) %s bytes", xSize, ySize, zSize, data.length);

		w.newLevelFromClassic(xSize, ySize, zSize, data);
	}

	void setBlock(short x, short y, short z, ubyte type)
	{
		//writefln("setBlock (%s, %s, %s) #%s", x, y, z, type);
	}

	void playerSpawn(byte id, char[] name,
			 double x, double y, double z,
			 ubyte yaw, ubyte pitch)
	{
		name = removeColorTags(name);

		//writefln("playerSpawn #%s \"%s\" (%s, %s, %s)", id, name, x, y, z);
	}

	void playerMoveTo(byte id, double x, double y, double z,
			  ubyte yaw, ubyte pitch)
	{
		//writefln("playerMoveTo #%s (%s, %s, %s) %s %s", id, x, y, z, yaw, pitch);
	}

	void playerMove(byte id, double x, double y, double z,
			ubyte yaw, ubyte pitch)
	{
		//writefln("playerMove #%s (%s, %s, %s) %s %s", id, x, y, z, yaw, pitch);
	}

	void playerMove(byte id, double x, double y, double z)
	{
		//writefln("playerMove #%s (%s, %s, %s)", id, x, y, z);
	}

	void playerMove(byte id, ubyte yaw, ubyte pitch)
	{
		//writefln("playerMove #%s %s %s", id, yaw, pitch);
	}

	void playerDespawn(byte id)
	{
		//writefln("playerDespawn #%s", id);
	}

	void playerType(ubyte type)
	{
		//writefln("playerMove type %s", type);
	}

	void message(byte playerId, char[] msg)
	{
		if (playerId)
			l.info("msg: #%s: %s", playerId, removeColorTags(msg));
		else
			l.info("msg: %s", removeColorTags(msg));
	}

	void disconnect(char[] reason)
	{
		auto rs = removeColorTags(reason);

		l.info("Disconnected: \"%s\"", rs);

		r.displayError(["Disconencted", rs], false);
		r.deleteMe(this);
	}
}

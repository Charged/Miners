// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.classic.runner;

import charge.charge;

import minecraft.runner;
import minecraft.viewer;
import minecraft.options;
import minecraft.classic.world;
import minecraft.classic.connection;
import minecraft.importer.network;


/**
 * Classic runner
 */
class ClassicRunner : public ViewerRunner, public ClassicClientNetworkListener
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

	this(Router r, Options opts,
	     char[] hostname, ushort port,
	     char[] username, char[] password)
	{
		w = new ClassicWorld(opts);

		l.info("Connecting to mc://%s:%s/%s", hostname, port, username);

		c = new ClientConnection(this, hostname, port,
					 username, password);
		super(r, opts, w);
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
		l.info("Connected:");
		l.info("\t%s", name);
		l.info("\t%s", motd);
	}

	void levelInitialize()
	{
		//writefln("levelInitialize");
	}

	void levelLoadUpdate(ubyte percent)
	{
		//writefln("lebelLoadUpdate %s", percent);
	}

	void levelFinalize(uint xSize, uint ySize, uint zSize, ubyte[] data)
	{
		l.info("levelFinalize (%sx%sx%s) %s", xSize, ySize, zSize, data.length);

		w.newLevelFromClassic(xSize, ySize, zSize, data);
	}

	void setBlock(short x, short y, short z, ubyte type)
	{
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
			l.info("#%s: %s", playerId, removeColorTags(msg));
		else
			l.info("%s", removeColorTags(msg));
	}

	void disconnect(char[] reason)
	{
		l.info("Disconnected: \"%s\"", removeColorTags(reason));
	}
}

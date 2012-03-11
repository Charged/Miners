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
		if (w is null)
			w = new ClassicWorld(opts);

		super(r, opts, w);
	}

	this(Router r, Options opts,
	     char[] filename)
	{
		w = new ClassicWorld(opts, filename);

		this(r, opts);
	}

	this(Router r, Options opts, ClientConnection c,
	     uint xSize, uint ySize, uint zSize, ubyte[] data)
	{
		this.c = c;
		this.w = new ClassicWorld(opts, xSize, ySize, zSize, data);
		this(r, opts);

		c.setListener(this);
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
	}

	void levelFinalize(uint xSize, uint ySize, uint zSize, ubyte[] data)
	{
		l.info("levelFinalize (%sx%sx%s) %s bytes", xSize, ySize, zSize, data.length);

		w.newLevelFromClassic(xSize, ySize, zSize, data);
	}

	void setBlock(short x, short y, short z, ubyte type)
	{
	}

	void playerSpawn(byte id, char[] name,
			 double x, double y, double z,
			 double heading, double pitch)
	{
		name = removeColorTags(name);
	}

	void playerMoveTo(byte id, double x, double y, double z,
			  double heading, double pitch)
	{
	}

	void playerMove(byte id, double x, double y, double z,
			double heading, double pitch)
	{
	}

	void playerMove(byte id, double x, double y, double z)
	{
	}

	void playerMove(byte id, double heading, double pitch)
	{
	}

	void playerDespawn(byte id)
	{
	}

	void playerType(ubyte type)
	{
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

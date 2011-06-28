// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.classic.runner;

import charge.charge;

import minecraft.world;
import minecraft.runner;
import minecraft.viewer;
import minecraft.gfx.manager;
import minecraft.actors.helper;
import minecraft.terrain.common;
import minecraft.terrain.finite;
import minecraft.classic.connection;
import minecraft.importer.network;
import minecraft.importer.converter;

class ClassicWorld : public World
{
private:
	mixin SysLogging;

	FiniteTerrain ft;

public:
	this(RenderManager rm, ResourceStore rs)
	{
		this.spawn = Point3d(64, 67, 64);

		super(rm, rs);

		// Create initial terrain
		newLevel(128, 128, 128);

		// Set the level with some sort of valid data
		generateLevel(ft);
	}

	~this()
	{
		delete ft;
		ft = null;
		t = null;
	}

	/**
	 * Change the current level
	 */
	void newLevel(uint x, uint y, uint z)
	{
		delete ft;

		ft = new FiniteTerrain(this, rs, x, y, z);
		t = ft;
		t.buildIndexed = rm.textureArray;
		t.setBuildType(rm.bt);
	}

	/**
	 * Replace the current level with one from classic data.
	 *
	 * Flips and convert the data.
	 */
	void newLevelFromClassic(uint xSize, uint ySize, uint zSize, ubyte[] data)
	{
		ubyte from, block, meta;

		newLevel(xSize, ySize, zSize);

		// Get the pointer directly to the data
		auto p = ft.getBlockPointer(0, 0, 0);

		// Flip & convert the world
		for (int x; x < xSize; x++) {
			for (int z; z < zSize; z++) {
				for (int y; y < ySize; y++) {
					from = data[(xSize*y + x) * zSize + z];
					convertClassicToBeta(from, block, meta);
					*p = block;
					p++;
				}
			}
		}
	}

	/**
	 * "Generate" a level.
	 */
	void generateLevel(FiniteTerrain ct)
	{
		for (int x; x < ct.xSize; x++) {
			for (int z; z < ct.zSize; z++) {
				ct[x, 0, z] =  7;
				for (int y = 1; y < ct.ySize; y++) {
					if (y < 64)
						ct[x, y, z] = 1;
					else if (y == 64)
						ct[x, y, z] = 3;
					else if (y == 65)
						ct[x, y, z] = 3;
					else if (y == 66)
						ct[x, y, z] = 2;
					else
						ct[x, y, z] = 0;
				}
			}
		}
	}
}


/**
 * Inbuilt ViewerRunner
 */
class ClassicRunner : public ViewerRunner, public ClassicClientNetworkListener
{
private:
	mixin SysLogging;

protected:
	ClientConnection c;
	ClassicWorld w;

public:
	this(Router r, RenderManager rm, ResourceStore rs)
	{
		w = new ClassicWorld(rm, rs);

		super(r, w, rm);
	}

	this(Router r, RenderManager rm, ResourceStore rs,
	     char[] hostname, ushort port,
	     char[] username, char[] password)
	{
		w = new ClassicWorld(rm, rs);

		l.info("Connecting to mc://%s:%s/%s", hostname, port, username);

		c = new ClientConnection(this, hostname, port,
					 username, password);
		super(r, w, rm);
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

// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.runner;

import charge.charge;
import charge.math.ints;

import miners.types;
import miners.runner;
import miners.viewer;
import miners.options;
import miners.actors.otherplayer;
import miners.classic.world;
import miners.classic.connection;
import miners.importer.network;
import miners.importer.converter;


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

	OtherPlayer players[ubyte.max+1];

	int sentCounter;
	Point3d saveCamPos;
	double saveCamHeading;
	double saveCamPitch;

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

		if (c is null)
			return;

		c.doPackets();

		if (!(sentCounter++ % 5)) {
			auto pos = cam.position;
			if (pos != saveCamPos ||
			    cam_heading != saveCamHeading ||
			    cam_pitch != saveCamPitch) {

				c.sendClientPlayerUpdate(pos.x,
							 pos.y,
							 pos.z,
							 cam_heading,
							 cam_pitch);

				saveCamPos = pos;
				saveCamHeading = cam_heading;
				saveCamPitch = cam_pitch;
			} else {
				sentCounter = 0;
			}
		}
	}

	/*
	 *
	 * Input functions.
	 *
	 */


	void mouseDown(CtlMouse mouse, int button)
	{
		super.mouseDown(mouse, button);

		if ((button != 1 && button != 3) || !grabbed)
			return;

		int xLast, yLast, zLast;
		int numBlocks;

		bool stepPlace(int x, int y, int z) {
			numBlocks++;

			auto b = w.t[x, y, z];
			if (b.type == 0) {
				xLast = x;
				yLast = y;
				zLast = z;
				return true;
			}

			// Lets not replace the block the camera happens to be in.
			if (numBlocks <= 2)
				return false;

			w.t[xLast, yLast, zLast] = Block(3, 0);
			w.t.markVolumeDirty(xLast, yLast, zLast, 1, 1, 1);
			w.t.resetBuild();

			if (c !is null)
				c.sendClientSetBlock(cast(short)xLast,
						     cast(short)yLast,
						     cast(short)zLast,
						     1, 3);

			// We should only place one block.
			return false;
		}

		bool stepRemove(int x, int y, int z) {
			auto b = w.t[x, y, z];

			if (b.type == 0)
				return true;

			w.t[x, y, z] = Block();
			w.t.markVolumeDirty(x, y, z, 1, 1, 1);
			w.t.resetBuild();

			if (c !is null)
				c.sendClientSetBlock(cast(short)x,
						     cast(short)y,
						     cast(short)z,
						     0, 3);

			// We should only remove one block.
			return false;
		}

		auto pos = cam.position;
		auto vec = cam.rotation.rotateHeading();

		if (button == 3)
			stepDirection(pos, vec, 6, &stepPlace);
		else if (button == 1)
			stepDirection(pos, vec, 6, &stepRemove);
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
		Block block;

		convertClassicToBeta(type, block.type, block.meta);
		w.t[x, y, z] = block;
		w.t.markVolumeDirty(x, y, z, 1, 1, 1);
		w.t.resetBuild();
	}

	void playerSpawn(byte id, char[] name,
			 double x, double y, double z,
			 double heading, double pitch)
	{
		name = removeColorTags(name);

		auto index = cast(ubyte)id;

		// Skip this player.
		if (index == 255) {
			cam.position = Point3d(x, y, z);
			cam_heading = heading;
			cam_pitch = pitch;
			return;
		}

		// Should not happen, but we arn't trusting the servers.
		if (players[index] !is null)
			delete players[index];

		double offset = 52.0 / 32.0;
		auto pos = Point3d(x, y - offset, z);
		auto p = new OtherPlayer(w, index, pos, heading, pitch);
		players[index] = p;
	}

	/**
	 * AKA Teleport.
	 */
	void playerMoveTo(byte id, double x, double y, double z,
			  double heading, double pitch)
	{
		auto index = cast(ubyte)id;

		// Skip this player.
		if (index == 255) {
			cam.position = Point3d(x, y, z);
			cam_heading = heading;
			cam_pitch = pitch;
			return;
		}

		auto p = players[index];
		// Stray packets.
		if (p is null)
			return;

		// XXX Don't render the player model at all.
		//if (y == -1024)
		//	return;

		double offset = 52.0 / 32.0;
		auto pos = Point3d(x, y - offset, z);
		p.update(pos, heading, pitch);
	}

	void playerMove(byte id, double x, double y, double z,
			double heading, double pitch)
	{
		auto p = players[cast(ubyte)id];

		// Stray packets.
		if (p is null)
			return;

		auto pos = p.position + Vector3d(x, y, z);
		p.update(pos, heading, pitch);
	}

	void playerMove(byte id, double x, double y, double z)
	{
		auto p = players[cast(ubyte)id];

		// Stray packets.
		if (p is null)
			return;

		auto pos = p.position + Vector3d(x, y, z);
		p.update(pos, p.heading, p.pitch);
	}

	void playerMove(byte id, double heading, double pitch)
	{
		auto p = players[cast(ubyte)id];

		// Stray packets.
		if (p is null)
			return;

		auto pos = p.position;
		p.update(pos, heading, pitch);
	}

	void playerDespawn(byte id)
	{
		auto index = cast(ubyte)id;

		// Skip player.
		if (index == 255)
			return;

		delete players[index];
	}

	void playerType(ubyte type)
	{
		l.info("player type changed %s.", type);
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

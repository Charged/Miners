// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.flayer.runner;

import std.math;
import std.thread;

import lib.loader;
import lib.sdl.sdl;
import lib.mineflayer.mineflayer;

import charge.charge;
import charge.math.ints;

import minecraft.world;
import minecraft.runner;
import minecraft.viewer;
import minecraft.options;
import minecraft.actors.mob;
import minecraft.actors.animals;
import minecraft.actors.otherplayer;
import minecraft.terrain.beta;
import minecraft.terrain.chunk;
import minecraft.flayer.library;

/**
 * MineFlayer Runner
 */
class FlayerRunner : public ViewerRunner, public MfGameListener
{
public:
	/* Mineflayer Related */
	Library lib;

	char[] server;
	char[] user;
	char[] pass;
	ushort port;

	/* Misc state */
	int ticks;
	Mob[int] map;

	MfGame *mf;
	BetaWorld w;

private:
	mixin SysLogging;

public:
	this(Router r, Options opts)
	{
		this.w = new BetaWorld(null, opts);
		super(r, opts, w);

		std.stdio.writefln("You need to edit src/minecraft/flayer/runner.d");
		if (grabbed)
			throw new Exception("You need to edit src/minecraft/flayer/runner.d");

		server = "localhost";
		port = 25565;
		user = "Derpster";
		pass = "PASSWORD";

		std.stdio.writefln("################################");
		std.stdio.writefln("#");
		std.stdio.writefln("# minecraft://%s@%s:%s/", user, server, port);
		std.stdio.writefln("#");
		std.stdio.writefln("################################");

		MfLibrary.init();
		mf = MfGame(user, pass, server, port, this);
	}

protected:
	/*
	 *
	 * Events
	 *
	 */


	/**
	 * Updated the player position.
	 */
	void playerPositionUpdated()
	{
		Point3d pos;
		double height;
		mf.getPlayerPosition(pos, height);

		pos.y += height;
		pcam.position = pos;
	}

	/**
	 * Handle chunk that has been updated.
	 */
	void chunkUpdated(int x, int y, int z, int sx, int sy, int sz)
	{
		int xPos, xOff, zPos, zOff;

		// Walk over the chunks that are updated.
		xPos = cast(int)floor(x/16.0);
		xOff = xPos * 16;
		for (; xOff < x + sx; xOff += 16, xPos++) {
			zPos = cast(int)floor(z/16.0);
			zOff = zPos * 16;
			for (; zOff < z + sz; zOff += 16, zPos++) {
				auto c = w.bt.loadChunk(xPos, zPos);

				// This is clearly outside of what we care about.
				if (c is null)
					continue;

				c.valid = true;
				c.allocBlocksAndData();
				c.markDirty();

				int xStart = imax( 0, x - xOff);
				int zStart = imax( 0, z - zOff);

				int xSize = imin(16, x + sx - xOff) - xStart;
				int zSize = imin(16, z + sz - zOff) - zStart;

				copyToChunk(c, xStart, y, zStart, xSize, sy, zSize);
			}
		}

		// Mark chunks dirty.
		// We must mark all chunks that neighbor a changed block.
		x -= 1;
		z -= 1;
		sx += 2;
		sz += 2;

		xPos = cast(int)floor(x/16.0);
		xOff = xPos * 16;
		for (; xOff < x + sx; xOff += 16, xPos++) {
			zPos = cast(int)floor(z/16.0);
			zOff = zPos * 16;
			for (; zOff < z + sz; zOff += 16, zPos++) {
				auto c = w.bt.loadChunk(xPos, zPos);

				// This is clearly outside of what we care about.
				if (c is null)
					continue;

				c.markDirty();
			}
		}

		// Reset the so we start closer to the player.
		w.bt.buildReset();
	}

	/**
	 * Setup the new Mob, Player or Item.
	 */
	void entitySpawned(int type, int id, Point3d pos,
			   double heading, double pitch, double height)
	{
		Mob m;

		switch(type) {
		case mineflayer_NamedPlayerEntity:
			m = new OtherPlayer(w, id, pos, heading, pitch);
			break;
		case mineflayer_MobEntity:
			m = new Animal(w, id, pos, heading, pitch);
			break;
		default:
		}

		if (m !is null)
			map[id] = m;
	}

	/**
	 * Remove a Mob, Player or Item.
	 */
	void entityDespawned(int id)
	{
		auto mPtr = id in map;
		if (mPtr is null)
			return;

		auto m = *mPtr;

		map.remove(id);
		delete m;
	}

	/**
	 * Move a Mob, Player or Item.
	 */
	void entityMoved(int id, Point3d pos, double heading, double pitch, double height)
	{
		auto mPtr = id in map;
		if (mPtr is null)
			return;

		auto m = *mPtr;
		m.update(pos, heading, pitch);
	}


	/*
	 *
	 * Helper code.
	 *
	 */


	/**
	 * Copy from mineflayer to the chunk.
	 *
	 * Coords in chunk space.
	 */
	void copyToChunk(Chunk c, int x, int y, int z, uint xS, uint yS, uint zS)
	{
		int xOff = c.xPos * 16;
		int zOff = c.zPos * 16;

		for (int px = x; px < x + xS; px++) {
			for (int pz = z; pz < z + zS; pz++) {
				ubyte *bPtr = c.getPointerY(px, pz);
				ubyte *dPtr = c.getDataPointerY(px, pz);

				for (int py = y; py < y+yS; py++) {
					ubyte block, meta;
					mf.getBlock(xOff + px, py, zOff + pz, block, meta);

					bPtr[py] = block;

					int m = py / 2;
					if (py % 2 == 0)
						dPtr[m] = (0xf0 & dPtr[m]) | (meta & 0x0f);
					else
						dPtr[m] = (0x0f & dPtr[m]) | ((meta << 4) & 0xf0);
				}
			}
		}
	}


	/*
	 *
	 * Runner and input callbacks
	 *
	 */


	/**
	 * Called each step, which is 100 times a second.
	 */
	void logic()
	{
		mf.doCallbacks();

		if (ticks++ > 1) {
			mf.setPlayerLook(cam_heading, cam_pitch);
			ticks = 0;
		}

		super.logic();
	}

	/**
	 * Keyboard pressed.
	 */
	void keyDown(CtlKeyboard kb, int sym)
	{
		switch(sym) {
		case SDLK_w:
			mf.setControl(mineflayer_ForwardControl, true);
			break;
		case SDLK_s:
			mf.setControl(mineflayer_BackControl, true);
			break;
		case SDLK_a:
			mf.setControl(mineflayer_LeftControl, true);
			break;
		case SDLK_d:
			mf.setControl(mineflayer_RightControl, true);
			break;
		case SDLK_e:
			break;
		case SDLK_LSHIFT:
			mf.setControl(mineflayer_CrouchControl, true);
			break;
		case SDLK_SPACE:
			mf.setControl(mineflayer_JumpControl, true);
			break;
		default:
			super.keyDown(kb, sym);
		}
	}

	/**
	 * Keyboard released.
	 */
	void keyUp(CtlKeyboard kb, int sym)
	{
		switch(sym) {
		case SDLK_w:
			mf.setControl(mineflayer_ForwardControl, false);
			break;
		case SDLK_s:
			mf.setControl(mineflayer_BackControl, false);
			break;
		case SDLK_a:
			mf.setControl(mineflayer_LeftControl, false);
			break;
		case SDLK_d:
			mf.setControl(mineflayer_RightControl, false);
			break;
		case SDLK_LSHIFT:
			mf.setControl(mineflayer_CrouchControl, false);
			break;
		case SDLK_SPACE:
			mf.setControl(mineflayer_JumpControl, false);
			break;
		default:
			super.keyUp(kb, sym);
		}
	}
}

// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.flayer.library;

import std.stdio;

import charge.math.point3d;
import charge.math.vector3d;
import charge.math.quatd;

import lib.loader;

import lib.mineflayer.mineflayer;

class MfLibrary
{
	static Library lib;

	static void init()
	{
		char[] libName = "libmineflayer-core.so";
		char[][] libNames;

		libNames ~= libName;

		lib = Library.loads(libNames);

		if (lib is null) {
			std.stdio.writefln("Could not find mineflayer looked for: ", libNames);
			throw new Exception("");
		}

		loadMineflayer(&lib.symbol);
	}
}

/**
 * Listener for events comming from a MineFlayer game.
 */
interface MfGameListener
{
	void playerPositionUpdated();
	void chunkUpdated(int x, int y, int z, int sx, int sy, int sz);

	void entitySpawned(int type, int id, Point3d pos,
			   double heading, double pitch, double height);
	void entityDespawned(int id);
	void entityMoved(int id, Point3d pos, double heading, double pitch, double height);
}

/**
 * Represents a MineFlayer game.
 *
 * We do some tricks and turn a "real" MineFlayer game pointer into
 * this game struct to get better syntax. This also takes care of
 * going between the different coordinate systems.
 */
struct MfGame
{
	static MfGame* opCall(char[] user, char[] pass,
			      char[] server, ushort port,
			      MfGameListener gl)
	{
		mineflayer_Callbacks cbs;
		cbs.playerPositionUpdated = &cbPlayerPositionUpdated;
		cbs.chunkUpdated = &cbChunkUpdated;
		cbs.loginStatusUpdated = &cbLoginStatusUpdated;
		cbs.entitySpawned = &cbEntitySpawned;
		cbs.entityDespawned = &cbEntityDespawned;
		cbs.entityMoved = &cbEntityMoved;

		mineflayer_Url url;
		url.username = mineflayer_Utf8(user);
		url.password = mineflayer_Utf8(pass);
		url.hostname = mineflayer_Utf8(server);
		url.port = port;

		auto ret = mineflayer_createGamePullCallbacks(url, cbs, cast(void*)gl);
		return cast(MfGame*)ret;
	}

	/**
	 * Get a single block from Mineflayer.
	 *
	 * Handles coord conversions for us.
	 */
	void getBlock(int x, int y, int z, out ubyte block, out ubyte meta)
	{
		auto game = cast(mineflayer_GamePtr)this;

		// Mineflayer has switched the axies around and flipped them.
		auto b = mineflayer_blockAt(game, mineflayer_Int3D(x, y, z));
		block = cast(ubyte)b.type;
		meta = cast(ubyte)b.metadata;
	}

	/**
	 * Return player position.
	 */
	void getPlayerPosition(out Point3d pos, out double height)
	{
		auto game = cast(mineflayer_GamePtr)this;

		auto ep = mineflayer_playerPosition(game);
		auto p = ep.pos;
		auto d = ep.height;

		pos = Point3d(ep.pos.x, ep.pos.y, ep.pos.z);
		height = ep.height;
	}

	void setPlayerLook(double heading, double pitch)
	{
		auto game = cast(mineflayer_GamePtr)this;

		mineflayer_setPlayerLook(game, heading, pitch, 0);
	}

	void doCallbacks()
	{
		auto game = cast(mineflayer_GamePtr)this;

		mineflayer_doCallbacks(game);
	}

	void setControl(mineflayer_Control c, bool active)
	{
		auto game = cast(mineflayer_GamePtr)this;

		mineflayer_setControlActivated(game, c, active);
	}


	/*
	 *
	 * Callbacks
	 *
	 */


	/**
	 * Transforms a Mineflayer chunkUpdate into charge coords.
	 */
	extern(C) static void cbChunkUpdated(void *ctx, mineflayer_Int3D s, mineflayer_Int3D sz)
	{
		auto gl = cast(MfGameListener)ctx;

		// Need to convert the coords from Mineflayer to Charge coords.
		gl.chunkUpdated(s.x, s.y, s.z, sz.x, sz.y, sz.z);
	}

	/**
	 * Transforms a Mineflayer playerPositionUpdated into charge coords.
	 */
	extern(C) static void cbPlayerPositionUpdated(void *ctx)
	{
		auto gl = cast(MfGameListener)ctx;

		// Need to convert the coords from Mineflayer to Charge coords.
		gl.playerPositionUpdated();
	}

	/**
	 * Transforms a Mineflayer entitySpawned into charge coords.
	 */
	extern(C) static void cbEntitySpawned(void *ctx, mineflayer_Entity *me)
	{
		auto gl = cast(MfGameListener)ctx;

		auto type = me.type;
		auto id = me.entity_id;
		auto p = Point3d(me.position.pos.x, me.position.pos.y, me.position.pos.z);
		auto heading = me.position.yaw;
		auto pitch = me.position.pitch;
		auto h = me.position.height;

		gl.entitySpawned(me.type, id, p, heading, pitch, h);
	}

	/**
	 * Just route a despawn event.
	 */
	extern(C) static void cbEntityDespawned(void *ctx, mineflayer_Entity *me)
	{
		auto gl = cast(MfGameListener)ctx;

		auto id = me.entity_id;

		gl.entityDespawned(id);
	}

	/**
	 * Transforms a Mineflayer entityMoved into charge coords.
	 */
	extern(C) static void cbEntityMoved(void *ctx, mineflayer_Entity *me)
	{
		auto gl = cast(MfGameListener)ctx;

		auto id = me.entity_id;
		auto p = Point3d(me.position.pos.x, me.position.pos.y, me.position.pos.z);
		auto r = Quatd(me.position.yaw, me.position.pitch, 0);
		auto heading = me.position.yaw;
		auto pitch = me.position.pitch;
		auto h = me.position.height;

		gl.entityMoved(id, p, heading, pitch, h);
	}


	/*
	 *
	 * Debug junk!
	 *
	 */


    	extern(C) static void cbLoginStatusUpdated(void *ctx, mineflayer_LoginStatus status)
	{
		switch(status) {		
		case mineflayer_DisconnectedStatus:
			std.stdio.writefln("mineflayer_DisconnectedStatus");
			assert(false);
		case mineflayer_ConnectingStatus:
			std.stdio.writefln("mineflayer_ConnectingStatus");
			break;
		case mineflayer_WaitingForHandshakeResponseStatus:
			std.stdio.writefln("mineflayer_WaitingForHandshakeResponseStatus");
			break;
		case mineflayer_WaitingForSessionIdStatus:
			std.stdio.writefln("mineflayer_WaitingForSessionIdStatus");
			break;
		case mineflayer_WaitingForNameVerificationStatus:
			std.stdio.writefln("mineflayer_WaitingForNameVerificationStatus");
			break;
		case mineflayer_WaitingForLoginResponseStatus:
			std.stdio.writefln("mineflayer_WaitingForLoginResponseStatus");
			break;
		case mineflayer_SuccessStatus:
			std.stdio.writefln("mineflayer_SuccessStatus");
			break;
		case mineflayer_SocketErrorStatus:
			std.stdio.writefln("mineflayer_SocketErrorStatus");
			assert(false);
		default:
			std.stdio.writefln("mineflayer_LoginStatus Uknown");
			assert(false);
		}
	}
}

// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.interfaces;


/**
 * A classic connection interface.
 */
interface ClassicClientConnection
{
	void setListener(ClassicClientListener l);

	/*
	 * Message Listener
	 */

	void setMessageListener(ClassicClientMessageListener ml);
	ClassicClientMessageListener getMessageListener();
}

/**
 * Receiver of client packages from a ClientConnection.
 */
interface ClassicClientListener
{
	void indentification(ubyte ver, string name, string motd, ubyte type);

	void levelInitialize();
	void levelLoadUpdate(ubyte precent);
	void levelFinalize(uint x, uint y, uint z, ubyte[] data);

	void disconnect(string reason);

	/*
	 * These packets are what normaly comes during gameplay.
	 */

	void setBlock(short x, short y, short z, ubyte type);

	void playerSpawn(byte id, string name, double x, double y, double z,
			 double heading, double pitch);

	void playerMoveTo(byte id, double x, double y, double z,
			  double heading, double pitch);
	void playerMove(byte id, double x, double y, double z,
			double heading, double pitch);
	void playerMove(byte id, double x, double y, double z);
	void playerMove(byte id, double heading, double pitch);
	void playerDespawn(byte id);
	void playerType(ubyte type);

	void ping();
}

/**
 * Receiver of client messages from a ClientConnection.
 */
interface ClassicClientMessageListener
{
	void archive(byte id, string message);

	/*
	 * Player tracking.
	 */

	void addPlayer(byte id, string name);
	void removePlayer(byte id);
	void removeAllPlayers();
}

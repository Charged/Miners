// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module robbers.world;

import charge.charge;
import robbers.network;

import robbers.actors.gold;


class World : GameWorld
{
private:
	NetworkSender ns;
	bool isServer;
	uint generation;
	SyncPacketManager syncMan;

	mixin SysLogging;

public:

	alias Vector!(NetworkObject) NetObjVector;

	NetObjVector netobjs;
	GoldManager gm;

	GfxProjCamera camera;

	this(NetworkSender ns, bool server)
	{
		super();
		this.isServer = server;
		phy.setStepLength(10);
		this.ns = ns;

		if (!isServer)
			syncMan = new SyncPacketManager(0);

		gm = new GoldManager(this);
	}

	~this()
	{

	}

	void tick()
	{
		foreach(t; tickers)
			t.tick();

		phy.tick();

		generation++;

		if (syncMan) {
			syncMan.setGen(generation);
			syncMan.pushPackets();			
		}
	}

	/*
	 * Misc
	 */

	bool server()
	{
		return isServer;
	}

	NetworkSender net()
	{
		return ns;
	}

	uint gen()
	{
		return generation;
	}

	void updateGeneration(uint gen)
	{
		this.generation = gen;
	}

	SyncPacketManager sync()
	{	
		return syncMan;
	}
}

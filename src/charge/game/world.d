// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for World, Actor and Ticker.
 */
module charge.game.world;

import charge.util.vector;
import charge.math.movable;
import charge.gfx.world;
import charge.phy.world;
import charge.sys.resource : Pool;


/**
 * Base class for all actors inside a World.
 */
abstract class Actor : Movable
{
public:
	World w;


public:
	this(World world)
	{
		this.w = world;
		w.add(this);
	}

	~this()
	{
		w.rem(this);
	}

}

/**
 * When added to World recieves a tick ever logic step.
 */
interface Ticker
{
	void tick();
}

/**
 * Container object for other sub system Worlds and actors.
 */
class World
{
public:
	Pool pool;

	alias Vector!(Actor) ActorVector;
	alias Vector!(Ticker) TickerVector;

	ActorVector actors;
	TickerVector tickers;

	charge.gfx.world.World gfx;
	charge.phy.world.World phy;


public:
	this(Pool p)
	in {
		assert(p !is null);
	}
	body {
		this.pool = p;

		if (charge.gfx.gfx.gfxLoaded) {
			gfx = new charge.gfx.world.World(pool);
		}

		if (charge.phy.phy.phyLoaded) {
			phy = new charge.phy.world.World(pool);
			phy.setStepLength(10);
		}
	}

	~this()
	{
		Actor a;

		while((a = actors[0]) !is null)
			delete a;
	}

	void tick()
	{
		if (charge.phy.phy.phyLoaded)
			phy.tick();

		foreach(t; tickers)
			t.tick();
	}


	/*
	 * Vector access
	 */


	void add(Actor a)
	{
		actors.add(a);
	}

	void addTicker(Ticker t)
	{
		tickers.add(t);
	}

	void rem(Actor a)
	{
		actors.remove = a;
	}

	void remTicker(Ticker t)
	{
		tickers.remove(t);
	}
}

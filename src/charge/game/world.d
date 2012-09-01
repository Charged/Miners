// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.game.world;

import charge.util.vector;
import charge.math.movable;
import charge.gfx.world;
import charge.phy.world;

interface Ticker
{
	void tick();
}

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

class World
{
private:
	charge.gfx.world.World gfxWorld;
	charge.phy.world.World phyWorld;

public:

	alias charge.gfx.world.World GfxWorld;
	alias charge.phy.world.World PhyWorld;

	alias Vector!(Actor) ActorVector;
	alias Vector!(Ticker) TickerVector;

	ActorVector actors;
	TickerVector tickers;

	this()
	{
		if (charge.gfx.gfx.gfxLoaded) {
			gfxWorld = new GfxWorld();
		}

		if (charge.phy.phy.phyLoaded) {
			phyWorld = new PhyWorld();
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
		actors.add = a;
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

	/*
	 * Misc
	 */

	GfxWorld gfx()
	{
		return gfxWorld;
	}

	PhyWorld phy()
	{
		return phyWorld;
	}

}

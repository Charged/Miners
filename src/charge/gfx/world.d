// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for World and Actor.
 */
module charge.gfx.world;

import charge.util.vector;
import charge.math.movable;

import charge.gfx.gfx;
import charge.gfx.renderqueue;
import charge.gfx.cull;
import charge.gfx.light;
import charge.gfx.texture;


/**
 * Base class for all graphics actors.
 */
abstract class Actor : Movable
{
private:
	World w;

public:
	this(World w)
	{
		assert(w !is null);
		this.w = w;

		w.add(this);
	}

	~this()
	{
		if (w !is null)
			w.remove(this);
		w = null;
	}

	void build() {}

	abstract void cullAndPush(Cull cull, RenderQueue rq);
}

/**
 * Base class for all lights.
 */
abstract class Light : Movable
{
public:
	World w;


public:
	this(World w)
	{
		assert(w !is null);
		this.w = w;
		w.add(this);
	}

	~this()
	{
		if (w !is null) {
			w.remove(this);
			w = null;
		}
	}
}

/**
 * Container for graphics actors and lights.
 */
class World
{
public:
	alias Vector!(Actor) ActorVector;
	alias Vector!(Light) LightVector;
	Fog fog;
	Texture bg; /** Used as a background image */


private:
	ActorVector a;
	LightVector l;


public:
	this()
	{
		if (!charge.gfx.gfx.gfxLoaded)
			throw new Exception("gfx module not loaded");
	}

	~this()
	{
		// Ugh this needs to be done else where.
		assert(bg is null);

		Actor actor;
		/* vector not safe to traverse while removing elements */
		while((actor = a[0]) !is null)
			delete actor;

		Light light;
		/* vector not safe to traverse while removing elements */
		while((light = l[0]) !is null)
			delete light;
	}

	/**
	 * Returns the actors vector.
	 * In some regards i is a copy.
	 * In other it isn't since interal array is shared.
	 */
	ActorVector actors()
	{
		return a;
	}

	/**
	 * Returns the actors vector.
	 * In some regards i is a copy.
	 * In other it isn't since interal array is shared.
	 */
	LightVector lights()
	{
		return l;
	}


protected:
	void add(Light l)
	{
		this.l.add(l);
	}

	void remove(Light l)
	{
		this.l.remove(l);
	}

	void add(Actor a)
	{
		this.a.add(a);
	}

	void remove(Actor a)
	{
		this.a.remove(a);
	}
}

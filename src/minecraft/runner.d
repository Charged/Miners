// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.runner;

import std.math;
import lib.sdl.sdl;

import charge.charge;

import minecraft.world;
import minecraft.terrain.chunk;
import minecraft.terrain.vol;

/**
 * Base class for game logic or viewer logic runners.
 */
class Runner
{
public:
	World w;

	GfxCamera cam;

private:
	mixin SysLogging;

public:
	this(World w)
	{
		this.w = w;
	}

	~this()
	{
	}

	abstract void resize(uint w, uint h);
	abstract void logic();

	bool build()
	{
		if (w !is null && w.vt !is null)
			return w.vt.buildOne();
		else
			return false;
	}
}

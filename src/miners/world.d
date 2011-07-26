// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.world;

import std.math;

import charge.charge;

import miners.options;
import miners.builder.data;
import miners.terrain.beta;
import miners.terrain.common;
import miners.importer.info;


/**
 * Base class for different world types.
 */
abstract class World : public GameWorld
{
public:
	Options opts; /** Shared with other worlds */
	Terrain t;
	Point3d spawn;

private:
	mixin SysLogging;

public:
	this(Options opts)
	{
		super();
		this.opts = opts;
	}

	~this()
	{
		delete t;
		t = null;
	}
}

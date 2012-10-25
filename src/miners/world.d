// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.world;

import charge.charge;

import miners.options;
import miners.terrain.common;


/**
 * Base class for different world types.
 */
abstract class World : GameWorld
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
		super(SysPool());
		this.opts = opts;
	}

	~this()
	{
		assert(t is null);
	}

	void breakApart()
	{
		breakApartAndNull(t);
		super.breakApart();
	}
}

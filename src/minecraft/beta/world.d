// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.beta.world;

import std.math;

import charge.charge;

import minecraft.world;
import minecraft.options;
import minecraft.builder.data;
import minecraft.terrain.beta;
import minecraft.terrain.common;
import minecraft.importer.info;


/**
 * World containing a infite beta world.
 */
class BetaWorld : public World
{
public:
	BetaTerrain bt;
	char[] dir;

public:
	this(MinecraftLevelInfo *info, Options opts)
	{
		this.spawn = info ? info.spawn : Point3d(0, 64, 0);
		this.dir = info ? info.dir : null;
		super(opts);

		t = bt = new BetaTerrain(this, dir, opts);

		// Find the actuall spawn height
		auto x = cast(int)spawn.x;
		auto y = cast(int)spawn.y;
		auto z = cast(int)spawn.z;
		auto xPos = x < 0 ? (x - 15) / 16 : x / 16;
		auto zPos = z < 0 ? (z - 15) / 16 : z / 16;

		bt.setCenter(xPos, zPos);
		bt.loadChunk(xPos, zPos);

		auto p = bt.getPointerY(x, z);
		for (int i = y; i < 128; i++) {
			if (tile[p[i]].filled)
				continue;
			if (tile[p[i+1]].filled)
				continue;

			spawn.y = i;
			break;
		}
	}
}

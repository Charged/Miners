// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.world;

import std.math;

import charge.charge;

import minecraft.gfx.manager;
import minecraft.terrain.data;
import minecraft.terrain.beta;
import minecraft.terrain.common;
import minecraft.actors.helper;
import minecraft.importer.info;

abstract class World : public GameWorld
{
public:
	RenderManager rm; /** Shared with other worlds */
	ResourceStore rs; /** Shared with other worlds */
	Terrain t;
	Point3d spawn;

private:
	mixin SysLogging;

public:
	this(RenderManager rm, ResourceStore rs)
	{
		super();
		this.rm = rm;
		this.rs = rs;
	}

	~this()
	{
		delete t;
	}

	void switchRenderer()
	{
		rm.switchRenderer();
		t.setBuildType(rm.bt);
	}

protected:

}

class BetaWorld : public World
{
public:
	BetaTerrain bt;
	char[] dir;

public:
	this(MinecraftLevelInfo *info, RenderManager rm, ResourceStore rs)
	{
		this.spawn = info ? info.spawn : Point3d(0, 64, 0);
		this.dir = info ? info.dir : null;
		super(rm, rs);

		bt = new BetaTerrain(this, dir, rs);
		t = bt;
		t.buildIndexed = rm.textureArray;
		t.setBuildType(rm.bt);

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

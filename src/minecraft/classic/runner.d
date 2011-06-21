// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.classic.runner;

import charge.charge;

import minecraft.world;
import minecraft.runner;
import minecraft.viewer;
import minecraft.gfx.manager;
import minecraft.actors.helper;
import minecraft.terrain.common;
import minecraft.terrain.finite;


class ClassicWorld : public World
{
private:
	mixin SysLogging;

	FiniteTerrain ct;

public:
	this(RenderManager rm, ResourceStore rs)
	{
		this.spawn = Point3d(64, 67, 64);
		super(rm, rs);

		ct = new FiniteTerrain(this, rs, 128, 128, 128);
		t = ct;
		t.buildIndexed = rm.textureArray;
		t.setBuildType(rm.bt);

		generateLevel(ct);
	}

	/**
	 * "Generate" a level.
	 */
	void generateLevel(FiniteTerrain ct)
	{
		for (int x; x < ct.xSize; x++) {
			for (int z; z < ct.zSize; z++) {
				ct[x, 0, z] =  7;
				for (int y = 1; y < ct.ySize; y++) {
					if (y < 64)
						ct[x, y, z] = 1;
					else if (y == 64)
						ct[x, y, z] = 3;
					else if (y == 65)
						ct[x, y, z] = 3;
					else if (y == 66)
						ct[x, y, z] = 2;
					else
						ct[x, y, z] = 0;
				}
			}
		}
	}
}

/**
 * Inbuilt ViewerRunner
 */
class ClassicRunner : public ViewerRunner
{
private:
	mixin SysLogging;

public:
	this(Router r, RenderManager rm, ResourceStore rs)
	{
		w = new ClassicWorld(rm, rs);
		super(r, w, rm);
	}
}

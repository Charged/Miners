// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module box.cube;

import charge.charge;
import box.world;


class Cube : GameActor, GameTicker
{
public:
	GfxCube gfx;
	PhyCube phy;

public:
	this(World w)
	{
		super(w);
		w.addTicker(this);

		gfx = new charge.gfx.cube.Cube(w.gfx);
		phy = new charge.phy.cube.Cube(w.phy);
	}

	~this()
	{
		assert(gfx is null);
		assert(phy is null);
	}

	void breakApart()
	{
		w.remTicker(this);
		breakApartAndNull(gfx);
		breakApartAndNull(phy);
		super.breakApart();
	}

	void tick()
	{
		gfx.position = phy.position;
		gfx.rotation = phy.rotation;
	}

	void setPosition(ref Point3d pos) { phy.setPosition(pos); gfx.setPosition(pos); }
	void getPosition(out Point3d pos) { phy.getPosition(pos); }
	void setRotation(ref Quatd rot) { phy.setRotation(rot); gfx.setRotation(rot); }
	void getRotation(out Quatd rot) { phy.getRotation(rot); }
}

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

	override void breakApart()
	{
		w.remTicker(this);
		breakApartAndNull(gfx);
		breakApartAndNull(phy);
		super.breakApart();
	}

	override void tick()
	{
		gfx.position = phy.position;
		gfx.rotation = phy.rotation;
	}

	override void setPosition(ref Point3d pos) { phy.setPosition(pos); gfx.setPosition(pos); }
	override void getPosition(out Point3d pos) { phy.getPosition(pos); }
	override void setRotation(ref Quatd rot) { phy.setRotation(rot); gfx.setRotation(rot); }
	override void getRotation(out Quatd rot) { phy.getRotation(rot); }
}

// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.actors.animals;

import charge.charge;

import minecraft.world;
import minecraft.actors.mob;


/**
 * Animal base mob.
 */
class Animal : public Mob
{
public:
	GfxCube thing;

public:
	this(World w, int id, Point3d pos, double heading, double pitch)
	{
		super(w, id);

		thing = new GfxCube(w.gfx);
		update(pos, heading, pitch);
	}

	~this()
	{
		delete thing;
	}

	void update(Point3d pos, double heading, double pitch)
	{
		auto rot = Quatd(heading, pitch, 0);
		GameActor.setPosition(pos);
		GameActor.setRotation(rot);

		pos.y += 0.5;
		thing.position = pos;
		thing.rotation = rot;
	}
}

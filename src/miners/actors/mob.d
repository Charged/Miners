// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.actors.mob;

import charge.charge;

import miners.world;


/**
 * Base class for OtherPlayers and Mobs.
 */
class Mob : GameActor
{
public:
	World w;

	int id;
	Vector3d vel;

public:
	this(World w, int id)
	{
		super(w);
		this.w = w;
		this.id = id;
		this.vel = Vector3d();
	}

	/**
	 * Get a update from game logic or server.
	 */
	abstract void update(Point3d pos, double heading, double pitch);

	/**
	 * Can't set position the normal way on mobs.
	 */
	void setPosition(ref Point3d pos)
	{
		assert(false);
	}

	/**
	 * Can't set rotation the normal way on mobs.
	 */
	void setRotation(ref Quatd rot)
	{
		assert(false);
	}
}

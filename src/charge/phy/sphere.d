// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.phy.sphere;

import charge.math.movable;

import charge.phy.ode;
import charge.phy.actor;
import charge.phy.world;


class Sphere : Body
{
	this(World w, Point3d pos)
	{
		super(w, pos);

		massSetSphere(1.0, 0.5);
		collisionSphere(0.5);
	}
}

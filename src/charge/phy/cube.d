// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for Cube.
 */
module charge.phy.cube;

import charge.phy.ode;
import charge.phy.actor;
import charge.phy.world;


class Cube : Body
{
public:
	this(World phy)
	{
		super(phy, pos);

		massSetBox(1.0, 1.0, 1.0, 1.0);
		collisionBox(1.0, 1.0, 1.0);
	}
}

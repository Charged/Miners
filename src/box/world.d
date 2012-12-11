// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module box.world;

import charge.charge;


/**
 * Box World.
 */
class World : GameWorld
{
	this()
	{
		super(SysPool());
	}
}

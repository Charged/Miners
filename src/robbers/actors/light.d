// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module robbers.actors.light;

import charge.charge;
import robbers.world;


class SunLight : GameActor
{
private:
	GfxSimpleLight light;

public:
	this(World w, Point3d pos, Quatd rot, bool shadow)
	{
		super(w);

		light = new GfxSimpleLight();
		light.position = pos;
		light.rotation = rot;
		light.shadow = shadow;
		w.gfx.add(light);
	}

}

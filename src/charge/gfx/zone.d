// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.gfx.zone;

import charge.gfx.world;
import charge.gfx.renderqueue;
import charge.gfx.cull;

class Zone
{
public:

	abstract void add(Actor a);

	abstract void remove(Actor a);

	void cullAndPush(Cull c, RenderQueue rq)
	{

	}

}

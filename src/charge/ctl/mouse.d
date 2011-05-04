// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.ctl.mouse;

import charge.util.signal;
import charge.ctl.device;

class Mouse : public Device
{
private:


public:
	Signal!(Mouse, int, int) move;
	Signal!(Mouse, int) down;
	Signal!(Mouse, int) up;

	~this()
	{
		move.destruct();
		down.destruct();
		up.destruct();
	}
}

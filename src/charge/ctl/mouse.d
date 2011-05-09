// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.ctl.mouse;

import charge.util.signal;
import charge.ctl.device;

class Mouse : public Device
{
public:
	int state; /**< Mask of button state, 1 == pressed */
	int x;
	int y;

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

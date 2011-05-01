// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.ctl.keyboard;

import charge.util.signal;
import charge.ctl.device;

class Keyboard : public Device
{
private:

public:
	Signal!(Keyboard, int) down;
	Signal!(Keyboard, int) up;

	~this()
	{
		down.destruct();
		up.destruct();
	}
}

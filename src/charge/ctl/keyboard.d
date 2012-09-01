// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.ctl.keyboard;

import charge.util.signal;
import charge.ctl.device;

import lib.sdl.keysym;

class Keyboard : Device
{
public:
	int mod;

public:
	Signal!(Keyboard, int, dchar, char[]) down;
	Signal!(Keyboard, int) up;

	~this()
	{
		down.destruct();
		up.destruct();
	}

	final bool ctrl()
	{
		return (mod & KMOD_CTRL) != 0;
	}

	final bool alt()
	{
		return (mod & KMOD_ALT) != 0;
	}

	final bool meta()
	{
		return (mod & KMOD_META) != 0;
	}

	final bool shift()
	{
		return (mod & KMOD_SHIFT) != 0;
	}
}

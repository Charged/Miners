// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.ion.runner;

import charge.charge;

import miners.world;
import miners.runner;
import miners.viewer;
import miners.options;
import miners.interfaces;
import miners.classic.world;
import miners.actors.camera;
import miners.actors.sunlight;
import miners.actors.otherplayer;


/**
 * IonRunner
 */
class IonRunner : public ViewerRunner
{
private:
	mixin SysLogging;

public:
	this(Router r, Options opts)
	{
		super(r, opts, new ClassicWorld(opts));
	}

	~this()
	{
	}

	void logic()
	{
		super.logic();
	}
}

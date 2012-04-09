// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.ion.runner;

import charge.charge;

import miners.world;
import miners.runner;
import miners.viewer;
import miners.options;
import miners.interfaces;
import miners.ion.dcpu;
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

	Dcpu c;
	bool cpuRunning;

public:
	this(Router r, Options opts)
	{
		super(r, opts, new ClassicWorld(opts));

		c = Dcpu_Create();

		Dcpu_SetSysCall(c, &exit, 0, cast(void*)this);
		cpuRunning = true;
	}

	~this()
	{
		Dcpu_Destroy(&c);
	}

	void logic()
	{
		super.logic();

		if (!cpuRunning)
			return;

		Dcpu_Execute(c, 10000);

		auto m = Dcpu_GetRam(c);
	}

	extern(C) static void exit(Dcpu c, void *data)
	{
		auto ir = cast(IonRunner)data;

		auto v = Dcpu_GetRegister(ir.c, Dcpu_Register.DR_A);
		Dcpu_SetRegister(ir.c, Dcpu_Register.DR_A, v);

		Dcpu_Push(ir.c, v);
		Dcpu_Pop(ir.c);
	}

}

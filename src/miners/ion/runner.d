// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.ion.runner;

import std.stdio;
static import std.file;

import lib.dcpu.dcpu;

import charge.charge;

import charge.game.gui.container;
import charge.game.gui.messagelog;

import miners.world;
import miners.runner;
import miners.viewer;
import miners.options;
import miners.interfaces;
import miners.ion.texture;
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
	DpcuTexture ct;
	GfxDraw d;
	GfxSpotLight sl;

public:
	this(Router r, Options opts, char[] file)
	{
		if (file is null)
			file = "a.dcpu16";

		auto mem = cast(ushort[])std.file.read(file);

		super(r, opts, new ClassicWorld(opts));

		c = Dcpu_Create();

		cpuRunning = true;
		Dcpu_SetSysCall(c, &cPrintf, 2, cast(void*)this);

		Dcpu_GetRam(c)[0 .. mem.length] = mem;

		d = new GfxDraw();
		ct = new DpcuTexture(Dcpu_GetRam(c));

		sl = new GfxSpotLight();
		w.gfx.add(sl);
	}

	~this()
	{
		if (c !is null)
			Dcpu_Destroy(&c);

		if (ct !is null) {
			ct.destruct();
			ct = null;
		}
	}

	void render()
	{

	}

	void logic()
	{
		super.logic();

		if (!cpuRunning)
			return;

		cpuRunning = Dcpu_Execute(c, 10000) == 1;

		auto m = Dcpu_GetRam(c);
	}

	void render(GfxRenderTarget rt)
	{
		cam.resize(rt.width, rt.height);

		sl.position = cam.position + cam.rotation * Vector3d(.5, -.5, 0);
		sl.rotation = Quatd(cam_heading, cam_pitch, 0);

		r.render(w.gfx, cam.current, rt);

		ct.paint();
		auto t = ct.texture;

		int x = rt.width / 2 - t.width / 2;
		int y = rt.height / 2 - t.height / 2;

		d.target = rt;
		d.start();
		d.blit(t, x, y);
		d.stop();
	}

	void printf()
	{
		auto v = Dcpu_Pop(c);
		auto s = Dcpu_GetRam(c)[v .. ushort.max];
		foreach (c; s) {
			if (!c)
				break;
			writef(cast(char)(0x7f & c));
		}
	}

	extern(C) static void cPrintf(Dcpu me, void *data)
	{
		auto ir = cast(IonRunner)data;
		ir.printf();
	}
}

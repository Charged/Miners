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

	vm_t* vm;
	//Dcpu c;
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

		cpuRunning = true;
		vm = vm_create();
		vm.ram[0 .. mem.length] = mem;

		d = new GfxDraw();
		ct = new DpcuTexture(vm.ram.ptr);

		sl = new GfxSpotLight();
		w.gfx.add(sl);
	}

	~this()
	{
		assert(sl is null);
		assert(vm is null);
		assert(ct is null);
	}

	void close()
	{
		w.gfx.remove(sl);
		delete sl;

		if (vm !is null) {
			vm_free(vm);
			vm = null;
		}

		if (ct !is null) {
			ct.destruct();
			ct = null;
		}

		super.close();
	}

	void render()
	{

	}

	void logic()
	{
		super.logic();

		if (!cpuRunning)
			return;

		cpuRunning = vm_run_cycles(vm, 10000);
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
}

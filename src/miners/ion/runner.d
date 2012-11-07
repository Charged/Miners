// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.ion.runner;

import std.file : read;

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

import charge.game.dcpu.cpu;
import charge.game.dcpu.lem1802;


/**
 * IonRunner
 */
class IonRunner : ViewerRunner
{
private:
	mixin SysLogging;

	Dcpu c;
	Lem1802 lem;
	GfxDraw d;
	GfxSpotLight sl;

public:
	this(Router r, Options opts, string file)
	{
		if (file is null)
			file = "a.dcpu16";

		auto mem = cast(ushort[])read(file);

		super(r, opts, new ClassicWorld(opts));

		c = new Dcpu();
		c.ram[0 .. mem.length] = mem;

		d = new GfxDraw();
		lem = new Lem1802(c);

		sl = new GfxSpotLight(w.gfx);
	}

	~this()
	{
		assert(sl is null);
		assert(c is null);
		assert(lem is null);
	}

	void close()
	{
		breakApartAndNull(sl);
		if (c !is null) {
			c.close();
			c = null;
		}

		if (lem !is null) {
			lem.destruct();
			lem = null;
		}

		super.close();
	}

	void render()
	{

	}

	void logic()
	{
		super.logic();

		c.step(1000);
	}

	void render(GfxRenderTarget rt)
	{
		cam.resize(rt.width, rt.height);

		sl.position = cam.position + cam.rotation * Vector3d(.5, -.5, 0);
		sl.rotation = Quatd(cam_heading, cam_pitch, 0);

		r.render(w.gfx, cam.current, rt);

		lem.paintTexture();
		auto t = lem.texture;

		int x = rt.width / 2 - t.width;
		int y = rt.height / 2 - t.height;

		d.target = rt;
		d.start();
		d.blit(t, Color4f.White, false,
		       0, 0, t.width, t.height,
		       x, y, t.width * 2, t.height * 2);
		d.stop();
	}
}

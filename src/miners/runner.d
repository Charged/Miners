// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.runner;

import charge.charge;

import miners.world;
import miners.options;
import miners.interfaces;


/**
 * Base class for lever viewers and game logic runners.
 */
class GameRunnerBase : Runner
{
public:
	Router r;
	World w;
	Options opts;

	Movable centerer;
	int x; /**< Current chunk of camera */
	int y; /**< Current chunk of camera */
	int z; /**< Current chunk of camera */

	bool inControl;
	bool grabbed;
	CtlKeyboard keyboard;
	CtlMouse mouse;

private:
	mixin SysLogging;

public:
	this(Router r, Options opts, World w)
	{
		super(Type.Game);

		this.r = r;
		this.opts = opts;
		this.w = w;
		keyboard = CtlInput().keyboard;
		mouse = CtlInput().mouse;
		grabbed = true;
		r.addBuilder(&this.build);
	}

	~this()
	{
	}

	void close()
	{
		r.removeBuilder(&this.build);
	}

	abstract void render(GfxRenderTarget rt);

	void logic()
	{
		w.tick();

		centerMap();
	}

	/**
	 * Build things like terrain meshes.
	 *
	 * Return true if want to be called again.
	 */
	bool build()
	{
		if (w !is null && w.t !is null)
			return w.t.buildOne();
		else
			return false;
	}

	void assumeControl()
	{
		if (inControl)
			return;

		// Remember grab status.
		grab = grabbed;

		keyboard.up ~= &this.keyUp;
		keyboard.down ~= &this.keyDown;

		mouse.up ~= &this.mouseUp;
		mouse.down ~= &this.mouseDown;
		mouse.move ~= &this.mouseMove;

		inControl = true;
	}

	void dropControl()
	{
		if (!inControl)
			return;

		keyboard.up.disconnect(&this.keyUp);
		keyboard.down.disconnect(&this.keyDown);

		mouse.up.disconnect(&this.mouseUp);
		mouse.down.disconnect(&this.mouseDown);
		mouse.move.disconnect(&this.mouseMove);

		inControl = false;
	}

protected:
	/**
	 * Center the map around the camera.
	 */
	void centerMap()
	{
		if (centerer is null)
			return;

		auto p = centerer.position;
		int x = cast(int)p.x;
		int y = cast(int)p.y;
		int z = cast(int)p.z;
		x = p.x < 0 ? (x - 16) / 16 : x / 16;
		y = p.y < 0 ? (y - 16) / 16 : y / 16;
		z = p.z < 0 ? (z - 16) / 16 : z / 16;

		if (this.x != x || this.y != y || this.z != z)
			w.t.setCenter(x, y, z);
		this.x = x;
		this.y = y;
		this.z = z;
	}

	bool grab(bool val)
	{
		uint w, h;
		bool fullscreen;
		Core().size(w, h, fullscreen);

		// This seems to fix the view jumping issue when the mouse
		// has moved from the center when its not grabbed.
		if (!mouse.grab)
			mouse.warp(w / 2, h / 2);

		mouse.grab = val;
		mouse.show = !val;

		// Center the mouse for menu/chat when ungrabbing.
		if (!mouse.grab)
			mouse.warp(w / 2, h / 2);

		grabbed = val;

		return grabbed;
	}

	bool grab()
	{
		return grabbed;
	}

	abstract void keyDown(CtlKeyboard kb, int sym, dchar unicode, char[] str);
	abstract void keyUp(CtlKeyboard kb, int sym);
	abstract void mouseMove(CtlMouse mouse, int ixrel, int iyrel);
	abstract void mouseDown(CtlMouse m, int button);
	abstract void mouseUp(CtlMouse m, int button);
}

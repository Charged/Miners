// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.runner;

import std.math;

import charge.charge;

import miners.world;
import miners.options;


/**
 * Used for signaling raising errors and turning on the Error menu.
 *
 * The text should be informative as to what actions the user can
 * do to help solve the error, worst case point him to the bugzilla.
 */
class GameException : public Exception
{
public:
	Exception next;

public:
	this(char[] text, Exception next)
	{
		if (text is null)
			text = bugzilla;

		super(text);
		this.next = next;
	}

private:
	const char[] bugzilla =
`Charged Miners experienced some kind of problem, this isn't meant to happen.
Sorry about that, please file a bug in the Charge Miners issue tracker and
tell us what happened. Also please privode the Exception printout if shown.

            https://github.com/Wallbraker/Charged-Miners/issues`;
}


/**
 * Specialized runner for Minecraft.
 */
class Runner : public GameRunner
{
	abstract bool build();
}

/**
 * Specialized router for Minecraft.
 */
interface Router : public GameRouter
{
	Runner loadLevel(char[] dir);
	void render(GfxWorld w, GfxCamera c, GfxRenderTarget t);

	void displayError(Exception e, bool panic);
	void displayError(char[][] texts, bool panic);
}

/**
 * Base class for lever viewers and game logic runners.
 */
class GameRunnerBase : public Runner
{
public:
	Router r;
	World w;
	Options opts;

	Movable centerer;
	int x; /**< Current chunk of camera */
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
		this.r = r;
		this.opts = opts;
		this.w = w;
		keyboard = CtlInput().keyboard;
		mouse = CtlInput().mouse;
		grabbed = true;
	}

	~this()
	{
	}

	void close()
	{
	}

	abstract void render(GfxRenderTarget rt);

	void logic()
	{
		w.tick();

		centerMap();
	}

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
		int z = cast(int)p.z;
		x = p.x < 0 ? (x - 16) / 16 : x / 16;
		z = p.z < 0 ? (z - 16) / 16 : z / 16;

		if (this.x != x || this.z != z)
			w.t.setCenter(x, z);
		this.x = x;
		this.z = z;
	}

	bool grab(bool val)
	{
		mouse.grab = val;
		mouse.show = !val;
		grabbed = val;
		return grabbed;
	}

	bool grab()
	{
		return grabbed;
	}

	abstract void keyDown(CtlKeyboard kb, int sym);
	abstract void keyUp(CtlKeyboard kb, int sym);
	abstract void mouseMove(CtlMouse mouse, int ixrel, int iyrel);
	abstract void mouseDown(CtlMouse m, int button);
	abstract void mouseUp(CtlMouse m, int button);
}

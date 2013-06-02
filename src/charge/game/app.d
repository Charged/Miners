// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for App base classes.
 */
module charge.game.app;

import lib.sdl.sdl;

import charge.util.vector;
import charge.core;
import charge.ctl.input;
import charge.ctl.keyboard;
import charge.ctl.mouse;
import charge.gfx.gfx;
import charge.gfx.sync;
import charge.gfx.target;
import charge.sys.tracker;
import charge.sys.resource;


abstract class App
{
protected:
	Input i;
	Keyboard keyboard;
	Mouse mouse;
	Core c;
	bool running;

private:
	bool closed;

public:
	this(CoreOptions opts)
	{
		running = true;

		c = Core(opts);

		i = Input();
		i.quit ~= &stop;

		keyboard = i.keyboard;
		mouse = i.mouse;
	}

	~this()
	{
		assert(closed);
	}

	void close()
	{
		running = false;
		i.quit -= &stop;
		c.close();
		closed = true;
	}

	abstract void loop();

protected:
	void stop()
	{
		running = false;
	}
}

abstract class SimpleApp : App
{
protected:
	GfxSync curSync;

	bool fastRender = true; //< Try to render as fast as possible.

	TimeTracker networkTime;
	TimeTracker renderTime;
	TimeTracker logicTime;
	TimeTracker inputTime;
	TimeTracker buildTime;
	TimeTracker idleTime;

public:
	this(CoreOptions opts = null)
	{
		if (opts is null)
			opts = new CoreOptions();

		renderTime = new TimeTracker("gfx");
		inputTime = new TimeTracker("ctl");
		logicTime = new TimeTracker("logic");
		buildTime = new TimeTracker("build");
		idleTime = new TimeTracker("idle");

		super(opts);

		i.resize ~= &resize;
	}

	~this()
	{
		i.resize -= &resize;
	}

	abstract void render();
	abstract void logic();

	void resize(uint w, uint h)
	{
		Core().resize(w, h);
	}

	/**
	 * Idle is a bit missleading name, this function is always after a
	 * frame is completed. Time is the difference between when the next
	 * logic step should happen and the current time, so it can be a
	 * negative value if we are behind (often happens when rendering
	 * takes to long to complete).
	 */
	void idle(long time)
	{
		if (time > 0) {
			if (curSync && fastRender)
				gfxSyncWaitAndDelete(curSync, time);
			else
				SDL_Delay(cast(uint)time);
		}
	}

	void loop()
	{
		long now = SDL_GetTicks();
		long step = 10;
		long where = now;
		long last = now;

		bool changed; //< Tracks if should render

		while(running) {
			now = SDL_GetTicks();

			doInput();

			while(where < now) {
				doInput();
				doLogic();

				where = where + step;
				changed = true;
			}

			if (changed && gfxLoaded) {
				changed = !gfxSyncWaitAndDelete(curSync, 0);
				if (!changed) {
					doRender();
					curSync = gfxSyncInsert();
				}
			}

			now = SDL_GetTicks();
			long diff = (step + where) - now;
			doIdle(diff);
		}

		close();
	}


private final:
	void doInput()
	{
		inputTime.start();
		scope(exit) inputTime.stop();
		i.tick();
	}

	void doLogic()
	{
		logicTime.start();
		scope(exit) logicTime.stop();
		logic();
	}

	void doRender()
	{
		renderTime.start();
		scope(exit) renderTime.stop();
		render();
	}

	void doIdle(long diff)
	{
		idleTime.start();
		scope(exit) idleTime.stop();
		idle(diff);
	}
}

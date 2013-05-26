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
	TimeTracker networkTime;
	TimeTracker renderTime;
	TimeTracker logicTime;
	TimeTracker inputTime;
	TimeTracker buildTime;
	TimeTracker idleTime;

	bool changed; //< Tracks if should render

public:
	this(CoreOptions opts = null)
	{
		if (opts is null)
			opts = new CoreOptions();

		networkTime = new TimeTracker("net");
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

	abstract void network();
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
		charge.sys.resource.Pool().collect();

		if (time > 0)
			SDL_Delay(cast(uint)time);
	}

	void input()
	{
		i.tick();
	}

	override void loop()
	{
		long now = SDL_GetTicks();
		long step = 10;
		long where = now;
		long last = now;


		while(running) {
			now = SDL_GetTicks();

			do_input();
			do_network();

			while(where < now) {
				do_input();
				do_network();
				do_logic();

				where = where + step;
				changed = true;
			}

			if (changed) {
				changed = false;
				do_render();
			}

			now = SDL_GetTicks();
			long diff = (step + where) - now;
			do_idle(diff);
		}

		close();
	}

private:
	void do_network() { networkTime.start(); network(); networkTime.stop(); }
	void do_render() { renderTime.start(); render(); renderTime.stop(); }
	void do_logic() { logicTime.start(); logic(); logicTime.stop(); }
	void do_input() { inputTime.start(); input(); inputTime.stop(); }
	void do_idle(long time) { idleTime.start(); idle(time); idleTime.stop(); }
}

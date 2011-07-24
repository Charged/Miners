// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.game.app;

import std.stdio;
import charge.charge;
import lib.sdl.sdl;

struct TimeKeeper
{
	long then;
	long accumilated;

	void start()
	{
		then = SDL_GetTicks();
	}

	void stop()
	{
		accumilated += SDL_GetTicks() - then;
	}

	double calc(long elapsed)
	{
		double ret = accumilated / cast(real)elapsed * 100.0;
		accumilated = 0;
		return ret;
	}
}

abstract class App
{
protected:
	bool running;

public:

	this(char[][] args)
	{
		running = true;

		CtlInput().quit ~= &stop;
	}

	~this()
	{
		CtlInput().quit -= &stop;
	}

	abstract void loop();

protected:
	void stop()
	{
		running = false;
	}

}

abstract class SimpleApp : public App
{
protected:
	TimeKeeper networkTime;
	TimeKeeper renderTime;
	TimeKeeper logicTime;
	TimeKeeper inputTime;
	TimeKeeper idleTime;
	
public:
	this(char[][] args)
	{
		super(args);
		CtlInput().resize ~= &resize;
	}

	~this()
	{
		CtlInput().resize -= &resize;
	}

	abstract void network();
	abstract void render();
	abstract void logic();
	abstract void close();

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
		CtlInput().tick();
	}

	void loop()
	{
		long now = SDL_GetTicks();
		long step = 10;
		long where = now;
		long last = now;

		bool changed;

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
				do_render();
				changed = false;
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

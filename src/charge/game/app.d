// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.game.app;

import lib.sdl.sdl;

import charge.util.vector;
import charge.core;
import charge.ctl.input;
import charge.gfx.target;
import charge.sys.resource;
import charge.game.runner;


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
	Input i;
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

abstract class SimpleApp : public App
{
protected:
	TimeKeeper networkTime;
	TimeKeeper renderTime;
	TimeKeeper logicTime;
	TimeKeeper inputTime;
	TimeKeeper idleTime;

public:
	this(CoreOptions opts = null)
	{
		if (opts is null)
			opts = new CoreOptions();

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

abstract class RouterApp : SimpleApp, Router
{
private:
	Vector!(Runner) vec;
	Vector!(Runner) del;
	Runner currentInput;
	bool dirty;

public:
	this(CoreOptions opts = null)
	{
		super(opts);
	}

	~this()
	{
		assert(vec.length == 0);
		assert(del.length == 0);
		assert(currentInput is null);
	}

	void close()
	{
		while(vec.length || del.length) {
			deleteAll();
			manageRunners();
		}

		super.close();
	}

	void render()
	{
		auto rt = DefaultTarget();

		int i = cast(int)vec.length;
		foreach_reverse(r; vec) {
			i--;
			if (r.flags & Runner.Flag.Blocker)
				break;
		}

		for(; i < vec.length; i++)
			vec[i].render(rt);

		rt.swap();
	}

	void logic()
	{
		manageRunners();

		foreach_reverse(r; vec) {
			r.logic();

			if (r.flags & Runner.Flag.Blocker)
				break;
		}
	}

	void network()
	{
	}


	/*
	 *
	 * Router functions.
	 *
	 */


	void quit()
	{
		running = false;
	}

	void push(Runner r)
	{
		assert(r !is null);

		dirty = true;

		if (r.flags & Runner.Flag.AlwaysOnTop)
			return vec ~= r;

		int i = cast(int)vec.length;
		for(--i; (i >= 0) && (vec[i].flags & Runner.Flag.AlwaysOnTop); i--) { }
		// should be placed after the first non AlwaysOnTop runner.
		i++;

		// Might be moved, but also covers the case where it is empty.
		vec ~= r;
		for (Runner o, n = r; i < vec.length; i++, n = o) {
			o = vec[i];
			vec[i] = n;
		}
	}

	void remove(Runner r)
	{
		vec.remove(r);
		dirty = true;
	}

	void deleteMe(Runner r)
	{
		if (r is null)
			return;

		remove(r);

		// Don't delete a runner already on the list
		foreach(ru; del)
			if (ru is r)
				return;
		del ~= r;
	}

	void deleteAll()
	{
		foreach(r; vec.adup)
			deleteMe(r);
	}

	final void manageRunners()
	{
		if (!dirty)
			return;
		dirty = false;

		Runner newRunner;

		foreach_reverse(r; vec) {
			assert(r !is null);

			if (!(r.flags & Runner.Flag.TakesInput))
				continue;
			newRunner = r;
			break;
		}

		// If there is nobody to take the input we quit the game.
		if (newRunner is null)
			stop();

		if (currentInput !is newRunner) {
			if (currentInput !is null)
				currentInput.dropControl;
			currentInput = newRunner;
			if (currentInput !is null)
				currentInput.assumeControl;
		}

		auto tmp = del.adup;
		del.removeAll();
		foreach(r; tmp) {
			r.close;
			// XXX Change runners so this isn't needed.
			delete r;
		}
	}
}

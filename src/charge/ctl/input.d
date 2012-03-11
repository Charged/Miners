// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.ctl.input;

import lib.sdl.sdl;

import charge.util.signal;
import charge.sys.logger;

import charge.ctl.device;
import charge.ctl.mouse;
import charge.ctl.keyboard;

class Input
{
private:
	mixin Logging;

	static Input instance;
	Mouse[] mouseArray;
	Keyboard[] keyboardArray;

public:
	Signal!(Device) hotplug;
	Signal!(uint, uint) resize;
	Signal!() quit;

public:
	static Input opCall()
	{
		if (instance is null)
			instance = new Input();

		return instance;
	}

	Mouse mouse()
	{
		return mouseArray[0];
	}

	Keyboard keyboard()
	{
		return keyboardArray[0];
	}

	Mouse[] mice()
	{
		return mouseArray.dup;
	}

	Keyboard[] keyboards()
	{
		return keyboardArray.dup;
	}

	void tick()
	{
		SDL_Event e;

		while(SDL_PollEvent(&e)) {
			if (e.type == SDL_QUIT)
				quit();

			// Hack
			//if (e.type == SDL_KEYUP)
			//	if (e.key.keysym.sym == SDLK_ESCAPE)
			//		quit();

			if (e.type == SDL_KEYDOWN) {
				auto k = keyboardArray[0];
				k.mod = e.key.keysym.mod;
				k.down(k, e.key.keysym.sym);
			}

			if (e.type == SDL_KEYUP) {
				auto k = keyboardArray[0];
				k.mod = e.key.keysym.mod;
				k.up(k, e.key.keysym.sym);
			}

			if (e.type == SDL_MOUSEMOTION) {
				auto m = mouseArray[0];
				m.state = e.motion.state;
				m.x = e.motion.x;
				m.y = e.motion.y;
				m.move(m, e.motion.xrel, e.motion.yrel);
			}

			if (e.type == SDL_MOUSEBUTTONDOWN) {
				auto m = mouseArray[0];
				m.state |= (1 << e.button.button);
				m.x = e.button.x;
				m.y = e.button.y;
				m.down(m, e.button.button);
			}

			if (e.type == SDL_MOUSEBUTTONUP) {
				auto m = mouseArray[0];
				m.state = ~(1 << e.button.button) & m.state;
				m.x = e.button.x;
				m.y = e.button.y;
				m.up(m, e.button.button);
			}

			if (e.type == SDL_VIDEORESIZE)
				resize(cast(uint)e.resize.w, cast(uint)e.resize.h);
		}
	}

private:
	this()
	{
		keyboardArray ~= new Keyboard();
		mouseArray ~= new Mouse();
	}

	~this()
	{
		hotplug.destruct();
		resize.destruct();
		quit.destruct();
	}
}

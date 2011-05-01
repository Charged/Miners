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

			/* Hack */
			if (e.type == SDL_KEYUP)
				if (e.key.keysym.sym == SDLK_ESCAPE)
					quit();

			if (e.type == SDL_KEYDOWN)
				keyboardArray[0].down(keyboardArray[0], e.key.keysym.sym);

			if (e.type == SDL_KEYUP)
				keyboardArray[0].up(keyboardArray[0], e.key.keysym.sym);

			if (e.type == SDL_MOUSEMOTION)
				mouseArray[0].move(mouseArray[0], e.motion.xrel, e.motion.yrel);

			if (e.type == SDL_MOUSEBUTTONDOWN)
				mouseArray[0].down(mouseArray[0], e.button.button);

			if (e.type == SDL_MOUSEBUTTONUP)
				mouseArray[0].up(mouseArray[0], e.button.button);
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
		quit.destruct();
	}
}

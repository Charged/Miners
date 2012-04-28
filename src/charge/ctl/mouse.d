// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.ctl.mouse;

import lib.sdl.sdl;

import charge.util.signal;
import charge.ctl.device;

class Mouse : public Device
{
public:
	int state; /**< Mask of button state, 1 == pressed */
	int x;
	int y;

public:
	Signal!(Mouse, int, int) move;
	Signal!(Mouse, int) down;
	Signal!(Mouse, int) up;

	~this()
	{
		move.destruct();
		down.destruct();
		up.destruct();
	}

	void warp(uint x, uint y)
	{
		SDL_WarpMouse(cast(Uint16)x, cast(Uint16)y);
	}

	bool grab(bool status)
	{
		auto mode = status ? SDL_GrabMode.SDL_GRAB_ON : SDL_GrabMode.SDL_GRAB_OFF;
		return SDL_WM_GrabInput(mode) == SDL_GrabMode.SDL_GRAB_ON;
	}

	bool grab()
	{
		auto status = SDL_WM_GrabInput(SDL_GrabMode.SDL_GRAB_QUERY);
		return status == SDL_GrabMode.SDL_GRAB_ON;
	}

	bool show(bool status)
	{
		auto mode = status ? SDL_ENABLE : SDL_DISABLE;
		return SDL_ShowCursor(mode) == SDL_ENABLE;
	}

	bool show()
	{
		return SDL_ShowCursor(SDL_QUERY) == SDL_ENABLE;
	}
}

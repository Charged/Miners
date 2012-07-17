// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.game.runner;

import charge.gfx.target;



/**
 * A game runner often is a level logic or menu.
 */
class Runner
{
public:
	enum Flag {
		TakesInput    = 0x01,
		Transparent   = 0x02,
		Blocker       = 0x04,
		AlwaysOnTop   = 0x08,
	}

	enum Type {
		Background = 0,
		Game = Flag.TakesInput | Flag.Blocker,
		Menu = Flag.TakesInput | Flag.Transparent,
		Overlay = Flag.AlwaysOnTop | Flag.Transparent,
	}


	union {
		Flag flags;
		Type type;
	}

public:
	this(Type type)
	{
		this.type = type;
	}

	/**
	 * Called to notify that the screen has changed resolution.
	 */
	abstract void resize(uint w, uint h);

	/**
	 * Step the game logic one step.
	 */
	abstract void logic();

	/**
	 * Render view of this runner into target.
	 */
	abstract void render(RenderTarget rt);

	/**
	 * Install all input listeners.
	 */
	abstract void assumeControl();

	/**
	 * Uninstall all input listeners.
	 */
	abstract void dropControl();

	/**
	 * Shutdown this runner.
	 */
	abstract void close();
}

/**
 * A interface back to the main controller, often the main game loop.
 */
interface Router
{
public:
	/**
	 * Push this runner to top of the stack.
	 */
	void push(Runner r);

	/**
	 * Remove this runner from the stack.
	 */
	void remove(Runner r);

	/**
	 * The given runner wants to be deleted.
	 */
	void deleteMe(Runner r);
}

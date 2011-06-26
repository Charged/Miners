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
	 * Switch control to this runner.
	 */
	void switchTo(Runner r);

	/**
	 * The given runner wants to be deleted.
	 */
	void deleteMe(Runner r);
}

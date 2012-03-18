// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.interfaces;


import charge.gfx.camera : GfxCamera = Camera;
import charge.gfx.world : GfxWorld = World;
import charge.gfx.target : GfxRenderTarget = RenderTarget;


/**
 * Specialized runner for Miners.
 */
interface Runner
{
	/**
	 * Called to notify that the screen has changed resolution.
	 */
	void resize(uint w, uint h);

	/**
	 * Step the game logic one step.
	 */
	void logic();

	/**
	 * Build things like terrain meshes.
	 *
	 * Return true if want to be called again.
	 */
	bool build();

	/**
	 * Render view of this runner into target.
	 */
	void render(GfxRenderTarget rt);

	/**
	 * Install all input listeners.
	 */
	void assumeControl();

	/**
	 * Uninstall all input listeners.
	 */
	void dropControl();

	/**
	 * Shutdown this runner.
	 */
	void close();
}


/**
 * Specialized router for Miners.
 */
interface Router
{
	/*
	 *
	 * Runner related.
	 *
	 */


	/**
	 * Switch control to this runner.
	 */
	void switchTo(Runner r);

	/**
	 * The given runner wants to be deleted.
	 */
	void deleteMe(Runner r);

	/**
	 * Render the world, from camera to rt.
	 */
	void render(GfxWorld w, GfxCamera c, GfxRenderTarget rt);

	/**
	 * Load a level, name should be a level directory
	 * containing level.dat for final and a file for
	 * classic levels.
	 *
	 * If name is null it opens a random level for beta
	 * and a flatland for classic.
	 */
	Runner loadLevel(char[] name, bool classic = false);


	/*
	 *
	 * Menu related.
	 *
	 */


	/**
	 * Displays a error message menu, if panic is true the
	 * only the only thing to do is close the game.
	 *
	 * Closes any other menu and overlays the current runner.
	 */
	void displayError(Exception e, bool panic);

	/**
	 * See above.
	 */
	void displayError(char[][] texts, bool panic);
}

// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.interfaces;

import charge.gfx.camera : GfxCamera = Camera;
import charge.gfx.world : GfxWorld = World;
import charge.gfx.target : GfxRenderTarget = RenderTarget;
static import charge.game.runner;

import miners.types;
public import miners.classic.interfaces : ClassicConnection = Connection;

alias charge.game.runner.Runner Runner;
alias charge.game.runner.Router GameRouter;

/**
 * Specialized router for Miners.
 */
interface Router : GameRouter
{
	/**
	 * Gracefully quit the game.
	 */
	void quit();

	/**
	 * Get the menu manager.
	 */
	MenuManager menu();


	/*
	 *
	 * Runner related.
	 *
	 */


	/**
	 * Add a callback to be run on idle time.
	 */
	void addBuilder(bool delegate() dg);

	/**
	 * Remove a builder callback.
	 */
	void removeBuilder(bool delegate() dg);

	/**
	 * Background the menu, called from menu.
	 */
	void backgroundMenu();

	/**
	 * Foreground the menu, called from menu.
	 */
	void foregroundMenu();


	/**
	 * Render the world, from camera to rt.
	 */
	void render(GfxWorld w, GfxCamera c, GfxRenderTarget rt);

	/**
	 * Start the Ion Runner.
	 */
	void chargeIon();

	/**
	 * Load a level, name should be a level directory
	 * containing level.dat for final and a file for
	 * classic levels.
	 *
	 * If name is null it opens a random level for beta
	 * and a flatland for classic.
	 */
	void loadLevel(char[] name, bool classic = false);

	/**
	 * Start a classic runner listening to the given connection.
	 */
	void connectedTo(ClassicConnection cc,
	                 uint x, uint y, uint z,
	                 ubyte[] data);
}

interface MenuManager
{
	/**
	 * Close the current menu hiding it.
	 */
	void closeMenu();

	/**
	 * Closes any other menu and overlays the current runner.
	 */
	void displayMainMenu();

	/**
	 * See above.
	 */
	void displayPauseMenu();

	/**
	 * See above.
	 */
	void displayLevelSelector();

	/**
	 * Display a generic info menu.
	 * Dg is called on button pressed, if null the menu will be closed.
	 *
	 * Also see above.
	 */
	void displayInfo(char[] header, char[][] texts,
	                 char[] buttonText, void delegate() dg);

	/**
	 * Display the classic block selector.
	 */
	void displayClassicBlockSelector(void delegate(ubyte) selectedDg);

	/**
	 * Display the classic server list.
	 */
	void displayClassicMenu();

	/**
	 * Display a list of classic servers that the user can connect to.
	 */
	void displayClassicList(ClassicServerInfo[] csi);

	/**
	 * Connect to a classic server by first connecting to the
	 * minecraft.net server looking up mppass and other details
	 * with the serverId given in ClassicServerInfo.
	 */
	void getClassicServerInfoAndConnect(ClassicServerInfo csi);

	/**
	 * Connect to a classic server using the server address,
	 * port, mppass & username in the given ClassicServerInfo.
	 */
	void connectToClassic(ClassicServerInfo csi);

	/**
	 * Connect to a classic server by first connecting to the
	 * minecraft.net server looking up mppass and other details
	 * with the serverId given in ClassicServerInfo.
	 *
	 * This function is unsecure and should only be used for debugging.
	 */
	void connectToClassic(char[] user, char[] pass, ClassicServerInfo csi);

	/**
	 * Display the a world change menu.
	 */
	void classicWorldChange(ClassicConnection cc);

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

	/**
	 * XXX These two are a bit of a hack.
	 */
	void setTicker(void delegate());

	/**
	 * XXX These two are a bit of a hack.
	 */
	void unsetTicker(void delegate());
}

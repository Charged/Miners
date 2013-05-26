// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.interfaces;

import charge.gfx.camera : GfxCamera = Camera;
import charge.gfx.world : GfxWorld = World;
import charge.gfx.target : GfxRenderTarget = RenderTarget;
static import charge.game.scene;

import miners.types;
public import miners.classic.interfaces : ClassicConnection = Connection;

alias charge.game.scene.Scene Scene;


/**
 * Specialized router for Miners.
 */
interface Router : charge.game.scene.SceneManager
{
	/*
	 *
	 * Scene related.
	 *
	 */


	/**
	 * Render the world, from camera to rt.
	 */
	void render(GfxWorld w, GfxCamera c, GfxRenderTarget rt);

	/**
	 * Load a level, name should be a classic level filename.
	 *
	 * If name is null it generates a simple flatland.
	 */
	void loadLevelClassic(string name);

	/**
	 * Start a classic scene listening to the given connection.
	 */
	void connectedTo(ClassicConnection cc,
	                 uint x, uint y, uint z,
	                 ubyte[] data);


	/*
	 *
	 * Menu related functions
	 *
	 */


	/**
	 * Shows the main menu, overlays the current scene.
	 */
	void displayMainMenu();

	/**
	 * See above.
	 */
	void displayPauseMenu();

	/**
	 * See above, but specialized for classic.
	 */
	void displayClassicPauseMenu(Scene part);

	/**
	 * Display a generic info menu.
	 * Dg is called on button pressed, if null the menu will be closed.
	 *
	 * Also see above.
	 */
	void displayInfo(string header, string[] texts,
	                 string buttonText, void delegate() dg);

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
	void connectToClassic(string user, string pass, ClassicServerInfo csi);

	/**
	 * Display the a world change menu.
	 */
	void classicWorldChange(ClassicConnection cc);

	/**
	 * Displays a error message menu, if panic is true the
	 * only the only thing to do is close the game.
	 *
	 * Closes any other menu and overlays the current scene.
	 */
	void displayError(Exception e, bool panic);

	/**
	 * See above.
	 */
	void displayError(string[] texts, bool panic);
}

// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for Scene base class and SceneManager interface.
 */
module charge.game.scene;

import charge.gfx.target;


/**
 * A scene often is a level, menu overlay or a loading screen.
 */
class Scene
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
	 * Step the game logic one step.
	 */
	abstract void logic();

	/**
	 * Render view of this scene into target.
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
	 * Shutdown this scene.
	 */
	abstract void close();
}

/**
 * A interface back to the main controller, often the main game loop.
 */
interface SceneManager
{
public:
	/**
	 * Quit the game.
	 */
	void quit();

	/**
	 * Push this scene to top of the stack.
	 */
	void push(Scene r);

	/**
	 * Remove this scene from the stack.
	 */
	void remove(Scene r);

	/**
	 * The given scene wants to be deleted.
	 */
	void deleteMe(Scene r);

	/**
	 * Add a callback to be run on idle time.
	 */
	void addBuilder(bool delegate() dg);

	/**
	 * Remove a builder callback.
	 */
	void removeBuilder(bool delegate() dg);
}

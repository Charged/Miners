// Copyright © 2011-2013, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for SceneManagerApp base classes.
 */
module charge.game.scene.app;

import lib.sdl.sdl : SDL_Delay;

import charge.core : CoreOptions;
import charge.util.vector : Vector;

import charge.gfx.target;
import charge.game.app;
import charge.game.scene.scene;


/**
 * Base class for games wishing to use Scenes, implements
 * most if not all needed SceneManager functions needed.
 */
abstract class SceneManagerApp : App, SceneManager
{
private:
	Vector!(Scene) vec;
	Vector!(Scene) del;
	Scene currentInput;

	bool dirty; //< Do we need to manage scenes.
	bool built; //< Have we built this logic pass.

	alias bool delegate() BuilderDg;
	Vector!(BuilderDg) builders;

public:
	this(CoreOptions opts = null)
	{
		super(opts);
	}

	~this()
	{
		assert(vec.length == 0);
		assert(del.length == 0);
		assert(builders.length == 0);
		assert(currentInput is null);
	}

	override void close()
	{
		while(vec.length || del.length) {
			deleteAll();
			manageScenes();
		}

		super.close();
	}

	override void render()
	{
		auto rt = DefaultTarget();

		int i = cast(int)vec.length;
		foreach_reverse(r; vec) {
			i--;
			if (r.flags & Scene.Flag.Blocker)
				break;
		}

		for(; i < vec.length; i++)
			vec[i].render(rt);

		rt.swap();
	}

	override void logic()
	{
		// This make sure we at least call
		// the builders once per frame.
		built = false;

		manageScenes();

		foreach_reverse(r; vec) {
			r.logic();

			if (r.flags & Scene.Flag.Blocker)
				break;
		}
	}

	override void idle(long time)
	{
		// If we have built at least once this frame and have very little
		// time left don't build again. But we always build one each frame.
		if (built && time < 5 || builders.length == 0)
			return super.idle(time);

		// Account this time for build instead of idle
		buildTime.start();

		// Need to reset each idle check
		built = false;

		// Do the build
		foreach(b; builders)
			built = b() || built;

		// Delete unused resources
		charge.sys.resource.Pool().collect();

		// Switch back to idle
		buildTime.stop();

		// Didn't build anything, just sleep.
		if (!built)
			return super.idle(time);
	}


	/*
	 *
	 * Router functions.
	 *
	 */


	override void quit()
	{
		running = false;
	}

	override void push(Scene r)
	{
		assert(r !is null);

		// Remove and then reinsert the scene on top.
		remove(r);

		if (r.flags & Scene.Flag.AlwaysOnTop)
			return vec ~= r;

		int i = cast(int)vec.length;
		for(--i; (i >= 0) && (vec[i].flags & Scene.Flag.AlwaysOnTop); i--) { }
		// should be placed after the first non AlwaysOnTop scene.
		i++;

		// Might be moved, but also covers the case where it is empty.
		vec ~= r;
		for (Scene o, n = r; i < vec.length; i++, n = o) {
			o = vec[i];
			vec[i] = n;
		}
	}

	override void remove(Scene r)
	{
		vec.remove(r);
		dirty = true;
	}

	override void addBuilder(bool delegate() dg)
	{
		builders ~= dg;
	}

	override void removeBuilder(bool delegate() dg)
	{
		builders.remove(dg);
	}

	override void deleteMe(Scene r)
	{
		if (r is null)
			return;

		remove(r);

		// Don't delete a scene already on the list
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

	final void manageScenes()
	{
		if (!dirty)
			return;
		dirty = false;

		Scene newScene;

		foreach_reverse(r; vec) {
			assert(r !is null);

			if (!(r.flags & Scene.Flag.TakesInput))
				continue;
			newScene = r;
			break;
		}

		// If there is nobody to take the input we quit the game.
		if (newScene is null)
			quit();

		if (currentInput !is newScene) {
			if (currentInput !is null)
				currentInput.dropControl;
			currentInput = newScene;
			if (currentInput !is null)
				currentInput.assumeControl;
		}

		auto tmp = del.adup;
		del.removeAll();
		foreach(r; tmp) {
			r.close;
			// XXX Change scenes so this isn't needed.
			delete r;
		}
	}
}

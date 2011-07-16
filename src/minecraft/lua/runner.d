// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.lua.runner;

import std.file;

import charge.charge;
import charge.game.lua;

import minecraft.world;
import minecraft.runner;
import minecraft.options;
import minecraft.actors.camera;
import minecraft.actors.sunlight;
import minecraft.lua.wrappers.actors;

class ScriptRunner : public GameRunnerBase
{
public:
	LuaState s;
	SunLight sl;
	Camera c;

	bool initialized;

private:
	mixin SysLogging;

public:
	this(Router r, Options opts, World w)
	{
		super(r, opts, w);

		// Create common actors
		sl = new SunLight(w);
		c = new Camera(w);
		cam = c.c;
	}

	this(Router r, Options opts, World w, char[] filename)
	{
		if (!exists(filename)) {
			l.warn("No such file (%s) (this is not a error)", filename);
			throw new Exception("Error initalizing lua script");
		}

		this(r, opts, w);

		initLuaState();

		loadfile(filename);
	}

	~this()
	{
		dropControl();

		if (initialized) {
			delete s;
			delete c;
			delete sl;
			delete w;
		}
	}


	/*
	 *
	 * Callbacks
	 *
	 */


	void resize(uint w, uint h)
	{
		s.getGlobalz("resize");
		s.pushNumber(w);
		s.pushNumber(h);

		if (s.call(2) == 2) {
			l.warn(s.toString(-1));
		}
	}

	void logic()
	{
		s.getGlobalz("logic");
		if (s.call() == 2) {
			l.warn(s.toString(-1));
		}
		super.logic();
	}

	void render()
	{
		s.getGlobalz("render");
		if (s.call() == 2) {
			l.warn(s.toString(-1));
		}

	}

protected:
	/*
	 *
	 * Lua functions.
	 *
	 */


	/**
	 * Create the state lua state and set it up to receive files.
	 *
	 * Open Lua libraries.
	 * Register all Charge structs and classes.
	 * And push world, light, camera and terrain.
	 */
	void initLuaState()
	{
		// Create a lua state
		s = new LuaState();
		// Push standard libraries
		s.openLibs();

		// Registers classes
		Color4fWrapper.register(s);
		Vector3dWrapper.register(s);
		Point3dWrapper.register(s);
		QuatdWrapper.register(s);

		MouseWrapper.register(s);
		KeyboardWrapper.register(s);

		WorldWrapper.register(s);
		CameraWrapper.register(s);
		OptionsWrapper.register(s);
		SunLightWrapper.register(s);
		BetaTerrainWrapper.register(s);

		setNil("World");
		setNil("Game");
		setNil("Camera");
		setNil("SunLight");


		// Ctl

		s.pushStringz("mouse");
		s.pushClass(mouse);
		s.setTable(lib.lua.lua.LUA_GLOBALSINDEX);

		s.pushStringz("keyboard");
		s.pushClass(keyboard);
		s.setTable(lib.lua.lua.LUA_GLOBALSINDEX);


		// Mc

		s.pushStringz("light");
		s.pushClass(sl);
		s.setTable(lib.lua.lua.LUA_GLOBALSINDEX);

		s.pushStringz("world");
		s.pushClass(w);
		s.setTable(lib.lua.lua.LUA_GLOBALSINDEX);

		s.pushStringz("camera");
		s.pushClass(c);
		s.setTable(lib.lua.lua.LUA_GLOBALSINDEX);

		s.pushStringz("terrain");
		s.pushClass(w.t);
		s.setTable(lib.lua.lua.LUA_GLOBALSINDEX);

		s.pushStringz("options");
		s.pushClass(opts);
		s.setTable(lib.lua.lua.LUA_GLOBALSINDEX);
	}

	void loadfile(char[] filename)
	{
		auto ret = s.loadFile(filename);
		if (ret == 3) {
			l.warn("loadFile failed \n",
			       s.toString(-3), "\n",
			       s.toString(-2), "\n",
			       s.toString(-1), "\n");

			delete s;

			throw new Exception("Error initalizing lua script");
		}

		ret = s.call();
		if (ret == 2) {
			l.warn("call failed\n", s.toString(-1));

			delete s;
			delete c;
			delete sl;
			throw new Exception("Error initalizing lua script");
		}

		// Make sure the script has the right screen size.
		auto rt = GfxDefaultTarget();
		resize(rt.width, rt.height);

		initialized = true;
	}


	/*
	 *
	 * Callbacks
	 *
	 */


	void keyUp(CtlKeyboard kb, int sym)
	{
		s.getGlobalz("keyUp");
		s.pushNumber(sym);

		if (s.call(1) == 2) {
			l.warn(s.toString(-1));
		}
	}

	void keyDown(CtlKeyboard kb, int sym)
	{
		s.getGlobalz("keyDown");
		s.pushNumber(sym);

		if (s.call(1) == 2) {
			l.warn(s.toString(-1));
		}
	}

	void mouseUp(CtlMouse m, int button)
	{
		s.getGlobalz("mouseUp");
		s.pushNumber(button);

		if (s.call(1) == 2) {
			l.warn(s.toString(-1));
		}
	}

	void mouseDown(CtlMouse m, int button)
	{
		s.getGlobalz("mouseDown");
		s.pushNumber(button);

		if (s.call(1) == 2) {
			l.warn(s.toString(-1));
		}
	}

	void mouseMove(CtlMouse mouse, int xrel, int yrel)
	{
		s.getGlobalz("mouseMove");
		s.pushNumber(xrel);
		s.pushNumber(yrel);

		if (s.call(2) == 2) {
			l.warn(s.toString(-1));
		}
	}


	/*
	 *
	 * Helper functions
	 *
	 */


	final void setNil(char* str)
	{
		s.pushStringz(str);
		s.pushNil();
		s.setTable(lib.lua.lua.LUA_GLOBALSINDEX);
	}
}

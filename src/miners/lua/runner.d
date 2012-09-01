// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.lua.runner;

import std.file;

import charge.charge;

import charge.sys.file;

import miners.world;
import miners.runner;
import miners.options;
import miners.interfaces;
import miners.actors.camera;
import miners.actors.sunlight;
import miners.lua.state;

import lib.lua.lua;
import lib.lua.lauxlib;

import miners.lua.wrappers.types;
import miners.lua.functions;
import miners.lua.wrappers.isle;
import miners.lua.wrappers.beta;
import miners.lua.wrappers.types;
import miners.lua.wrappers.actors;
import miners.lua.wrappers.terrain;
import miners.lua.wrappers.classic;


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
		centerer = c;
	}

	this(Router r, Options opts, World w, string filename)
	{
		auto file = FileManager(filename);
		if (file is null) {
			l.warn("No such file (%s) (this is not a error)", filename);
			throw new Exception("Error initalizing lua script");
		}

		this(r, opts, w);

		initLuaState();

		loadfile(file, filename);
	}

	~this()
	{
		assert(sl is null);
		assert(s is null);
		assert(c is null);
		assert(w is null);
	}

	void close()
	{
		if (initialized) {
			delete s;
			delete c;
			delete sl;
			delete w;
			initialized = false;
		}
		super.close();
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

	void render(GfxRenderTarget rt)
	{
		r.render(w.gfx, c.current, rt);
/*
		s.getGlobalz("render");
		if (s.call() == 2) {
			l.warn(s.toString(-1));
		}
*/
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

		// Repalace the loaders with our own.
		s.replacePackageLoaders(&loadPackage);

		// Remove the C lib loader as well.
		s.getGlobal("package");
		s.pushString("loadlib");
		s.pushNil();
		s.setTable(-3);

		// Replace dofile with our own.
		s.pushString("dofile");
		s.pushCFunction(&doFile);
		s.setTable(lib.lua.lua.LUA_GLOBALSINDEX);

		// Load charge
		s.openCharge();
		s.pop();

		// Load miners
		openMiners(s);
		s.pop();

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

	/**
	 * Load a file and do the last initialization.
	 *
	 * Part of the runner init process.
	 */
	void loadfile(File file, string filename)
	{
		assert(file !is null);

		char[] buf = cast(char[])file.peekMem();
		int ret;

		ret = s.loadStringAsFile(buf, filename);
		if (ret == 3) {
			l.warn("loadFile failed \n",
			       s.toString(-3), "\n",
			       s.toString(-2), "\n",
			       s.toString(-1), "\n");

			delete s;
			delete c;
			delete sl;

			throw new Exception("Error initalizing lua script");
		}

		delete file;

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

	/**
	 * This function replaces the lua doFile function.
	 */
	extern (C) static int doFile(lua_State *l)
	{
		auto s = LuaState(l);
		s.checkString(1);

		auto filename = s.toString(1);
		auto file = FileManager(filename);
		if (file is null)
			s.error("could not find file " ~ filename);

		char[] buf = cast(char[])file.peekMem();

		int ret = s.loadStringAsFile(buf, filename);
		delete file;

		if (ret)
			lua_error(l);

		// We don't use pcall here.
		lua_call(l, 0, 0);
		return 0;
	}

	/**
	 * Used as a loader for require.
	 */
	extern (C) static int loadPackage(lua_State *l)
	{
		auto s = LuaState(l);
		s.checkString(1);

		auto pkg = s.toString(1);
		auto filename = "script/" ~ pkg ~ ".lua";

		auto file = FileManager(filename);
		if (file is null) {
			// Special format for require
			s.pushString("\n\tno file '" ~ filename ~ "'");
			return 1;
		}

		char[] buf = cast(char[])file.peekMem();

		int ret = s.loadStringAsFile(buf, filename);
		delete file;

		return 1;
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

	void keyDown(CtlKeyboard kb, int sym, dchar unicode, char[] str)
	{
		// XXX Hack
		if (sym == 27)
			return r.displayPauseMenu();

		s.getGlobalz("keyDown");
		s.pushNumber(sym);
		s.pushNumber(unicode);
		if (str !is null)
			s.pushString(str);
		else
			s.pushNil();

		if (s.call(3) == 2) {
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

	const luaL_Reg minerslib[] = [
		{ "Block", &BlockWrapper.newBlock },
		{ "OtherPlayer", &OtherPlayerWrapper.newOtherPlayer },
		{ "getRayPoints", &getRayPoints },
		{ null, null },
	];

	void openMiners(LuaState s)
	{
		s.pushCFunction(&openlib);
		s.pushStringz("miners");
		s.call(1);
	}

	extern (C) static int openlib(lua_State *l)
	{
		auto s = LuaState(l);

		luaL_register(l, "miners", minerslib.ptr);

		// Register structs
		BlockWrapper.register(s);

		// Register actors
		CameraWrapper.register(s);
		OptionsWrapper.register(s);
		SunLightWrapper.register(s);
		OtherPlayerWrapper.register(s);

		// Register world and terrain
		IsleWorldWrapper.register(s);
		BetaWorldWrapper.register(s);
		BetaTerrainWrapper.register(s);
		ClassicWorldWrapper.register(s);
		FiniteTerrainWrapper.register(s);

		return 1;
	}
}

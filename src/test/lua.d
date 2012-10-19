// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module test.lua;

import std.stdio : writefln;

import lib.lua.lua : LUA_GLOBALSINDEX;

import charge.charge;
import charge.game.lua;


class GameCamera : GameActor
{
private:
	GfxProjCamera c;
	GfxRenderer r;
	GfxDefaultTarget rt;

public:
	this(GameWorld w)
	{
		super(w);
		GfxRenderer.init();
		r = GfxRenderer.create();
		rt = GfxDefaultTarget();
		r.target(rt);

		c = new GfxProjCamera();
	}

	~this()
	{

	}

	void render()
	{
		rt.clear();
		r.render(c, w.gfx);
		rt.swap();
	}

	void setPosition(ref Point3d pos) { c.setPosition(pos); }
	void getPosition(out Point3d pos) { c.getPosition(pos); }
	void setRotation(ref Quatd rot) { c.setRotation(rot); }
	void getRotation(out Quatd rot) { c.getRotation(rot); }
}

class GameCube : GameActor
{
private:
	GfxRigidModel gfx;

public:
	this(GameWorld w)
	{
		super(w);
		gfx = GfxRigidModel(w.gfx, "res/cube.bin");
	}

	void setPosition(ref Point3d pos) { gfx.setPosition(pos); }
	void getPosition(out Point3d pos) { gfx.getPosition(pos); }
	void setRotation(ref Quatd rot) { gfx.setRotation(rot); }
	void getRotation(out Quatd rot) { gfx.getRotation(rot); }

}

class GameSunLight : GameActor
{
private:
	GfxSimpleLight gfx;

public:
	this(GameWorld w)
	{
		super(w);
		gfx = new GfxSimpleLight(w.gfx);
	}

	void setPosition(ref Point3d pos) { gfx.setPosition(pos); }
	void getPosition(out Point3d pos) { gfx.getPosition(pos); }
	void setRotation(ref Quatd rot) { gfx.setRotation(rot); }
	void getRotation(out Quatd rot) { gfx.getRotation(rot); }
}

struct GameWorldWrapper
{
	const static char *namez = "d_class_charge_game_world_World";
	const static string name = "d_class_charge_game_world_World";

	extern (C) static int newGameWorld(lua_State *l)
	{
		auto s = LuaState(l);
		GameWorld w;

		try {
			w = new GameWorld(SysPool());
		} catch (Exception e) {
			s.error(e);
		}

		s.pushClass(w);
		return 1;
	}

	static void register(LuaState s)
	{
		s.registerClass!(GameWorld);
		s.pushCFunction(&ObjectWrapper.toString);
		s.setFieldz(-2, "__tostring");
		s.pop();

		s.pushString("GameWorld");
		s.pushCFunction(&newGameWorld);
		s.setTable(LUA_GLOBALSINDEX);
	}
}

struct GameCameraWrapper
{
	const static char *namez = "d_class_test_lua_GameCamera";
	const static string name = "d_class_test_lua_GameCamera";

	extern (C) static int newGameCamera(lua_State *l)
	{
		auto s = LuaState(l);
		auto w = s.checkClass!(GameWorld)(1, false);
		GameCamera c;

		try
			c = new GameCamera(w);
		catch (Exception e)
			s.error(e);

		s.pushClass(c);
		return 1;
	}

	extern (C) static int render(lua_State *l)
	{
		auto s = LuaState(l);
		auto c = s.checkClassName!(GameCamera)(1, false, name);

		try
			c.render();
		catch (Exception e)
			s.error(e);

		return 0;
	}

	static void register(LuaState s)
	{
		s.registerClass!(GameCamera);
		s.pushCFunction(&ObjectWrapper.toString);
		s.setFieldz(-2, "__tostring");
		s.pushCFunction(&MovableWrapper.index);
		s.setFieldz(-2, "__index");
		s.pushCFunction(&MovableWrapper.newIndex);
		s.setFieldz(-2, "__newindex");
		s.pushCFunction(&render);
		s.setFieldz(-2, "render");
		s.pop();

		s.pushString("GameCamera");
		s.pushCFunction(&newGameCamera);
		s.setTable(LUA_GLOBALSINDEX);
	}
}

struct GameCubeWrapper
{
	const static char *namez = "d_class_test_lua_GameCube";
	const static string name = "d_class_test_lua_GameCube";

	extern (C) static int newGameCube(lua_State *l)
	{
		auto s = LuaState(l);
		auto w = s.checkClass!(GameWorld)(1, false);
		GameCube c;

		try
			c = new GameCube(w);
		catch (Exception e)
			s.error(e);

		s.pushClass(c);
		return 1;
	}

	static void register(LuaState s)
	{
		s.registerClass!(GameCube);
		s.pushCFunction(&ObjectWrapper.toString);
		s.setFieldz(-2, "__tostring");
		s.pushCFunction(&MovableWrapper.index);
		s.setFieldz(-2, "__index");
		s.pushCFunction(&MovableWrapper.newIndex);
		s.setFieldz(-2, "__newindex");
		s.pop();

		s.pushString("GameCube");
		s.pushCFunction(&newGameCube);
		s.setTable(LUA_GLOBALSINDEX);
	}
}

struct GameSunLightWrapper
{
	const static char *namez = "d_class_test_lua_GameSunLight";
	const static string name = "d_class_test_lua_GameSunLight";

	extern (C) static int newGameSunLight(lua_State *l)
	{
		auto s = LuaState(l);
		auto w = s.checkClass!(GameWorld)(1, false);
		GameSunLight sl;

		try
			sl = new GameSunLight(w);
		catch (Exception e)
			s.error(e);

		s.pushClass(sl);
		return 1;
	}

	static void register(LuaState s)
	{
		s.registerClass!(GameSunLight);
		s.pushCFunction(&ObjectWrapper.toString);
		s.setFieldz(-2, "__tostring");
		s.pushCFunction(&MovableWrapper.index);
		s.setFieldz(-2, "__index");
		s.pushCFunction(&MovableWrapper.newIndex);
		s.setFieldz(-2, "__newindex");
		s.pop();

		s.pushString("GameSunLight");
		s.pushCFunction(&newGameSunLight);
		s.setTable(LUA_GLOBALSINDEX);
	}
}

class Game : GameSimpleApp
{
private:
	uint ticks;
	Movable m;
	LuaState s;

public:
	this(string[] args)
	{
		/* This will initalize Core and other important things */
		super();

		int ret;
		s = new LuaState();
		Point3d p = Point3d();
		Vector3d v = Vector3d(10, 0, 0);
		m = new Movable();

		s.openLibs();
		s.openCharge();

		GameCubeWrapper.register(s);
		GameWorldWrapper.register(s);
		GameCameraWrapper.register(s);
		GameSunLightWrapper.register(s);

/*
		s.registerClass!(Movable);
		s.pushCFunction(&ObjectWrapper.toString);
		s.setFieldz(-2, "__tostring");
		s.pushCFunction(&MovableWrapper.index);
		s.setFieldz(-2, "__index");
		s.pushCFunction(&MovableWrapper.newIndex);
		s.setFieldz(-2, "__newindex");
		s.pop();

		s.pushString("m");
		s.pushClass(m);
		s.setTable(lib.lua.lua.LUA_GLOBALSINDEX);*/

		ret = s.loadFile("res/test.lua");
		writefln(ret);
		if (ret == 3) {
			writefln("loadFile failed \"", s.toString(-3), "\"");
			writefln("loadFile failed \"", s.toString(-2), "\"");
			writefln("loadFile failed \"", s.toString(-1), "\"");
			throw new Exception("error");
		}

		ret = s.call();
		if (ret == 2) {
			writefln("call failed \"", s.toString(-1), "\"");
			throw new Exception("error");
		}

	}

	void logic()
	{
		s.getGlobalz("tick");
		if (s.call  == 2) {
			writefln(s.toString(-1));
		}
	}

	void render()
	{
		s.getGlobalz("render");
		if (s.call  == 2) {
			writefln(s.toString(-1));
		}
	}

	void close() {}
	void network() {}
}

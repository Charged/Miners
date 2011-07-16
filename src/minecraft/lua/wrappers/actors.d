// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.lua.wrappers.actors;

import std.math;

import charge.charge;
import charge.game.lua;

import minecraft.world;
import minecraft.options;
import minecraft.actors.camera;
import minecraft.actors.sunlight;


struct CameraWrapper
{
	const static char *namez = "d_class_minecraft_lua_actors_Camera";
	const static char[] name = "d_class_minecraft_lua_actors_Camera";

	extern (C) static int newCamera(lua_State *l)
	{
		auto s = LuaState(l);
		auto w = s.checkClass!(World)(1, false);
		Camera c;

		try
			c = new Camera(w);
		catch (Exception e)
			s.error(e);

		s.pushClass(c);
		return 1;
	}

	extern (C) static int index(lua_State *l)
	{
		auto s = LuaState(l);
		char[] key;
		auto c = s.checkClass!(Camera)(1, false);
		s.checkString(2);

		key = s.toString(2);
		switch(key) {
		case "position":
			c.c.getPosition(*Point3dWrapper.push(s));
			break;
		case "rotation":
			c.c.getRotation(*QuatdWrapper.push(s));
			break;
		case "far":
			s.pushNumber(c.c.far);
			break;
		case "near":
			s.pushNumber(c.c.near);
			break;
		case "ratio":
			s.pushNumber(c.c.ratio);
			break;
		default:
			s.getMetaTable(1);
			s.pushValue(2);
			s.getTable(-2);
			break;
		}

		return 1;
	}

	extern (C) static int newIndex(lua_State *l)
	{
		auto s = LuaState(l);
		char[] key;
		auto c = s.checkClass!(Camera)(1, false);
		s.checkString(2);

		key = s.toString(2);
		switch(key)	{
		case "position":
			c.c.setPosition(*s.checkPoint3d(3));
			break;
		case "rotation":
			c.c.setRotation(*s.checkQuatd(3));
			break;
		case "far":
			c.c.far = s.toNumber(3);
			(cast(World)c.w).t.setViewRadii(cast(int)(c.c.far / 16 + 1));
			break;
		case "near":
			c.c.near = s.toNumber(3);
			break;
		case "ratio":
			c.c.ratio = s.toNumber(3);
			break;
		default:
			s.error("No memeber of that that name");
			break;
		}

		return 0;
	}

	static void register(LuaState s)
	{
		s.registerClass!(Camera);
		s.pushCFunction(&ObjectWrapper.toString);
		s.setFieldz(-2, "__tostring");
		s.pushCFunction(&index);
		s.setFieldz(-2, "__index");
		s.pushCFunction(&newIndex);
		s.setFieldz(-2, "__newindex");
		s.pop();

		s.pushString("Camera");
		s.pushCFunction(&newCamera);
		s.setTable(lib.lua.lua.LUA_GLOBALSINDEX);
	}
}

struct SunLightWrapper
{
	const static char *namez = "d_class_minecraft_lua_actors_SunLight";
	const static char[] name = "d_class_minecraft_lua_actors_SunLight";

	extern (C) static int newSunLight(lua_State *l)
	{
		auto s = LuaState(l);
		auto w = s.checkClass!(World)(1, false);
		SunLight sl;

		try
			sl = new SunLight(w);
		catch (Exception e)
			s.error(e);

		s.pushClass(sl);
		return 1;
	}

	extern (C) static int index(lua_State *l)
	{
		auto s = LuaState(l);
		char[] key;
		auto sl = s.checkClass!(SunLight)(1, false);
		s.checkString(2);

		key = s.toString(2);
		switch(key) {
		case "position":
			sl.gfx.getPosition(*Point3dWrapper.push(s));
			break;
		case "rotation":
			sl.gfx.getRotation(*QuatdWrapper.push(s));
			break;
		case "diffuse":
			s.pushColor4f(sl.gfx.diffuse);
			break;
		case "ambient":
			s.pushColor4f(sl.gfx.ambient);
			break;
		case "fog":
			// TODO
			//s.pushBool(sl.gfx.fog !is null);
			break;
		case "fogStart":
			s.pushNumber(sl.fog.start);
			break;
		case "fogStop":
			s.pushNumber(sl.fog.stop);
			break;
		case "fogColor":
			s.pushColor4f(sl.fog.color);
			break;
		default:
			s.getMetaTable(1);
			s.pushValue(2);
			s.getTable(-2);
			break;
		}

		return 1;
	}

	extern (C) static int newIndex(lua_State *l)
	{
		auto s = LuaState(l);
		char[] key;
		auto sl = s.checkClass!(SunLight)(1, false);
		s.checkString(2);

		key = s.toString(2);
		switch(key)	{
		case "position":
			auto p = Point3dWrapper.check(s, 3);
			try {
				sl.gfx.setPosition(*p);
				return 1;
			} catch (Exception e) {
				return s.error(e);
			}
		case "rotation":
			auto q = QuatdWrapper.check(s, 3);
			try {
				sl.gfx.setRotation(*q);
				return 1;
			} catch (Exception e) {
				return s.error(e);
			}
		case "diffuse":
			auto color = 
			sl.gfx.diffuse = *s.checkColor4f(3);
			break;
		case "ambient":
			sl.gfx.ambient = *s.checkColor4f(3);
			break;
		case "fog":
			// TODO
			//sl.w.gfx.fog = s.toBool(3) ? sl.fog : null;
			break;
		case "fogStart":
			sl.fog.start = s.toNumber(3);
			break;
		case "fogStop":
			sl.fog.stop = s.toNumber(3);
			break;
		case "fogColor":
			sl.fog.color = *s.checkColor4f(3);
			break;
		default:
			s.error("No memeber of that that name");
			break;
		}

		return 0;
	}

	static void register(LuaState s)
	{
		s.registerClass!(SunLight);
		s.pushCFunction(&ObjectWrapper.toString);
		s.setFieldz(-2, "__tostring");
		s.pushCFunction(&index);
		s.setFieldz(-2, "__index");
		s.pushCFunction(&newIndex);
		s.setFieldz(-2, "__newindex");
		s.pop();

		s.pushString("SunLight");
		s.pushCFunction(&newSunLight);
		s.setTable(lib.lua.lua.LUA_GLOBALSINDEX);
	}
}

struct OptionsWrapper
{
	const static char *namez = "d_class_minecraft_options_Options";
	const static char[] name = "d_class_minecraft_options_Options";

	extern (C) static int index(lua_State *l)
	{
		auto s = LuaState(l);
		char[] key;
		auto opts = s.checkClass!(Options)(1, false);
		s.checkString(2);

		key = s.toString(2);
		switch(key) {
		case "aa":
			s.pushBool(opts.aa());
			break;
		case "shadow":
			s.pushBool(opts.shadow());
			break;
		case "renderer":
			s.pushString(opts.rendererString);
			break;
		case "showDebug":
			s.pushBool(opts.showDebug());
			break;
		case "viewDistance":
			s.pushNumber(opts.viewDistance());
			break;
		default:
			s.getMetaTable(1);
			s.pushValue(2);
			s.getTable(-2);
			break;
		}

		return 1;
	}

	extern (C) static int newIndex(lua_State *l)
	{
		auto s = LuaState(l);
		char[] key;
		auto opts = s.checkClass!(Options)(1, false);
		s.checkString(2);

		key = s.toString(2);
		switch(key)	{
		case "aa":
			opts.aa = s.toBool(3);
			break;
		case "shadow":
			opts.shadow = s.toBool(3);
			break;
		case "showDebug":
			opts.showDebug = s.toBool(3);
			break;
		case "viewDistance":
			opts.viewDistance = s.toNumber(3);
			break;
		default:
			s.error("No memeber of that that name");
			break;
		}

		return 0;
	}


	extern (C) static int switchRenderer(lua_State *l)
	{
		auto s = LuaState(l);
		auto opts = s.checkClass!(Options)(1, false);

		try {
			opts.changeRenderer();
		} catch (Exception e) {
			s.error(e);
		}

		return 0;
	}

	extern (C) static int screenshot(lua_State *l)
	{
		auto s = LuaState(l);

		try {
			Core().screenShot();
		} catch (Exception e) {
			s.error(e);
		}

		return 1;
	}

	static void register(LuaState s)
	{
		s.registerClass!(Options);
		s.pushCFunction(&ObjectWrapper.toString);
		s.setFieldz(-2, "__tostring");
		s.pushCFunction(&index);
		s.setFieldz(-2, "__index");
		s.pushCFunction(&newIndex);
		s.setFieldz(-2, "__newindex");
		s.pushCFunction(&switchRenderer);
		s.setFieldz(-2, "switchRenderer");
		s.pushCFunction(&screenshot);
		s.setFieldz(-2, "screenshot");
		s.pop();
	}
}
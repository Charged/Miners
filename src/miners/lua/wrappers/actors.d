// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.lua.wrappers.actors;

import std.math;

import charge.charge;

import miners.world;
import miners.options;
import miners.lua.state;
import miners.actors.camera;
import miners.actors.sunlight;
import miners.actors.otherplayer;


struct CameraWrapper
{
	const static char *namez = "d_class_minecraft_lua_actors_Camera";
	const static string name = "d_class_minecraft_lua_actors_Camera";

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
		string key;
		auto c = s.checkClass!(Camera)(1, false);
		s.checkString(2);

		key = s.toString(2);
		switch(key) {
		case "position":
			c.getPosition(*s.pushPoint3d());
			break;
		case "rotation":
			c.getRotation(*s.pushQuatd());
			break;
		case "far":
			s.pushNumber(c.far);
			break;
		case "near":
			s.pushNumber(c.near);
			break;
		case "iso":
			s.pushBool(c.iso);
			break;
		case "proj":
			s.pushBool(c.proj);
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
		string key;
		auto c = s.checkClass!(Camera)(1, false);
		s.checkString(2);

		key = s.toString(2);
		switch(key)	{
		case "position":
			c.setPosition(*s.checkPoint3d(3));
			break;
		case "rotation":
			c.setRotation(*s.checkQuatd(3));
			break;
/*
		case "far":
			c.far = s.toNumber(3);
			break;
		case "near":
			c.near = s.toNumber(3);
			break;
*/
		case "iso":
			c.iso = s.toBool(3);
			break;
		case "proj":
			c.proj = s.toBool(3);
			break;
		default:
			s.error("No memeber of that that name");
			break;
		}

		return 0;
	}

	extern (C) static int resize(lua_State *l)
	{
		auto s = LuaState(l);
		auto c = s.checkClass!(Camera)(1, false);
		auto w = cast(uint)s.checkNumber(2);
		auto h = cast(uint)s.checkNumber(3);

		try {
			c.resize(w, h);
		} catch (Exception e) {
			s.error(e);
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
		s.pushCFunction(&resize);
		s.setFieldz(-2, "resize");
		s.pop();
	}
}

struct SunLightWrapper
{
	const static char *namez = "d_class_minecraft_lua_actors_SunLight";
	const static string name = "d_class_minecraft_lua_actors_SunLight";

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
		string key;
		auto sl = s.checkClass!(SunLight)(1, false);
		s.checkString(2);

		key = s.toString(2);
		switch(key) {
		case "position":
			sl.gfx.getPosition(*s.pushPoint3d());
			break;
		case "rotation":
			sl.gfx.getRotation(*s.pushQuatd());
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
		case "fogProcent":
			s.pushNumber(sl.procent);
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
		string key;
		auto sl = s.checkClass!(SunLight)(1, false);
		s.checkString(2);

		key = s.toString(2);
		switch(key)	{
		case "position":
			auto p = s.checkPoint3d(3);
			try {
				sl.gfx.setPosition(*p);
				return 1;
			} catch (Exception e) {
				return s.error(e);
			}
		case "rotation":
			auto q = s.checkQuatd(3);
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
		case "fogProcent":
			sl.procent = s.toNumber(3);
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
	}
}

struct OtherPlayerWrapper
{
	const static char *namez = "d_class_minecraft_actors_otherplayer_OtherPlayer";
	const static string name = "d_class_minecraft_actors_otherplayer_OtherPlayer";

	extern (C) static int newOtherPlayer(lua_State *l)
	{
		auto s = LuaState(l);
		auto w = s.checkClass!(World)(1, false);
		OtherPlayer op;

		try
			op = new OtherPlayer(w, 0, Point3d(), 0, 0);
		catch (Exception e)
			s.error(e);

		// Lua state "owns" this object, and can delete it.
		auto p = s.pushClass(op, true);
		return 1;
	}

	extern (C) static int index(lua_State *l)
	{
		auto s = LuaState(l);
		string key;
		auto op = s.checkClass!(OtherPlayer)(1, false);
		s.checkString(2);

		key = s.toString(2);
		switch(key) {
		case "position":
			op.getPosition(*s.pushPoint3d());
			break;
		case "rotation":
			op.getRotation(*s.pushQuatd());
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
		string key;
		auto op = s.checkClass!(OtherPlayer)(1, false);
		s.checkString(2);

		key = s.toString(2);
		switch(key)	{
		case "position":
			auto p = s.checkPoint3d(3);
			try {
				op.setPosition(*p);
				return 1;
			} catch (Exception e) {
				return s.error(e);
			}
		case "rotation":
			auto q = s.checkQuatd(3);
			try {
				op.setRotation(*q);
				return 1;
			} catch (Exception e) {
				return s.error(e);
			}
		default:
			s.error("No memeber of that that name");
			break;
		}

		return 0;
	}

	extern (C) static int update(lua_State *l)
	{
		auto s = LuaState(l);
		string key;
		auto op = s.checkClass!(OtherPlayer)(1, false);
		auto pos = s.checkPoint3d(2);
		auto heading = s.checkNumber(3);
		auto pitch = s.checkNumber(4);

		try {
			op.update(*pos, heading, pitch);
		} catch (Exception e) {
			return s.error(e);
		}

		return 0;
	}

	static void register(LuaState s)
	{
		s.registerClass!(OtherPlayer);
		s.pushCFunction(&ObjectWrapper.toString);
		s.setFieldz(-2, "__tostring");
		s.pushCFunction(&index);
		s.setFieldz(-2, "__index");
		s.pushCFunction(&newIndex);
		s.setFieldz(-2, "__newindex");
		s.pushCFunction(&update);
		s.setFieldz(-2, "update");
		s.pop();
	}
}

struct OptionsWrapper
{
	const static char *namez = "d_class_minecraft_options_Options";
	const static string name = "d_class_minecraft_options_Options";

	extern (C) static int index(lua_State *l)
	{
		auto s = LuaState(l);
		string key;
		auto opts = s.checkClass!(Options)(1, false);
		s.checkString(2);

		key = s.toString(2);
		switch(key) {
		case "aa":
			s.pushBool(opts.aa());
			break;
		case "fog":
			s.pushBool(opts.fog());
			break;
		case "shadow":
			s.pushBool(opts.shadow());
			break;
		case "renderer":
			s.pushString(opts.rendererString);
			break;
		case "hideUi":
			s.pushBool(opts.hideUi());
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
		string key;
		auto opts = s.checkClass!(Options)(1, false);
		s.checkString(2);

		key = s.toString(2);
		switch(key)	{
		case "aa":
			opts.aa = s.toBool(3);
			break;
		case "fog":
			opts.fog = s.toBool(3);
			break;
		case "shadow":
			opts.shadow = s.toBool(3);
			break;
		case "hideUi":
			opts.hideUi = s.toBool(3);
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

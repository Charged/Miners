// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.lua.wrappers.finite;

import std.math;

import charge.game.lua;

import miners.terrain.finite;


struct FiniteTerrainWrapper
{
	const static char *namez = "d_class_minecraft_terrain_finite_FiniteTerrain";
	const static char[] name = "d_class_minecraft_terrain_finite_FintieTerrain";

	extern (C) static int index(lua_State *l)
	{
		auto s = LuaState(l);
		char[] key;
		auto w = s.checkClass!(FiniteTerrain)(1, false);
		s.checkString(2);

		key = s.toString(2);
		switch(key) {
		default:
			s.getMetaTable(1);
			s.pushValue(2);
			s.getTable(-2);
			break;
		}

		return 1;
	}

	extern (C) static int block(lua_State *l)
	{
		auto s = LuaState(l);
		auto ft = s.checkClass!(FiniteTerrain)(1, false);
		auto x = cast(int)floor(s.toNumber(2));
		auto y = cast(int)floor(s.toNumber(3));
		auto z = cast(int)floor(s.toNumber(4));

		auto b = ft[x, y, z];

		s.pushNumber(b);
		return 1;
	}

	static void register(LuaState s)
	{
		s.registerClass!(FiniteTerrain);
		s.pushCFunction(&ObjectWrapper.toString);
		s.setFieldz(-2, "__tostring");
		s.pushCFunction(&index);
		s.setFieldz(-2, "__index");
		s.pushCFunction(&block);
		s.setFieldz(-2, "block");
		s.pop();
	}
}

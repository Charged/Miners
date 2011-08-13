// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.lua.wrappers.terrain;

import std.math;

import miners.lua.state;
import miners.terrain.beta;
import miners.terrain.finite;
import miners.terrain.common;


struct TerrainWrapper
{
	const static char *namez = "d_class_minecraft_terrain_common_Terrain";
	const static char[] name = "d_class_minecraft_terrain_common_Terrain";

	extern (C) static int index(lua_State *l)
	{
		auto s = LuaState(l);
		auto w = s.checkClass!(Terrain)(1, false);
		auto k = s.checkString(2);;

		switch(k) {
		default:
			s.getMetaTable(1);
			s.pushValue(2);
			s.getTable(-2);
			break;
		}

		return 1;
	}

	extern (C) static int resetBuild(lua_State *l)
	{
		auto s = LuaState(l);
		auto w = s.checkClass!(Terrain)(1, false);

		w.resetBuild();

		return 0;
	}

	extern (C) static int markBlockDirty(lua_State *l)
	{
		auto s = LuaState(l);
		auto w = s.checkClass!(Terrain)(1, false);
		int x, y, z;

		if (s.isPoint3d(2)) {
			auto pos = s.toPoint3d(2);
			x = cast(int)floor(pos.x);
			y = cast(int)floor(pos.y);
			z = cast(int)floor(pos.z);
		} else {
			x = cast(int)floor(s.toNumber(2));
			y = cast(int)floor(s.toNumber(3));
			z = cast(int)floor(s.toNumber(4));
		}

		w.markVolumeDirty(x, y, z, 1, 1, 1);
		return 0;
	}

	extern (C) static int markVolumeDirty(lua_State *l)
	{
		auto s = LuaState(l);
		auto w = s.checkClass!(Terrain)(1, false);
		int x, y, z;
		uint sx, sy, sz;

		if (s.isPoint3d(2)) {
			auto pos = s.toPoint3d(2);
			x = cast(int)floor(pos.x);
			y = cast(int)floor(pos.y);
			z = cast(int)floor(pos.z);
			sx = cast(uint)floor(s.toNumber(3));
			sy = cast(uint)floor(s.toNumber(4));
			sz = cast(uint)floor(s.toNumber(5));
		} else {
			x = cast(int)floor(s.toNumber(2));
			y = cast(int)floor(s.toNumber(3));
			z = cast(int)floor(s.toNumber(4));
			sx = cast(uint)floor(s.toNumber(5));
			sy = cast(uint)floor(s.toNumber(6));
			sz = cast(uint)floor(s.toNumber(7));
		}

		w.markVolumeDirty(x, y, z, sx, sy, sz);
		return 0;
	}

	extern (C) static int getType(lua_State *l)
	{
		auto s = LuaState(l);
		auto bt = s.checkClass!(Terrain)(1, false);
		int x, y, z;

		if (s.isPoint3d(2)) {
			auto pos = s.toPoint3d(2);
			x = cast(int)floor(pos.x);
			y = cast(int)floor(pos.y);
			z = cast(int)floor(pos.z);
		} else {
			x = cast(int)floor(s.toNumber(2));
			y = cast(int)floor(s.toNumber(3));
			z = cast(int)floor(s.toNumber(4));
		}

		auto b = bt.getType(x, y, z);

		s.pushNumber(b);
		return 1;
	}

	extern (C) static int get(lua_State *l)
	{
		auto s = LuaState(l);
		auto bt = s.checkClass!(Terrain)(1, false);
		int x, y, z;

		if (s.isPoint3d(2)) {
			auto pos = s.toPoint3d(2);
			x = cast(int)floor(pos.x);
			y = cast(int)floor(pos.y);
			z = cast(int)floor(pos.z);
		} else {
			x = cast(int)floor(s.toNumber(2));
			y = cast(int)floor(s.toNumber(3));
			z = cast(int)floor(s.toNumber(4));
		}

		s.pushBlock(bt[x, y, z]);

		return 1;
	}

	extern (C) static int set(lua_State *l)
	{
		auto s = LuaState(l);
		auto bt = s.checkClass!(Terrain)(1, false);
		auto b = s.checkBlock(2);
		int x, y, z;

		if (s.isPoint3d(3)) {
			auto pos = s.toPoint3d(3);
			x = cast(int)floor(pos.x);
			y = cast(int)floor(pos.y);
			z = cast(int)floor(pos.z);
		} else {
			x = cast(int)floor(s.toNumber(3));
			y = cast(int)floor(s.toNumber(4));
			z = cast(int)floor(s.toNumber(5));
		}

		bt[x, y, z] = *b;

		s.pushBlock(*b);
		return 1;
	}
}

struct FiniteTerrainWrapper
{
	const static char *namez = "d_class_minecraft_terrain_finite_FiniteTerrain";
	const static char[] name = "d_class_minecraft_terrain_finite_FintieTerrain";

	static void register(LuaState s)
	{
		s.registerClass!(FiniteTerrain);
		s.pushCFunction(&ObjectWrapper.toString);
		s.setFieldz(-2, "__tostring");
		s.pushCFunction(&TerrainWrapper.index);
		s.setFieldz(-2, "__index");
		s.pushCFunction(&TerrainWrapper.getType);
		s.setFieldz(-2, "getType");
		s.pushCFunction(&TerrainWrapper.get);
		s.pushValue(-1);
		s.setFieldz(-3, "get");
		s.setFieldz(-2, "getBlock");
		s.pushCFunction(&TerrainWrapper.set);
		s.pushValue(-1);
		s.setFieldz(-3, "set");
		s.setFieldz(-2, "setBlock");
		s.pushCFunction(&TerrainWrapper.markBlockDirty);
		s.pushValue(-1);
		s.setFieldz(-3, "mark");
		s.pushValue(-1);
		s.setFieldz(-3, "markDirty");
		s.setFieldz(-2, "markBlockDirty");
		s.pushCFunction(&TerrainWrapper.markVolumeDirty);
		s.pushValue(-1);
		s.setFieldz(-3, "markVolume");
		s.setFieldz(-2, "markVolumeDirty");
		s.pushCFunction(&TerrainWrapper.resetBuild);
		s.setFieldz(-2, "resetBuild");
		s.pop();
	}
}

struct BetaTerrainWrapper
{
	const static char *namez = "d_class_minecraft_terrain_beta_BetaTerrain";
	const static char[] name = "d_class_minecraft_terrain_beta_BetaTerrain";

	static void register(LuaState s)
	{
		s.registerClass!(BetaTerrain);
		s.pushCFunction(&ObjectWrapper.toString);
		s.setFieldz(-2, "__tostring");
		s.pushCFunction(&TerrainWrapper.index);
		s.setFieldz(-2, "__index");
		s.pushCFunction(&TerrainWrapper.getType);
		s.setFieldz(-2, "getType");
		s.pushCFunction(&TerrainWrapper.get);
		s.pushValue(-1);
		s.setFieldz(-3, "get");
		s.setFieldz(-2, "getBlock");
		s.pushCFunction(&TerrainWrapper.set);
		s.pushValue(-1);
		s.setFieldz(-3, "set");
		s.setFieldz(-2, "setBlock");
		s.pushCFunction(&TerrainWrapper.markBlockDirty);
		s.pushValue(-1);
		s.setFieldz(-3, "mark");
		s.pushValue(-1);
		s.setFieldz(-3, "markDirty");
		s.setFieldz(-2, "markBlockDirty");
		s.pushCFunction(&TerrainWrapper.markVolumeDirty);
		s.pushValue(-1);
		s.setFieldz(-3, "markVolume");
		s.setFieldz(-2, "markVolumeDirty");
		s.pushCFunction(&TerrainWrapper.resetBuild);
		s.setFieldz(-2, "resetBuild");
		s.pop();
	}
}

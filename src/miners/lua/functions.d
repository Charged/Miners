// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.lua.functions;

import std.math;

import charge.math.ints;
import charge.charge;

import miners.world;
import miners.terrain.common;
import miners.lua.state;
import miners.lua.wrappers.actors;

import lib.lua.lua;
import lib.lua.lauxlib;


/**
 * This functions returns all the positions of all
 * the blocks that the ray intersects with.
 *
 * Lua:
 *  function getRayPoints(pos, dir, length)
 *  pos is a Point
 *  dir is a Vector
 *  length is a number
 */
extern (C) static int getRayPoints(lua_State *l)
{
	const maxNumBlocks = 30; // Don't push to many hits
	auto s = LuaState(l);
	auto pos = s.checkPoint3d(1);
	auto vec = s.checkVector3d(2);
	auto dist = s.checkNumber(3);
	int numBlocks;

	// Remove the arguments
	s.pop(3);


	bool step(int x, int y, int z) {

		if (++numBlocks > maxNumBlocks)
			return false;

		auto p = s.pushPoint3d();
		*p = Point3d(x, y, z);

		return true;
	}

	stepDirection(*pos, *vec, dist, &step);

	return numBlocks;
}

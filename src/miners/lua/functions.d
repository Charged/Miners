// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.lua.functions;

import std.math;

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
	auto startPos = s.checkPoint3d(1);
	auto pos = *startPos;
	auto startVec = s.checkVector3d(2);
	auto vec = *startVec;
	auto dist = s.checkNumber(3);
	double step = 0.005; // Seems good.
	int xCur, yCur, zCur;
	int numBlocks;

	// Remove the arguments
	s.pop(3);

	vec.normalize();
	vec.scale(step);

	xCur = int.min; // Yes this will skip this coord
	yCur = int.min; // if we start in it. But come on!
	zCur = int.min;

	for (double t = 0; t <= dist && numBlocks <= maxNumBlocks; t += step) {
		int xCalc = cast(int)floor(pos.x);
		int yCalc = cast(int)floor(pos.y);
		int zCalc = cast(int)floor(pos.z);

		if (xCalc != xCur ||
		    yCalc != yCur ||
		    zCalc != zCur) {
			xCur = xCalc;
			yCur = yCalc;
			zCur = zCalc;

			numBlocks++;

			auto p = s.pushPoint3d();
			*p = pos;
		}

		pos += vec;
	}

	return numBlocks;
}

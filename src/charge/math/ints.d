// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file with advanced math functions for manipulating ints.
 */
module charge.math.ints;

import std.math : floor;

import charge.math.point3d;
import charge.math.vector3d;


/**
 * @ingroup Math
 * @{
 */
static final int imin(int a, int b) { return a < b ? a : b; }
static final int imax(int a, int b) { return a > b ? a : b; }
static final int imin4(int a, int b, int c, int d) { return imin(imin(a, b), imin(c, d)); }
static final int imax4(int a, int b, int c, int d) { return imax(imax(a, b), imax(c, d)); }
static final int iclamp(int min, int v, int max) { return imax(min, imin(v, max)); }
/** @} */

/**
 * Calculate the mipmap level size with value as the
 * starting size, as defined by the OpenGL spec.
 *
 * @ingroup Math
 */
int minify(int value, int level)
{
	return value >> level;
}

/**
 * Calculate the number of blocks a given size is for blocksize.
 *
 * @ingroup Math
 */
int nblocks(int size, int blockSize)
{
	return (size+blockSize-1)/blockSize;
}

/**
 * Encodes a int into a uint where lower absulte values
 * corresponds to lower values of uints.
 *
 * -4 -- 1101  --  0101
 * -2 -- 1110  --  0011
 * -1 -- 1111  --  0001
 *  0 -- 0000  --  0000
 *  1 -- 0001  --  0010
 *  2 -- 0010  --  0100
 *  3 -- 0011  --  0110
 *
 * @ingroup Math
 */
uint toDiffCode(int diff)
{
	// x86 does replicating shifts.
	int replicate = diff >> 31;
	return ((~diff & replicate) | (diff & ~replicate)) << 1 | (replicate & 1);
}

/**
 * Decodes a value encoded by toDiffCode.
 *
 * @ingroup Math
 */
int fromDiffCode(uint diffCode)
{
	bool minus = cast(bool)(diffCode & 1);
	uint shifted = diffCode >> 1;
	return (~shifted * minus) | (shifted * !minus);
}

/**
 * Step from the point start in the vector given by heading dist long.
 *
 * Calls the given delegate for each integer unit that we step.
 *
 * @ingroup Math
 */
void stepDirection(ref Point3d start,
		   ref Vector3d heading,
		   double dist,
		   bool delegate(int x, int y, int z) dg)
{
	// So we can change both pos and vector.
	auto pos = start;
	auto vec = heading;
	// Seems good.
	double step = 0.005;
	int xCur, yCur, zCur;

	vec.normalize();
	vec.scale(step);

	// We just need a coord that is different from the first.
	xCur = cast(int)floor(pos.x) + 1;

	for (double t = 0; t <= dist; t += step) {
		int xCalc = cast(int)floor(pos.x);
		int yCalc = cast(int)floor(pos.y);
		int zCalc = cast(int)floor(pos.z);

		pos += vec;
		if (xCalc == xCur &&
		    yCalc == yCur &&
		    zCalc == zCur)
			continue;

		xCur = xCalc;
		yCur = yCalc;
		zCur = zCalc;

		if (!dg(xCur, yCur, zCur))
			break;
	}
}

// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.builder.helpers;

import miners.builder.types;
import miners.builder.emit;
import miners.builder.quad;
import miners.builder.helpers;
import miners.builder.workspace;


/*
 *
 * Position.
 *
 */


/**
 * Calculates global floating point coordinates from local shifted coordinates.
 *
 * Reads x, y, z for coordinates.
 * Reads from p the fields: xOff, yOff, zOff for offsets.
 * And devides the result with VERTEX_SIZE_DIVISOR.
 *
 * Result is stored in the variables xF, yF, zF.
 */
template PositionCalculator()
{
	float xF = cast(float)(x+p.xOff) / VERTEX_SIZE_DIVISOR;
	float yF = cast(float)(y+p.yOff) / VERTEX_SIZE_DIVISOR;
	float zF = cast(float)(z+p.zOff) / VERTEX_SIZE_DIVISOR;
}


/*
 *
 * Normal.
 *
 */


/**
 * Does the normal point alongside the axis.
 */
bool isNormalPositive(sideNormal normal)
{
	return cast(bool)(normal & 1);
}

/**
 * Is the normal parallel to the X axis.
 */
bool isNormalX(sideNormal normal)
{
	return !(normal & 6);
}

/**
 * Is the normal parallel to the Y axis.
 */
bool isNormalY(sideNormal normal)
{
	return !!(normal & 2);
}

/**
 * Is the normal parallel to the Z axis.
 */
bool isNormalZ(sideNormal normal)
{
	return !!(normal & 4);
}


/*
 *
 * UV
 *
 */


/**
 * Convinience function for texture array
 */
ubyte calcTextureXZ(BuildBlockDescriptor *dec)
{
	return dec.xzTex;
}

/**
 * Convinience function for texture array
 */
ubyte calcTextureY(BuildBlockDescriptor *dec)
{
	return dec.yTex;
}

/**
 * Setup manipulated texture coords.
 */
template UVManipulator(int A)
{
	ushort uTL = uvCoords[A][0][0];
	ushort vTL = uvCoords[A][0][1];
	ushort uBL = uvCoords[A][1][0];
	ushort vBL = uvCoords[A][1][1];
	ushort uBR = uvCoords[A][2][0];
	ushort vBR = uvCoords[A][2][1];
	ushort uTR = uvCoords[A][3][0];
	ushort vTR = uvCoords[A][3][1];
}

/**
 * Transform texture coords according to an offset and uvManip.
 *
 * With the top-left corner as origin, L and R are the distance
 * to the origin on the u-axis, and T and B on the v-axis.
 */
ushort[][] genMappedManipUVs(int L, int R, int T, int B,
			     int u_offset, int v_offset, int manip)
{
	L += u_offset;
	R += u_offset;
	T += v_offset;
	B += v_offset;

	ushort[][] uv;

	switch (manip) {
		case uvManip.ROT_90:
			uv = [
				[T, UV_SIZE_DIVISOR-L],
				[B, UV_SIZE_DIVISOR-L],
				[B, UV_SIZE_DIVISOR-R],
				[T, UV_SIZE_DIVISOR-R]
			];
			break;
		case uvManip.ROT_180:
			uv = [
				[UV_SIZE_DIVISOR-L, UV_SIZE_DIVISOR-T],
				[UV_SIZE_DIVISOR-L, UV_SIZE_DIVISOR-B],
				[UV_SIZE_DIVISOR-R, UV_SIZE_DIVISOR-B],
				[UV_SIZE_DIVISOR-R, UV_SIZE_DIVISOR-T]
			];
			break;
		case uvManip.ROT_270:
			uv = [
				[UV_SIZE_DIVISOR-T, L],
				[UV_SIZE_DIVISOR-B, L],
				[UV_SIZE_DIVISOR-B, R],
				[UV_SIZE_DIVISOR-T, R]
			];
			break;
		case uvManip.FLIP_U:
			uv = [
				[UV_SIZE_DIVISOR-L, T],
				[UV_SIZE_DIVISOR-L, B],
				[UV_SIZE_DIVISOR-R, B],
				[UV_SIZE_DIVISOR-R, T]
			];
			break;
		case uvManip.NONE:
		default:
			uv = [
				[L, T],
				[L, B],
				[R, B],
				[R, T]
			];
	}

	return uv;
}

/**
 * Calculate texture coords for a quad on the xz-plane, showing parts
 * of the texture without stretching it.
 */
ushort[][] genMappedManipUVsY(int x1, int x2, int z1, int z2,
			      int u_offset, int v_offset, int manip)
{
	// Result of modulo operation in D has the same sign as the divident, we don't
	// want this behaviour for negative inputs, so we move these into a safe range.
	x1 += 256; x2 += 256;
	z1 += 256; z2 += 256;

	ushort L = cast(ushort)(x1 % UV_SIZE_DIVISOR);
	ushort T = cast(ushort)(z1 % UV_SIZE_DIVISOR);
	ushort R = L + (x2-x1);
	ushort B = T + (z2-z1);

	return genMappedManipUVs(L, R, T, B, u_offset, v_offset, manip);
}

/**
 * Calculate texture coords for a quad on the xz-plane, showing parts
 * of the texture without stretching it.
 */
ushort[][] genMappedManipUVsXZ(int x1, int x2, int y1, int y2, int z1, int z2,
			       int u_offset, int v_offset, sideNormal normal, int manip)
{
	// Result of modulo operation in D has the same sign as the divident, we don't
	// want this behaviour for negative inputs, so we move these into a safe range.
	x1 += 256; x2 += 256;
	z1 += 256; z2 += 256;
	y1 += 256; y2 += 256;

	ushort L = 0, T = 0, R = 0, B = 0;

	if (normal == sideNormal.ZP) {
		L = cast(ushort)(x1 % UV_SIZE_DIVISOR);
		R = L + (x2 - x1);
	} else if (normal == sideNormal.ZN) {
		R = UV_SIZE_DIVISOR - x1 % UV_SIZE_DIVISOR;
		L = R - (x2 - x1);
	} else if (normal == sideNormal.XP) {
		L = cast(ushort)(z1 % UV_SIZE_DIVISOR);
		R = L + (z2 - z1);
	} else {
		R = UV_SIZE_DIVISOR - z1 % UV_SIZE_DIVISOR;
		L = R - (z2 - z1);
	}

	B = cast(ushort)(UV_SIZE_DIVISOR - y1 % UV_SIZE_DIVISOR);
	T = B - (y2 - y1);

	return genMappedManipUVs(L, R, T, B, u_offset, v_offset, manip);
}


/*
 *
 * Ambient occlusion
 *
 */


/**
 * Calculate the ambiant term depending if the surounding blocks are filled.
 *
 * If two diagonal sides around a corner is set full occlusion occurs.
 * If any of the sides or the corner is set half occlusion occurs.
 *
 * Example: aoBL.
 *   None set,          aoBL = 0
 *   c1 set,            aoBL = 1
 *   c2 set,            aoBL = 1
 *   c4 set,            aoBL = 1
 *   c1 & c2 set,       aoBL = 1
 *   c1 & c4 set,       aoBL = 1
 *   c2 & c4 set,       aoBL = 2
 *   c1, c2 & c4 set,   aoBL = 2
 */
ubyte calcAmbient(bool side1, bool side2, bool corner)
{
	return cast(ubyte)((side1 & side2) + (side1 | side2 | corner));
}

/**
 *
 * Setup coordinates for the ambient occlusion scanner.
 *
 * The coordiantes are mapped the same as the UV coords are
 * (tho the UV coords are v = 1-v). But the names match up.
 *
 *   +-------------+-------------+-------------+
 *   |             |             |             |
 *   |(x-1, y, z-1)| (x, y, z-1) |(x+1, y, z-1)|
 *   |             |             |             |
 *   |     c5      |     c7      |     c8      |
 *   |             |             |             |
 *   |(Xn, y+1, Zn)|(Xm, y+1, Zm)|(Xp, y+1, Zp)|
 *   |             |             |             |
 *   +-------------+-------------+-------------+
 *   |             |(0, 1) (1, 1)|             |
 *   | (x-1, y, z) | aoTL   aoTR | (x+1, y, z) |
 *   |             |             |             |
 *   |     c4      |             |     c5      |
 *   |             |             |             |
 *   | (Xn, y, Zn) | aoBL   aoBR | (Xp, y, Zp) |
 *   |             |(0, 0) (1, 0)|             |
 *   +-------------+-------------+-------------+
 *   |             |             |             |
 *   |(x-1, y, z+1)| (x, y, z+1) |(x+1, y, z+1)|
 *   |             |             |             |
 *   |     c1      |     c2      |     c3      |
 *   |             |             |             |
 *   |(Xn, y-1, Zn)|(Xm, y-1, Zm)|(Xp, y-1, Zp)|
 *   |             |             |             |
 *   +-------------+-------------+-------------+
 * 
 */
template AOSetupScannerCoordsXZ()
{
	// On which x should we look at, if Z just set it to the middle.
	int aoXm = normalIsX ? x + positive - !positive : x;
	int aoXn = aoXm + (normalIsZ & !positive) - (normalIsZ & positive);
	int aoXp = aoXm + (normalIsZ & positive) - (normalIsZ & !positive);
	// On which z position should we look at, if X just set it to the middle.
	int aoZm = normalIsZ ? z + positive - !positive : z;
	int aoZn = aoZm + (normalIsX & positive) - (normalIsX & !positive);
	int aoZp = aoZm + (normalIsX & !positive) - (normalIsX & positive);
}

/**
 * Scans and returns filled status of corner blockes, used for fake AO.
 *
 * Reads aoXn, aoXm, aoXp, y, aoZn, aoZm, aoZp.
 * As given by the AOSetupScannerCoordsXZ template-
 *
 * Declares and set c[1-8].
 */
template AOScannerXZ()
{
	auto c1 = data.filled(aoXn, y-1, aoZn);
	auto c2 = data.filled(aoXm, y-1, aoZm);
	auto c3 = data.filled(aoXp, y-1, aoZp);
	auto c4 = data.filled(aoXn, y  , aoZn);
	auto c5 = data.filled(aoXp, y  , aoZp);
	auto c6 = data.filled(aoXn, y+1, aoZn);
	auto c7 = data.filled(aoXm, y+1, aoZm);
	auto c8 = data.filled(aoXp, y+1, aoZp);
}

/**
 * Scans and returns filled status of corner blockes, used for fake AO.
 *
 * Reads x, aoy, z for position.
 * Declares and set c[1-8].
 */
template AOScannerY()
{
	auto c1 = data.filled(x-1, aoy, z+1);
	auto c2 = data.filled(x  , aoy, z+1);
	auto c3 = data.filled(x+1, aoy, z+1);
	auto c4 = data.filled(x-1, aoy, z  );
	auto c5 = data.filled(x+1, aoy, z  );
	auto c6 = data.filled(x-1, aoy, z-1);
	auto c7 = data.filled(x  , aoy, z-1);
	auto c8 = data.filled(x+1, aoy, z-1);
}

/**
 *
 * Convinience template to delcare and calculate all corners.
 *
 * Each corner is occluded by the neighboring blocks. So aoBL that is
 * bottom left is occluded by c1, c2, c4.
 *
 *   +-------------+-------------+-------------+
 *   |             |             |             |
 *   |(x-1, y, z-1)| (x, y, z-1) |(x+1, y, z-1)|
 *   |             |             |             |
 *   |     c5      |     c7      |     c8      |
 *   |             |             |             |
 *   |(Xn, y+1, Zn)|(Xm, y+1, Zm)|(Xp, y+1, Zp)|
 *   |             |             |             |
 *   +-------------+-------------+-------------+
 *   |             |(0, 1) (1, 1)|             |
 *   | (x-1, y, z) | aoTL   aoTR | (x+1, y, z) |
 *   |             |             |             |
 *   |     c4      |             |     c5      |
 *   |             |             |             |
 *   | (Xn, y, Zn) | aoBL   aoBR | (Xp, y, Zp) |
 *   |             |(0, 0) (1, 0)|             |
 *   +-------------+-------------+-------------+
 *   |             |             |             |
 *   |(x-1, y, z+1)| (x, y, z+1) |(x+1, y, z+1)|
 *   |             |             |             |
 *   |     c1      |     c2      |     c3      |
 *   |             |             |             |
 *   |(Xn, y-1, Zn)|(Xm, y-1, Zm)|(Xp, y-1, Zp)|
 *   |             |             |             |
 *   +-------------+-------------+-------------+
 */
template AOCalculator()
{
	auto aoBR = calcAmbient(c2, c5, c3);
	auto aoTR = calcAmbient(c5, c7, c8);
	auto aoTL = calcAmbient(c4, c7, c6);
	auto aoBL = calcAmbient(c2, c4, c1);
}


/*
 *
 * Build helper functions.
 *
 */


/**
 * Pretty much used for all solid blocks.
 */
void solidDec(Packer *p, WorkspaceData *data, BuildBlockDescriptor *dec, uint x, uint y, uint z)
{
	int set = data.getSolidSet(x, y, z);

	/* all set */
	if (set == 0)
		return;

	makeXYZ(p, data, dec, x, y, z, set);
}


/**
 * Used for saplings & plants.
 */
void diagonalSprite(Packer *p, int x, int y, int z, BuildBlockDescriptor *dec)
{
	auto tex = calcTextureXZ(dec);

	const shift = VERTEX_SIZE_BIT_SHIFT;
	x <<= shift;
	y <<= shift;
	z <<= shift;

	int x1 = x, x2 = x+16;
	int y1 = y, y2 = y+16;
	int z1 = z, z2 = z+16;

	emitDiagonalQuads(p, x1, x2, y1, y2, z1, z2, tex);
}


/**
 * Used for redstone- & regular-torches also for redstone repeaters.
 *
 * Coords are shifted.
 */
void standingTorch(Packer *p, int x, int y, int z, ubyte tex)
{
	// Renders a torch with its center at x,z in shifted coordinates.
	int x1 = x-8, x2 = x+8;
	int y1 = y,   y2 = y+16;
	int z1 = z+1, z2 = z-1;

	emitQuadXZN(p, x1, x2, y1, y2, z2, z2, tex, sideNormal.ZN);
	emitQuadXZP(p, x1, x2, y1, y2, z1, z1, tex, sideNormal.ZP);

	x1 = x+1; x2 = x-1;
	z1 = z-8; z2 = z+8;

	emitQuadXZN(p, x2, x2, y1, y2, z1, z2, tex, sideNormal.XN);
	emitQuadXZP(p, x1, x1, y1, y2, z1, z2, tex, sideNormal.XP);

	// Use center part of the texture as top.
	emitQuadMappedUVYP(p, x-1, x+1, y+10, z-1, z+1, tex, sideNormal.YP,
			8 - x % 16, 8 - z % 16 -1, uvManip.NONE);
}

// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.terrain.builder;

import charge.charge;

import minecraft.gfx.vbo;

import minecraft.terrain.vol;
import minecraft.terrain.data;
import minecraft.terrain.chunk;
import minecraft.terrain.workspace;

/*
 * Define how many sub devisions there are in a texture tile.
 */
const UV_SIZE_BIT_SHIFT = 4;
const UV_SIZE_DIVISOR = 1 << UV_SIZE_BIT_SHIFT;

/**
 * Which corner of the uv map is this vertex in.
 */
enum uvCoord : ushort {
	LEFT   = 0,
	CENTER = UV_SIZE_DIVISOR / 2,
	RIGHT  = UV_SIZE_DIVISOR,
	TOP    = 0,
	MIDDLE = UV_SIZE_DIVISOR / 2,
	BOTTOM = UV_SIZE_DIVISOR,
};

/**
 * Should the packer manipulate the coords in any way.
 */
enum uvManip {
	NONE,
	HALF_V,
	HALF_U,
	FLIP_U,
	ROT_90,
	ROT_180,
	ROT_270,
	SIZE,
}

/**
 * Pre-made uv coords manipulation
 *
 * TopLeft, BottomLeft, BottomRight, TopRight
 */
uvCoord uvCoords[uvManip.SIZE][4][2] = [
	[ // uvManip.NONE
		[uvCoord.LEFT,  uvCoord.TOP],
		[uvCoord.LEFT,  uvCoord.BOTTOM],
		[uvCoord.RIGHT, uvCoord.BOTTOM],
		[uvCoord.RIGHT, uvCoord.TOP],
	],
	[ // uvManip.HALF_V
		[uvCoord.LEFT,  uvCoord.TOP],
		[uvCoord.LEFT,  uvCoord.MIDDLE],
		[uvCoord.RIGHT, uvCoord.MIDDLE],
		[uvCoord.RIGHT, uvCoord.TOP],
	],
	[ // uvManip.HALF_U
		[uvCoord.LEFT,   uvCoord.TOP],
		[uvCoord.LEFT,   uvCoord.BOTTOM],
		[uvCoord.MIDDLE, uvCoord.BOTTOM],
		[uvCoord.MIDDLE, uvCoord.TOP],
	],
	[ // uvManip.FLIP_U
		[uvCoord.RIGHT, uvCoord.TOP],
		[uvCoord.RIGHT, uvCoord.BOTTOM],
		[uvCoord.LEFT,  uvCoord.BOTTOM],
		[uvCoord.LEFT,  uvCoord.TOP],
	],
	[ // uvManip.ROT_90
		[uvCoord.LEFT,  uvCoord.BOTTOM],
		[uvCoord.RIGHT, uvCoord.BOTTOM],
		[uvCoord.RIGHT, uvCoord.TOP],
		[uvCoord.LEFT,  uvCoord.TOP],
	],
	[ // uvManip.ROT_180
		[uvCoord.RIGHT, uvCoord.BOTTOM],
		[uvCoord.RIGHT, uvCoord.TOP],
		[uvCoord.LEFT,  uvCoord.TOP],
		[uvCoord.LEFT,  uvCoord.BOTTOM],
	],
	[ // uvManip.ROT_270
		[uvCoord.RIGHT, uvCoord.TOP],
		[uvCoord.LEFT,  uvCoord.TOP],
		[uvCoord.LEFT,  uvCoord.BOTTOM],
		[uvCoord.RIGHT, uvCoord.BOTTOM],
	],
];

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
ushort[][] MappedUVManipulator(int L, int R, int T, int B,
			       int u_offset, int v_offset, int manip)
{
	L += u_offset;
	R += u_offset;
	T += v_offset;
	B += v_offset;

	ushort uv[][];

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
ushort[][] MappedUVYManipulator(int x1, int x2, int z1, int z2,
		   	         int u_offset, int v_offset, int manip)
{
	ushort L = cast(ushort)(x1 % UV_SIZE_DIVISOR);
	ushort T = cast(ushort)(z1 % UV_SIZE_DIVISOR);
	ushort R = L + (x2-x1);
	ushort B = T + (z2-z1);

	return MappedUVManipulator(L, R, T, B, u_offset, v_offset, manip);
}

/**
 * Calculate texture coords for a quad on the xz-plane, showing parts
 * of the texture without stretching it.
 */
ushort[][] MappedUVXZManipulator(int x1, int x2, int y1, int y2, int z1, int z2,
		   	         int u_offset, int v_offset, sideNormal normal, int manip)
{
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

	return MappedUVManipulator(L, R, T, B, u_offset, v_offset, manip);
}

/*
 * Used to convert a chunk block coord into a int and back to a float.
 *
 * That is the builder uses fix precision floating point.
 */
const VERTEX_SIZE_BIT_SHIFT = 4;
const VERTEX_SIZE_DIVISOR = 16;

/**
 * The normal of a side.
 */
enum sideNormal : ubyte {
	XN = 0,
	XP = 1,
	YN = 2,
	YP = 3,
	ZN = 4,
	ZP = 5,

// These extended normals are not accepted by most
// functions only the emitters and packers take these.
	XNZN = 6,
	XNZP = 7,
	XPZN = 8,
	XPZP = 9,
}


int normalTable[] = [
	-1, 0, 0,
	 1, 0, 0,
	 0,-1, 0,
	 0, 1, 0,
	 0, 0,-1,
	 0, 0, 1,

// Extended normals
	-1, 0,-1,
	-1, 0, 1,
	 1, 0,-1,
	 1, 0, 1,
];

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

/**
 * For use together with solid set
 */
enum sideMask {
     XN = 1 << sideNormal.XN,
     XP = 1 << sideNormal.XP,
     YN = 1 << sideNormal.YN,
     YP = 1 << sideNormal.YP,
     ZN = 1 << sideNormal.ZN,
     ZP = 1 << sideNormal.ZP
}

/**
 * Convinience function for texture array
 */
ubyte calcTextureXZ(BlockDescriptor *dec)
{
	return cast(ubyte)(dec.xz.u + 16 * dec.xz.v);
}

/**
 * Convinience function for texture array
 */
ubyte calcTextureY(BlockDescriptor *dec)
{
	return cast(ubyte)(dec.y.u + 16 * dec.y.v);
}

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

/**
 * Calculates global floating point coordinates from local shifted coordinates.
 *
 * Reads x, y, z for coordinates.
 * Reads xOff, yOff, zOff for offsets.
 * And devides the result with VERTEX_SIZE_DIVISOR.
 *
 * Result is stored in the variables xF, yF, zF.
 */
template PositionCalculator()
{
	float xF = cast(float)(x+xOff) / VERTEX_SIZE_DIVISOR;
	float yF = cast(float)(y+yOff) / VERTEX_SIZE_DIVISOR;
	float zF = cast(float)(z+zOff) / VERTEX_SIZE_DIVISOR;
}

/*
 * Packes verticies into a ArrayMesh.
 *
 * Does not take shifted coordinates.
 */
template ArrayPacker()
{
	int *verts;
	int num;

	void pack(int x, int y, int z, ubyte texture, ubyte light,
		  sideNormal normal, ubyte uv_off, int manip)
	{
		int high = (x << 0) | (normal << 5) | (texture << 8);
		int low = (z << 0) | (y << 5) | (light << 12);
		verts[num++] = high | low << 16;
	}
}

/*
 * Packs verticies into a RigidMesh.
 *
 * Takes shifted coordinates.
 */
template MeshPacker()
{
	RigidMeshBuilder mb;
	int xOff;
	int yOff;
	int zOff;

	void pack(int x, int y, int z, ubyte texture, ubyte light,
		  sideNormal normal, ushort u, ushort v)
	{
		float uF = (texture % 16 + cast(float)u / UV_SIZE_DIVISOR) / 16.0f;
		float vF = (texture / 16 + cast(float)v / UV_SIZE_DIVISOR) / 16.0f;

		int nx = normalTable[normal*3+0];
		int ny = normalTable[normal*3+1];
		int nz = normalTable[normal*3+2];

		mixin PositionCalculator!();

		mb.vert(xF, yF, zF, uF, vF, nx, ny, nz);
	}
}

/*
 * Packs verticies into a compact mesh non-indexed texture coords.
 *
 * Takes shifted coordinates.
 */
template CompactMeshPacker()
{
	ChunkVBOCompactMesh.Vertex *verts;
	int iv;
	int xOff;
	int yOff;
	int zOff;

	void pack(int x, int y, int z, ubyte texture, ubyte light,
		  sideNormal normal, ushort u, ushort v)
	{
		int uI = (texture & 0x0f) * 16;
		int vI = (texture & 0xf0);
		uI += u;
		vI += v;

		mixin PositionCalculator!();

		verts[iv].position[0] = xF;
		verts[iv].position[1] = yF;
		verts[iv].position[2] = zF;
		verts[iv].u = cast(ushort)uI;
		verts[iv].v = cast(ushort)vI;
		verts[iv].light = light;
		verts[iv].normal = normal;
		verts[iv].texture = texture;
		verts[iv].pad = 0;
		iv++;
	}
}

/*
 * Packs verticies into a compact mesh non-indexed texture coords.
 *
 * Takes shifted coordinates.
 */
template CompactMeshPackerIndexed()
{
	ChunkVBOCompactMesh.Vertex *verts;
	int iv;
	int xOff;
	int yOff;
	int zOff;

	void pack(int x, int y, int z, ubyte texture, ubyte light,
		  sideNormal normal, ushort u, ushort v)
	{
		int tex = texture;
		int uI = u << 4;
		int vI = v << 4;

		mixin PositionCalculator!();

		verts[iv].position[0] = xF;
		verts[iv].position[1] = yF;
		verts[iv].position[2] = zF;
		verts[iv].u = cast(ushort)uI;
		verts[iv].v = cast(ushort)vI;
		verts[iv].light = light;
		verts[iv].normal = normal;
		verts[iv].texture = cast(ubyte)tex;
		verts[iv].pad = 0;
		iv++;
	}
}

/**
 * Helper functions for emiting quads to a packer.
 */
template QuadEmitter(alias T)
{
	mixin T!();

	void emitQuadAOYP(int x1, int x2, int y, int z1, int z2,
			  ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
			  ubyte texture, sideNormal normal)
	{
		pack(x1, y, z1, texture, aoTL, normal, uvCoord.LEFT, uvCoord.TOP);
		pack(x1, y, z2, texture, aoBL, normal, uvCoord.LEFT, uvCoord.BOTTOM);
		pack(x2, y, z2, texture, aoBR, normal, uvCoord.RIGHT, uvCoord.BOTTOM);
		pack(x2, y, z1, texture, aoTR, normal, uvCoord.RIGHT, uvCoord.TOP);
	}

	void emitQuadAOYP(int x1, int x2, int y, int z1, int z2,
			  ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
			  ubyte texture, sideNormal normal, uvManip manip)
	{
		mixin UVManipulator!(manip);

		pack(x1, y, z1, texture, aoTL, normal, uTL, vTL);
		pack(x1, y, z2, texture, aoBL, normal, uBL, vBL);
		pack(x2, y, z2, texture, aoBR, normal, uBR, vBR);
		pack(x2, y, z1, texture, aoTR, normal, uTR, vTR);
	}

	void emitQuadMappedUVAOYP(int x1, int x2, int y, int z1, int z2,
				  ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
				  ubyte texture, sideNormal normal,
				  int u_offset, int v_offset, uvManip manip)
	{
		ushort uv[][] = MappedUVYManipulator(x1, x2, z1, z2, u_offset, v_offset, manip);

		pack(x1, y, z1, texture, aoTL, normal, uv[0][0], uv[0][1]);
		pack(x1, y, z2, texture, aoBL, normal, uv[1][0], uv[1][1]);
		pack(x2, y, z2, texture, aoBR, normal, uv[2][0], uv[2][1]);
		pack(x2, y, z1, texture, aoTR, normal, uv[3][0], uv[3][1]);
	}

	void emitQuadMappedUVAOYP(int x1, int x2, int y, int z1, int z2,
				  ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
				  ubyte texture, sideNormal normal,
				  int u_offset, int v_offset)
	{
		emitQuadMappedUVAOYP(x1, x2, y, z1, z2, aoBL, aoBR, aoTL, aoTR,
				     texture, normal, u_offset, v_offset, uvManip.NONE);
	}

	void emitQuadAOYN(int x1, int x2, int y, int z1, int z2,
			  ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
			  ubyte texture, sideNormal normal)
	{
		pack(x1, y, z1, texture, aoTL, normal, uvCoord.LEFT, uvCoord.TOP);
		pack(x2, y, z1, texture, aoTR, normal, uvCoord.RIGHT, uvCoord.TOP);
		pack(x2, y, z2, texture, aoBR, normal, uvCoord.RIGHT, uvCoord.BOTTOM);
		pack(x1, y, z2, texture, aoBL, normal, uvCoord.LEFT, uvCoord.BOTTOM);
	}

	void emitQuadMappedUVAOYN(int x1, int x2, int y, int z1, int z2,
				  ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
				  ubyte texture, sideNormal normal,
				  int u_offset, int v_offset, uvManip manip)
	{
		ushort uv[][] = MappedUVYManipulator(x1, x2, z1, z2, u_offset, v_offset, manip);

		pack(x1, y, z1, texture, aoTL, normal, uv[0][0], uv[0][1]);
		pack(x2, y, z1, texture, aoTR, normal, uv[3][0], uv[3][1]);
		pack(x2, y, z2, texture, aoBR, normal, uv[2][0], uv[2][1]);
		pack(x1, y, z2, texture, aoBL, normal, uv[1][0], uv[1][1]);
	}

	void emitQuadMappedUVAOYN(int x1, int x2, int y, int z1, int z2,
				  ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
				  ubyte texture, sideNormal normal,
				  int u_offset, int v_offset)
	{
		emitQuadMappedUVAOYN(x1, x2, y, z1, z2, aoBL, aoBR, aoTL, aoTR,
				     texture, normal, u_offset, v_offset, uvManip.NONE);
	}

	void emitQuadAOXZP(int x1, int x2, int y1, int y2, int z1, int z2,
			   ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
			   ubyte texture, sideNormal normal)
	{
		pack(x2, y1, z1, texture, aoBR, normal, uvCoord.RIGHT, uvCoord.BOTTOM);
		pack(x2, y2, z1, texture, aoTR, normal, uvCoord.RIGHT, uvCoord.TOP);
		pack(x1, y2, z2, texture, aoTL, normal, uvCoord.LEFT, uvCoord.TOP);
		pack(x1, y1, z2, texture, aoBL, normal, uvCoord.LEFT, uvCoord.BOTTOM);
	}

	void emitQuadMappedUVAOXZP(int x1, int x2, int y1, int y2, int z1, int z2,
				   ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
				   ubyte texture, sideNormal normal,
				   int u_offset, int v_offset, uvManip manip)
	{
		ushort uv[][] = MappedUVXZManipulator(x1, x2, y1, y2, z1, z2, u_offset, v_offset, normal, manip);

		pack(x2, y1, z1, texture, aoBR, normal, uv[2][0], uv[2][1]);
		pack(x2, y2, z1, texture, aoTR, normal, uv[3][0], uv[3][1]);
		pack(x1, y2, z2, texture, aoTL, normal, uv[0][0], uv[0][1]);
		pack(x1, y1, z2, texture, aoBL, normal, uv[1][0], uv[1][1]);
	}

	void emitQuadMappedUVAOXZP(int x1, int x2, int y1, int y2, int z1, int z2,
				   ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
				   ubyte texture, sideNormal normal,
				   int u_offset, int v_offset)
	{
		emitQuadMappedUVAOXZP(x1, x2, y1, y2, z1, z2, aoBL, aoBR, aoTL, aoTR,
				      texture, normal, u_offset, v_offset, uvManip.NONE);
	}

	void emitQuadAOXZN(int x1, int x2, int y1, int y2, int z1, int z2,
			   ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
			   ubyte texture, sideNormal normal)
	{
		pack(x1, y1, z2, texture, aoBR, normal, uvCoord.RIGHT, uvCoord.BOTTOM);
		pack(x1, y2, z2, texture, aoTR, normal, uvCoord.RIGHT, uvCoord.TOP);
		pack(x2, y2, z1, texture, aoTL, normal, uvCoord.LEFT, uvCoord.TOP);
		pack(x2, y1, z1, texture, aoBL, normal, uvCoord.LEFT, uvCoord.BOTTOM);
	}

	void emitQuadMappedUVAOXZN(int x1, int x2, int y1, int y2, int z1, int z2,
				   ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
				   ubyte texture, sideNormal normal,
				   int u_offset, int v_offset, uvManip manip)
	{
		ushort uv[][] = MappedUVXZManipulator(x1, x2, y1, y2, z1, z2, u_offset, v_offset, normal, manip);

		pack(x1, y1, z2, texture, aoBR, normal, uv[2][0], uv[2][1]);
		pack(x1, y2, z2, texture, aoTR, normal, uv[3][0], uv[3][1]);
		pack(x2, y2, z1, texture, aoTL, normal, uv[0][0], uv[0][1]);
		pack(x2, y1, z1, texture, aoBL, normal, uv[1][0], uv[1][1]);
	}

	void emitQuadMappedUVAOXZN(int x1, int x2, int y1, int y2, int z1, int z2,
				   ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
				   ubyte texture, sideNormal normal,
				   int u_offset, int v_offset)
	{
		emitQuadMappedUVAOXZN(x1, x2, y1, y2, z1, z1, aoBL, aoBR, aoTL, aoTR,
				      texture, normal, u_offset, v_offset, uvManip.NONE);
	}

	void emitQuadAOXZP(int x1, int x2, int y1, int y2, int z1, int z2,
			   ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
			   ubyte texture, sideNormal normal, uvManip manip)
	{
		mixin UVManipulator!(manip);

		pack(x2, y1, z1, texture, aoBR, normal, uBR, vBR);
		pack(x2, y2, z1, texture, aoTR, normal, uTR, vTR);
		pack(x1, y2, z2, texture, aoTL, normal, uTL, vTL);
		pack(x1, y1, z2, texture, aoBL, normal, uBL, vBL);
	}

	void emitQuadAOXZN(int x1, int x2, int y1, int y2, int z1, int z2,
			   ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
			   ubyte texture, sideNormal normal, uvManip manip)
	{
		mixin UVManipulator!(manip);

		pack(x1, y1, z2, texture, aoBR, normal, uBR, vBR);
		pack(x1, y2, z2, texture, aoTR, normal, uTR, vTR);
		pack(x2, y2, z1, texture, aoTL, normal, uTL, vTL);
		pack(x2, y1, z1, texture, aoBL, normal, uBL, vBL);
	}

	void emitHalfQuadAOXZP(int x1, int x2, int y1, int y2, int z1, int z2,
			       ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
			       ubyte texture, sideNormal normal)
	{
		mixin UVManipulator!(uvManip.HALF_V);

		pack(x2, y1, z1, texture, aoBR, normal, uBR, vBR);
		pack(x2, y2, z1, texture, aoTR, normal, uTR, vTR);
		pack(x1, y2, z2, texture, aoTL, normal, uTL, vTL);
		pack(x1, y1, z2, texture, aoBL, normal, uBL, vBL);
	}

	void emitHalfQuadAOXZM(int x1, int x2, int y1, int y2, int z1, int z2,
			       ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
			       ubyte texture, sideNormal normal)
	{
		mixin UVManipulator!(uvManip.HALF_V);

		pack(x1, y1, z2, texture, aoBR, normal, uBR, vBR);
		pack(x1, y2, z2, texture, aoTR, normal, uTR, vTR);
		pack(x2, y2, z1, texture, aoTL, normal, uTL, vTL);
		pack(x2, y1, z1, texture, aoBL, normal, uBL, vBL);
	}

	void emitQuadYP(int x1, int x2, int y, int z1, int z2,
			ubyte tex, sideNormal normal)
	{
		emitQuadAOYP(x1, x2, y, z1, z2, 0, 0, 0, 0, tex, normal);
	}

	void emitQuadYP(int x1, int x2, int y, int z1, int z2,
			ubyte tex, sideNormal normal, uvManip manip)
	{
		emitQuadAOYP(x1, x2, y, z1, z2, 0, 0, 0, 0, tex, normal, manip);
	}

	void emitQuadMappedUVYP(int x1, int x2, int y, int z1, int z2,
				  ubyte texture, sideNormal normal,
				  int u_offset, int v_offset, uvManip manip)
	{
		emitQuadMappedUVAOYP(x1, x2, y, z1, z2, 0, 0, 0, 0,
				     texture, normal, u_offset, v_offset, manip);
	}

	void emitQuadMappedUVYP(int x1, int x2, int y, int z1, int z2,
				  ubyte texture, sideNormal normal)
	{
		emitQuadMappedUVAOYP(x1, x2, y, z1, z2, 0, 0, 0, 0,
				     texture, normal, 0, 0, uvManip.NONE);
	}

	void emitQuadYN(int x1, int x2, int y, int z1, int z2,
			ubyte tex, sideNormal normal)
	{
		emitQuadAOYN(x1, x2, y, z1, z2, 0, 0, 0, 0, tex, normal);
	}

	void emitQuadMappedUVYN(int x1, int x2, int y, int z1, int z2,
				  ubyte texture, sideNormal normal,
				  int u_offset, int v_offset, uvManip manip)
	{
		emitQuadMappedUVAOYN(x1, x2, y, z1, z2, 0, 0, 0, 0,
				     texture, normal, u_offset, v_offset, manip);
	}

	void emitQuadMappedUVYN(int x1, int x2, int y, int z1, int z2,
				  ubyte texture, sideNormal normal)
	{
		emitQuadMappedUVAOYN(x1, x2, y, z1, z2, 0, 0, 0, 0,
				     texture, normal, 0, 0, uvManip.NONE);
	}

	void emitQuadXZP(int x1, int x2, int y1, int y2, int z1, int z2,
			 ubyte tex, sideNormal normal)
	{
		emitQuadAOXZP(x1, x2, y1, y2, z1, z2, 0, 0, 0, 0, tex, normal);
	}

	void emitQuadXZN(int x1, int x2, int y1, int y2, int z1, int z2,
			 ubyte tex, sideNormal normal)
	{
		emitQuadAOXZN(x1, x2, y1, y2, z1, z2, 0, 0, 0, 0, tex, normal);
	}

	void emitQuadXZP(int x1, int x2, int y1, int y2, int z1, int z2,
			 ubyte tex, sideNormal normal, uvManip manip)
	{
		emitQuadAOXZP(x1, x2, y1, y2, z1, z2, 0, 0, 0, 0, tex, normal, manip);
	}

	void emitQuadXZN(int x1, int x2, int y1, int y2, int z1, int z2,
			 ubyte tex, sideNormal normal, uvManip manip)
	{
		emitQuadAOXZN(x1, x2, y1, y2, z1, z2, 0, 0, 0, 0, tex, normal, manip);
	}

	void emitTiltedQuadXZP(int bx1, int bx2, int tx1, int tx2, int y1, int y2,
			       int bz1, int bz2, int tz1, int tz2,
			       ubyte tex, sideNormal normal)
	{
		pack(bx2, y1, bz1, tex, 0, normal, uvCoord.RIGHT, uvCoord.BOTTOM);
		pack(tx2, y2, tz1, tex, 0, normal, uvCoord.RIGHT, uvCoord.TOP);
		pack(tx1, y2, tz2, tex, 0, normal, uvCoord.LEFT, uvCoord.TOP);
		pack(bx1, y1, bz2, tex, 0, normal, uvCoord.LEFT, uvCoord.BOTTOM);
	}

	void emitTiltedQuadXZN(int bx1, int bx2, int tx1, int tx2, int y1, int y2,
			       int bz1, int bz2, int tz1, int tz2,
			       ubyte tex, sideNormal normal)
	{
		pack(bx1, y1, bz2, tex, 0, normal, uvCoord.RIGHT, uvCoord.BOTTOM);
		pack(tx1, y2, tz2, tex, 0, normal, uvCoord.RIGHT, uvCoord.TOP);
		pack(tx2, y2, tz1, tex, 0, normal, uvCoord.LEFT, uvCoord.TOP);
		pack(bx2, y1, bz1, tex, 0, normal, uvCoord.LEFT, uvCoord.BOTTOM);
	}

	void emitQuadMappedUVXZP(int x1, int x2, int y1, int y2, int z1, int z2,
				 ubyte tex, sideNormal normal,
				 int u_offset, int v_offset, uvManip manip)
	{
		emitQuadMappedUVAOXZP(x1, x2, y1, y2, z1, z2, 0, 0, 0, 0,
				      tex, normal, u_offset, v_offset, manip);
	}

	void emitQuadMappedUVXZN(int x1, int x2, int y1, int y2, int z1, int z2,
				 ubyte tex, sideNormal normal,
				 int u_offset, int v_offset, uvManip manip)
	{
		emitQuadMappedUVAOXZN(x1, x2, y1, y2, z1, z2, 0, 0, 0, 0,
				      tex, normal, u_offset, v_offset, manip);
	}

	void emitQuadMappedUVXZP(int x1, int x2, int y1, int y2, int z1, int z2,
				 ubyte tex, sideNormal normal)
	{
		emitQuadMappedUVAOXZP(x1, x2, y1, y2, z1, z2, 0, 0, 0, 0,
			      tex, normal, 0, 0, uvManip.NONE);
	}

	void emitQuadMappedUVXZN(int x1, int x2, int y1, int y2, int z1, int z2,
				 ubyte tex, sideNormal normal)
	{
		emitQuadMappedUVAOXZN(x1, x2, y1, y2, z1, z2, 0, 0, 0, 0,
			      tex, normal, 0, 0, uvManip.NONE);
	}

	void emitDiagonalQuads(int x1, int x2, int y1, int y2, int z1, int z2, ubyte tex)
	{
		emitQuadAOXZN(x1, x2, y1, y2, z1, z2, 0, 0, 0, 0, tex, sideNormal.XNZN);
		emitQuadAOXZP(x1, x2, y1, y2, z1, z2, 0, 0, 0, 0, tex, sideNormal.XPZP);

		// We flip the z values to get the other two set of coords.
		emitQuadAOXZP(x1, x2, y1, y2, z2, z1, 0, 0, 0, 0, tex, sideNormal.XNZP);
		emitQuadAOXZN(x1, x2, y1, y2, z2, z1, 0, 0, 0, 0, tex, sideNormal.XPZN);
	}

	/*
		+--+
		|  |
		|  +--+
		| /   |
		|/    |
		o-----+
	*/
	void emitStairQuadsLP(int x1, int x3, int y1, int y3, int z1, int z3,
			      ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
			      ubyte texture, sideNormal normal)
	{
		ubyte aoTC = cast(ubyte)((aoTL + aoTR)/2);
		ubyte aoMR = cast(ubyte)((aoBR + aoTR)/2);
		ubyte aoMC = cast(ubyte)((aoBL + aoTR)/2);

		int x2 = (x1 + x3)/2, y2 = (y1 + y3)/2, z2 = (z1 + z3)/2;

		pack(x2, y2, z2, texture, aoMC, normal, uvCoord.CENTER, uvCoord.MIDDLE);
		pack(x2, y3, z2, texture, aoTC, normal, uvCoord.CENTER, uvCoord.TOP);
		pack(x1, y3, z3, texture, aoTL, normal, uvCoord.LEFT,   uvCoord.TOP);
		pack(x1, y1, z3, texture, aoBL, normal, uvCoord.LEFT,   uvCoord.BOTTOM);

		pack(x2, y2, z2, texture, aoMC, normal, uvCoord.CENTER, uvCoord.MIDDLE);
		pack(x1, y1, z3, texture, aoBL, normal, uvCoord.LEFT,   uvCoord.BOTTOM);
		pack(x3, y1, z1, texture, aoBR, normal, uvCoord.RIGHT,  uvCoord.BOTTOM);
		pack(x3, y2, z1, texture, aoMR, normal, uvCoord.RIGHT,  uvCoord.MIDDLE);
	}

	void emitStairQuadsLN(int x1, int x3, int y1, int y3, int z1, int z3,
			      ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
			      ubyte texture, sideNormal normal)
	{
		ubyte aoTC = cast(ubyte)((aoTL + aoTR)/2);
		ubyte aoML = cast(ubyte)((aoBL + aoTL)/2);
		ubyte aoMC = cast(ubyte)((aoBL + aoTR)/2);

		int x2 = (x1 + x3)/2, y2 = (y1 + y3)/2, z2 = (z1 + z3)/2;

		pack(x2, y2, z2, texture, aoMC, normal, uvCoord.CENTER, uvCoord.MIDDLE);
		pack(x1, y1, z3, texture, aoBR, normal, uvCoord.LEFT,   uvCoord.BOTTOM);
		pack(x1, y3, z3, texture, aoTR, normal, uvCoord.LEFT,   uvCoord.TOP);
		pack(x2, y3, z2, texture, aoTC, normal, uvCoord.CENTER, uvCoord.TOP);

		pack(x2, y2, z2, texture, aoMC, normal, uvCoord.CENTER, uvCoord.MIDDLE);
		pack(x3, y2, z1, texture, aoML, normal, uvCoord.RIGHT,  uvCoord.MIDDLE);
		pack(x3, y1, z1, texture, aoBL, normal, uvCoord.RIGHT,  uvCoord.BOTTOM);
		pack(x1, y1, z3, texture, aoBR, normal, uvCoord.LEFT,   uvCoord.BOTTOM);
	}

	/*
		   +--+
		   |  |
		+--+  |
		|   \ |
		|    \|
		o-----+
	*/
	void emitStairQuadsRP(int x1, int x3, int y1, int y3, int z1, int z3,
			      ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
			      ubyte texture, sideNormal normal)
	{
		ubyte aoTC = cast(ubyte)((aoTL + aoTR)/2);
		ubyte aoML = cast(ubyte)((aoBL + aoTL)/2);
		ubyte aoMC = cast(ubyte)((aoBL + aoTR)/2);

		int x2 = (x1 + x3)/2, y2 = (y1 + y3)/2, z2 = (z1 + z3)/2;

		pack(x2, y2, z2, texture, aoMC, normal, uvCoord.CENTER, uvCoord.MIDDLE);
		pack(x1, y2, z3, texture, aoML, normal, uvCoord.LEFT,   uvCoord.MIDDLE);
		pack(x1, y1, z3, texture, aoBL, normal, uvCoord.LEFT,   uvCoord.BOTTOM);
		pack(x3, y1, z1, texture, aoBR, normal, uvCoord.RIGHT,  uvCoord.BOTTOM);

		pack(x2, y2, z2, texture, aoMC, normal, uvCoord.CENTER, uvCoord.MIDDLE);
		pack(x3, y1, z1, texture, aoBR, normal, uvCoord.RIGHT,  uvCoord.BOTTOM);
		pack(x3, y3, z1, texture, aoTR, normal, uvCoord.RIGHT,  uvCoord.TOP);
		pack(x2, y3, z2, texture, aoTC, normal, uvCoord.CENTER, uvCoord.TOP);
	}

	void emitStairQuadsRN(int x1, int x3, int y1, int y3, int z1, int z3,
			      ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
			      ubyte texture, sideNormal normal)
	{
		ubyte aoTC = cast(ubyte)((aoTL + aoTR)/2);
		ubyte aoMR = cast(ubyte)((aoBR + aoTR)/2);
		ubyte aoMC = cast(ubyte)((aoBL + aoTR)/2);

		int x2 = (x1 + x3)/2, y2 = (y1 + y3)/2, z2 = (z1 + z3)/2;

		pack(x2, y2, z2, texture, aoMC, normal, uvCoord.CENTER, uvCoord.MIDDLE);
		pack(x3, y1, z1, texture, aoBL, normal, uvCoord.RIGHT,  uvCoord.BOTTOM);
		pack(x1, y1, z3, texture, aoBR, normal, uvCoord.LEFT,   uvCoord.BOTTOM);
		pack(x1, y2, z3, texture, aoMR, normal, uvCoord.LEFT,   uvCoord.MIDDLE);

		pack(x2, y2, z2, texture, aoMC, normal, uvCoord.CENTER, uvCoord.MIDDLE);
		pack(x2, y3, z2, texture, aoTC, normal, uvCoord.CENTER, uvCoord.TOP);
		pack(x3, y3, z1, texture, aoTL, normal, uvCoord.RIGHT,  uvCoord.TOP);
		pack(x3, y1, z1, texture, aoBL, normal, uvCoord.RIGHT,  uvCoord.BOTTOM);
	}
}

/**
 * Constructs fullsized quads.
 *
 * Coordinates are shifted.
 */
template QuadBuilder(alias T)
{
	mixin QuadEmitter!(T);

	void makeY(BlockDescriptor *dec, uint x, uint y, uint z, sideNormal normal)
	{
		bool positive = isNormalPositive(normal);
		auto aoy = y + positive - !positive;
		mixin AOScannerY!();
		mixin AOCalculator!();

		int x1 = x, x2 = x+1;
		int z1 = z, z2 = z+1;
		y += positive;

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x1 <<= shift;
		x2 <<= shift;
		y  <<= shift;
		z1 <<= shift;
		z2 <<= shift;

		ubyte texture = calcTextureY(dec);

		if (positive) {
			emitQuadAOYP(x1, x2, y, z1, z2,
				     aoBL, aoBR, aoTL, aoTR,
				     texture, normal);
		} else {
			emitQuadAOYN(x1, x2, y, z1, z2,
				     aoBL, aoBR, aoTL, aoTR,
				     texture, normal);
		}
	}

	void makeStairXZ(BlockDescriptor *dec, uint x, uint y, uint z, sideNormal normal, bool left)
	{
		bool positive = isNormalPositive(normal);
		bool normalIsZ = isNormalZ(normal);
		bool normalIsX = !normalIsZ;

		mixin AOSetupScannerCoordsXZ!();
		mixin AOScannerXZ!();
		mixin AOCalculator!();

		// Where does the side stand.
		int x1 = x + (positive & normalIsX);
		int z1 = z + (positive & normalIsZ);

		// If the normal is parallel to the other axis change the coordinate.
		int x2 = x1 + normalIsZ;
		int z2 = z1 + normalIsX;

		// Height
		int y1 = y, y2 = y+1;

		ubyte texture = calcTextureXZ(dec);

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x1 <<= shift;
		x2 <<= shift;
		y1 <<= shift;
		y2 <<= shift;
		z1 <<= shift;
		z2 <<= shift;

		auto emitStairQuads = &emitStairQuadsLP;
		if (positive) {
			if (left) {
				emitStairQuads = &emitStairQuadsLP;
			} else {
				emitStairQuads = &emitStairQuadsRP;
			}
		} else {
			if (left) {
				emitStairQuads = &emitStairQuadsLN;
			} else {
				emitStairQuads = &emitStairQuadsRN;
			}
		}

		emitStairQuads(x1, x2, y1, y2, z1, z2,
			       aoBL, aoBR, aoTL, aoTR,
			       texture, normal);
	}

	void makeXZ(BlockDescriptor *dec, uint x, uint y, uint z, sideNormal normal)
	{
		bool positive = isNormalPositive(normal);
		bool normalIsZ = isNormalZ(normal);
		bool normalIsX = !normalIsZ;

		mixin AOSetupScannerCoordsXZ!();
		mixin AOScannerXZ!();
		mixin AOCalculator!();

		// Where does the side stand.
		int x1 = x + (positive & normalIsX);
		int z1 = z + (positive & normalIsZ);

		// If the normal is parallel to the other axis change the coordinate.
		int x2 = x1 + normalIsZ;
		int z2 = z1 + normalIsX;

		// Height
		int y1 = y, y2 = y+1;

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x1 <<= shift;
		x2 <<= shift;
		y1 <<= shift;
		y2 <<= shift;
		z1 <<= shift;
		z2 <<= shift;

		ubyte texture = calcTextureXZ(dec);

		if (positive) {
			emitQuadAOXZP(x1, x2, y1, y2, z1, z2,
				      aoBL, aoBR, aoTL, aoTR,
				      texture, normal);
		} else {
			emitQuadAOXZN(x1, x2, y1, y2, z1, z2,
				      aoBL, aoBR, aoTL, aoTR,
				      texture, normal);
		}
	}

	void makeXYZ(BlockDescriptor *dec, uint x, uint y, uint z, int set)
	{
		if (set & sideMask.XN)
			makeXZ(dec, x, y, z, sideNormal.XN);

		if (set & sideMask.XP)
			makeXZ(dec, x, y, z, sideNormal.XP);

		if (set & sideMask.YN)
			makeY(dec, x, y, z, sideNormal.YN);

		if (set & sideMask.YP)
			makeY(dec, x, y, z, sideNormal.YP);

		if (set & sideMask.ZN)
			makeXZ(dec, x, y, z, sideNormal.ZN);

		if (set & sideMask.ZP)
			makeXZ(dec, x, y, z, sideNormal.ZP);
	}

	void makeHalfY(BlockDescriptor *dec, uint x, uint y, uint z)
	{
		auto aoy = y;
		mixin AOScannerY!();
		mixin AOCalculator!();

		int x1 = x, x2 = x+1;
		int z1 = z, z2 = z+1;

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x1 <<= shift;
		x2 <<= shift;
		z1 <<= shift;
		z2 <<= shift;

		y <<= shift;
		y += VERTEX_SIZE_DIVISOR / 2;

		ubyte texture = calcTextureY(dec);

		emitQuadAOYP(x1, x2, y, z1, z2,
			     aoBL, aoBR, aoTL, aoTR,
			     texture, sideNormal.YP);
	}

	void makeHalfXZ(BlockDescriptor *dec, uint x, uint y, uint z, sideNormal normal)
	{
		bool positive = isNormalPositive(normal);
		bool normalIsZ = isNormalZ(normal);
		bool normalIsX = !normalIsZ;

		mixin AOSetupScannerCoordsXZ!();

		auto c1 = data.filled(aoXn, y-1, aoZn);
		auto c2 = data.filled(aoXm, y-1, aoZm);
		auto c3 = data.filled(aoXp, y-1, aoZp);
		auto c4 = data.filled(aoXn, y  , aoZn);
		auto c5 = data.filled(aoXp, y  , aoZp);
		auto c6 = false;
		auto c7 = false;
		auto c8 = false;

		mixin AOCalculator!();

		// Where does the side stand.
		int x1 = x + (positive & normalIsX);
		int z1 = z + (positive & normalIsZ);

		// If the normal is parallel to the other axis change the coordinate.
		int x2 = x1 + normalIsZ;
		int z2 = z1 + normalIsX;

		// Height
		int y1 = y, y2;

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x1 <<= shift;
		x2 <<= shift;
		y1 <<= shift;
		y2 = y1 + VERTEX_SIZE_DIVISOR / 2;
		z1 <<= shift;
		z2 <<= shift;

		ubyte texture = calcTextureXZ(dec);

		if (positive) {
			emitHalfQuadAOXZP(x1, x2, y1, y2, z1, z2,
					  aoBL, aoBR, aoTL, aoTR,
					  texture, normal);
		} else {
			emitHalfQuadAOXZM(x1, x2, y1, y2, z1, z2,
					  aoBL, aoBR, aoTL, aoTR,
					  texture, normal);
		}
	}

	void makeHalfXYZ(BlockDescriptor *dec, uint x, uint y, uint z, int set)
	{
		if (set & sideMask.XN)
			makeHalfXZ(dec, x, y, z, sideNormal.XN);

		if (set & sideMask.XP)
			makeHalfXZ(dec, x, y, z, sideNormal.XP);

		if (set & sideMask.YN)
			makeY(dec, x, y, z, sideNormal.YN);

		if (set & sideMask.YP)
			makeHalfY(dec, x, y, z);

		if (set & sideMask.ZN)
			makeHalfXZ(dec, x, y, z, sideNormal.ZN);

		if (set & sideMask.ZP)
			makeHalfXZ(dec, x, y, z, sideNormal.ZP);
	}

	void makeFacedBlock(BlockDescriptor *dec, BlockDescriptor *decFace,
			    uint x, uint y, uint z, sideNormal faceNormal, int set)
	{

		if (set & sideMask.ZN)
			makeXZ((faceNormal == sideNormal.ZN) ? decFace : dec, x, y, z, sideNormal.ZN);
		if (set & sideMask.ZP)
			makeXZ((faceNormal == sideNormal.ZP) ? decFace : dec, x, y, z, sideNormal.ZP);
		if (set & sideMask.XN)
			makeXZ((faceNormal == sideNormal.XN) ? decFace : dec, x, y, z, sideNormal.XN);
		if (set & sideMask.XP)
			makeXZ((faceNormal == sideNormal.XP) ? decFace : dec, x, y, z, sideNormal.XP);
		if (set & sideMask.YN)
			makeY(dec, x, y, z, sideNormal.YN);
		if (set & sideMask.YP)
			makeY(dec, x, y, z, sideNormal.YP);
	}
}

/**
 * Dispatches blocks from a chunk.
 */
template BlockDispatcher(alias T)
{
	mixin QuadBuilder!(T);

	void solidDec(BlockDescriptor *dec, uint x, uint y, uint z) {
		int set = data.getSolidSet(x, y, z);

		/* all set */
		if (set == 0)
			return;

		makeXYZ(dec, x, y, z, set);
	}

	void solid(ubyte type, uint x, uint y, uint z) {
		auto dec = &tile[type];
		solidDec(dec, x, y, z);
	}

	void grass(int x, int y, int z) {
		if (data.get(x, y + 1, z) == 78 /* snow */)
			solid(78, x, y, z);
		else
			solid(2 /* grass */, x, y, z);
	}

	void water(int x, int y, int z) {
		int set = data.getSolidOrTypesSet(8, 9, x, y, z);
		auto dec = &tile[8];
		ubyte tex = calcTextureXZ(dec);
		
		int x1 = x, x2 = x+1;
		int z1 = z, z2 = z+1;

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x1 <<= shift;
		x2 <<= shift;
		z1 <<= shift;
		z2 <<= shift;

		int y1 = y, y2 = y + 1;
		y1 <<= shift;
		y2 <<= shift;

		auto aboveType = data.get(x, y+1, z);
		if (aboveType != 8 && aboveType != 9) {
			set |= sideMask.YP;
			y2 -= 2;
		}

		if (set & sideMask.XN)
			emitQuadXZN(x1, x1, y1, y2, z1, z2, tex, sideNormal.XN);
		if (set & sideMask.XP)
			emitQuadXZP(x2, x2, y1, y2, z1, z2, tex, sideNormal.XP);

		if (set & sideMask.YN)
			emitQuadYN(x1, x2, y1, z1, z2, tex, sideNormal.YN);
		if (set & sideMask.YP)
			emitQuadYP(x1, x2, y2, z1, z2, tex, sideNormal.YP);

		if (set & sideMask.ZN)
			emitQuadXZN(x1, x2, y1, y2, z1, z1, tex, sideNormal.ZN);
		if (set & sideMask.ZP)
			emitQuadXZP(x1, x2, y1, y2, z2, z2, tex, sideNormal.ZP);
	}

	void wood(int x, int y, int z) {
		auto dec = &woodTile[data.getDataUnsafe(x, y, z)];
		solidDec(dec, x, y, z);
	}

	void glass(uint x, uint y, uint z) {
		const type = 20;
		auto dec = &tile[type];
		int set = data.getSolidOrTypeSet(type, x, y, z);

		/* all set */
		if (set == 0)
			return;

		makeXYZ(dec, x, y, z, set);
	}

	void dispenser(int x, int y, int z) {
		auto dec = &tile[23];
		auto decFront = &dispenserFrontTile;
		int set = data.getSolidSet(x, y, z);
		auto d = data.getDataUnsafe(x, y, z);

		auto faceNormal = [sideNormal.ZN, sideNormal.ZP,
				   sideNormal.XN, sideNormal.XP][d-2];

		makeFacedBlock(dec, decFront, x, y, z, faceNormal, set);
	}

	void wool(int x, int y, int z) {
		auto dec = &woolTile[data.getDataUnsafe(x, y, z)];
		solidDec(dec, x, y, z);
	}

	void sapling(int x, int y, int z) {
		auto d = data.getDataUnsafe(x, y, z);
		auto dec = &saplingTile[d & 3];
		auto tex = calcTextureXZ(dec);

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x <<= shift;
		y <<= shift;
		z <<= shift;

		int x1 = x, x2 = x+16;
		int y1 = y, y2 = y+16;
		int z1 = z, z2 = z+16;

		emitDiagonalQuads(x1, x2, y1, y2, z1, z2, tex);
	}

	void plants(ubyte type, int x, int y, int z) {
		auto desc = &tile[type];
		auto tex = calcTextureXZ(desc);

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x <<= shift;
		y <<= shift;
		z <<= shift;

		int x1 = x, x2 = x+16;
		int y1 = y, y2 = y+16;
		int z1 = z, z2 = z+16;

		emitDiagonalQuads(x1, x2, y1, y2, z1, z2, tex);
	}

	void slab(ubyte type, uint x, uint y, uint z) {
		int set = data.getSolidOrTypeSet(type, x, y, z);
		auto d = data.getDataUnsafe(x, y, z);

		auto dec = &slabTile[d];

		if (type == 44)
			makeHalfXYZ(dec, x, y, z, set | sideMask.YP);

		else if (set != 0) /* nothing to do */
			makeXYZ(dec, x, y, z, set);
	}

	void standing_torch(int x, int y, int z, ubyte tex) {
		// Renders a torch in the center of a block. Block coordinates need
		// to be shifted.
		int x1 = x,   x2 = x+16;
		int y1 = y,   y2 = y+16;
		int z1 = z+9, z2 = z+7;

		emitQuadXZN(x1, x2, y1, y2, z2, z2, tex, sideNormal.ZN);
		emitQuadXZP(x1, x2, y1, y2, z1, z1, tex, sideNormal.ZP);

		x1 = x+9; x2 = x+7;
		z1 = z;   z2 = z+16;

		emitQuadXZN(x2, x2, y1, y2, z1, z2, tex, sideNormal.XN);
		emitQuadXZP(x1, x1, y1, y2, z1, z2, tex, sideNormal.XP);
	}

	void torch(ubyte type, int x, int y, int z) {
		auto dec = &tile[type];
		ubyte tex = calcTextureXZ(dec);
		auto d = data.getDataUnsafe(x, y, z);

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x <<= shift;
		y <<= shift;
		z <<= shift;

		if (d >= 5)
			return standing_torch(x, y, z, tex);

		d--;

		int bxoff = [-8, +8,  0,  0][d];
		int txoff = bxoff / 4;
		int bzoff = [ 0,  0, -8, +8][d];
		int tzoff = bzoff / 4;

		int x1 = x,   x2 = x+16;
		int y1 = y+3, y2 = y+19;
		int z1 = z+9, z2 = z+7;

		emitTiltedQuadXZN(x1+bxoff, x2+bxoff, x1+txoff, x2+txoff, y1, y2,
				  z2+bzoff, z2+bzoff, z2+tzoff, z2+tzoff, tex, sideNormal.ZN);
		emitTiltedQuadXZP(x1+bxoff, x2+bxoff, x1+txoff, x2+txoff, y1, y2,
				  z1+bzoff, z1+bzoff, z1+tzoff, z1+tzoff, tex, sideNormal.ZP);

		x1 = x+9; x2 = x+7;
		z1 = z;   z2 = z+16;

		emitTiltedQuadXZN(x2+bxoff, x2+bxoff, x2+txoff, x2+txoff, y1, y2,
				  z1+bzoff, z2+bzoff, z1+tzoff, z2+tzoff, tex, sideNormal.XN);
		emitTiltedQuadXZP(x1+bxoff, x1+bxoff, x1+txoff, x1+txoff, y1, y2,
				  z1+bzoff, z2+bzoff, z1+tzoff, z2+tzoff, tex, sideNormal.XP);

	}

	void redstone_wire(int x, int y, int z) {
		bool shouldLinkTo(ubyte type) {
			return type == 55 || type == 75 || type == 76;
		}

		auto d = data.getDataUnsafe(x, y, z);

		// Find all neighbours with either redstone wire or a torch.
		ubyte NORTH = data.get(x, y, z-1), NORTH_DOWN = data.get(x, y-1, z-1), NORTH_UP = data.get(x, y+1, z-1);
		ubyte SOUTH = data.get(x, y, z+1), SOUTH_DOWN = data.get(x, y-1, z+1), SOUTH_UP = data.get(x, y+1, z+1);
		ubyte EAST = data.get(x-1, y, z), EAST_DOWN = data.get(x-1, y-1, z), EAST_UP = data.get(x-1, y+1, z);
		ubyte WEST = data.get(x+1, y, z), WEST_DOWN = data.get(x+1, y-1, z), WEST_UP = data.get(x+1, y+1, z);

		auto north = shouldLinkTo(NORTH) || shouldLinkTo(NORTH_UP) || shouldLinkTo(NORTH_DOWN);
		auto south = shouldLinkTo(SOUTH) || shouldLinkTo(SOUTH_UP) || shouldLinkTo(SOUTH_DOWN);
		auto east = shouldLinkTo(EAST) || shouldLinkTo(EAST_UP) || shouldLinkTo(EAST_DOWN);
		auto west = shouldLinkTo(WEST) || shouldLinkTo(WEST_UP) || shouldLinkTo(WEST_DOWN);

		ubyte connection = north << 0 | south << 1 | east << 2 | west << 3;

		int x1=x, y1=y, z1=z;

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x1 <<= shift;
		y1 <<= shift;
		z1 <<= shift;

		struct WireMapping {
			RedstoneWireType type;
			uvManip manip;
		}

		// For every possible combination of redstone connections, get the needed tile
		// and necessary uv manipulations.
		const WireMapping mappings[] = [
			{RedstoneWireType.Crossover, 	uvManip.NONE},		// A single wire, no connections.
			{RedstoneWireType.Line,		uvManip.ROT_90},	// N
			{RedstoneWireType.Line,		uvManip.ROT_90},	// S
			{RedstoneWireType.Line,		uvManip.ROT_90},	// N+S
			{RedstoneWireType.Line,		uvManip.NONE},		// E
			{RedstoneWireType.Corner,    	uvManip.ROT_90},	// E+N
			{RedstoneWireType.Corner,    	uvManip.NONE},		// E+S
			{RedstoneWireType.Tjunction,   	uvManip.NONE},		// E+N+S
			{RedstoneWireType.Line,		uvManip.NONE},		// W
			{RedstoneWireType.Corner,    	uvManip.ROT_180},	// W+N
			{RedstoneWireType.Corner,    	uvManip.FLIP_U},	// W+S
			{RedstoneWireType.Tjunction,   	uvManip.FLIP_U},	// W+N+S
			{RedstoneWireType.Line,		uvManip.NONE},		// W+E
			{RedstoneWireType.Tjunction,   	uvManip.ROT_90},	// W+E+N
			{RedstoneWireType.Tjunction,   	uvManip.ROT_270},	// W+E+S
			{RedstoneWireType.Crossover,	uvManip.NONE}		// W+E+N+S
		];

		uint active = (d > 0) ? 1 : 0;
		WireMapping tile = mappings[connection];

		// Place wire on the ground.
		ubyte tex = calcTextureXZ(&redstoneWireTile[active][tile.type]);
		emitQuadYP(x1, x1+16, y1+1, z1, z1+16, tex, sideNormal.YP, tile.manip);

		// Place wire at the side of a block.
		tex = calcTextureXZ(&redstoneWireTile[active][RedstoneWireType.Line]);

		if (shouldLinkTo(NORTH_UP))
			emitQuadXZP(x1, x1+16, y1, y1+16, z1+1, z1+1, tex, sideNormal.ZP, uvManip.ROT_90);
		if (shouldLinkTo(SOUTH_UP))
			emitQuadXZN(x1, x1+16, y1, y1+16, z1+15, z1+15, tex, sideNormal.ZN, uvManip.ROT_90);
		if (shouldLinkTo(EAST_UP))
			emitQuadXZP(x1+1, x1+1, y1, y1+16, z1, z1+16, tex, sideNormal.XP, uvManip.ROT_90);
		if (shouldLinkTo(WEST_UP))
			emitQuadXZN(x1+15, x1+15, y1, y1+16, z1, z1+16, tex, sideNormal.XN, uvManip.ROT_90);
	}

	void craftingTable(uint x, uint y, uint z) {
		int set = data.getSolidSet(x, y, z);
		int setAlt = set & (1 << 0 | 1 << 4);
		auto dec = &tile[58];
		auto decAlt = &craftingTableAltTile;

		// Don't emit the same sides
		set &= ~setAlt;

		if (set != 0)
			makeXYZ(dec, x, y, z, set);

		if (setAlt != 0)
			makeXYZ(decAlt, x, y, z, setAlt);
	}

	void crops(int x, int y, int z) {
		auto dec = &cropsTile[data.getDataUnsafe(x, y, z)];
		ubyte tex = calcTextureXZ(dec);
		const int set = 51;

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x <<= shift;
		y <<= shift;
		z <<= shift;

		// TODO Crops should be offset 1/16 of a block.
		int x1 = x,    x2 = x+16;
		int y1 = y,    y2 = y+16;

		int z1 = z+4;
		emitQuadXZN(x1, x2, y1, y2, z1, z1, tex, sideNormal.ZN);
		emitQuadXZP(x1, x2, y1, y2, z1, z1, tex, sideNormal.ZP);
		int z2 = z+12;
		emitQuadXZN(x1, x2, y1, y2, z2, z2, tex, sideNormal.ZN);
		emitQuadXZP(x1, x2, y1, y2, z2, z2, tex, sideNormal.ZP);

		z1 = z; z2 = z+16;

		x1 = x+4;
		emitQuadXZN(x1, x1, y1, y2, z1, z2, tex, sideNormal.XN);
		emitQuadXZP(x1, x1, y1, y2, z1, z2, tex, sideNormal.XP);

		x2 = x+12;
		emitQuadXZN(x2, x2, y1, y2, z1, z2, tex, sideNormal.XN);
		emitQuadXZP(x2, x2, y1, y2, z1, z2, tex, sideNormal.XP);
	}

	void stair(ubyte type, int x, int y, int z) {
		auto dec = &tile[type];
		int set = data.getSolidSet(x, y, z);
		auto d = data.getDataUnsafe(x, y, z);
		ubyte tex = calcTextureXZ(dec);

		// Half front
		sideMask frontMask = [sideMask.XN, sideMask.XP, sideMask.ZN, sideMask.ZP][d];
		makeHalfXYZ(dec, x, y, z, frontMask & set);

		sideMask backMask = [sideMask.XP, sideMask.XN, sideMask.ZP, sideMask.ZN][d];
		makeXYZ(dec, x, y, z, (backMask | sideMask.YN) & set);

		sideNormal norm1 = [sideNormal.ZN, sideNormal.ZP, sideNormal.XN, sideNormal.XP][d];
		makeStairXZ(dec, x, y, z, norm1, d == 1 || d == 2);

		sideNormal norm2 = [sideNormal.ZP, sideNormal.ZN, sideNormal.XP, sideNormal.XN][d];
		makeStairXZ(dec, x, y, z, norm2, d == 1 || d == 2);

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x <<= shift;
		y <<= shift;
		z <<= shift;

		int X1 = x, XM = x + 8, X2 = x + 16;
		int Y1 = y, YM = y + 8, Y2 = y + 16;
		int Z1 = z, ZM = z + 8, Z2 = z + 16;

		// Midfront (top) and back
		sideMask midfront = [sideMask.XN, sideMask.XP, sideMask.ZN, sideMask.ZP][d];

		int x1 = [XM, X1, X1, X1][d];
		int x2 = [X2, XM, X2, X2][d];
		int z1 = [Z1, Z1, ZM, Z1][d];
		int z2 = [Z2, Z2, Z2, ZM][d];
		int ya = [YM, YM, YM, Y1][d];
		int yb = [YM, YM, Y1, YM][d];
		int yc = [YM, Y1, YM, YM][d];
		int yd = [Y1, YM, YM, YM][d];

		if (midfront & sideMask.ZN)
			emitQuadXZN(x1, x2, ya, Y2, z1, z1, tex, sideNormal.ZN, uvManip.HALF_V);
		if (midfront & sideMask.ZP)
			emitQuadXZP(x1, x2, yb, Y2, z2, z2, tex, sideNormal.ZP, uvManip.HALF_V);
		if (midfront & sideMask.XN)
			emitQuadXZN(x1, x1, yc, Y2, z1, z2, tex, sideNormal.XN, uvManip.HALF_V);
		if (midfront & sideMask.XP)
			emitQuadXZP(x2, x2, yd, Y2, z1, z2, tex, sideNormal.XP, uvManip.HALF_V);

		// Top
		uvManip manip = [uvManip.HALF_U, uvManip.HALF_U, uvManip.HALF_V, uvManip.HALF_V][d];

		if (set & sideMask.YP)
			emitQuadYP(x1, x2, Y2, z1, z2, tex, sideNormal.YP, manip);

		int x3 = [X1, XM, X1, X1][d];
		int x4 = [XM, X2, X2, X2][d];
		int z3 = [Z1, Z1, Z1, ZM][d];
		int z4 = [Z2, Z2, ZM, Z2][d];
		emitQuadYP(x3, x4, YM, z3, z4, tex, sideNormal.YP, manip);
	}

	void door(ubyte type, int x, int y, int z) {
		auto dec = &tile[type];
		int set = data.getSolidSet(x, y, z);
		auto d = data.getDataUnsafe(x, y, z);
		ubyte tex;
		if (d & 8)
			// top half
			tex = calcTextureXZ(dec);
		else
			// bottom half
			tex = calcTextureY(dec);

		bool flip = false;
		if (d & 4)
		{
			d += 1;
			flip = true;
		}

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x <<= shift;
		y <<= shift;
		z <<= shift;

		int x1 = [x,    x,    x+13, x   ][d & 3];
		int x2 = [x+3,  x+16, x+16, x+16][d & 3];
		int y1 = y;
		int y2 = y+16;
		int z1 = [z,    z,    z,    z+13][d & 3];
		int z2 = [z+16, z+3,  z+16, z+16][d & 3];

		if (flip) {
			if (set & sideMask.ZN)
				emitQuadXZN(x1, x2, y1, y2, z1, z1, tex, sideNormal.ZN, uvManip.FLIP_U);
			if (set & sideMask.ZP)
				emitQuadXZP(x1, x2, y1, y2, z2, z2, tex, sideNormal.ZP, uvManip.FLIP_U);
			if (set & sideMask.XN)
				emitQuadXZN(x1, x1, y1, y2, z1, z2, tex, sideNormal.XN, uvManip.FLIP_U);
			if (set & sideMask.XP)
				emitQuadXZP(x2, x2, y1, y2, z1, z2, tex, sideNormal.XP, uvManip.FLIP_U);
		} else {
			if (set & sideMask.ZN)
				emitQuadXZN(x1, x2, y1, y2, z1, z1, tex, sideNormal.ZN);
			if (set & sideMask.ZP)
				emitQuadXZP(x1, x2, y1, y2, z2, z2, tex, sideNormal.ZP);
			if (set & sideMask.XN)
				emitQuadXZN(x1, x1, y1, y2, z1, z2, tex, sideNormal.XN);
			if (set & sideMask.XP)
				emitQuadXZP(x2, x2, y1, y2, z1, z2, tex, sideNormal.XP);
		}

		if (set & sideMask.YN)
			emitQuadYN(x1, x2, y1, z1, z2, tex, sideNormal.YN);
		if (set & sideMask.YP)
			emitQuadYP(x1, x2, y2, z1, z2, tex, sideNormal.YP);
	}

	void ladder(ubyte type, int x, int y, int z) {
		auto dec = &tile[type];
		auto d = data.getDataUnsafe(x, y, z);
		ubyte tex = calcTextureXZ(dec);

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x <<= shift;
		y <<= shift;
		z <<= shift;

		d -= 2;

		int x1 = [x,    x,    x+15, x+1 ][d];
		int x2 = [x+16, x+16, x+15, x+1 ][d];
		int y1 = y;
		int y2 = y+16;
		int z1 = [z+15, z+1,  z,    z   ][d];
		int z2 = [z+15, z+1,  z+16, z+16][d];
		sideNormal normal = [sideNormal.ZN, sideNormal.ZP,
				     sideNormal.XN, sideNormal.XP][d];
		bool positive = isNormalPositive(normal);

		if (positive)
			emitQuadXZP(x1, x2, y1, y2, z1, z2, tex, normal);
		else
			emitQuadXZN(x1, x2, y1, y2, z1, z2, tex, normal);
	}

	void leaves(int x, int y, int z) {
		auto d = data.getDataUnsafe(x, y, z);
		auto dec = &leavesTile[d & 3];
		solidDec(dec, x, y, z);
	}

	void farmland(int x, int y, int z) {
		auto d = data.getDataUnsafe(x, y, z);
		if (d > 0)
			d = 1;
		auto dec = &farmlandTile[d];
		solidDec(dec, x, y, z);
	}

	void furnace(ubyte type, int x, int y, int z) {
		auto dec = &tile[type];
		auto decFront = &furnaceFrontTile[type - 61];
		int set = data.getSolidSet(x, y, z);
		auto d = data.getDataUnsafe(x, y, z);

		auto faceNormal = [sideNormal.ZN, sideNormal.ZP,
				   sideNormal.XN, sideNormal.XP][d-2];

		makeFacedBlock(dec, decFront, x, y, z, faceNormal, set);
	}

	void signpost(int x, int y, int z) {
		auto dec = &tile[63];
		int set = data.getSolidSet(x, y, z);
		auto d = data.getDataUnsafe(x, y, z);
		ubyte tex = calcTextureXZ(dec);

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x <<= shift;
		y <<= shift;
		z <<= shift;

		int x1 = x+7, x2 = x+9;
		int z1 = z+7, z2 = z+9;
		int y1 = y, y2 = y+8;

		// Pole
		emitQuadXZN(x1, x1, y1, y2, z1, z2, tex, sideNormal.XN);
		emitQuadXZP(x2, x2, y1, y2, z1, z2, tex, sideNormal.XP);
		emitQuadXZN(x1, x2, y1, y2, z1, z1, tex, sideNormal.ZN);
		emitQuadXZP(x1, x2, y1, y2, z2, z2, tex, sideNormal.ZP);

		bool north = [ true,  true, false, false,
			      false, false,  true,  true,
			       true,  true, false, false,
			      false, false,  true,  true][d];
		// Sign
		if (north) {
			// North/South orientation
			z1 = z+7;
			z2 = z+9;
			x1 = x;
			x2 = x+16;
			y1 = y+8;
			y2 = y+16;
		} else {
			// West/East orientation
			x1 = x+7;
			x2 = x+9;
			z1 = z;
			z2 = z+16;
			y1 = y+8;
			y2 = y+16;
		}

		emitQuadXZN(x1, x1, y1, y2, z1, z2, tex, sideNormal.XN);
		emitQuadXZP(x2, x2, y1, y2, z1, z2, tex, sideNormal.XP);
		emitQuadYN(x1, x2, y1, z1, z2, tex, sideNormal.YN);
		emitQuadYP(x1, x2, y2, z1, z2, tex, sideNormal.YP);
		emitQuadXZN(x1, x2, y1, y2, z1, z1, tex, sideNormal.ZN);
		emitQuadXZP(x1, x2, y1, y2, z2, z2, tex, sideNormal.ZP);
	}

	void wallsign(int x, int y, int z) {
		auto dec = &tile[68];
		int set = data.getSolidSet(x, y, z);
		auto d = data.getDataUnsafe(x, y, z);
		ubyte tex = calcTextureXZ(dec);

		d -= 2;

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x <<= shift;
		y <<= shift;
		z <<= shift;

		int x1 = [x,    x,    x+14, x   ][d];
		int x2 = [x+16, x+16, x+16, x+2 ][d];
		int y1 = y+4;
		int y2 = y+12;
		int z1 = [z+14, z,    z,    z   ][d];
		int z2 = [z+16, z+2,  z+16, z+16][d];

		// Signs don't occupy a whole block, so the front face has to be shown, even
		// when a block is in front of it.
		if (set & sideMask.ZN || d == 0)
			emitQuadXZN(x1, x2, y1, y2, z1, z1, tex, sideNormal.ZN);
		if (set & sideMask.ZP || d == 1)
			emitQuadXZP(x1, x2, y1, y2, z2, z2, tex, sideNormal.ZP);
		if (set & sideMask.XN || d == 2)
			emitQuadXZN(x1, x1, y1, y2, z1, z2, tex, sideNormal.XN);
		if (set & sideMask.XP || d == 3)
			emitQuadXZP(x2, x2, y1, y2, z1, z2, tex, sideNormal.XP);

		emitQuadYN(x1, x2, y1, z1, z2, tex, sideNormal.YN);
		emitQuadYP(x1, x2, y2, z1, z2, tex, sideNormal.YP);
	}

	void stone_button(int x, int y, int z) {
		auto dec = &tile[77];
		int set = data.getSolidSet(x, y, z);
		auto d = data.getDataUnsafe(x, y, z);
		ubyte tex = calcTextureXZ(dec);

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x <<= shift;
		y <<= shift;
		z <<= shift;

		// Button pressed state.
		int depth = (d & 8) ? 1 : 2;

		d -= 1;
		d &= 3;

		int x1 = [x,       x+16-depth, x+5,     x+5       ][d];
		int x2 = [x+depth, x+16,       x+11,    x+11      ][d];
		int z1 = [z+5,     z+5,        z,       z+16-depth][d];
		int z2 = [z+11,    z+11,       z+depth, z+16      ][d];
		int y1 = y+6;
		int y2 = y+10;

		// Don't render the face where the button is attached to the block.
		if (set & sideMask.ZN || d != 2)
			emitQuadXZN(x1, x2, y1, y2, z1, z1, tex, sideNormal.ZN);
		if (set & sideMask.ZP || d != 3)
			emitQuadXZP(x1, x2, y1, y2, z2, z2, tex, sideNormal.ZP);
		if (set & sideMask.XN || d != 0)
			emitQuadXZN(x1, x1, y1, y2, z1, z2, tex, sideNormal.XN);
		if (set & sideMask.XP || d != 1)
			emitQuadXZP(x2, x2, y1, y2, z1, z2, tex, sideNormal.XP);

		emitQuadYN(x1, x2, y1, z1, z2, tex, sideNormal.YN);
		emitQuadYP(x1, x2, y2, z1, z2, tex, sideNormal.YP);
	}

	void pressure_plate(ubyte type, int x, int y, int z) {
		auto dec = &tile[type];
		ubyte tex = calcTextureXZ(dec);

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x <<= shift;
		y <<= shift;
		z <<= shift;

		int x1 = x+1, x2 = x+15;
		int z1 = z+1, z2 = z+15;
		int y1 = y, y2 = y+1;

		emitQuadXZN(x1, x1, y1, y2, z1, z2, tex, sideNormal.XN);
		emitQuadXZP(x2, x2, y1, y2, z1, z2, tex, sideNormal.XP);
		emitQuadXZN(x1, x2, y1, y2, z1, z1, tex, sideNormal.ZN);
		emitQuadXZP(x1, x2, y1, y2, z2, z2, tex, sideNormal.ZP);
		emitQuadYP(x1, x2, y2, z1, z2, tex, sideNormal.YP);
	}

	void snow(int x, int y, int z) {
		// Make snow into full block for now
		solid(80, x, y, z);
	}

	void fence(int x, int y, int z) {
		const type = 85;
		auto dec = &tile[type];
		int set = data.getSolidSet(x, y, z);
		ubyte tex = calcTextureXZ(dec);

		// Look for nearby fences.
		auto north = data.get(x, y, z-1) == type;
		auto east = data.get(x-1, y, z) == type;

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x <<= shift;
		y <<= shift;
		z <<= shift;

		int x1 = x+6, x2 = x+10;
		int z1 = z+6, z2 = z+10;
		int y1 = y, y2 = y+16;

		// Pole.
		emitQuadMappedUVXZN(x1, x1, y1, y2, z1, z2, tex, sideNormal.XN);
		emitQuadMappedUVXZP(x2, x2, y1, y2, z1, z2, tex, sideNormal.XP);
		emitQuadMappedUVXZN(x1, x2, y1, y2, z1, z1, tex, sideNormal.ZN);
		emitQuadMappedUVXZP(x1, x2, y1, y2, z2, z2, tex, sideNormal.ZP);

		if (set & sideMask.YN)
			emitQuadMappedUVYN(x1, x2, y1, z1, z2, tex, sideNormal.YN);
		if (set & sideMask.YP)
			emitQuadMappedUVYP(x1, x2, y2, z1, z2, tex, sideNormal.YP);

		// Bars in north or east direction.
		if (north) {
			z1 = z-6;
			z2 = z+6;

			emitQuadMappedUVYP(x1+1, x2-1, y+15, z1, z2, tex, sideNormal.YP, 0, -8, uvManip.NONE);
			emitQuadMappedUVYN(x1+1, x2-1, y+12, z1, z2, tex, sideNormal.YN, 0, -8, uvManip.NONE);
			emitQuadMappedUVXZP(x2-1, x2-1, y+12, y+15, z1, z2, tex,sideNormal.XP, -8, 0, uvManip.NONE);
			emitQuadMappedUVXZN(x1+1, x1+1, y+12, y+15, z1, z2, tex,sideNormal.XN, 8, 0, uvManip.NONE);

			emitQuadMappedUVYP(x1+1, x2-1, y+9, z1, z2, tex, sideNormal.YP, 0, -8, uvManip.NONE);
			emitQuadMappedUVYN(x1+1, x2-1, y+6, z1, z2, tex, sideNormal.YN, 0, -8, uvManip.NONE);
			emitQuadMappedUVXZP(x2-1, x2-1, y+6, y+9, z1, z2, tex,sideNormal.XP, -8, 0, uvManip.NONE);
			emitQuadMappedUVXZN(x1+1, x1+1, y+6, y+9, z1, z2, tex,sideNormal.XN, 8, 0, uvManip.NONE);
		}

		if (east) {
			z1 = z+6,
			z2 = z+10;
			x1 = x-6;
			x2 = x+6;

			emitQuadMappedUVYP(x1, x2, y+15, z1+1, z2-1, tex, sideNormal.YP, -8, 0, uvManip.NONE);
			emitQuadMappedUVYN(x1, x2, y+12, z1+1, z2-1, tex, sideNormal.YN, -8, 0, uvManip.NONE);
			emitQuadMappedUVXZP(x1, x2, y+12, y+15, z2-1, z2-1, tex, sideNormal.ZP, -8, 0, uvManip.NONE);
			emitQuadMappedUVXZN(x1, x2, y+12, y+15, z1+1, z1+1, tex, sideNormal.ZN, 8, 0, uvManip.NONE);

			emitQuadMappedUVYP(x1, x2, y+9, z1+1, z2-1, tex, sideNormal.YP, -8, 0, uvManip.NONE);
			emitQuadMappedUVYN(x1, x2, y+6, z1+1, z2-1, tex, sideNormal.YN, -8, 0, uvManip.NONE);
			emitQuadMappedUVXZP(x1, x2, y+6, y+9, z2-1, z2-1, tex, sideNormal.ZP, -8, 0, uvManip.NONE);
			emitQuadMappedUVXZN(x1, x2, y+6, y+9, z1+1, z1+1, tex, sideNormal.ZN, 8,0, uvManip.NONE);
		}
	}

	void pumpkin(int x, int y, int z) {
		auto dec = &tile[86];
		auto decFront = &pumpkinFrontTile;
		int set = data.getSolidSet(x, y, z);
		auto d = data.getDataUnsafe(x, y, z);

		auto faceNormal = [sideNormal.ZN, sideNormal.XP,
				   sideNormal.ZP, sideNormal.XN][d];

		makeFacedBlock(dec, decFront, x, y, z, faceNormal, set);
	}

	void jack_o_lantern(int x, int y, int z) {
		auto dec = &tile[91];
		auto decFront = &jackolanternFrontTile;
		int set = data.getSolidSet(x, y, z);
		auto d = data.getDataUnsafe(x, y, z);

		auto faceNormal = [sideNormal.ZN, sideNormal.XP,
				   sideNormal.ZP, sideNormal.XN][d];

		makeFacedBlock(dec, decFront, x, y, z, faceNormal, set);
	}

	void cake(int x, int y, int z) {
		auto dec = &tile[92];
		int set = data.getSolidSet(x, y, z);
		auto d = data.getDataUnsafe(x, y, z);

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x <<= shift;
		y <<= shift;
		z <<= shift;

		ubyte top_tex = calcTextureY(dec);
		ubyte side_tex = calcTextureXZ(dec);
		ubyte tex = 0;

		// How much is missing from the cake.
		int width = 2*d + 1;

		emitQuadMappedUVYP(x+width, x+16, y+8, z, z+16, top_tex, sideNormal.YP);

		emitQuadMappedUVXZN(x+width, x+16, y, y+8, z+1,  z+1,  side_tex, sideNormal.ZN, 0, -8, uvManip.NONE);
		emitQuadMappedUVXZP(x+width, x+16, y, y+8, z+15, z+15, side_tex, sideNormal.ZP, 0, -8, uvManip.NONE);
		emitQuadMappedUVXZP(x+15,    x+15, y, y+8, z,    z+16, side_tex, sideNormal.XP, 0, -8, uvManip.NONE);

		// Render side where the cake was/will be cut.
		if (d > 0)
			tex = calcTextureXZ(&cakeTile[0]);
		else
			tex = side_tex;
		emitQuadMappedUVXZN(x+width, x+width, y, y+8, z, z+16, tex, sideNormal.XN, 0,-8, uvManip.NONE);

		if (set & sideMask.YN) {
			tex = calcTextureY(&cakeTile[1]);
			emitQuadMappedUVYN(x+width, x+16, y, z, z+16, tex, sideNormal.YN);
		}
	}

	void cactus(int x, int y, int z) {
		const type = 81;
		auto dec = &tile[type];
		ubyte tex = calcTextureXZ(dec);

		int x2 = x+1;
		int y2 = y+1;
		int z2 = z+1;

		if (!data.filledOrType(type, x, y+1, z))
			makeY(dec, x, y, z, sideNormal.YP);
		if (!data.filledOrType(type, x, y-1, z)) {
			dec = &cactusBottomTile;
			makeY(dec, x, y, z, sideNormal.YN);
		}

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x <<= shift;
		x2 <<= shift;
		y <<= shift;
		y2 <<= shift;
		z <<= shift;
		z2 <<= shift;

		emitQuadXZN(x, x2, y, y2, z+1, z+1, tex, sideNormal.ZN);
		emitQuadXZP(x, x2, y, y2, z+15, z+15, tex, sideNormal.ZP);
		emitQuadXZN(x+1, x+1, y, y2, z, z2, tex, sideNormal.XN);
		emitQuadXZP(x+15, x+15, y, y2, z, z2, tex, sideNormal.XP);
	}

	void redstone_repeater(ubyte type, int x, int y, int z) {
		auto dec = &tile[type];
		ubyte tex = calcTextureY(dec);
		auto d = data.getDataUnsafe(x, y, z);
		auto active = (type == 93);

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x <<= shift;
		y <<= shift;
		z <<= shift;

		int y1 = y,   x1 = x,    z1 = z;
		int y2 = y+2, x2 = x+16, z2 = z+16;

		// Sides
		emitQuadMappedUVXZN(x1, x2, y1, y2, z1, z1, tex, sideNormal.ZN);
		emitQuadMappedUVXZP(x1, x2, y1, y2, z2, z2, tex, sideNormal.ZP);
		emitQuadMappedUVXZN(x1, x1, y1, y2, z1, z2, tex, sideNormal.XN);
		emitQuadMappedUVXZP(x2, x2, y1, y2, z1, z2, tex, sideNormal.XP);

		// Top
		uvManip manip = [uvManip.NONE, uvManip.ROT_90, uvManip.ROT_180, uvManip.ROT_270][d & 3];
		emitQuadYP(x, x+16, y+2, z, z+16, tex, sideNormal.YP, manip);

		// Torches
		dec = &tile[(active) ? 75 : 76];
		tex = calcTextureXZ(dec);

		x1 = [x,   x+5, x,   x-5][d & 3];
		z1 = [z-5, z,   z+5, z  ][d & 3];
		standing_torch(x1, y-3, z1, tex);

		// Moving torch, delay is position offset in pixels.
		auto delay = (d >> 2) * 2;

		// Offset by +1/-1 to move torch in default position.
		x2 = [x,         x+1-delay, x,         x-1+delay][d & 3];
		z2 = [z-1+delay, z,         z+1-delay, z        ][d & 3];
		standing_torch(x2, y-3, z2, tex);
	}

	void b(uint x, uint y, uint z) {
		static int count = 0;
		ubyte type = data.get(x, y, z);

		switch(type) {
			case 2:
				grass(x, y, z);
				break;
			case 8:
			case 9:
				water(x, y, z);
				break;
			case 17:
				wood(x, y, z);
				break;
			case 18:
				leaves(x, y, z);
				break;
			case 20:
				glass(x, y, z);
				break;
			case 23:
				dispenser(x, y, z);
				break;
			case 35:
				wool(x, y, z);
				break;
			case 6:
				sapling(x, y, z);
				break;
			case 37:
			case 38:
			case 39:
			case 40:
			case 83:
				plants(type, x, y, z);
				break;
			case 43:
			case 44:
				slab(type, x, y, z);
				break;
			case 50:
			case 75:
			case 76:
				torch(type, x, y, z);
				break;
			case 52:
				solid(52, x, y, z);
				break;
			case 55:
				redstone_wire(x, y, z);
				break;
			case 58:
				craftingTable(x, y, z);
				break;
			case 59:
				crops(x, y, z);
				break;
			case 60:
				farmland(x, y, z);
				break;
			case 61:
			case 62:
				furnace(type, x, y, z);
				break;
			case 63:
				signpost(x, y, z);
				break;
			case 64:
			case 71:
				door(type, x, y, z);
				break;
			case 65:
				ladder(type, x, y, z);
				break;
			case 53:
			case 67:
				stair(type, x, y, z);
				break;
			case 68:
				wallsign(x, y, z);
				break;
			case 70:
			case 72:
				pressure_plate(type, x, y, z);
				break;
			case 77:
				stone_button(x, y, z);
				break;
			case 78:
				snow(x, y, z);
				break;
			case 81:
				cactus(x, y, z);
				break;
			case 85:
				fence(x, y, z);
				break;
			case 86:
				pumpkin(x, y, z);
				break;
			case 91:
				jack_o_lantern(x, y, z);
				break;
			case 92:
				cake(x, y, z);
				break;
			case 93:
			case 94:
				redstone_repeater(type, x, y, z);
				break;
			default:
				if (tile[type].filled)
					solid(type, x, y, z);
		}
	}
}

ChunkVBORigidMesh buildRigidMeshFromChunk(Chunk chunk)
{
	auto data = WorkspaceData.malloc();
	auto mb = new RigidMeshBuilder(128*1024, 0, RigidMesh.Types.QUADS);
	scope(exit) { data.free(); delete mb; }

	mixin BlockDispatcher!(MeshPacker) dispatch;

	data.copyFromChunk(chunk);

	dispatch.mb = mb;
	xOff = chunk.xOff << VERTEX_SIZE_BIT_SHIFT;
	yOff = chunk.yOff << VERTEX_SIZE_BIT_SHIFT;
	zOff = chunk.zOff << VERTEX_SIZE_BIT_SHIFT;

	for (int x; x < 16; x++) {
		for (int y; y < 128; y++) {
			for (int z; z < 16; z++) {
				b(x, y, z);
			}
		}
	}

	// C memory freed above with scope(exit)
	return ChunkVBORigidMesh(mb, chunk.xPos, chunk.zPos);
}

ChunkVBOCompactMesh buildCompactMeshFromChunk(Chunk chunk)
{
	auto data = WorkspaceData.malloc();
	cMemoryArray!(ChunkVBOCompactMesh.Vertex) vertices;
	scope(exit) { data.free(); vertices.free(); }

	mixin BlockDispatcher!(CompactMeshPacker);

	data.copyFromChunk(chunk);

	verts = vertices.realloc(128 * 1024);
	xOff = chunk.xOff << VERTEX_SIZE_BIT_SHIFT;
	yOff = chunk.yOff << VERTEX_SIZE_BIT_SHIFT;
	zOff = chunk.zOff << VERTEX_SIZE_BIT_SHIFT;

	for (int x; x < 16; x++) {
		for (int y; y < 128; y++) {
			for (int z; z < 16; z++) {
				b(x, y, z);
			}
		}
	}

	// C memory freed above with scope(exit)
	return ChunkVBOCompactMesh(verts[0 .. iv], chunk.xPos, chunk.zPos);
}

ChunkVBOCompactMesh buildCompactMeshIndexedFromChunk(Chunk chunk)
{
	auto data = WorkspaceData.malloc();
	cMemoryArray!(ChunkVBOCompactMesh.Vertex) vertices;
	scope(exit) { data.free(); vertices.free(); }

	mixin BlockDispatcher!(CompactMeshPackerIndexed);

	data.copyFromChunk(chunk);

	verts = vertices.realloc(128 * 1024);
	xOff = chunk.xOff << VERTEX_SIZE_BIT_SHIFT;
	yOff = chunk.yOff << VERTEX_SIZE_BIT_SHIFT;
	zOff = chunk.zOff << VERTEX_SIZE_BIT_SHIFT;

	for (int x; x < 16; x++) {
		for (int y; y < 128; y++) {
			for (int z; z < 16; z++) {
				b(x, y, z);
			}
		}
	}

	// C memory freed above with scope(exit)
	return ChunkVBOCompactMesh(verts[0 .. iv], chunk.xPos, chunk.zPos);
}

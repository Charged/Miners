// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.terrain.builder;

import charge.charge;

import minecraft.gfx.vbo;

import minecraft.terrain.vol;
import minecraft.terrain.data;
import minecraft.terrain.chunk;
import minecraft.terrain.workspace;


/**
 * Should the packer manipulate the coords in any way.
 */
enum uvManip {
	NONE,
	HALF_V,
}

/**
 * Which corner of the uv map is this vertex in.
 */
enum uvCorner {
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_RIGHT
};

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
		  sideNormal normal, ubyte uv_off, int manip)
	{
		float u = (texture % 16 + uv_off % 2) / 16.0f;
		float v = (texture / 16 + uv_off / 2) / 16.0f;

		int nx = normalTable[normal*3+0];
		int ny = normalTable[normal*3+1];
		int nz = normalTable[normal*3+2];

		mixin PositionCalculator!();

		if (manip == uvManip.HALF_V & (uv_off >> 1))
			v -= (1 / 16.0f) / 2;

		mb.vert(xF, yF, zF, u, v, nx, ny, nz);
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
		  sideNormal normal, ubyte uv_off, int manip)
	{
		ubyte u = (texture % 16 + uv_off % 2);
		ubyte v = (texture / 16 + uv_off / 2);

		mixin PositionCalculator!();

		verts[iv].position[0] = xF;
		verts[iv].position[1] = yF;
		verts[iv].position[2] = zF;
		verts[iv].texture_u_or_index = u;
		verts[iv].texture_v_or_pad = v;
		verts[iv].normal = normal;
		verts[iv].light = light;
		verts[iv].texture_u_offset = 0;
		verts[iv].texture_v_offset =
			cast(ubyte)(uv_off & 2 && manip == uvManip.HALF_V ? -8 : 0);
		verts[iv].torch_light = 0;
		verts[iv].sun_light = 0;
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

	void pack(int x, int y, int z, ubyte texture, ubyte light, ubyte normal, ubyte uv_off, int manip)
	{
		mixin PositionCalculator!();

		verts[iv].position[0] = xF;
		verts[iv].position[1] = yF;
		verts[iv].position[2] = zF;
		verts[iv].texture_u_or_index = texture;
		verts[iv].texture_v_or_pad = 0;
		verts[iv].normal = normal;
		verts[iv].light = light;
		verts[iv].texture_u_offset = 0;
		verts[iv].texture_v_offset =
			cast(ubyte)(manip == uvManip.HALF_V ? 8 : 0);
		verts[iv].torch_light = 0;
		verts[iv].sun_light = 0;
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
		pack(x1, y, z1, texture, aoTL, normal, uvCorner.TOP_LEFT, uvManip.NONE);
		pack(x1, y, z2, texture, aoBL, normal, uvCorner.BOTTOM_LEFT, uvManip.NONE);
		pack(x2, y, z2, texture, aoBR, normal, uvCorner.BOTTOM_RIGHT, uvManip.NONE);
		pack(x2, y, z1, texture, aoTR, normal, uvCorner.TOP_RIGHT, uvManip.NONE);
	}

	void emitQuadAOYN(int x1, int x2, int y, int z1, int z2,
			  ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
			  ubyte texture, sideNormal normal)
	{
		pack(x1, y, z1, texture, aoTL, normal, uvCorner.TOP_LEFT, uvManip.NONE);
		pack(x2, y, z1, texture, aoTR, normal, uvCorner.TOP_RIGHT, uvManip.NONE);
		pack(x2, y, z2, texture, aoBR, normal, uvCorner.BOTTOM_RIGHT, uvManip.NONE);
		pack(x1, y, z2, texture, aoBL, normal, uvCorner.BOTTOM_LEFT, uvManip.NONE);
	}

	void emitQuadAOXZP(int x1, int x2, int y1, int y2, int z1, int z2,
			   ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
			   ubyte texture, sideNormal normal)
	{
		pack(x2, y1, z1, texture, aoBR, normal, uvCorner.BOTTOM_RIGHT, uvManip.NONE);
		pack(x2, y2, z1, texture, aoTR, normal, uvCorner.TOP_RIGHT, uvManip.NONE);
		pack(x1, y2, z2, texture, aoTL, normal, uvCorner.TOP_LEFT, uvManip.NONE);
		pack(x1, y1, z2, texture, aoBL, normal, uvCorner.BOTTOM_LEFT, uvManip.NONE);
	}

	void emitQuadAOXZN(int x1, int x2, int y1, int y2, int z1, int z2,
			   ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
			   ubyte texture, sideNormal normal)
	{
		pack(x1, y1, z2, texture, aoBR, normal, uvCorner.BOTTOM_RIGHT, uvManip.NONE);
		pack(x1, y2, z2, texture, aoTR, normal, uvCorner.TOP_RIGHT, uvManip.NONE);
		pack(x2, y2, z1, texture, aoTL, normal, uvCorner.TOP_LEFT, uvManip.NONE);
		pack(x2, y1, z1, texture, aoBL, normal, uvCorner.BOTTOM_LEFT, uvManip.NONE);
	}

	void emitHalfQuadAOXZP(int x1, int x2, int y1, int y2, int z1, int z2,
			       ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
			       ubyte texture, sideNormal normal)
	{
		pack(x2, y1, z1, texture, aoBR, normal, uvCorner.BOTTOM_RIGHT, uvManip.HALF_V);
		pack(x2, y2, z1, texture, aoTR, normal, uvCorner.TOP_RIGHT, uvManip.HALF_V);
		pack(x1, y2, z2, texture, aoTL, normal, uvCorner.TOP_LEFT, uvManip.HALF_V);
		pack(x1, y1, z2, texture, aoBL, normal, uvCorner.BOTTOM_LEFT, uvManip.HALF_V);
	}

	void emitHalfQuadAOXZM(int x1, int x2, int y1, int y2, int z1, int z2,
			       ubyte aoBL, ubyte aoBR, ubyte aoTL, ubyte aoTR,
			       ubyte texture, sideNormal normal)
	{
		pack(x1, y1, z2, texture, aoBR, normal, uvCorner.BOTTOM_RIGHT, uvManip.HALF_V);
		pack(x1, y2, z2, texture, aoTR, normal, uvCorner.TOP_RIGHT, uvManip.HALF_V);
		pack(x2, y2, z1, texture, aoTL, normal, uvCorner.TOP_LEFT, uvManip.HALF_V);
		pack(x2, y1, z1, texture, aoBL, normal, uvCorner.BOTTOM_LEFT, uvManip.HALF_V);
	}

	void emitQuadYP(int x1, int x2, int y, int z1, int z2,
			ubyte tex, sideNormal normal)
	{
		emitQuadAOYP(x1, x2, y, z1, z2, 0, 0, 0, 0, tex, normal);
	}

	void emitQuadYN(int x1, int x2, int y, int z1, int z2,
			ubyte tex, sideNormal normal)
	{
		emitQuadAOYN(x1, x2, y, z1, z2, 0, 0, 0, 0, tex, normal);
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

	void emitDiagonalQuads(int x1, int x2, int y1, int y2, int z1, int z2, ubyte tex)
	{
		emitQuadAOXZN(x1, x2, y1, y2, z1, z2, 0, 0, 0, 0, tex, sideNormal.XNZN);
		emitQuadAOXZP(x1, x2, y1, y2, z1, z2, 0, 0, 0, 0, tex, sideNormal.XPZP);

		// We flip the z values to get the other two set of coords.
		emitQuadAOXZP(x1, x2, y1, y2, z2, z1, 0, 0, 0, 0, tex, sideNormal.XNZP);
		emitQuadAOXZN(x1, x2, y1, y2, z2, z1, 0, 0, 0, 0, tex, sideNormal.XPZN);
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

	void flower(ubyte type, int x, int y, int z) {
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

		/* all set */
		if (set == 0)
			return;

		if (type == 44)
			makeHalfXYZ(dec, x, y, z, set);
		else
			makeXYZ(dec, x, y, z, set);
	}

	void torch(int x, int y, int z) {
		auto dec = &tile[50];
		ubyte tex = calcTextureXZ(dec);
		auto d = data.getDataUnsafe(x, y, z);

		// TODO Support other directions
		if (d != 5)
			return;

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x <<= shift;
		y <<= shift;
		z <<= shift;

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

		makeHalfXYZ(dec, x, y, z, set);

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x <<= shift;
		y <<= shift;
		z <<= shift;

		int x1 = [x+8,  x,    x,    x   ][d];
		int x2 = [x+16, x+8,  x+16, x+16][d];
		int y1 = y+8;
		int y2 = y+16;
		int z1 = [z,    z,    z+8,  z   ][d];
		int z2 = [z+16, z+16, z+16, z+8 ][d];

		if (set & sideMask.ZN)
			emitQuadXZN(x1, x2, y1, y2, z1, z1, tex, sideNormal.ZN);
		if (set & sideMask.ZP)
			emitQuadXZP(x1, x2, y1, y2, z2, z2, tex, sideNormal.ZP);
		if (set & sideMask.XN)
			emitQuadXZN(x1, x1, y1, y2, z1, z2, tex, sideNormal.XN);
		if (set & sideMask.XP)
			emitQuadXZP(x2, x2, y1, y2, z1, z2, tex, sideNormal.XP);
		if (set & sideMask.YP)
			emitQuadYP(x1, x2, y2, z1, z2, tex, sideNormal.YP);
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

		if (set & sideMask.ZN)
			emitQuadXZN(x1, x2, y1, y2, z1, z1, tex, sideNormal.ZN);
		if (set & sideMask.ZP)
			emitQuadXZP(x1, x2, y1, y2, z2, z2, tex, sideNormal.ZP);
		if (set & sideMask.XN)
			emitQuadXZN(x1, x1, y1, y2, z1, z2, tex, sideNormal.XN);
		if (set & sideMask.XP)
			emitQuadXZP(x2, x2, y1, y2, z1, z2, tex, sideNormal.XP);
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

	void snow(int x, int y, int z) {
		// Make snow into full block for now
		solid(80, x, y, z);
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
				solid(type, x, y, z);
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
			case 37:
			case 38:
				flower(type, x, y, z);
				break;
			case 43:
			case 44:
				slab(type, x, y, z);
				break;
			case 50:
				torch(x, y, z);
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
			case 78:
				snow(x, y, z);
				break;
			case 86:
				pumpkin(x, y, z);
				break;
			case 91:
				jack_o_lantern(x, y, z);
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

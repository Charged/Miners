// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.terrain.builder;

import minecraft.gfx.vbo;

import minecraft.terrain.vol;
import minecraft.terrain.data;
import minecraft.terrain.chunk;

import charge.charge;

struct WorkspaceData
{
	/**
	 * Allocate a workspace from the C heap.
	 */
	static WorkspaceData* malloc()
	{
		return cast(WorkspaceData*)
			std.c.stdlib.malloc(WorkspaceData.sizeof);
	}

	/**
	 * Free a workspace that was allocted from the C heap.
	 */
	void free()
	{
		std.c.stdlib.free(cast(void*)this);
	}

	/*
	 * We copy the data so we can use unsafe accessor functionswhen building
	 * mesh geometry data.
	 */
	const int ws_width = 16+2;
	const int ws_height = 128+2;
	const int ws_depth = 16+2;

	const int ws_data_width = 16+2;
	const int ws_data_height = 128/2+2;
	const int ws_data_depth = 16+2;

	ubyte blocks[ws_width][ws_depth][ws_height];
	ubyte data[ws_data_width][ws_data_depth][ws_data_height];

	ubyte opIndex(int x, int y, int z)
	{
		return blocks[x+1][z+1][y+1];
	}

	ubyte opIndexAssign(ubyte value, int x, int y, int z)
	{
		return blocks[x+1][z+1][y+1] = value;
	}

	ubyte get(int x, int y, int z)
	{
		return (*this)[x, y, z];
	}

	ubyte getDataUnsafe(int x, int y, int z)
	{
		ubyte d = data[x+1][z+1][y/2+1];
		if (y % 2 == 0)
			return d & 0xf;
		return cast(ubyte)(d >> 4);
	}
	
	bool filled(int x, int y, int z)
	{
		auto t = (*this)[x, y, z];
		return tile[t].filled != 0;
	}

	bool filledOrType(ubyte type, int x, int y, int z)
	{
		auto t = (*this)[x, y, z];
		return tile[t].filled != 0 || t == type;
	}

	int getSolidSet(int x, int y, int z)
	{
		auto xmc = !filled(x-1,   y,   z);
		auto xpc = !filled(x+1,   y,   z);
		auto ymc = !filled(  x, y-1,   z);
		auto ypc = !filled(  x, y+1,   z);
		auto zmc = !filled(  x,   y, z-1);
		auto zpc = !filled(  x,   y, z+1);
		return xmc << 0 | xpc << 1 | ymc << 2 | ypc << 3 | zmc << 4 | zpc << 5;
	}

	int getSolidOrTypeSet(ubyte type, int x, int y, int z)
	{
		auto xmc = !filledOrType(type, x-1,   y,   z);
		auto xpc = !filledOrType(type, x+1,   y,   z);
		auto ymc = !filledOrType(type,   x, y-1,   z);
		auto ypc = !filledOrType(type,   x, y+1,   z);
		auto zmc = !filledOrType(type,   x,   y, z-1);
		auto zpc = !filledOrType(type,   x,   y, z+1);
		return xmc << 0 | xpc << 1 | ymc << 2 | ypc << 3 | zmc << 4 | zpc << 5;
	}

	void copyFromChunk(Chunk chunk)
	{
		for (int x; x < ws_width; x++) {
			for (int z; z < ws_depth; z++) {
				ubyte *ptr = chunk.getPointerY(x-1, z-1);
				blocks[x][z][0] = ptr[0];
				blocks[x][z][1 .. ws_height+1-2] = ptr[0 .. ws_height-2];
				blocks[x][z][length-1] = 0;

				ptr = chunk.getDataPointerY(x-1, z-1);
				data[x][z][0] = cast(ubyte)(ptr[0] << 4);
				data[x][z][1 .. ws_data_height+1-2] = ptr[0 .. ws_data_height-2];
				data[x][z][length-1] = 0;
			}
		}
	}
}

/*
 * Used to convert a chunk block coord into a int and back to a float.
 *
 * That is the builder uses fix precision floating point.
 */
const VERTEX_SIZE_BIT_SHIFT = 4;
const VERTEX_SIZE_DIVISOR = 16;


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
 */
ubyte calcAmbient(bool side1, bool side2, bool corner)
{
	return cast(ubyte)((side1 & side2) + (side1 | side2 | corner));
}

/**
 * Convinience template to delcare and calculate all corners.
 */
template AOCalculator()
{
	auto ao235 = calcAmbient(c2, c5, c3);
	auto ao578 = calcAmbient(c5, c7, c8);
	auto ao467 = calcAmbient(c4, c7, c6);
	auto ao124 = calcAmbient(c2, c4, c1);
}

/**
 * Scans and returns filled status of corner blockes, used for fake AO.
 *
 * Reads x, aoy, z for position.
 * Declares and set c[1-8].
 */
template AOScannerY()
{
	auto c1 = data.filled(x-1, aoy, z-1);
	auto c2 = data.filled(x  , aoy, z-1);
	auto c3 = data.filled(x+1, aoy, z-1);
	auto c4 = data.filled(x-1, aoy, z  );
	auto c5 = data.filled(x+1, aoy, z  );
	auto c6 = data.filled(x-1, aoy, z+1);
	auto c7 = data.filled(x  , aoy, z+1);
	auto c8 = data.filled(x+1, aoy, z+1);
}

/**
 * Scans and returns filled status of corner blockes, used for fake AO.
 *
 * Reads xsn, xs, xsp, y, zsn, zs, xsp for position.
 * Declares and set c[1-8].
 */
template AOScannerXZ()
{
	auto c1 = data.filled(xsn, y-1, zsn);
	auto c2 = data.filled(xs , y-1, zs );
	auto c3 = data.filled(xsp, y-1, zsp);
	auto c4 = data.filled(xsn, y  , zsn);
	auto c5 = data.filled(xsp, y  , zsp);
	auto c6 = data.filled(xsn, y+1, zsn);
	auto c7 = data.filled(xs , y+1, zs );
	auto c8 = data.filled(xsp, y+1, zsp);
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

	void pack(int x, int y, int z, ubyte texture, ubyte light, ubyte normal, ubyte uv_off, bool half)
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

	void pack(int x, int y, int z, ubyte texture, ubyte light, ubyte normal, ubyte uv_off, bool half)
	{
		float u = (texture % 16 + uv_off % 16) / 16.0f;
		float v = (texture / 16 + uv_off / 16) / 16.0f;
		int minus = normal & 1;
		int nx = (normal&2)>>1;
		int nz = (normal&4)>>2;
		int ny = !nx & !nz;
		nx = (nx & !minus) -(nx & minus);
		ny = (ny & !minus) -(ny & minus);
		nz = (nz & !minus) -(nz & minus);

		mixin PositionCalculator!();

		if (half & (uv_off >> 4))
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

	void pack(int x, int y, int z, ubyte texture, ubyte light, ubyte normal, ubyte uv_off, bool half)
	{
		ubyte u = (texture % 16 + uv_off % 16);
		ubyte v = (texture / 16 + uv_off / 16);

		mixin PositionCalculator!();

		verts[iv].position[0] = xF;
		verts[iv].position[1] = yF;
		verts[iv].position[2] = zF;
		verts[iv].normal = normal;
		verts[iv].light = light;
		verts[iv].texture_u_or_index = u;
		verts[iv].texture_v_or_offset = v;
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

	void pack(int x, int y, int z, ubyte texture, ubyte light, ubyte normal, ubyte uv_off, bool half)
	{
		mixin PositionCalculator!();

		verts[iv].position[0] = xF;
		verts[iv].position[1] = yF;
		verts[iv].position[2] = zF;
		verts[iv].normal = normal;
		verts[iv].light = light;
		verts[iv].texture_u_or_index = texture;
		verts[iv].texture_v_or_offset = half;
		iv++;
	}
}

/**
 * Helper functions for emiting quads to a packer.
 */
template QuadEmitter(alias T)
{
	mixin T!();

	void makeQuadAOYP(int x1, int x2, int y, int z1, int z2,
			  ubyte c1, ubyte c2, ubyte c3, ubyte c4,
			  ubyte texture, ubyte normal)
	{
		pack(x1, y, z1, texture, c1/*ao124*/, normal,  0, false);
		pack(x1, y, z2, texture, c2/*ao467*/, normal, 16, false);
		pack(x2, y, z2, texture, c3/*ao578*/, normal, 17, false);
		pack(x2, y, z1, texture, c4/*ao235*/, normal,  1, false);
	}

	void makeQuadAOYN(int x1, int x2, int y, int z1, int z2,
			  ubyte c1, ubyte c2, ubyte c3, ubyte c4,
			  ubyte texture, ubyte normal)
	{
		pack(x1, y, z1, texture, c1/*ao124*/, normal,  0, false);
		pack(x2, y, z1, texture, c2/*ao235*/, normal,  1, false);
		pack(x2, y, z2, texture, c3/*ao578*/, normal, 17, false);
		pack(x1, y, z2, texture, c4/*ao467*/, normal, 16, false);
	}

	void makeQuadAOXZP(int x1, int x2, int y1, int y2, int z1, int z2,
			   ubyte c1, ubyte c2, ubyte c3, ubyte c4,
			   ubyte texture, ubyte normal)
	{
		pack(x2, y1, z1, texture, c1/*ao124*/, normal, 17, false);
		pack(x2, y2, z1, texture, c2/*ao467*/, normal,  1, false);
		pack(x1, y2, z2, texture, c3/*ao578*/, normal,  0, false);
		pack(x1, y1, z2, texture, c4/*ao235*/, normal, 16, false);
	}

	void makeQuadAOXZN(int x1, int x2, int y1, int y2, int z1, int z2,
			   ubyte c1, ubyte c2, ubyte c3, ubyte c4,
			   ubyte texture, ubyte normal)
	{
		pack(x1, y1, z2, texture, c1/*ao235*/, normal, 17, false);
		pack(x1, y2, z2, texture, c2/*ao578*/, normal,  1, false);
		pack(x2, y2, z1, texture, c3/*ao467*/, normal,  0, false);
		pack(x2, y1, z1, texture, c4/*ao124*/, normal, 16, false);
	}

	void makeHalfQuadAOXZP(int x1, int x2, int y1, int y2, int z1, int z2,
			   ubyte c1, ubyte c2, ubyte c3, ubyte c4,
			   ubyte texture, ubyte normal)
	{
		pack(x2, y1, z1, texture, c1/*ao124*/, normal, 17, true);
		pack(x2, y2, z1, texture, c2/*ao467*/, normal,  1, true);
		pack(x1, y2, z2, texture, c3/*ao578*/, normal,  0, true);
		pack(x1, y1, z2, texture, c4/*ao235*/, normal, 16, true);
	}

	void makeHalfQuadAOXZN(int x1, int x2, int y1, int y2, int z1, int z2,
			   ubyte c1, ubyte c2, ubyte c3, ubyte c4,
			   ubyte texture, ubyte normal)
	{
		pack(x1, y1, z2, texture, c1/*ao235*/, normal, 17, true);
		pack(x1, y2, z2, texture, c2/*ao578*/, normal,  1, true);
		pack(x2, y2, z1, texture, c3/*ao467*/, normal,  0, true);
		pack(x2, y1, z1, texture, c4/*ao124*/, normal, 16, true);
	}

	void makeQuadYP(int x1, int x2, int y, int z1, int z2, ubyte tex, ubyte normal)
	{
		makeQuadAOYP(x1, x2, y, z1, z2, 0, 0, 0, 0, tex, normal);
	}

	void makeQuadYN(int x1, int x2, int y, int z1, int z2, ubyte tex, ubyte normal)
	{
		makeQuadAOYN(x1, x2, y, z1, z2, 0, 0, 0, 0, tex, normal);
	}

	void makeQuadXZP(int x1, int x2, int y1, int y2, int z1, int z2,
			 ubyte tex, ubyte normal)
	{
		makeQuadAOXZP(x1, x2, y1, y2, z1, z2, 0, 0, 0, 0, tex, normal);
	}

	void makeQuadXZN(int x1, int x2, int y1, int y2, int z1, int z2,
			 ubyte tex, ubyte normal)
	{
		makeQuadAOXZN(x1, x2, y1, y2, z1, z2, 0, 0, 0, 0, tex, normal);
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

	void makeY(BlockDescriptor *dec, uint x, uint y, uint z, bool minus)
	{
		auto aoy = y - minus + !minus;
		mixin AOScannerY!();
		mixin AOCalculator!();

		int x1 = x, x2 = x+1;
		int z1 = z, z2 = z+1;
		y += !minus;

		ubyte normal = minus;
		ubyte texture = calcTextureY(dec);

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x1 <<= shift;
		x2 <<= shift;
		y  <<= shift;
		z1 <<= shift;
		z2 <<= shift;

		if (minus) {
			makeQuadAOYN(x1, x2, y, z1, z2,
				     ao124, ao235, ao578, ao467,
				     texture, normal);
		} else {
			makeQuadAOYP(x1, x2, y, z1, z2,
				     ao124, ao467, ao578, ao235,
				     texture, normal);
		}
	}

	void makeXZ(BlockDescriptor *dec, uint x, uint y, uint z, bool minus, bool xaxis)
	{
		bool xm = !minus & xaxis;
		bool zm = !minus & !xaxis;
		int xs = xaxis ? x - minus + !minus : x;
		int xsn = xs + !xaxis;
		int xsp = xs - !xaxis;
		int zs = !xaxis ? z - minus + !minus : z;
		int zsp = zs + xaxis;
		int zsn = zs - xaxis;
		mixin AOScannerXZ!();
		mixin AOCalculator!();

		int x1 = x+xm, x2 = x+xm+!xaxis;
		int y1 = y   , y2 = y+1;
		int z1 = z+zm, z2 = z+zm+xaxis;

		ubyte normal = cast(ubyte)((xaxis ? 2 : 4) | minus);
		ubyte texture = calcTextureXZ(dec);

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x1 <<= shift;
		x2 <<= shift;
		y1 <<= shift;
		y2 <<= shift;
		z1 <<= shift;
		z2 <<= shift;

		if (minus) {
			makeQuadAOXZN(x1, x2, y1, y2, z1, z2,
				      ao235, ao578, ao467, ao124,
				      texture, normal);
		} else {
			makeQuadAOXZP(x1, x2, y1, y2, z1, z2,
				      ao124, ao467, ao578, ao235,
				      texture, normal);
		}
	}

	void makeXYZ(BlockDescriptor *dec, uint x, uint y, uint z, int set)
	{
		if (set & 1)
			makeXZ(dec, x, y, z, true, true);

		if (set & 2)
			makeXZ(dec, x, y, z, false, true);

		if (set & 4)
			makeY(dec, x, y, z, true);

		if (set & 8)
			makeY(dec, x, y, z, false);

		if (set & 16)
			makeXZ(dec, x, y, z, true, false);

		if (set & 32)
			makeXZ(dec, x, y, z, false, false);
	}

	void makeHalfY(BlockDescriptor *dec, uint x, uint y, uint z)
	{
		auto aoy = y;
		mixin AOScannerY!();
		mixin AOCalculator!();

		int x1 = x, x2 = x+1;
		int z1 = z, z2 = z+1;

		ubyte texture = calcTextureY(dec);

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x1 <<= shift;
		x2 <<= shift;
		z1 <<= shift;
		z2 <<= shift;

		y <<= shift;
		y += VERTEX_SIZE_DIVISOR / 2;

		makeQuadAOYP(x1, x2, y, z1, z2,
			     ao124, ao467, ao578, ao235,
			     texture, 0);
	}

	void makeHalfXZ(BlockDescriptor *dec, uint x, uint y, uint z, bool minus, bool xaxis)
	{
		bool xm = !minus & xaxis;
		bool zm = !minus & !xaxis;
		int xs = xaxis ? x - minus + !minus : x;
		int xsn = xs + !xaxis;
		int xsp = xs - !xaxis;
		int zs = !xaxis ? z - minus + !minus : z;
		int zsp = zs + xaxis;
		int zsn = zs - xaxis;

		auto c1 = data.filled(xsn, y-1, zsn);
		auto c2 = data.filled(xs , y-1, zs );
		auto c3 = data.filled(xsp, y-1, zsp);
		auto c4 = data.filled(xsn, y  , zsn);
		auto c5 = data.filled(xsp, y  , zsp);
		auto c6 = false;
		auto c7 = false;
		auto c8 = false;

		mixin AOCalculator!();

		int x1 = x+xm, x2 = x+xm+!xaxis;
		int y1 = y   , y2;
		int z1 = z+zm, z2 = z+zm+xaxis;

		ubyte normal = cast(ubyte)((xaxis ? 2 : 4) | minus);
		ubyte texture = calcTextureXZ(dec);

		const shift = VERTEX_SIZE_BIT_SHIFT;
		x1 <<= shift;
		x2 <<= shift;
		y1 <<= shift;
		y2 = y1 + VERTEX_SIZE_DIVISOR / 2;
		z1 <<= shift;
		z2 <<= shift;

		if (minus) {
			makeHalfQuadAOXZN(x1, x2, y1, y2, z1, z2,
					 ao235, ao578, ao467, ao124,
					 texture, normal);
		} else {
			makeHalfQuadAOXZP(x1, x2, y1, y2, z1, z2,
					  ao124, ao467, ao578, ao235,
					  texture, normal);
		}
	}

	void makeHalfXYZ(BlockDescriptor *dec, uint x, uint y, uint z, int set)
	{
		if (set & 1)
			makeHalfXZ(dec, x, y, z, true, true);

		if (set & 2)
			makeHalfXZ(dec, x, y, z, false, true);

		if (set & 4)
			makeY(dec, x, y, z, true);

		if (set & 8)
			makeHalfY(dec, x, y, z);

		if (set & 16)
			makeHalfXZ(dec, x, y, z, true, false);

		if (set & 32)
			makeHalfXZ(dec, x, y, z, false, false);
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

	void wool(int x, int y, int z) {
		auto dec = &woolTile[data.getDataUnsafe(x, y, z)];
		solidDec(dec, x, y, z);
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

		makeQuadXZP(x1, x2, y1, y2, z1, z1, tex, 4);
		makeQuadXZN(x1, x2, y1, y2, z2, z2, tex, 5);

		x1 = x+9; x2 = x+7;
		z1 = z;   z2 = z+16;

		makeQuadXZP(x1, x1, y1, y2, z1, z2, tex, 2);
		makeQuadXZN(x2, x2, y1, y2, z1, z2, tex, 3);
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
		int z1 = z+12, z2 = z+4;

		makeQuadXZP(x1, x2, y1, y2, z1, z1, tex, 4);
		makeQuadXZN(x1, x2, y1, y2, z1, z1, tex, 5);
		makeQuadXZP(x1, x2, y1, y2, z2, z2, tex, 4);
		makeQuadXZN(x1, x2, y1, y2, z2, z2, tex, 5);

		x1 = x+12; x2 = x+4;
		z1 = z;    z2 = z+16;

		makeQuadXZP(x1, x1, y1, y2, z1, z2, tex, 2);
		makeQuadXZN(x1, x1, y1, y2, z1, z2, tex, 3);
		makeQuadXZP(x2, x2, y1, y2, z1, z2, tex, 2);
		makeQuadXZN(x2, x2, y1, y2, z1, z2, tex, 3);
	}

	void farmland(int x, int y, int z) {
		auto d = data.getDataUnsafe(x, y, z);
		if (d > 0)
			d = 1;
		auto dec = &farmlandTile[d];
		solidDec(dec, x, y, z);
	}

	void snow(int x, int y, int z) {
		// Make snow into full block for now
		solid(80, x, y, z);
	}

	void b(uint x, uint y, uint z) {
		static int count = 0;
		ubyte type = data.get(x, y, z);

		switch(type) {
			case 2:
				grass(x, y, z);
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
			case 35:
				wool(x, y, z);
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
			case 78:
				snow(x, y, z);
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




/*****************************************************************************
 * Code for Array textures.
 *
 */

template QuadBuilderNonShifted(alias T)
{
	mixin QuadEmitter!(T);

	void makeY(BlockDescriptor *dec, uint x, uint y, uint z, bool minus)
	{
		auto aoy = y - minus + !minus;

		mixin AOScannerY!();
		mixin AOCalculator!();

		int x1 = x, x2 = x+1;
		int z1 = z, z2 = z+1;
		y += !minus;

		ubyte normal = minus;
		ubyte texture = calcTextureY(dec);

		if (minus) {
			makeQuadAOYN(x1, x2, y, z1, z2,
				     ao124, ao235, ao578, ao467,
				     texture, normal);
		} else {
			makeQuadAOYP(x1, x2, y, z1, z2,
				     ao124, ao467, ao578, ao235,
				     texture, normal);
		}
	}

	void makeXZ(BlockDescriptor *dec, uint x, uint y, uint z, bool minus, bool xaxis)
	{
		bool xm = !minus & xaxis;
		bool zm = !minus & !xaxis;
		int xs = xaxis ? x - minus + !minus : x;
		int xsn = xs + !xaxis;
		int xsp = xs - !xaxis;
		int zs = !xaxis ? z - minus + !minus : z;
		int zsp = zs + xaxis;
		int zsn = zs - xaxis;

		mixin AOScannerXZ!();
		mixin AOCalculator!();

		int x1 = x+xm, x2 = x+xm+!xaxis;
		int y1 = y   , y2 = y+1;
		int z1 = z+zm, z2 = z+zm+xaxis;

		ubyte normal = cast(ubyte)((xaxis ? 2 : 4) | minus);
		ubyte texture = calcTextureXZ(dec);

		if (minus) {
			makeQuadAOXZN(x1, x2, y1, y2, z1, z2,
				      ao235, ao578, ao467, ao124,
				      texture, normal);
		} else {
			makeQuadAOXZP(x1, x2, y1, y2, z1, z2,
				      ao124, ao467, ao578, ao235,
				      texture, normal);
		}
	}

	void makeXYZ(BlockDescriptor *dec, uint x, uint y, uint z, int set)
	{
		if (set & 1)
			makeXZ(dec, x, y, z, true, true);

		if (set & 2)
			makeXZ(dec, x, y, z, false, true);

		if (set & 4)
			makeY(dec, x, y, z, true);

		if (set & 8)
			makeY(dec, x, y, z, false);

		if (set & 16)
			makeXZ(dec, x, y, z, true, false);

		if (set & 32)
			makeXZ(dec, x, y, z, false, false);
	}
}

/*
 * The merging of quads could possible be done for all type of quads this,
 * however this led to artifacts as between the seams of areas. Not a big
 * deal for leafs tho.
 */
struct LeafBuilder
{
	WorkspaceData *data;
	mixin QuadEmitter!(ArrayPacker);
	int saved;

	static char[] checkString(char[] add)
	{
		return
			"ubyte type = data.get(x, y, z);"
			"" ~ add ~ ";"
			"ubyte type2 = data.get(x, y, z);"
			"auto ret = type == 18 && (type2 == 18 || !tile[type2].filled);"
			"return ret;";
	}

	bool checkXP(int x, int y, int z) { mixin(checkString("x++")); }
	bool checkXN(int x, int y, int z) { mixin(checkString("x--")); }
	bool checkYP(int x, int y, int z) { mixin(checkString("y++")); }
	bool checkYN(int x, int y, int z) { mixin(checkString("y--")); }
	bool checkZP(int x, int y, int z) { mixin(checkString("z++")); }
	bool checkZN(int x, int y, int z) { mixin(checkString("z--")); }

	template checkTmpl(alias walkAxis)
	{
		int gobble()
		{
			ubyte type2;
			walkAxis++;
			for (;walkAxis < 16; walkAxis++) {
				if (!check(x, y, z))
					return walkAxis;
			}
			return walkAxis;
		}

		int find()
		{
			for (;walkAxis < 16; walkAxis++)
				if (check(x, y, z))
					return walkAxis;
			return walkAxis;
		}
	}

	void makeXRowN(int x, int y, ubyte normal, bool minus)
	{
		ubyte type = 18;
		auto dec = &tile[type];
		int z, z1, z2;
		auto check = minus ? &checkXN : &checkXP;
		ubyte texture = calcTextureXZ(dec);

		mixin checkTmpl!(z);

		z1 = find();
		for (; z1 < 16;) {
			z2 = gobble();

			if (minus)
				makeQuadXZN(  x,   x, y, y+1, z1, z2, texture, normal);
			else
				makeQuadXZP(x+1, x+1, y, y+1, z1, z2, texture, normal);

			saved += (z2 - 1 - z1) * 4;

			z1 = find();
		}
	}

	void makeYRowN(int y, int z, ubyte normal, bool minus)
	{
		ubyte type = 18;
		auto dec = &tile[type];
		int x, x1, x2;
		auto check = minus ? &checkYN : &checkYP;
		ubyte texture = calcTextureY(dec);

		mixin checkTmpl!(x);

		x1 = find();
		for (; x1 < 16;) {
			x2 = gobble();

			if (minus)
				makeQuadYN(x1, x2, y  , z, z+1, texture, normal);
			else
				makeQuadYP(x1, x2, y+1, z, z+1, texture, normal);

			saved += (x2 - 1 - x1) * 4;

			x1 = find();
		}
	}

	void makeZRowN(int y, int z, ubyte normal, bool minus)
	{
		ubyte type = 18;
		auto dec = &tile[type];
		int x, x1, x2;
		auto check = minus ? &checkZN : &checkZP;
		ubyte texture = calcTextureXZ(dec);

		mixin checkTmpl!(x);

		x1 = find();
		for (; x1 < 16;) {
			x2 = gobble();

			if (minus)
				makeQuadXZN(x1, x2, y, y+1, z, z, texture, normal);
			else
				makeQuadXZP(x1, x2, y, y+1, z+1, z+1, texture, normal);

			saved += (x2 - 1 - x1) * 4;

			x1 = find();
		}
	}

	void makeXRow(int y, int z)
	{
		makeXRowN(z, y, 2, false);
		makeXRowN(z, y, 3, true);
		makeYRowN(y, z, 0, false);
		makeYRowN(y, z, 1, true);
		makeZRowN(y, z, 4, false);
		makeZRowN(y, z, 5, true);
	}

	void build()
	{
		for (int y; y < 128; y++) {
			for (int z; z < 16; z++) {
				makeXRow(y, z);
			}
		}
	}
}

ChunkVBOArray buildArrayFromChunk(Chunk chunk)
{
	auto data = WorkspaceData.malloc();
	cMemoryArray!(int) vertices;
	scope(exit) { data.free(); vertices.free(); }

	mixin QuadBuilderNonShifted!(ArrayPacker) bldr;
	LeafBuilder lbldr;

	data.copyFromChunk(chunk);

	verts = vertices.realloc(128*1024);

	lbldr.data = data;
	lbldr.verts = verts;
	lbldr.build();

	num = lbldr.num;

	void solidDec(BlockDescriptor *dec, uint x, uint y, uint z) {
		int set = data.getSolidSet(x, y, z);

		/* all set */
		if (set == 0)
			return;

		bldr.makeXYZ(dec, x, y, z, set);
	}

	void solid(ubyte type, uint x, uint y, uint z) {
		auto dec = &tile[type];
		solidDec(dec, x, y, z);
	}

	void glass(uint x, uint y, uint z) {
		const type = 20;
		auto dec = &tile[type];
		int set = data.getSolidOrTypeSet(type, x, y, z);

		/* all set */
		if (set == 0)
			return;

		bldr.makeXYZ(dec, x, y, z, set);
	}

	void grass(int x, int y, int z) {
		if (data.get(x, y + 1, z) == 78 /* snow */)
			solid(78, x, y, z);
		else
			solid(2 /* grass */, x, y, z);
	}

	void snow(int x, int y, int z) {
		// Make snow into full block for now
		solid(80, x, y, z);
	}

	void wood(int x, int y, int z) {
		auto dec = &woodTile[data.getDataUnsafe(x, y, z)];
		solidDec(dec, x, y, z);
	}

	void wool(int x, int y, int z) {
		auto dec = &woolTile[data.getDataUnsafe(x, y, z)];
		solidDec(dec, x, y, z);
	}

	void craftingTable(uint x, uint y, uint z) {
		int set = data.getSolidSet(x, y, z);
		int setAlt = set & (1 << 0 | 1 << 4);
		auto dec = &tile[58];
		auto decAlt = &craftingTableAltTile;

		// Don't emit the same sides
		set &= ~setAlt;

		if (set != 0)
			bldr.makeXYZ(dec, x, y, z, set);

		if (setAlt != 0)
			bldr.makeXYZ(decAlt, x, y, z, setAlt);
	}

	void b(uint x, uint y, uint z) {
		ubyte type = data.get(x, y, z);

		switch(type) {
			case 2:
				grass(x, y, z);
				break;
			case 17:
				wood(x, y, z);
				break;
			// Done by LeafBuilder
			//case 18:
			//	solid(type, x, y, z);
			//	break;
			case 20:
				glass(x, y, z);
				break;
			case 35:
				wool(x, y, z);
				break;
			case 58:
				craftingTable(x, y, z);
				break;
			case 78:
				snow(x, y, z);
				break;
			default:
				if (tile[type].filled)
					solid(type, x, y, z);
		}
	}

	for (int x; x < 16; x++) {
		for (int y; y < 128; y++) {
			for (int z; z < 16; z++) {
				b(x, y, z);
			}
		}
	}

	// C memory freed above with scope(exit)
	return ChunkVBOArray(verts[0 .. num], chunk.xPos, chunk.zPos);
}

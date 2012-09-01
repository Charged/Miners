// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.builder.classic;

import miners.defines;

import miners.builder.emit;
import miners.builder.quad;
import miners.builder.types;
import miners.builder.helpers;
import miners.builder.builder;
import miners.builder.workspace;


/*
 *
 * MeshBuilder
 *
 */


class ClassicMeshBuilder : MeshBuilderBuildArray
{
	this()
	{
		super(.buildArray.ptr, .tile.ptr);
	}
}


/*
 *
 * Data
 *
 */


private alias BuildBlockDescriptor.toTex toTex;


BuildBlockDescriptor tile[256] = [
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // air                   // 0
	{  true, toTex(  1,  0 ), toTex(  1,  0 ) }, // stone
	{  true, toTex(  3,  0 ), toTex(  0,  0 ) }, // grass
	{  true, toTex(  2,  0 ), toTex(  2,  0 ) }, // dirt
	{  true, toTex(  0,  1 ), toTex(  0,  1 ) }, // clobb
	{  true, toTex(  4,  0 ), toTex(  4,  0 ) }, // wooden plank
	{ false, toTex( 15,  0 ), toTex( 15,  0 ) }, // sapling
	{  true, toTex(  1,  1 ), toTex(  1,  1 ) }, // bedrock
	{ false, toTex( 14,  0 ), toTex( 14,  0 ) }, // water                 // 8
	{ false, toTex( 14,  0 ), toTex( 14,  0 ) }, // spring water
	{  true, toTex( 14,  1 ), toTex( 14,  1 ) }, // lava
	{  true, toTex( 14,  1 ), toTex( 14,  1 ) }, // spring lava
	{  true, toTex(  2,  1 ), toTex(  2,  1 ) }, // sand
	{  true, toTex(  3,  1 ), toTex(  3,  1 ) }, // gravel
	{  true, toTex(  0,  2 ), toTex(  0,  2 ) }, // gold ore
	{  true, toTex(  1,  2 ), toTex(  1,  2 ) }, // iron ore
	{  true, toTex(  2,  2 ), toTex(  2,  2 ) }, // coal ore              // 16
	{  true, toTex(  4,  1 ), toTex(  5,  1 ) }, // log
	{ false, toTex(  6,  1 ), toTex(  6,  1 ) }, // leaves
	{  true, toTex(  0,  3 ), toTex(  0,  3 ) }, // sponge
	{ false, toTex(  1,  3 ), toTex(  1,  3 ) }, // glass
	{  true, toTex(  0,  4 ), toTex(  0,  4 ) }, // red
	{  true, toTex(  1,  4 ), toTex(  1,  4 ) }, // orange
	{  true, toTex(  2,  4 ), toTex(  2,  4 ) }, // yellow
	{  true, toTex(  3,  4 ), toTex(  3,  4 ) }, // lime green            // 24
	{  true, toTex(  4,  4 ), toTex(  4,  4 ) }, // green
	{  true, toTex(  5,  4 ), toTex(  5,  4 ) }, // aqua green
	{  true, toTex(  6,  4 ), toTex(  6,  4 ) }, // cyan
	{  true, toTex(  7,  4 ), toTex(  7,  4 ) }, // blue
	{  true, toTex(  8,  4 ), toTex(  8,  4 ) }, // purple
	{  true, toTex(  9,  4 ), toTex(  9,  4 ) }, // indigo
	{  true, toTex( 10,  4 ), toTex( 10,  4 ) }, // violet
	{  true, toTex( 11,  4 ), toTex( 11,  4 ) }, // magenta               // 32
	{  true, toTex( 12,  4 ), toTex( 12,  4 ) }, // pink
	{  true, toTex( 13,  4 ), toTex( 13,  4 ) }, // black
	{  true, toTex( 14,  4 ), toTex( 14,  4 ) }, // grey
	{  true, toTex( 15,  4 ), toTex( 15,  4 ) }, // white,
	{ false, toTex( 13,  0 ), toTex( 13,  0 ) }, // yellow flower
	{ false, toTex( 12,  0 ), toTex( 12,  0 ) }, // red rose
	{ false, toTex( 13,  1 ), toTex(  0,  0 ) }, // brown myshroom
	{ false, toTex( 12,  1 ), toTex(  0,  0 ) }, // red mushroom          // 40
	{  true, toTex(  8,  2 ), toTex(  8,  1 ) }, // gold block
	{  true, toTex(  7,  2 ), toTex(  7,  1 ) }, // iron block
	{  true, toTex(  5,  0 ), toTex(  6,  0 ) }, // double slab
	{ false, toTex(  5,  0 ), toTex(  6,  0 ) }, // slab
	{  true, toTex(  7,  0 ), toTex(  7,  0 ) }, // brick block
	{  true, toTex(  8,  0 ), toTex(  9,  0 ) }, // tnt
	{  true, toTex(  3,  2 ), toTex(  4,  0 ) }, // bookshelf
	{  true, toTex(  4,  2 ), toTex(  4,  2 ) }, // moss stone            // 48
	{  true, toTex(  5,  2 ), toTex(  5,  2 ) }, // obsidian
];


/*
 *
 * Builder functions.
 *
 */


void air(Packer *p, int x, int y, int z, ubyte, WorkspaceData *data)
{
	// Nothing just return.
}


void solid(Packer *p, int x, int y, int z, ubyte type, WorkspaceData *data)
{
	auto dec = &tile[type];
	solidDec(p, data, dec, x, y, z);
}


void grass(Packer *p, int x, int y, int z, ubyte, WorkspaceData *data)
{
	int set = data.getSolidSet(x, y, z);
	auto grassDec = &tile[2];
	auto dirtDec = &tile[3];

	makeXYZ(p, data, grassDec, x, y, z, set & ~sideMask.YN);

	if (set & sideMask.YN)
		makeY(p, data, dirtDec, x, y, z, sideNormal.YN);
}


void water(Packer *packerPrev, int x, int y, int z, ubyte, WorkspaceData *data)
{
	auto p = packerPrev.next;
	assert(p !is null);
	int set = data.getSolidSet(x, y, z);
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
	if (data.isTypes(8, 9, x, y+1, z)) {
		int y3 = y1+14;

		if (set & sideMask.XN) {
			if (data.isTypes(8, 9, x-1, y, z)) {
				if (!data.isTypes(8, 9, x-1, y+1, z))
					emitQuadMappedUVXZN(p, x1, x1, y3, y2, z1, z2, tex, sideNormal.XN);
			} else {
				emitQuadXZN(p, x1, x1, y1, y2, z1, z2, tex, sideNormal.XN);
			}
		}

		if (set & sideMask.XP) {
			if (data.isTypes(8, 9, x+1, y, z)) {
				if (!data.isTypes(8, 9, x+1, y+1, z))
					emitQuadMappedUVXZP(p, x2, x2, y3, y2, z1, z2, tex, sideNormal.XP);
			} else {
				emitQuadXZP(p, x2, x2, y1, y2, z1, z2, tex, sideNormal.XP);
			}
		}

		if (set & sideMask.ZN) {
			if (data.isTypes(8, 9, x, y, z-1)) {
				if (!data.isTypes(8, 9, x, y+1, z-1))
					emitQuadMappedUVXZN(p, x1, x2, y3, y2, z1, z1, tex, sideNormal.ZN);
			} else {
				emitQuadXZN(p, x1, x2, y1, y2, z1, z1, tex, sideNormal.ZN);
			}
		}

		if (set & sideMask.ZP) {
			if (data.isTypes(8, 9, x, y, z+1)) {
				if (!data.isTypes(8, 9, x, y+1, z+1))
					emitQuadMappedUVXZP(p, x1, x2, y3, y2, z2, z2, tex, sideNormal.ZP);
			} else {
				emitQuadXZP(p, x1, x2, y1, y2, z2, z2, tex, sideNormal.ZP);
			}
		}

		if (set & sideMask.YN && !data.isTypes(8, 9, x, y-1, z))
			emitQuadYN(p, x1, x2, y1, z1, z2, tex, sideNormal.YN);
	} else {
		y2 -= 2;

		emitQuadYP(p, x1, x2, y2, z1, z2, tex, sideNormal.YP);

		set = data.getSolidOrTypesSet(8, 9, x, y, z);

		if (set & sideMask.XN)
			emitQuadMappedUVXZN(p, x1, x1, y1, y2, z1, z2, tex, sideNormal.XN);

		if (set & sideMask.XP)
			emitQuadMappedUVXZP(p, x2, x2, y1, y2, z1, z2, tex, sideNormal.XP);

		if (set & sideMask.ZN)
			emitQuadMappedUVXZN(p, x1, x2, y1, y2, z1, z1, tex, sideNormal.ZN);

		if (set & sideMask.ZP)
			emitQuadMappedUVXZP(p, x1, x2, y1, y2, z2, z2, tex, sideNormal.ZP);

		if (set & sideMask.YN)
			emitQuadMappedUVYN(p, x1, x2, y1, z1, z2, tex, sideNormal.YN);
	}



}


void glass(Packer *p, int x, int y, int z, ubyte, WorkspaceData *data)
{
	const type = 20;
	auto dec = &tile[type];
	int set = data.getSolidOrTypeSet(type, x, y, z);

	/* all set */
	if (set == 0)
		return;

	makeXYZ(p, data, dec, x, y, z, set);
}


void plants(Packer *p, int x, int y, int z, ubyte type, WorkspaceData *data)
{
	auto dec = &tile[type];
	diagonalSprite(p, x, y, z, dec);
}


void slab(Packer *p, int x, int y, int z, ubyte type, WorkspaceData *data)
{
	int set = data.getSolidOrTypeSet(type, x, y, z);
	auto dec = &tile[type];

	/* all set */
	if (set == 0)
		return;

	if (type == 44)
		makeHalfXYZ(p, data, dec, x, y, z, set | sideMask.YP);
	else
		makeXYZ(p, data, dec, x, y, z, set);
}


BuildFunction[256] buildArray = [
	&air,                //   0
	&solid,
	&grass,
	&solid,
	&solid,              //   4 
	&solid,
	&plants,
	&solid,
	&water,              //   8
	&water,
	&solid,
	&solid,
	&solid,              //  12
	&solid,
	&solid,
	&solid,
	&solid,              //  16
	&solid,
	&solid,
	&solid,
	&glass,              //  20
	&solid,
	&solid,
	&solid,
	&solid,              //  24
	&solid,
	&solid,
	&solid,
	&solid,              //  28 
	&solid,
	&solid,
	&solid,
	&solid,              //  32
	&solid,
	&solid,
	&solid,
	&solid,              //  36 
	&plants,
	&plants,
	&plants,
	&plants,             //  40
	&solid,
	&solid,
	&slab,
	&slab,               //  44
	&solid,
	&solid,
	&solid,
	&solid,              //  48
	&solid,
	&air,
	&air,
	&air,                //  52 
	&air,
	&air,
	&air,
	&air,                //  56
	&air,
	&air,
	&air,
	&air,                //  60 
	&air,
	&air,
	&air,
	&air,                //  64
	&air,
	&air,
	&air,
	&air,                //  68 
	&air,
	&air,
	&air,
	&air,                //  72
	&air,
	&air,
	&air,
	&air,                //  76 
	&air,
	&air,
	&air,
	&air,                //  80
	&air,
	&air,
	&air,
	&air,                //  84 
	&air,
	&air,
	&air,
	&air,                //  88
	&air,
	&air,
	&air,
	&air,                //  92
	&air,
	&air,
	&air,
	&air,                //  96 
	&air,
	&air,
	&air,
	&air,                // 100
	&air,
	&air,
	&air,
	&air,                // 104 
	&air,
	&air,
	&air,
	&air,                // 108
	&air,
	&air,
	&air,
	&air,                // 112 
	&air,
	&air,
	&air,
	&air,                // 116
	&air,
	&air,
	&air,
	&air,                // 120 
	&air,
	&air,
	&air,
	&air,                // 124
	&air,
	&air,
	&air,
	&air,                // 128
	&air,
	&air,
	&air,
	&air,                //   4 
	&air,
	&air,
	&air,
	&air,                //   8
	&air,
	&air,
	&air,
	&air,                //  12
	&air,
	&air,
	&air,
	&air,                //  16
	&air,
	&air,
	&air,
	&air,                //  20
	&air,
	&air,
	&air,
	&air,                //  24
	&air,
	&air,
	&air,
	&air,                //  28 
	&air,
	&air,
	&air,
	&air,                //  32
	&air,
	&air,
	&air,
	&air,                //  36 
	&air,
	&air,
	&air,
	&air,                //  40
	&air,
	&air,
	&air,
	&air,                //  44 
	&air,
	&air,
	&air,
	&air,                //  48
	&air,
	&air,
	&air,
	&air,                //  52 
	&air,
	&air,
	&air,
	&air,                //  56
	&air,
	&air,
	&air,
	&air,                //  60 
	&air,
	&air,
	&air,
	&air,                //  64
	&air,
	&air,
	&air,
	&air,                //  68 
	&air,
	&air,
	&air,
	&air,                //  72
	&air,
	&air,
	&air,
	&air,                //  76 
	&air,
	&air,
	&air,
	&air,                //  80
	&air,
	&air,
	&air,
	&air,                //  84 
	&air,
	&air,
	&air,
	&air,                //  88
	&air,
	&air,
	&air,
	&air,                //  92
	&air,
	&air,
	&air,
	&air,                //  96 
	&air,
	&air,
	&air,
	&air,                // 100
	&air,
	&air,
	&air,
	&air,                // 104 
	&air,
	&air,
	&air,
	&air,                // 108
	&air,
	&air,
	&air,
	&air,                // 112 
	&air,
	&air,
	&air,
	&air,                // 116
	&air,
	&air,
	&air,
	&air,                // 120 
	&air,
	&air,
	&air,
	&air,                // 124
	&air,
	&air,
	&air,
];

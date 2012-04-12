// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.builder.quad;

import miners.builder.emit;
import miners.builder.types;
import miners.builder.helpers;
import miners.builder.workspace;


/*
 * This file contains function for construction full and partial quads for blocks.
 */


/*
 *
 * Full block makers.
 *
 */


void makeY(Packer *p, WorkspaceData *data, BlockDescriptor *dec,
           uint x, uint y, uint z, sideNormal normal)
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
		emitQuadAOYP(p, x1, x2, y, z1, z2,
			     aoBL, aoBR, aoTL, aoTR,
			     texture, normal);
	} else {
		emitQuadAOYN(p, x1, x2, y, z1, z2,
			     aoBL, aoBR, aoTL, aoTR,
			     texture, normal);
	}
}

void makeXZ(Packer *p, WorkspaceData *data, BlockDescriptor *dec,
            uint x, uint y, uint z, sideNormal normal)
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
		emitQuadAOXZP(p, x1, x2, y1, y2, z1, z2,
			      aoBL, aoBR, aoTL, aoTR,
			      texture, normal);
	} else {
		emitQuadAOXZN(p, x1, x2, y1, y2, z1, z2,
			      aoBL, aoBR, aoTL, aoTR,
			      texture, normal);
	}
}

void makeXYZ(Packer *p, WorkspaceData *data, BlockDescriptor *dec,
             uint x, uint y, uint z, int set)
{
	if (set & sideMask.XN)
		makeXZ(p, data, dec, x, y, z, sideNormal.XN);

	if (set & sideMask.XP)
		makeXZ(p, data, dec, x, y, z, sideNormal.XP);

	if (set & sideMask.YN)
		makeY(p, data, dec, x, y, z, sideNormal.YN);

	if (set & sideMask.YP)
		makeY(p, data, dec, x, y, z, sideNormal.YP);

	if (set & sideMask.ZN)
		makeXZ(p, data, dec, x, y, z, sideNormal.ZN);

	if (set & sideMask.ZP)
		makeXZ(p, data, dec, x, y, z, sideNormal.ZP);
}


/*
 *
 * Half and other differntly highted block makers.
 *
 */


void makeHalfY(Packer *p, WorkspaceData *data, BlockDescriptor *dec,
               uint x, uint y, uint z,
               uint height = VERTEX_SIZE_DIVISOR / 2)
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
	y += height;

	ubyte texture = calcTextureY(dec);

	emitQuadAOYP(p, x1, x2, y, z1, z2,
		     aoBL, aoBR, aoTL, aoTR,
		     texture, sideNormal.YP);
}

void makeHalfXZ(Packer *p, WorkspaceData *data, BlockDescriptor *dec,
                uint x, uint y, uint z, sideNormal normal,
                uint height = VERTEX_SIZE_DIVISOR / 2)
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
	y2 = y1 + height;
	z1 <<= shift;
	z2 <<= shift;

	ubyte texture = calcTextureXZ(dec);

	if (height == VERTEX_SIZE_DIVISOR / 2) {
		if (positive) {
			emitHalfQuadAOXZP(p, x1, x2, y1, y2, z1, z2,
					  aoBL, aoBR, aoTL, aoTR,
					  texture, normal);
		} else {
			emitHalfQuadAOXZM(p, x1, x2, y1, y2, z1, z2,
					  aoBL, aoBR, aoTL, aoTR,
					  texture, normal);
		}
	} else {
		if (positive) {
			emitQuadMappedUVAOXZP(p, x1, x2, y1, y2, z1, z2,
					      aoBL, aoBR, aoTL, aoTR,
					      texture, normal,
					      0, 0, uvManip.NONE);
		} else {
			emitQuadMappedUVAOXZN(p, x1, x2, y1, y2, z1, z2,
					      aoBL, aoBR, aoTL, aoTR,
					      texture, normal,
					      0, 0, uvManip.NONE);
		}
	}
}

void makeHalfXYZ(Packer *p, WorkspaceData *data, BlockDescriptor *dec,
                 uint x, uint y, uint z, int set,
                 uint height = VERTEX_SIZE_DIVISOR / 2)
{
	if (set & sideMask.XN)
		makeHalfXZ(p, data, dec, x, y, z, sideNormal.XN, height);

	if (set & sideMask.XP)
		makeHalfXZ(p, data, dec, x, y, z, sideNormal.XP, height);

	if (set & sideMask.YN)
		makeY(p, data, dec, x, y, z, sideNormal.YN);

	if (set & sideMask.YP)
		makeHalfY(p, data, dec, x, y, z, height);

	if (set & sideMask.ZN)
		makeHalfXZ(p, data, dec, x, y, z, sideNormal.ZN, height);

	if (set & sideMask.ZP)
		makeHalfXZ(p, data, dec, x, y, z, sideNormal.ZP, height);
}

void makeFacedBlock(Packer *p, WorkspaceData *data,
                    BlockDescriptor *dec, BlockDescriptor *decFace,
                    uint x, uint y, uint z, sideNormal faceNormal, int set)
{

	if (set & sideMask.ZN)
		makeXZ(p, data, (faceNormal == sideNormal.ZN) ? decFace : dec, x, y, z, sideNormal.ZN);
	if (set & sideMask.ZP)
		makeXZ(p, data, (faceNormal == sideNormal.ZP) ? decFace : dec, x, y, z, sideNormal.ZP);
	if (set & sideMask.XN)
		makeXZ(p, data, (faceNormal == sideNormal.XN) ? decFace : dec, x, y, z, sideNormal.XN);
	if (set & sideMask.XP)
		makeXZ(p, data, (faceNormal == sideNormal.XP) ? decFace : dec, x, y, z, sideNormal.XP);
	if (set & sideMask.YN)
		makeY(p, data, dec, x, y, z, sideNormal.YN);
	if (set & sideMask.YP)
		makeY(p, data, dec, x, y, z, sideNormal.YP);
}


/*
 *
 * Stair side make function.
 *
 */


void makeStairXZ(Packer *p, WorkspaceData *data, BlockDescriptor *dec,
                 uint x, uint y, uint z, sideNormal normal, bool left)
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

	emitStairQuads(p, x1, x2, y1, y2, z1, z2,
		       aoBL, aoBR, aoTL, aoTR,
		       texture, normal);
}

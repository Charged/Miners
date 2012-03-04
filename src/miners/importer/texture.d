// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.importer.importer;

import std.mmfile;

import charge.util.zip;
import charge.math.color;
import charge.math.picture;

import miners.classic.data;
import miners.builder.data;
import miners.importer.folders;


/**
 * Locate minecraft.jar and extract terrain.png.
 *
 * Returns the terrain.png file a C allocated array.
 */
void[] extractMinecraftTexture(char[] dir = null)
{
	if (dir is null)
		dir = getMinecraftFolder();

	auto file = dir ~ "/bin/minecraft.jar";
	void[] data;

	auto mmap = new MmFile(file);
	data = cUncompressFromFile(mmap[], "terrain.png");
	delete mmap;

	return data;
}

/**
 * Do the manipulation of the texture
 */
void manipulateTexture(Picture pic)
{
	// Doesn't support biomes right now fixup the texture before use.
	applyStaticBiome(pic);

	// Doesn't support redstone wire that well either
	setupRedstoneWire(pic);
}

/**
 * Futher manipulate a picture so it works with classic.
 */
void manipulateTextureClassic(Picture pic)
{
	uint tile_size = pic.width / 16;
	uint tile_x = 0;
	uint tile_y = 4;
	uint max;
	tile_x *= tile_size;
	tile_y *= tile_size;

	for (int i; i < 15; i++) {
		auto t = &classicWoolTile[i];
		copyTile(pic, 0, 4, t.xz.u, t.xz.v);
		modulateColor(pic, t.xz.u, t.xz.v, classicWoolColors[i]);
	}
}

/**
 * Extract one tile form the given picture.
 */
Picture getTileAsSeperate(Picture src, char[] name, int tile_x, int tile_y)
{
	uint tile_size = src.width / 16;

	Picture dst = Picture(name, tile_size, tile_size);

	tile_x *= tile_size;
	tile_y *= tile_size;

	for (int x; x < tile_size; x++) {
		for (int y; y < tile_size; y++) {
			auto dstPtr = &dst.pixels[x + y * dst.width];
			auto srcPtr = &src.pixels[(x + tile_x) + (y + tile_y) * src.width];
			*dstPtr = *srcPtr;
		}
	}

	return dst;
}


/*
 * Functions for manipulating the terrain.png picture.
 */
private:

void applyStaticBiome(Picture pic)
{
	//auto grass = Color4b(88, 190, 55, 255);
	auto grass = Color4b(102, 180, 68, 255);

	// These colors are just a guess
	auto leavesRegular = Color4b(91, 139, 23, 255);
	auto leavesSpruce = Color4b(83, 107, 73, 255);
	auto leavesBirch = Color4b(125, 163, 83, 255);
	auto leavesOther = leavesRegular;

	// Copy to some currently unused texture tiles
	copyTile(pic, 4, 3, 9, 9); // Birch leaves
	copyTile(pic, 4, 3, 9, 10); // Other leaves

	modulateColor(pic, 0, 0, grass); // Top grass
	modulateColor(pic, 6, 2, grass); // Side grass blend
	modulateColor(pic, 7, 2, grass); // Tall grass
	modulateColor(pic, 8, 3, grass); // Fern
	modulateColor(pic, 4, 3, leavesRegular); // Tree leaves
	modulateColor(pic, 4, 8, leavesSpruce); // Spruce leaves
	modulateColor(pic, 9, 9, leavesBirch); // Birch leaves
	modulateColor(pic, 9, 10, leavesOther); // Other leaves

	// Blend the now colored side grass onto the used side
	blendTiles(pic, 3, 0, 6, 2);

	// When we are doing mipmaping, soften the edges.
	fillEmptyWithAverage(pic, 4, 3); // Leaves
	fillEmptyWithAverage(pic, 1, 3); // Glass
	fillEmptyWithAverage(pic, 1, 4); // Moster-spawn
}

void setupRedstoneWire(Picture pic) {
	auto active = Color4b(178, 0, 0, 155);
	auto inactive = Color4b(65, 0, 0, 155);

	// Clear tiles.
	auto tile = redstoneWireTile[0][RedstoneWireType.Corner];
	clearTile(pic, tile.xz.u, tile.xz.v);
	tile = redstoneWireTile[0][RedstoneWireType.Tjunction];
	clearTile(pic, tile.xz.u, tile.xz.v);

	foreach(BlockDescriptor dec; redstoneWireTile[1])
		clearTile(pic, dec.xz.u, dec.xz.v);

	// Create corner (2 connections) tile and T-form (3 connections) tile
	// from the crossover tile.
	auto src = redstoneWireTile[0][RedstoneWireType.Crossover];
	auto corner_dst = redstoneWireTile[0][RedstoneWireType.Corner];
	auto tjunction_dst = redstoneWireTile[0][RedstoneWireType.Tjunction];

	// AFAIK there are no non-square tile maps.
	uint tile_size = pic.width / 16;
	int h = tile_size / 2;
	int f = tile_size;
	copyTilePart(pic, src.xz.u*f, src.xz.v*f+h, f-h, f-h,
			corner_dst.xz.u*f, corner_dst.xz.v*f+h);

	copyTilePart(pic, src.xz.u*f, src.xz.v*f, f-h, f,
			tjunction_dst.xz.u*f, tjunction_dst.xz.v*f);

	// Copy all four wire tiles.
	for (int i = 0; i < 4; i++) {
		src = redstoneWireTile[0][i];
		auto dst = redstoneWireTile[1][i];
		copyTile(pic, src.xz.u, src.xz.v, dst.xz.u, dst.xz.v);
	}

	// Color the wire tiles.
	foreach(BlockDescriptor dec; redstoneWireTile[0])
		modulateColor(pic, dec.xz.u, dec.xz.v, inactive);

	foreach(BlockDescriptor dec; redstoneWireTile[1])
		modulateColor(pic, dec.xz.u, dec.xz.v, active);
}

void blendColor(Picture pic, uint tile_x, uint tile_y, Color4b color)
{
	uint tile_size = pic.width / 16;
	tile_x *= tile_size;
	tile_y *= tile_size;

	for (int x; x < tile_size; x++) {
		for (int y; y < tile_size; y++) {
			auto ptr = &pic.pixels[(x + tile_x) + (y + tile_y) * pic.width];
			ptr.blend(color);
			ptr.a = 255;
		}
	}
}

void modulateColor(Picture pic, uint tile_x, uint tile_y, Color4b color)
{
	uint tile_size = pic.width / 16;
	tile_x *= tile_size;
	tile_y *= tile_size;

	for (int x; x < tile_size; x++) {
		for (int y; y < tile_size; y++) {
			auto ptr = &pic.pixels[(x + tile_x) + (y + tile_y) * pic.width];
			ptr.modulate(color);
		}
	}
}

void copyTile(Picture pic, uint tile_x, uint tile_y, uint newtile_x, uint newtile_y)
{
	uint tile_size = pic.width / 16;
	tile_x *= tile_size;
	tile_y *= tile_size;
	newtile_x *= tile_size;
	newtile_y *= tile_size;

	for (int x; x < tile_size; x++) {
		for (int y; y < tile_size; y++) {
			auto ptr = &pic.pixels[(x + tile_x) + (y + tile_y) * pic.width];
			auto newptr = &pic.pixels[(x + newtile_x) + (y + newtile_y) * pic.width];
			*newptr = *ptr;
		}
	}
}

void blendTiles(Picture pic, uint dst_x, uint dst_y, uint src_x, uint src_y)
{
	uint tile_size = pic.width / 16;
	dst_x *= tile_size;
	dst_y *= tile_size;
	src_x *= tile_size;
	src_y *= tile_size;

	for (int x; x < tile_size; x++) {
		for (int y; y < tile_size; y++) {
			auto dst = &pic.pixels[(x + dst_x) + (y + dst_y) * pic.width];
			auto src = &pic.pixels[(x + src_x) + (y + src_y) * pic.width];
			dst.blend(*src);
		}
	}
}

void fillEmptyWithAverage(Picture pic, uint dst_x, uint dst_y)
{
	uint tile_size = pic.width / 16;
	dst_x *= tile_size;
	dst_y *= tile_size;

	uint num;
	double r = 0, g = 0, b = 0;

	for (int x; x < tile_size; x++) {
		for (int y; y < tile_size; y++) {
			auto dst = &pic.pixels[(x + dst_x) + (y + dst_y) * pic.width];
			if (dst.a == 0)
				continue;

			r += dst.r;
			g += dst.g;
			b += dst.b;
			num++;
		}
	}

	Color4b avrg;

	if (num == 0) {
		avrg = Color4b.Black;
		avrg.a = 0;
	} else {
		avrg.r = cast(ubyte)(r / num);
		avrg.g = cast(ubyte)(g / num);
		avrg.b = cast(ubyte)(b / num);
		avrg.a = 0;
	}

	for (int x; x < tile_size; x++) {
		for (int y; y < tile_size; y++) {
			auto dst = &pic.pixels[(x + dst_x) + (y + dst_y) * pic.width];
			if (dst.a != 0)
				continue;
			*dst = avrg;
		}
	}
}

void copyTilePart(Picture pic, uint src_x, uint src_y, uint src_w, uint src_h,
		uint dst_x, uint dst_y) {
	for (int x; x < src_w; x++) {
		for (int y; y < src_h; y++) {
			auto dst = &pic.pixels[(x + dst_x) + (y + dst_y) * pic.width];
			auto src = &pic.pixels[(x + src_x) + (y + src_y) * pic.width];
			*dst = *src;
		}
	}
}

void clearTile(Picture pic, uint tile_x, uint tile_y)
{
	modulateColor(pic, tile_x, tile_y, Color4b(0, 0, 0, 0));
}

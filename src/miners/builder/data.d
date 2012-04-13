// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.builder.data;

import miners.builder.types;


/*
 * This file contains data for converting a minecraft
 * block array into a mesh.
 */


private {
	alias BlockDescriptor.Type.Air Air;
	alias BlockDescriptor.Type.Block Block;
	alias BlockDescriptor.Type.DataBlock DataBlock;
	alias BlockDescriptor.Type.Stuff Stuff;
	alias BlockDescriptor.Type.NA NA;

	alias BlockDescriptor.toTex toTex;
}

BlockDescriptor tile[256] = [
	{ false, Air,       toTex(  0,  0 ), toTex(  0,  0 ), "air", },                  // 0
	{  true, Block,     toTex(  1,  0 ), toTex(  1,  0 ), "stone" },
	{  true, Block,     toTex(  3,  0 ), toTex(  0,  0 ), "grass" },
	{  true, Block,     toTex(  2,  0 ), toTex(  2,  0 ), "dirt" },
	{  true, Block,     toTex(  0,  1 ), toTex(  0,  1 ), "clobb" },
	{  true, Block,     toTex(  4,  0 ), toTex(  4,  0 ), "wooden plank" },
	{ false, Stuff,     toTex( 15,  0 ), toTex( 15,  0 ), "sapling" },
	{  true, Block,     toTex(  1,  1 ), toTex(  1,  1 ), "bedrock" },
	{ false, Stuff,     toTex( 15, 13 ), toTex( 15, 13 ), "water" },                 // 8
	{ false, Stuff,     toTex( 15, 13 ), toTex( 15, 13 ), "spring water" },
	{  true, Stuff,     toTex( 15, 15 ), toTex( 15, 15 ), "lava" },
	{  true, Stuff,     toTex( 15, 15 ), toTex( 15, 15 ), "spring lava" },
	{  true, Block,     toTex(  2,  1 ), toTex(  2,  1 ), "sand" },
	{  true, Block,     toTex(  3,  1 ), toTex(  3,  1 ), "gravel" },
	{  true, Block,     toTex(  0,  2 ), toTex(  0,  2 ), "gold ore" },
	{  true, Block,     toTex(  1,  2 ), toTex(  1,  2 ), "iron ore" },
	{  true, Block,     toTex(  2,  2 ), toTex(  2,  2 ), "coal ore" },              // 16
	{  true, DataBlock, toTex(  4,  1 ), toTex(  5,  1 ), "log" },
	{ false, Stuff,     toTex(  4,  3 ), toTex(  4,  3 ), "leaves" },
	{  true, Block,     toTex(  0,  3 ), toTex(  0,  3 ), "sponge" },
	{ false, Stuff,     toTex(  1,  3 ), toTex(  1,  3 ), "glass" },
	{  true, Block,     toTex(  0, 10 ), toTex(  0, 10 ), "lapis lazuli ore" },
	{  true, Block,     toTex(  0,  9 ), toTex(  0,  9 ), "lapis lazuli block" },
	{  true, DataBlock, toTex( 13,  2 ), toTex( 14,  3 ), "dispenser" },
	{  true, Block,     toTex(  0, 12 ), toTex(  0, 11 ), "sand Stone" },            // 24
	{  true, Block,     toTex( 10,  4 ), toTex( 10,  4 ), "note block" },
	{ false, Stuff,     toTex(  0,  4 ), toTex(  0,  4 ), "bed" },
	{ false, Stuff,     toTex(  0,  4 ), toTex(  0,  4 ), "powered rail" },
	{ false, Stuff,     toTex(  0,  4 ), toTex(  0,  4 ), "detector rail" },
	{ false, NA,        toTex(  0,  4 ), toTex(  0,  4 ), "n/a" },
	{ false, Stuff,     toTex(  0,  4 ), toTex(  0,  4 ), "web" },
	{ false, Stuff,     toTex(  7,  2 ), toTex(  7,  2 ), "tall grass" },
	{ false, NA,        toTex(  7,  3 ), toTex(  7,  3 ), "dead shrub" },            // 32
	{ false, NA,        toTex(  0,  4 ), toTex(  0,  4 ), "n/a" },
	{ false, NA,        toTex(  0,  4 ), toTex(  0,  4 ), "n/a" },
	{  true, DataBlock, toTex(  0,  4 ), toTex(  0,  4 ), "wool" },
	{ false, NA,        toTex(  0,  4 ), toTex(  0,  4 ), "n/a" },
	{ false, Stuff,     toTex( 13,  0 ), toTex( 13,  0 ), "yellow flower" },
	{ false, Stuff,     toTex( 12,  0 ), toTex( 12,  0 ), "red rose" },
	{ false, Stuff,     toTex( 13,  1 ), toTex(  0,  0 ), "brown myshroom" },
	{ false, Stuff,     toTex( 12,  1 ), toTex(  0,  0 ), "red mushroom" },          // 40
	{  true, Block,     toTex(  7,  1 ), toTex(  7,  1 ), "gold block" },
	{  true, Block,     toTex(  6,  1 ), toTex(  6,  1 ), "iron block" },
	{  true, DataBlock, toTex(  5,  0 ), toTex(  6,  0 ), "double slab" },
	{ false, Stuff,     toTex(  5,  0 ), toTex(  6,  0 ), "slab" },
	{  true, Block,     toTex(  7,  0 ), toTex(  7,  0 ), "brick block" },
	{  true, Block,     toTex(  8,  0 ), toTex(  9,  0 ), "tnt" },
	{  true, Block,     toTex(  3,  2 ), toTex(  4,  0 ), "bookshelf" },
	{  true, Block,     toTex(  4,  2 ), toTex(  4,  2 ), "moss stone" },            // 48
	{  true, Block,     toTex(  5,  2 ), toTex(  5,  2 ), "obsidian" },
	{ false, Stuff,     toTex(  0,  5 ), toTex(  0,  5 ), "torch" },
	{ false, Stuff,     toTex(  0,  0 ), toTex(  0,  0 ), "fire" },
	{ false, Stuff,     toTex(  1,  4 ), toTex(  1,  4 ), "monster spawner" },
	{ false, Stuff,     toTex(  4,  0 ), toTex(  4,  0 ), "wooden stairs" },
	{  true, DataBlock, toTex( 10,  1 ), toTex(  9,  1 ), "chest" },
	{ false, Stuff,     toTex(  4, 10 ), toTex(  4, 10 ), "redstone wire" },
	{  true, Block,     toTex(  2,  3 ), toTex(  2,  3 ), "diamond ore" },           // 56
	{  true, Block,     toTex(  8,  1 ), toTex(  8,  1 ), "diamond block" },
	{  true, DataBlock, toTex( 11,  3 ), toTex( 11,  2 ), "crafting table" },
	{ false, Stuff,     toTex(  0,  0 ), toTex(  0,  0 ), "crops" },
	{  true, Stuff,     toTex(  2,  0 ), toTex(  6,  5 ), "farmland" },
	{  true, DataBlock, toTex( 13,  2 ), toTex( 14,  3 ), "furnace" },
	{  true, DataBlock, toTex( 13,  2 ), toTex( 14,  3 ), "burning furnace" },
	{ false, Stuff,     toTex(  4,  0 ), toTex(  0,  0 ), "sign post" },
	{ false, Stuff,     toTex(  1,  5 ), toTex(  1,  6 ), "wooden door" },           // 64
	{ false, Stuff,     toTex(  3,  5 ), toTex(  3,  5 ), "ladder" },
	{ false, Stuff,     toTex(  0,  8 ), toTex(  0,  8 ), "rails" },
	{ false, Stuff,     toTex(  0,  1 ), toTex(  0,  1 ), "clobblestone stairs" },
	{ false, Stuff,     toTex(  4,  0 ), toTex(  4,  0 ), "wall sign" },
	{ false, Stuff,     toTex(  0,  0 ), toTex(  0,  0 ), "lever" },
	{ false, Stuff,     toTex(  1,  0 ), toTex(  1,  0 ), "stone pressure plate" },
	{ false, Stuff,     toTex(  2,  5 ), toTex(  2,  6 ), "iron door" },
	{ false, Stuff,     toTex(  4,  0 ), toTex(  4,  0 ), "wooden pressure plate" }, // 72
	{  true, Block,     toTex(  3,  3 ), toTex(  3,  3 ), "redostone ore" },
	{  true, Block,     toTex(  3,  3 ), toTex(  3,  3 ), "glowing rstone ore" },
	{ false, Stuff,     toTex(  3,  7 ), toTex(  3,  7 ), "redstone torch off" },
	{ false, Stuff,     toTex(  3,  6 ), toTex(  3,  6 ), "redstone torch on" },
	{ false, Stuff,     toTex(  1,  0 ), toTex(  1,  0 ), "stone button" },
	{ false, Stuff,     toTex(  2,  4 ), toTex(  2,  4 ), "snow" },
	{  true, Block,     toTex(  3,  4 ), toTex(  3,  4 ), "ice" },
	{  true, Block,     toTex(  2,  4 ), toTex(  2,  4 ), "snow block" },            // 80
	{ false, Stuff,     toTex(  6,  4 ), toTex(  5,  4 ), "cactus" },
	{  true, Block,     toTex(  8,  4 ), toTex(  8,  4 ), "clay block" },
	{ false, Stuff,     toTex(  9,  4 ), toTex(  0,  0 ), "sugar cane" },
	{  true, Block,     toTex( 10,  4 ), toTex( 11,  4 ), "jukebox" },
	{ false, Stuff,     toTex(  4,  0 ), toTex(  4,  0 ), "fence" },
	{  true, DataBlock, toTex(  6,  7 ), toTex(  6,  6 ), "pumpkin" },
	{  true, Block,     toTex(  7,  6 ), toTex(  7,  6 ), "netherrack" },
	{  true, Block,     toTex(  8,  6 ), toTex(  8,  6 ), "soul sand" },             // 88
	{  true, Block,     toTex(  9,  6 ), toTex(  9,  6 ), "glowstone block" },
	{ false, Stuff,     toTex(  0,  0 ), toTex(  0,  0 ), "portal" },
	{  true, DataBlock, toTex(  6,  7 ), toTex(  6,  6 ), "jack-o-lantern" },
	{ false, Stuff,     toTex( 10,  7 ), toTex(  9,  7 ), "cake block" },
	{ false, Stuff,     toTex(  3,  8 ), toTex(  3,  8 ), "redstone repeater off" },
	{ false, Stuff,     toTex(  3,  9 ), toTex(  3,  9 ), "redstone repeater on" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, Stuff,     toTex(  4,  5 ), toTex(  4,  5 ), "trap door" },             // 96
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },                   // 104
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },                   // 112
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },                   // 120
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{ false, NA,        toTex(  0,  0 ), toTex(  0,  0 ), "n/a" },
	{  true, DataBlock, toTex(  0,  0 ), toTex(  0,  0 ), "Classic Wool" },          // 128
];

BlockDescriptor snowyGrassBlock =
	{  true, Block, toTex( 4,  4 ), toTex( 2,  4 ), "snowy grass" };

BlockDescriptor woolTile[16] = [
	{  true, Block,     toTex(  0,  4 ), toTex(  0,  4 ), "white", },                // 0
	{  true, Block,     toTex(  2, 13 ), toTex(  2, 13 ), "orange" },
	{  true, Block,     toTex(  2, 12 ), toTex(  2, 12 ), "magenta" },
	{  true, Block,     toTex(  2, 11 ), toTex(  2, 11 ), "light blue" },
	{  true, Block,     toTex(  2, 10 ), toTex(  2, 10 ), "yellow" },
	{  true, Block,     toTex(  2,  9 ), toTex(  2,  9 ), "light green" },
	{  true, Block,     toTex(  2,  8 ), toTex(  2,  8 ), "pink" },
	{  true, Block,     toTex(  2,  7 ), toTex(  2,  7 ), "grey" },
	{  true, Block,     toTex(  1, 14 ), toTex(  1, 14 ), "light grey" },            // 8
	{  true, Block,     toTex(  1, 13 ), toTex(  1, 13 ), "cyan" },
	{  true, Block,     toTex(  1, 12 ), toTex(  1, 12 ), "purple" },
	{  true, Block,     toTex(  1, 11 ), toTex(  1, 11 ), "blue" },
	{  true, Block,     toTex(  1, 10 ), toTex(  1, 10 ), "brown" },
	{  true, Block,     toTex(  1,  9 ), toTex(  1,  9 ), "dark green" },
	{  true, Block,     toTex(  1,  8 ), toTex(  1,  8 ), "red" },
	{  true, Block,     toTex(  1,  7 ), toTex(  1,  7 ), "black" },
];

BlockDescriptor classicWoolTile[16] = [
	{  true, Block,     toTex(  1,  7 ), toTex(  1,  7 ), "red" },                   // 0
	{  true, Block,     toTex(  1,  8 ), toTex(  1,  8 ), "orange" },
	{  true, Block,     toTex(  1,  9 ), toTex(  1,  9 ), "yellow" },
	{  true, Block,     toTex(  1, 10 ), toTex(  1, 10 ), "lime green" },
	{  true, Block,     toTex(  1, 11 ), toTex(  1, 11 ), "green" },
	{  true, Block,     toTex(  1, 12 ), toTex(  1, 12 ), "aqua green" },
	{  true, Block,     toTex(  1, 13 ), toTex(  1, 13 ), "cyan" },
	{  true, Block,     toTex(  1, 14 ), toTex(  1, 14 ), "blue" },
	{  true, Block,     toTex(  2,  7 ), toTex(  2,  7 ), "purple" },                // 8
	{  true, Block,     toTex(  2,  8 ), toTex(  2,  8 ), "indigo" },
	{  true, Block,     toTex(  2,  9 ), toTex(  2,  9 ), "violet" },
	{  true, Block,     toTex(  2, 10 ), toTex(  2, 10 ), "magenta" },
	{  true, Block,     toTex(  2, 11 ), toTex(  2, 11 ), "pink" },
	{  true, Block,     toTex(  2, 12 ), toTex(  2, 12 ), "black" },
	{  true, Block,     toTex(  2, 13 ), toTex(  2, 13 ), "grey" },
	{  true, Block,     toTex(  0,  4 ), toTex(  0,  4 ), "white", },
];

BlockDescriptor woodTile[3] = [
	{  true, Block,     toTex(  4,  1 ), toTex(  5,  1 ), "normal", },                // 0
	{  true, Block,     toTex(  4,  7 ), toTex(  5,  1 ), "spruce" },
	{  true, Block,     toTex(  5,  7 ), toTex(  5,  1 ), "birch" }
];

BlockDescriptor saplingTile[4] = [
	{ false, Stuff,     toTex( 15,  0 ), toTex( 15,  0 ), "normal" },
	{ false, Stuff,     toTex( 15,  3 ), toTex( 15,  3 ), "spruce" },
	{ false, Stuff,     toTex( 15,  4 ), toTex( 15,  4 ), "birch" },
	{ false, Stuff,     toTex( 15,  0 ), toTex( 15,  0 ), "normal" },
];

BlockDescriptor tallGrassTile[4] = [
	{ false, Stuff,     toTex(  7,  3 ), toTex(  7,  3 ), "dead shrub" },
	{ false, Stuff,     toTex(  7,  2 ), toTex(  7,  2 ), "tall grass" },
	{ false, Stuff,     toTex(  8,  3 ), toTex(  8,  3 ), "fern" },
];

BlockDescriptor craftingTableAltTile =
	{  true, DataBlock, toTex( 12,  3 ), toTex( 11,  2 ), "crafting table" };

BlockDescriptor slabTile[4] = [
	{  true, Block,     toTex(  5,  0 ), toTex(  6,  0 ), "stone", },                // 0
	{  true, Block,     toTex(  0, 12 ), toTex(  0, 11 ), "sandstone" },
	{  true, Block,     toTex(  4,  0 ), toTex(  4,  0 ), "wooden plank" },
	{  true, Block,     toTex(  0,  1 ), toTex(  0,  1 ), "clobb" },
];

BlockDescriptor cropsTile[8] = [
	{  false, Stuff, toTex(  8,  5 ), toTex(  0,  5 ), "crops 0" },                  // 0
	{  false, Stuff, toTex(  9,  5 ), toTex(  0,  5 ), "crops 1" },
	{  false, Stuff, toTex( 10,  5 ), toTex(  0,  5 ), "crops 2" },
	{  false, Stuff, toTex( 11,  5 ), toTex(  0,  5 ), "crops 3" },
	{  false, Stuff, toTex( 12,  5 ), toTex(  0,  5 ), "crops 4" },
	{  false, Stuff, toTex( 13,  5 ), toTex(  0,  5 ), "crops 5" },
	{  false, Stuff, toTex( 14,  5 ), toTex(  0,  5 ), "crops 6" },
	{  false, Stuff, toTex( 15,  5 ), toTex(  0,  5 ), "crops 7" },
];

BlockDescriptor farmlandTile[2] = [
	{  true, Stuff,     toTex(  2,  0 ), toTex(  7,  5 ), "farmland dry" },          // 0
	{  true, Stuff,     toTex(  2,  0 ), toTex(  6,  5 ), "farmland wet" },
];

BlockDescriptor furnaceFrontTile[2] = [
	{  true, DataBlock, toTex( 12,  2 ), toTex( 14,  3 ), "furnace" },
	{  true, DataBlock, toTex( 13,  3 ), toTex( 14,  3 ), "burning furnace" },
];

BlockDescriptor dispenserFrontTile =
	{  true, DataBlock, toTex( 14,  2 ), toTex( 14,  3 ), "dispenser" };

BlockDescriptor pumpkinFrontTile =
	{  true, DataBlock, toTex(  7,  7 ), toTex(  6,  6 ), "pumpkin" };

BlockDescriptor jackolanternFrontTile =
	{  true, DataBlock, toTex(  8,  7 ), toTex(  6,  6 ), "jack-o-lantern" };

BlockDescriptor cactusBottomTile =
	{ false, Stuff,     toTex(  7,  4 ), toTex(  7,  4 ), "cactus" };

BlockDescriptor leavesTile[] = [
	{ false, Stuff,     toTex(  4,  3 ), toTex(  4,  3 ), "normal leaves" },
	{ false, Stuff,     toTex(  4,  8 ), toTex(  4,  8 ), "spruce leaves" },

	// (9,9) and (9,10) are created in applyStaticBiome()
	{ false, Stuff,     toTex(  9,  9 ), toTex(  9,  9 ), "birch leaves" },
	{ false, Stuff,     toTex(  9, 10 ), toTex(  9, 10 ), "other leaves" },
];

enum RedstoneWireType {
	Crossover,
	Line,
	Corner,
	Tjunction
};

BlockDescriptor redstoneWireTile[2][4] = [
	// inactive
	[
		{ false, Stuff, toTex(  4, 10 ), toTex(  4, 10 ), "crossover" },
		{ false, Stuff, toTex(  5, 10 ), toTex(  5, 10 ), "line" },
		{ false, Stuff, toTex(  6, 10 ), toTex(  6, 10 ), "corner" },
		{ false, Stuff, toTex(  7, 10 ), toTex(  7, 10 ), "T-junction" },
	],
	// active
	[
		{ false, Stuff, toTex(  4, 11 ), toTex(  4, 11 ), "crossover" },
		{ false, Stuff, toTex(  5, 11 ), toTex(  5, 11 ), "line" },
		{ false, Stuff, toTex(  6, 11 ), toTex(  6, 11 ), "corner" },
		{ false, Stuff, toTex(  7, 11 ), toTex(  7, 11 ), "T-junction" },
	]
];

BlockDescriptor cakeTile[2] = [
	{ false, Stuff,     toTex( 11,  7 ), toTex( 11,  7 ), "cake cut side" },
	{ false, Stuff,     toTex( 12,  7 ), toTex( 12,  7 ), "cake bottom" },
];

BlockDescriptor chestTile[6] = [
	{  true, DataBlock, toTex( 10,  1 ), toTex(  9,  1 ), "single chest" },
	{  true, DataBlock, toTex( 11,  1 ), toTex(  9,  1 ), "single chest front" },
	{  true, DataBlock, toTex(  9,  2 ), toTex(  9,  1 ), "double chest front left" },
	{  true, DataBlock, toTex( 10,  2 ), toTex(  9,  1 ), "double chest front right" },
	{  true, DataBlock, toTex(  9,  3 ), toTex(  9,  1 ), "double chest back left" },
	{  true, DataBlock, toTex( 10,  3 ), toTex(  9,  1 ), "double chest back right" },
];

BlockDescriptor railTile[5] = [
	{ false, Stuff,     toTex(  0,  7 ), toTex(  0,  7 ), "rails corner" },
	{ false, Stuff,     toTex(  0,  8 ), toTex(  0,  8 ), "rails line" },
	{ false, Stuff,     toTex(  3, 10 ), toTex(  3, 10 ), "powered rail off" },
	{ false, Stuff,     toTex(  3, 11 ), toTex(  3, 11 ), "powered rail on" },
	{ false, Stuff,     toTex(  3, 12 ), toTex(  3, 12 ), "detector rail" },
];

BlockDescriptor bedTile[6] = [
	{ false, Stuff,     toTex(  0,  0 ), toTex(  6,  8 ), "blanket top" },
	{ false, Stuff,     toTex(  6,  9 ), toTex(  0,  0 ), "blanket side" },
	{ false, Stuff,     toTex(  5,  9 ), toTex(  0,  0 ), "blanket back" },
	{ false, Stuff,     toTex(  0,  0 ), toTex(  7,  8 ), "cushion top" },
	{ false, Stuff,     toTex(  7,  9 ), toTex(  0,  0 ), "cushion side" },
	{ false, Stuff,     toTex(  8,  9 ), toTex(  0,  0 ), "cushion front" },
];

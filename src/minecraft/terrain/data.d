// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.terrain.data;

/*
 * Data for converting a minecraft block array into a mesh.
 */

struct BlockDescriptor {
	enum Type {
		Air,       /* you think that air you are breathing? */
		Block,     /* simple filled block, no data needed to cunstruct it */
		DataBlock, /* filled block, data needed create*/
		Stuff,     /* unfilled, data may be needed to create */
		NA,        /* Unused */
	}

	static struct TexCoord {
		ubyte u;
		ubyte v;
	};

	bool filled; /* A complete filled block */
	Type type;
	TexCoord xz;
	TexCoord y;
	char[] name;
};

private {
	alias BlockDescriptor.Type.Air Air;
	alias BlockDescriptor.Type.Block Block;
	alias BlockDescriptor.Type.DataBlock DataBlock;
	alias BlockDescriptor.Type.Stuff Stuff;
	alias BlockDescriptor.Type.NA NA;
}

BlockDescriptor tile[256] = [
	{ false, Air,       {  0,  0 }, {  0,  0 }, "air", },                  // 0
	{  true, Block,     {  1,  0 }, {  1,  0 }, "stone" },
	{  true, Block,     {  3,  0 }, {  0,  0 }, "grass" },
	{  true, Block,     {  2,  0 }, {  2,  0 }, "dirt" },
	{  true, Block,     {  0,  1 }, {  0,  1 }, "clobb" },
	{  true, Block,     {  4,  0 }, {  4,  0 }, "wooden plank" },
	{ false, Stuff,     { 15,  0 }, { 15,  0 }, "sapling" },
	{  true, Block,     {  1,  1 }, {  1,  1 }, "bedrock" },
	{ false, Stuff,     { 15, 13 }, { 15, 13 }, "water" },                 // 8
	{ false, Stuff,     { 15, 13 }, { 15, 13 }, "spring water" },
	{  true, Stuff,     { 15, 15 }, { 15, 15 }, "lava" },
	{  true, Stuff,     { 15, 15 }, { 15, 15 }, "spring lava" },
	{  true, Block,     {  2,  1 }, {  2,  1 }, "sand" },
	{  true, Block,     {  3,  1 }, {  3,  1 }, "gravel" },
	{  true, Block,     {  0,  2 }, {  0,  2 }, "gold ore" },
	{  true, Block,     {  1,  2 }, {  1,  2 }, "iron ore" },
	{  true, Block,     {  2,  2 }, {  2,  2 }, "coal ore" },              // 16
	{  true, DataBlock, {  4,  1 }, {  5,  1 }, "log" },
	{ false, Stuff,     {  4,  3 }, {  4,  3 }, "leaves" },
	{  true, Block,     {  0,  3 }, {  0,  3 }, "sponge" },
	{ false, Stuff,     {  1,  3 }, {  1,  3 }, "glass" },
	{  true, Block,     {  0, 10 }, {  0, 10 }, "lapis lazuli ore" },
	{  true, Block,     {  0,  9 }, {  0,  9 }, "lapis lazuli block" },
	{  true, DataBlock, { 13,  2 }, { 14,  3 }, "dispenser" },
	{  true, Block,     {  0, 12 }, {  0, 11 }, "sand Stone" },            // 24
	{  true, Block,     { 10,  4 }, { 10,  4 }, "note block" },
	{ false, Stuff,     {  0,  4 }, {  0,  4 }, "bed" },
	{ false, Stuff,     {  0,  4 }, {  0,  4 }, "powered rail" },
	{ false, Stuff,     {  0,  4 }, {  0,  4 }, "detector rail" },
	{ false, NA,        {  0,  4 }, {  0,  4 }, "n/a" },
	{ false, Stuff,     {  0,  4 }, {  0,  4 }, "web" },
	{ false, NA,        {  0,  4 }, {  0,  4 }, "n/a" },
	{ false, NA,        {  0,  4 }, {  0,  4 }, "n/a" },                   // 32
	{ false, NA,        {  0,  4 }, {  0,  4 }, "n/a" },
	{ false, NA,        {  0,  4 }, {  0,  4 }, "n/a" },
	{  true, DataBlock, {  0,  4 }, {  0,  4 }, "wool" },
	{ false, NA,        {  0,  4 }, {  0,  4 }, "n/a" },
	{ false, Stuff,     { 13,  0 }, { 13,  0 }, "yellow flower" },
	{ false, Stuff,     { 12,  0 }, { 12,  0 }, "red rose" },
	{ false, Stuff,     { 13,  1 }, {  0,  0 }, "brown myshroom" },
	{ false, Stuff,     { 12,  1 }, {  0,  0 }, "red mushroom" },          // 40
	{  true, Block,     {  7,  1 }, {  7,  1 }, "gold block" },
	{  true, Block,     {  6,  1 }, {  6,  1 }, "iron block" },
	{  true, DataBlock, {  5,  0 }, {  6,  0 }, "double slab" },
	{ false, Stuff,     {  5,  0 }, {  6,  0 }, "slab" },
	{  true, Block,     {  7,  0 }, {  7,  0 }, "brick block" },
	{  true, Block,     {  8,  0 }, {  9,  0 }, "tnt" },
	{  true, Block,     {  3,  2 }, {  4,  0 }, "bookshelf" },
	{  true, Block,     {  4,  2 }, {  4,  2 }, "moss stone" },            // 48
	{  true, Block,     {  5,  2 }, {  5,  2 }, "obsidian" },
	{ false, Stuff,     {  0,  5 }, {  0,  5 }, "torch" },
	{ false, Stuff,     {  0,  0 }, {  0,  0 }, "fire" },
	{ false, Stuff,     {  1,  4 }, {  1,  4 }, "monster spawner" },
	{ false, Stuff,     {  4,  0 }, {  4,  0 }, "wooden stairs" },
	{  true, DataBlock, { 10,  1 }, {  9,  1 }, "chest" },
	{ false, Stuff,     {  0,  0 }, {  0,  0 }, "redstone wire" },
	{  true, Block,     {  2,  3 }, {  2,  3 }, "diamond ore" },           // 56
	{  true, Block,     {  8,  1 }, {  8,  1 }, "diamond block" },
	{  true, DataBlock, { 11,  3 }, { 11,  2 }, "crafting table" },
	{ false, Stuff,     {  0,  0 }, {  0,  0 }, "crops" },
	{  true, Stuff,     {  2,  0 }, {  6,  5 }, "farmland" },
	{  true, DataBlock, { 13,  2 }, { 14,  3 }, "furnace" },
	{  true, DataBlock, { 13,  2 }, { 14,  3 }, "burning furnace" },
	{ false, Stuff,     {  4,  0 }, {  0,  0 }, "sign post" },
	{ false, Stuff,     {  1,  5 }, {  1,  6 }, "wooden door" },           // 64
	{ false, Stuff,     {  3,  5 }, {  3,  5 }, "ladder" },
	{ false, Stuff,     {  0,  0 }, {  0,  0 }, "rails" },
	{ false, Stuff,     {  0,  1 }, {  0,  1 }, "clobblestone stairs" },
	{ false, Stuff,     {  4,  0 }, {  4,  0 }, "wall sign" },
	{ false, Stuff,     {  0,  0 }, {  0,  0 }, "lever" },
	{ false, Stuff,     {  0,  0 }, {  0,  0 }, "stone pressure plate" },
	{ false, Stuff,     {  2,  5 }, {  2,  6 }, "iron door" },
	{ false, Stuff,     {  0,  0 }, {  0,  0 }, "wooden pressure plate" }, // 72
	{  true, Block,     {  3,  3 }, {  3,  3 }, "redostone ore" },
	{  true, Block,     {  3,  3 }, {  3,  3 }, "glowing rstone ore" },
	{ false, Stuff,     {  0,  0 }, {  0,  0 }, "redstone torch off" },
	{ false, Stuff,     {  0,  0 }, {  0,  0 }, "redstone torch on" },
	{ false, Stuff,     {  0,  0 }, {  0,  0 }, "stone button" },
	{ false, Stuff,     {  4,  4 }, {  2,  4 }, "snow" },
	{  true, Block,     {  3,  4 }, {  3,  4 }, "ice" },
	{  true, Block,     {  2,  4 }, {  2,  4 }, "snow block" },            // 80
	{ false, Stuff,     {  6,  4 }, {  5,  4 }, "cactus" },
	{  true, Block,     {  8,  4 }, {  8,  4 }, "clay block" },
	{ false, Stuff,     {  9,  4 }, {  0,  0 }, "sugar cane" },
	{  true, Block,     { 10,  4 }, { 11,  4 }, "jukebox" },
	{ false, Stuff,     {  4,  0 }, {  4,  0 }, "fence" },
	{  true, DataBlock, {  6,  7 }, {  6,  6 }, "pumpkin" },
	{  true, Block,     {  7,  6 }, {  7,  6 }, "netherrack" },
	{  true, Block,     {  8,  6 }, {  8,  6 }, "soul sand" },             // 88
	{  true, Block,     {  9,  6 }, {  9,  6 }, "glowstone block" },
	{ false, Stuff,     {  0,  0 }, {  0,  0 }, "portal" },
	{  true, DataBlock, {  6,  7 }, {  6,  6 }, "jack-o-lantern" },
	{ false, Stuff,     {  0,  0 }, {  0,  0 }, "cake block" },
	{ false, Stuff,     {  0,  0 }, {  0,  0 }, "redstone repeater off" },
	{ false, Stuff,     {  0,  0 }, {  0,  0 }, "redstone repeater on" },
	{ false, NA,        {  0,  0 }, {  0,  0 }, "n/a" },
	{ false, NA,        {  0,  0 }, {  0,  0 }, "n/a" },                   // 96
];

BlockDescriptor woolTile[256] = [
	{  true, Block,     {  0,  4 }, {  0,  4 }, "white", },                // 0
	{  true, Block,     {  2, 13 }, {  2, 13 }, "orange" },
	{  true, Block,     {  2, 12 }, {  2, 12 }, "magenta" },
	{  true, Block,     {  2, 11 }, {  2, 11 }, "light blue" },
	{  true, Block,     {  2, 10 }, {  2, 10 }, "yellow" },
	{  true, Block,     {  2,  9 }, {  2,  9 }, "light green" },
	{  true, Block,     {  2,  8 }, {  2,  8 }, "pink" },
	{  true, Block,     {  2,  7 }, {  2,  7 }, "grey" },
	{  true, Block,     {  1, 14 }, {  1, 14 }, "light grey" },            // 8
	{  true, Block,     {  1, 13 }, {  1, 13 }, "cyan" },
	{  true, Block,     {  1, 12 }, {  1, 12 }, "purple" },
	{  true, Block,     {  1, 11 }, {  1, 11 }, "blue" },
	{  true, Block,     {  1, 10 }, {  1, 10 }, "brown" },
	{  true, Block,     {  1,  9 }, {  1,  9 }, "dark green" },
	{  true, Block,     {  1,  8 }, {  1,  8 }, "red" },
	{  true, Block,     {  1,  7 }, {  1,  7 }, "black" },
];

BlockDescriptor woodTile[3] = [
	{  true, Block,     {  4,  1 }, {  5,  1 }, "normal", },                // 0
	{  true, Block,     {  4,  7 }, {  5,  1 }, "spruce" },
	{  true, Block,     {  5,  7 }, {  5,  1 }, "birch" }
];

BlockDescriptor saplingTile[4] = [
	{ false, Stuff,     { 15,  0 }, { 15,  0 }, "normal" },
	{ false, Stuff,     { 15,  3 }, { 15,  3 }, "spruce" },
	{ false, Stuff,     { 15,  4 }, { 15,  4 }, "birch" },
	{ false, Stuff,     { 15,  0 }, { 15,  0 }, "normal" },
];

BlockDescriptor craftingTableAltTile =
	{  true, DataBlock, { 12,  3 }, { 11,  2 }, "crafting table" };

BlockDescriptor slabTile[4] = [
	{  true, Block,     {  5,  0 }, {  6,  0 }, "stone", },                // 0
	{  true, Block,     {  0, 12 }, {  0, 11 }, "sandstone" },
	{  true, Block,     {  4,  0 }, {  4,  0 }, "wooden plank" },
	{  true, Block,     {  0,  1 }, {  0,  1 }, "clobb" },
];

BlockDescriptor cropsTile[8] = [
	{  false, Stuff, {  8,  5 }, {  0,  5 }, "crops 0" },                  // 0
	{  false, Stuff, {  9,  5 }, {  0,  5 }, "crops 1" },
	{  false, Stuff, { 10,  5 }, {  0,  5 }, "crops 2" },
	{  false, Stuff, { 11,  5 }, {  0,  5 }, "crops 3" },
	{  false, Stuff, { 12,  5 }, {  0,  5 }, "crops 4" },
	{  false, Stuff, { 13,  5 }, {  0,  5 }, "crops 5" },
	{  false, Stuff, { 14,  5 }, {  0,  5 }, "crops 6" },
	{  false, Stuff, { 15,  5 }, {  0,  5 }, "crops 7" },
];

BlockDescriptor farmlandTile[2] = [
	{  true, Stuff,     {  2,  0 }, {  7,  5 }, "farmland dry" },          // 0
	{  true, Stuff,     {  2,  0 }, {  6,  5 }, "farmland wet" },
];

BlockDescriptor furnaceFrontTile[2] = [
	{  true, DataBlock, { 12,  2 }, { 14,  3 }, "furnace" },
	{  true, DataBlock, { 13,  3 }, { 14,  3 }, "burning furnace" },
];

BlockDescriptor dispenserFrontTile =
	{  true, DataBlock, { 14,  2 }, { 14,  3 }, "dispenser" };

BlockDescriptor pumpkinFrontTile =
	{  true, DataBlock, {  7,  7 }, {  6,  6 }, "pumpkin" };

BlockDescriptor jackolanternFrontTile =
	{  true, DataBlock, {  8,  7 }, {  6,  6 }, "jack-o-lantern" };

BlockDescriptor cactusBottomTile =
	{ false, Stuff,     {  7,  4 }, {  7,  4 }, "cactus" };

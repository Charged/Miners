// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.data;

/**
 * ClassicBlock info struct.
 */
struct ClassicBlockInfo {
	ubyte type; /**< Beta type block */
	ubyte meta; /**< Beta meta data */
	bool correctlyConverted; /**< Correctly converted to beta */
	bool placable;
	char[] name;
	char[] betaName;
}

/**
 * Table holding information about beta blocks.
 *
 * XXX: Wool doesn't match.
 * XXX: Comfirm which blocks that doesn't match.
 */
ClassicBlockInfo classicBlocks[50] = [
	{  0,  0,  true, false, "Air",              "air"},            // 0
	{  1,  0,  true,  true, "Stone",            "stone"},
	{  2,  0,  true,  true, "Grass",            "grass"},
	{  3,  0,  true,  true, "Dirt",             "dirt"},
	{  4,  0,  true,  true, "Cobblestone",      "cobblestone"},
	{  5,  0,  true,  true, "Wooden plank",     "wooden pla"},
	{  6,  0,  true,  true, "Sapling",          "sapling"},
	{  7,  0,  true, false, "Bedrock",          "bedrock"},
	{  8,  0,  true,  true, "Water",            "water"},          // 8
	{  9,  0,  true, false, "Water s.",         "water s."},
	{ 10,  0,  true,  true, "Lava",             "lava"},
	{ 11,  0,  true, false, "Lava s.",          "lava s."},
	{ 12,  0,  true,  true, "Sand",             "sand"},
	{ 13,  0,  true,  true, "Gravel",           "gravel"},
	{ 14,  0,  true,  true, "Gold ore",         "gold ore"},
	{ 15,  0,  true,  true, "Iron ore",         "iron ore"},
	{ 16,  0,  true,  true, "Coal ore",         "coal ore"},       // 16
	{ 17,  0,  true,  true, "Wood",             "wood"},
	{ 18,  0,  true,  true, "Leaves",           "leaves"},
	{ 19,  0,  true,  true, "Sponge",           "sponge"},
	{ 20,  0,  true,  true, "Glass",            "glass"},
	{ 35, 14,  true,  true, "Red Cloth",        "wool red"},
	{ 35,  1,  true,  true, "Orange Cloth",     "wool orange"},
	{ 35,  4,  true,  true, "Yellow Cloth",     "wool yellow"},
	{ 35,  5, false,  true, "Lime Cloth",       "wool l. green"},  // 24
	{ 35,  5,  true,  true, "Green Cloth",      "wool l. green"},
	{ 35,  5, false,  true, "Aqua Green Cloth", "wool l. green"},
	{ 35,  9,  true,  true, "Cyan Cloth",       "wool cyan"},
	{ 35, 11,  true,  true, "Blue Cloth",       "wool blue"},
	{ 35, 10,  true,  true, "Purple Cloth",     "wool purple"},
	{ 35, 10, false,  true, "Indigo Cloth",     "wool purple"},
	{ 35, 10, false,  true, "Violet Cloth",     "wool purple"},
	{ 35,  2,  true,  true, "Magenta Cloth",    "wool mangenta"},  // 32
	{ 35,  6,  true,  true, "Pink Cloth",       "wool pink"},
	{ 35, 15,  true,  true, "Black Cloth",      "wool black"},
	{ 35,  8,  true,  true, "Gray Cloth",       "wool light grey"},
	{ 35,  0,  true,  true, "White Cloth",      "wool white"},
	{ 37,  0,  true,  true, "Dandilion",        "flower yellow"},
	{ 38,  0,  true,  true, "Rose",             "flower red"},
	{ 39,  0,  true,  true, "Brow Mushroom",    "mushroom brown"},
	{ 40,  0,  true,  true, "Red Mushroom",     "mushroom red"},   // 40
	{ 41,  0,  true,  true, "Gold Block",       "gold block"},
	{ 42,  0,  true,  true, "Iron Block",       "iron block"},
	{ 43,  0,  true,  true, "Double Slabs",     "double slabs"},
	{ 44,  0,  true,  true, "Slab",             "slab"},
	{ 45,  0,  true,  true, "Brick Block",      "brick block"},
	{ 46,  0,  true,  true, "TNT",              "tnt"},
	{ 47,  0,  true,  true, "Bookshelf",        "bookshelf"},
	{ 48,  0,  true,  true, "Moss Stone",       "moss stone"},     // 48
	{ 49,  0,  true,  true, "Obsidian",         "obsidian"},
];

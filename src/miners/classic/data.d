// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.data;

import charge.math.color;


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
	{128,  0,  true,  true, "Red Cloth",        "N/A"},
	{128,  1,  true,  true, "Orange Cloth",     "N/A"},
	{128,  2,  true,  true, "Yellow Cloth",     "N/A"},
	{128,  3,  true,  true, "Lime Cloth",       "N/A"},            // 24
	{128,  4,  true,  true, "Green Cloth",      "N/A"},
	{128,  5,  true,  true, "Aqua Green Cloth", "N/A"},
	{128,  6,  true,  true, "Cyan Cloth",       "N/A"},
	{128,  7,  true,  true, "Blue Cloth",       "N/A"},
	{128,  8,  true,  true, "Purple Cloth",     "N/A"},
	{128,  9,  true,  true, "Indigo Cloth",     "N/A"},
	{128, 10,  true,  true, "Violet Cloth",     "N/A"},
	{128, 11,  true,  true, "Magenta Cloth",    "N/A"},            // 32
	{128, 12,  true,  true, "Pink Cloth",       "N/A"},
	{128, 13,  true,  true, "Black Cloth",      "N/A"},
	{128, 14,  true,  true, "Gray Cloth",       "N/A"},
	{128, 15,  true,  true, "White Cloth",      "N/A"},
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

Color4b classicWoolColors[16] = [
	Color4b(255,  58,  58, 205),
	Color4b(255, 156,  58, 205),
	Color4b(255, 255,  58, 205),
	Color4b(156, 255,  58, 205),
	Color4b( 58, 255,  58, 205),
	Color4b( 58, 255, 156, 205),
	Color4b( 58, 255, 255, 205),
	Color4b(120, 187, 255, 205),
	Color4b(138, 138, 255, 205),
	Color4b(156,  58, 255, 205),
	Color4b(200,  85, 255, 205),
	Color4b(255,  58, 255, 205),
	Color4b(255,  58, 156, 205),
	Color4b( 94,  94,  94, 205),
	Color4b(167, 167, 167, 205),
	Color4b(255, 255, 255, 205),
];

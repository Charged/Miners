// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.importer.converter;

import minecraft.terrain.data;

struct ClassicToBeta {
	ubyte block;
	ubyte meta;
	bool convertCorrect;
	char[] name;
	char[] betaname;
}

/**
 * Table for converting classic blocks to beta.
 *
 * XXX: Wool doesn't match.
 * XXX: Comfirm which blocks that doesn't match.
 */
const ClassicToBeta classicToBetaBlocks[50] = [
	{  0,  0,  true, "air",             "air"},            // 0
	{  1,  0,  true, "stone",           "stone"},
	{  2,  0,  true, "grass",           "grass"},
	{  3,  0,  true, "dirt",            "dirt"},
	{  4,  0,  true, "cobblestone",     "cobblestone"},
	{  5,  0,  true, "wooden plank",    "wooden pla"},
	{  6,  0,  true, "sapling",         "sapling"},
	{  7,  0,  true, "bedrock",         "bedrock"},
	{  8,  0,  true, "water",           "water"},          // 8
	{  9,  0,  true, "water s.",        "water s."},
	{ 10,  0,  true, "lava",            "lava"},
	{ 11,  0,  true, "lava s.",         "lava s."},
	{ 12,  0,  true, "sand",            "sand"},
	{ 13,  0,  true, "gravel",          "gravel"},
	{ 14,  0,  true, "gold ore",        "gold ore"},
	{ 15,  0,  true, "iron ore",        "iron ore"},
	{ 16,  0,  true, "coal ore",        "coal ore"},       // 16
	{ 17,  0,  true, "wood",            "wood"},
	{ 18,  0,  true, "leaves",          "leaves"},
	{ 19,  0,  true, "sponge",          "sponge"},
	{ 20,  0,  true, "glass",           "glass"},
	{ 35, 14,  true, "wool red",        "wool red"},
	{ 35,  1,  true, "wool orange",     "wool orange"},
	{ 35,  4,  true, "wool yellow",     "wool yellow"},
	{ 35,  5, false, "wool lime",       "wool l. green"},  // 24
	{ 35,  5,  true, "wool green",      "wool l. green"},
	{ 35,  5, false, "wool aqua green", "wool l. green"},
	{ 35,  9,  true, "wool cyan",       "wool cyan"},
	{ 35, 11,  true, "wool blue",       "wool blue"},
	{ 35, 10,  true, "wool purple",     "wool purple"},
	{ 35, 10, false, "wool indigo",     "wool purple"},
	{ 35, 10, false, "wool violet",     "wool purple"},
	{ 35,  2,  true, "wool magenta",    "wool mangenta"},  // 32
	{ 35,  6,  true, "wool pink",       "wool pink"},
	{ 35, 15,  true, "wool black",      "wool black"},
	{ 35,  7,  true, "wool gray",       "wool grey"},
	{ 35,  0,  true, "wool white",      "wool white"},
	{ 37,  0,  true, "flower yellow",   "flower yellow"},
	{ 38,  0,  true, "flower red",      "flower red"},
	{ 39,  0,  true, "mushroom brown",  "mushroom brown"},
	{ 40,  0,  true, "mushroom red",    "mushroom red"},   // 40
	{ 41,  0,  true, "gold block",      "gold block"},
	{ 42,  0,  true, "iron block",      "iron block"},
	{ 43,  0,  true, "double slabs",    "double slabs"},
	{ 44,  0,  true, "slab",            "slab"},
	{ 45,  0,  true, "brick block",     "brick block"},
	{ 46,  0,  true, "tnt",             "tnt"},
	{ 47,  0,  true, "bookshelf",       "bookshelf"},
	{ 48,  0,  true, "moss stone",      "moss stone"},     // 48
	{ 49,  0,  true, "obsidian",        "obsidian"},
];

/**
 * Convert a single block of classic type to a beta block and meta.
 */
void convertClassicToBeta(ubyte from, out ubyte block, out ubyte meta)
{
	if (from >= 50)
		return;

	auto to = &classicToBetaBlocks[from];
	block = to.block;
	meta = to.meta;
}

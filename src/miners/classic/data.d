// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.data;

import charge.math.color;


/**
 * ClassicBlock info struct.
 */
struct ClassicBlockInfo {
	bool placable;
	char[] name;
}

/**
 * Table holding information about beta blocks.
 *
 * XXX: Comfirm which blocks that doesn't match.
 */
ClassicBlockInfo classicBlocks[50] = [
	{ false, "Air" },               // 0
	{  true, "Stone" },
	{  true, "Grass" },
	{  true, "Dirt" },
	{  true, "Cobblestone" },
	{  true, "Wooden plank" },
	{  true, "Sapling" },
	{ false, "Bedrock" },
	{  true, "Water" },             // 8
	{ false, "Water s." },
	{  true, "Lava" },
	{ false, "Lava s." },
	{  true, "Sand" },
	{  true, "Gravel" },
	{  true, "Gold ore" },
	{  true, "Iron ore" },
	{  true, "Coal ore" },          // 16
	{  true, "Wood" },
	{  true, "Leaves" },
	{  true, "Sponge" },
	{  true, "Glass" },
	{  true, "Red Cloth" },
	{  true, "Orange Cloth" },
	{  true, "Yellow Cloth" },
	{  true, "Lime Cloth" },        // 24
	{  true, "Green Cloth" },
	{  true, "Aqua Green Cloth" },
	{  true, "Cyan Cloth" },
	{  true, "Blue Cloth" },
	{  true, "Purple Cloth" },
	{  true, "Indigo Cloth" },
	{  true, "Violet Cloth" },
	{  true, "Magenta Cloth" },     // 32
	{  true, "Pink Cloth" },
	{  true, "Black Cloth" },
	{  true, "Gray Cloth" },
	{  true, "White Cloth" },
	{  true, "Dandilion" },
	{  true, "Rose" },
	{  true, "Brow Mushroom" },
	{  true, "Red Mushroom" },      // 40
	{  true, "Gold Block" },
	{  true, "Iron Block" },
	{  true, "Double Slabs" },
	{  true, "Slab" },
	{  true, "Brick Block" },
	{  true, "TNT" },
	{  true, "Bookshelf" },
	{  true, "Moss Stone" },        // 48
	{  true, "Obsidian" },
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

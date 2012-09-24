// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.data;

import charge.math.color;


/**
 * ClassicBlock info struct.
 */
struct ClassicBlockInfo {
	bool placable;
	bool selectable;
	char[] name;
}

/**
 * Table holding information about beta blocks.
 */
ClassicBlockInfo classicBlocks[50] = [
	{ false, false, "Air" },               // 0
	{  true,  true, "Stone" },
	{  true,  true, "Grass" },
	{  true,  true, "Dirt" },
	{  true,  true, "Cobblestone" },
	{  true,  true, "Wooden plank" },
	{  true,  true, "Sapling" },
	{  true,  true, "Bedrock" },
	{  true, false, "Water" },             // 8
	{ false, false, "Water s." },
	{  true, false, "Lava" },
	{ false, false, "Lava s." },
	{  true,  true, "Sand" },
	{  true,  true, "Gravel" },
	{  true,  true, "Gold ore" },
	{  true,  true, "Iron ore" },
	{  true,  true, "Coal ore" },          // 16
	{  true,  true, "Wood" },
	{  true,  true, "Leaves" },
	{  true,  true, "Sponge" },
	{  true,  true, "Glass" },
	{  true,  true, "Red Cloth" },
	{  true,  true, "Orange Cloth" },
	{  true,  true, "Yellow Cloth" },
	{  true,  true, "Lime Cloth" },        // 24
	{  true,  true, "Green Cloth" },
	{  true,  true, "Aqua Green Cloth" },
	{  true,  true, "Cyan Cloth" },
	{  true,  true, "Blue Cloth" },
	{  true,  true, "Purple Cloth" },
	{  true,  true, "Indigo Cloth" },
	{  true,  true, "Violet Cloth" },
	{  true,  true, "Magenta Cloth" },     // 32
	{  true,  true, "Pink Cloth" },
	{  true,  true, "Black Cloth" },
	{  true,  true, "Gray Cloth" },
	{  true,  true, "White Cloth" },
	{  true,  true, "Dandilion" },
	{  true,  true, "Rose" },
	{  true,  true, "Brow Mushroom" },
	{  true,  true, "Red Mushroom" },      // 40
	{  true,  true, "Gold Block" },
	{  true,  true, "Iron Block" },
	{  true,  true, "Double Slabs" },
	{  true,  true, "Slab" },
	{  true,  true, "Brick Block" },
	{  true,  true, "TNT" },
	{  true,  true, "Bookshelf" },
	{  true,  true, "Moss Stone" },        // 48
	{  true,  true, "Obsidian" },
];

Color4b classicWoolColors[16] = [
	Color4b(255,  58,  58, 255),
	Color4b(255, 156,  58, 255),
	Color4b(255, 255,  58, 255),
	Color4b(156, 255,  58, 255),
	Color4b( 58, 255,  58, 255),
	Color4b( 58, 255, 156, 255),
	Color4b( 58, 255, 255, 255),
	Color4b(120, 187, 255, 255),
	Color4b(138, 138, 255, 255),
	Color4b(156,  58, 255, 255),
	Color4b(200,  85, 255, 255),
	Color4b(255,  58, 255, 255),
	Color4b(255,  58, 156, 255),
	Color4b( 94,  94,  94, 255),
	Color4b(167, 167, 167, 255),
	Color4b(255, 255, 255, 255),
];

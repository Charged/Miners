// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.builder.data;

import miners.builder.types;


/*
 * This file contains data for converting a minecraft
 * block array into a mesh.
 */


private {
	alias BuildBlockDescriptor.toTex toTex;
}

BuildBlockDescriptor tile[256] = [
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // air                   // 0
	{  true, toTex(  1,  0 ), toTex(  1,  0 ) }, // stone
	{  true, toTex(  3,  0 ), toTex(  0,  0 ) }, // grass
	{  true, toTex(  2,  0 ), toTex(  2,  0 ) }, // dirt
	{  true, toTex(  0,  1 ), toTex(  0,  1 ) }, // clobb
	{  true, toTex(  4,  0 ), toTex(  4,  0 ) }, // wooden plank
	{ false, toTex( 15,  0 ), toTex( 15,  0 ) }, // sapling
	{  true, toTex(  1,  1 ), toTex(  1,  1 ) }, // bedrock
	{ false, toTex( 15, 13 ), toTex( 15, 13 ) }, // water                 // 8
	{ false, toTex( 15, 13 ), toTex( 15, 13 ) }, // spring water
	{  true, toTex( 15, 15 ), toTex( 15, 15 ) }, // lava
	{  true, toTex( 15, 15 ), toTex( 15, 15 ) }, // spring lava
	{  true, toTex(  2,  1 ), toTex(  2,  1 ) }, // sand
	{  true, toTex(  3,  1 ), toTex(  3,  1 ) }, // gravel
	{  true, toTex(  0,  2 ), toTex(  0,  2 ) }, // gold ore
	{  true, toTex(  1,  2 ), toTex(  1,  2 ) }, // iron ore
	{  true, toTex(  2,  2 ), toTex(  2,  2 ) }, // coal ore              // 16
	{  true, toTex(  4,  1 ), toTex(  5,  1 ) }, // log
	{ false, toTex(  4,  3 ), toTex(  4,  3 ) }, // leaves
	{  true, toTex(  0,  3 ), toTex(  0,  3 ) }, // sponge
	{ false, toTex(  1,  3 ), toTex(  1,  3 ) }, // glass
	{  true, toTex(  0, 10 ), toTex(  0, 10 ) }, // lapis lazuli ore
	{  true, toTex(  0,  9 ), toTex(  0,  9 ) }, // lapis lazuli block
	{  true, toTex( 13,  2 ), toTex( 14,  3 ) }, // dispenser
	{  true, toTex(  0, 12 ), toTex(  0, 11 ) }, // sand Stone            // 24
	{  true, toTex( 10,  4 ), toTex( 10,  4 ) }, // note block
	{ false, toTex(  0,  4 ), toTex(  0,  4 ) }, // bed
	{ false, toTex(  0,  4 ), toTex(  0,  4 ) }, // powered rail
	{ false, toTex(  0,  4 ), toTex(  0,  4 ) }, // detector rail
	{ false, toTex(  0,  4 ), toTex(  0,  4 ) }, // n/a
	{ false, toTex(  0,  4 ), toTex(  0,  4 ) }, // web
	{ false, toTex(  7,  2 ), toTex(  7,  2 ) }, // tall grass
	{ false, toTex(  7,  3 ), toTex(  7,  3 ) }, // dead shrub            // 32
	{ false, toTex(  0,  4 ), toTex(  0,  4 ) }, // n/a
	{ false, toTex(  0,  4 ), toTex(  0,  4 ) }, // n/a
	{  true, toTex(  0,  4 ), toTex(  0,  4 ) }, // wool
	{ false, toTex(  0,  4 ), toTex(  0,  4 ) }, // n/a
	{ false, toTex( 13,  0 ), toTex( 13,  0 ) }, // yellow flower
	{ false, toTex( 12,  0 ), toTex( 12,  0 ) }, // red rose
	{ false, toTex( 13,  1 ), toTex(  0,  0 ) }, // brown myshroom
	{ false, toTex( 12,  1 ), toTex(  0,  0 ) }, // red mushroom          // 40
	{  true, toTex(  7,  1 ), toTex(  7,  1 ) }, // gold block
	{  true, toTex(  6,  1 ), toTex(  6,  1 ) }, // iron block
	{  true, toTex(  5,  0 ), toTex(  6,  0 ) }, // double slab
	{ false, toTex(  5,  0 ), toTex(  6,  0 ) }, // slab
	{  true, toTex(  7,  0 ), toTex(  7,  0 ) }, // brick block
	{  true, toTex(  8,  0 ), toTex(  9,  0 ) }, // tnt
	{  true, toTex(  3,  2 ), toTex(  4,  0 ) }, // bookshelf
	{  true, toTex(  4,  2 ), toTex(  4,  2 ) }, // moss stone            // 48
	{  true, toTex(  5,  2 ), toTex(  5,  2 ) }, // obsidian
	{ false, toTex(  0,  5 ), toTex(  0,  5 ) }, // torch
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // fire
	{ false, toTex(  1,  4 ), toTex(  1,  4 ) }, // monster spawner
	{ false, toTex(  4,  0 ), toTex(  4,  0 ) }, // wooden stairs
	{  true, toTex( 10,  1 ), toTex(  9,  1 ) }, // chest
	{ false, toTex(  4, 10 ), toTex(  4, 10 ) }, // redstone wire
	{  true, toTex(  2,  3 ), toTex(  2,  3 ) }, // diamond ore           // 56
	{  true, toTex(  8,  1 ), toTex(  8,  1 ) }, // diamond block
	{  true, toTex( 11,  3 ), toTex( 11,  2 ) }, // crafting table
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // crops
	{  true, toTex(  2,  0 ), toTex(  6,  5 ) }, // farmland
	{  true, toTex( 13,  2 ), toTex( 14,  3 ) }, // furnace
	{  true, toTex( 13,  2 ), toTex( 14,  3 ) }, // burning furnace
	{ false, toTex(  4,  0 ), toTex(  0,  0 ) }, // sign post
	{ false, toTex(  1,  5 ), toTex(  1,  6 ) }, // wooden door           // 64
	{ false, toTex(  3,  5 ), toTex(  3,  5 ) }, // ladder
	{ false, toTex(  0,  8 ), toTex(  0,  8 ) }, // rails
	{ false, toTex(  0,  1 ), toTex(  0,  1 ) }, // clobblestone stairs
	{ false, toTex(  4,  0 ), toTex(  4,  0 ) }, // wall sign
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // lever
	{ false, toTex(  1,  0 ), toTex(  1,  0 ) }, // stone pressure plate
	{ false, toTex(  2,  5 ), toTex(  2,  6 ) }, // iron door
	{ false, toTex(  4,  0 ), toTex(  4,  0 ) }, // wooden pressure plate // 72
	{  true, toTex(  3,  3 ), toTex(  3,  3 ) }, // redostone ore
	{  true, toTex(  3,  3 ), toTex(  3,  3 ) }, // glowing rstone ore
	{ false, toTex(  3,  7 ), toTex(  3,  7 ) }, // redstone torch off
	{ false, toTex(  3,  6 ), toTex(  3,  6 ) }, // redstone torch on
	{ false, toTex(  1,  0 ), toTex(  1,  0 ) }, // stone button
	{ false, toTex(  2,  4 ), toTex(  2,  4 ) }, // snow
	{  true, toTex(  3,  4 ), toTex(  3,  4 ) }, // ice
	{  true, toTex(  2,  4 ), toTex(  2,  4 ) }, // snow block            // 80
	{ false, toTex(  6,  4 ), toTex(  5,  4 ) }, // cactus
	{  true, toTex(  8,  4 ), toTex(  8,  4 ) }, // clay block
	{ false, toTex(  9,  4 ), toTex(  0,  0 ) }, // sugar cane
	{  true, toTex( 10,  4 ), toTex( 11,  4 ) }, // jukebox
	{ false, toTex(  4,  0 ), toTex(  4,  0 ) }, // fence
	{  true, toTex(  6,  7 ), toTex(  6,  6 ) }, // pumpkin
	{  true, toTex(  7,  6 ), toTex(  7,  6 ) }, // netherrack
	{  true, toTex(  8,  6 ), toTex(  8,  6 ) }, // soul sand             // 88
	{  true, toTex(  9,  6 ), toTex(  9,  6 ) }, // glowstone block
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // portal
	{  true, toTex(  6,  7 ), toTex(  6,  6 ) }, // jack-o-lantern
	{ false, toTex( 10,  7 ), toTex(  9,  7 ) }, // cake block
	{ false, toTex(  3,  8 ), toTex(  3,  8 ) }, // redstone repeater off
	{ false, toTex(  3,  9 ), toTex(  3,  9 ) }, // redstone repeater on
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  4,  5 ), toTex(  4,  5 ) }, // trap door             // 96
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a                   // 104
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a                   // 112
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a                   // 120
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{ false, toTex(  0,  0 ), toTex(  0,  0 ) }, // n/a
	{  true, toTex(  0,  0 ), toTex(  0,  0 ) }, // Classic Wool          // 128
];

BuildBlockDescriptor snowyGrassBlock =
	{  true, toTex( 4,  4 ), toTex( 2,  4 ) }; // snowy grass

BuildBlockDescriptor woolTile[16] = [
	{  true, toTex(  0,  4 ), toTex(  0,  4 ) }, // white                // 0
	{  true, toTex(  2, 13 ), toTex(  2, 13 ) }, // orange
	{  true, toTex(  2, 12 ), toTex(  2, 12 ) }, // magenta
	{  true, toTex(  2, 11 ), toTex(  2, 11 ) }, // light blue
	{  true, toTex(  2, 10 ), toTex(  2, 10 ) }, // yellow
	{  true, toTex(  2,  9 ), toTex(  2,  9 ) }, // light green
	{  true, toTex(  2,  8 ), toTex(  2,  8 ) }, // pink
	{  true, toTex(  2,  7 ), toTex(  2,  7 ) }, // grey
	{  true, toTex(  1, 14 ), toTex(  1, 14 ) }, // light grey            // 8
	{  true, toTex(  1, 13 ), toTex(  1, 13 ) }, // cyan
	{  true, toTex(  1, 12 ), toTex(  1, 12 ) }, // purple
	{  true, toTex(  1, 11 ), toTex(  1, 11 ) }, // blue
	{  true, toTex(  1, 10 ), toTex(  1, 10 ) }, // brown
	{  true, toTex(  1,  9 ), toTex(  1,  9 ) }, // dark green
	{  true, toTex(  1,  8 ), toTex(  1,  8 ) }, // red
	{  true, toTex(  1,  7 ), toTex(  1,  7 ) }, // black
];

BuildBlockDescriptor classicWoolTile[16] = [
	{  true, toTex(  1,  7 ), toTex(  1,  7 ) }, // red                   // 0
	{  true, toTex(  1,  8 ), toTex(  1,  8 ) }, // orange
	{  true, toTex(  1,  9 ), toTex(  1,  9 ) }, // yellow
	{  true, toTex(  1, 10 ), toTex(  1, 10 ) }, // lime green
	{  true, toTex(  1, 11 ), toTex(  1, 11 ) }, // green
	{  true, toTex(  1, 12 ), toTex(  1, 12 ) }, // aqua green
	{  true, toTex(  1, 13 ), toTex(  1, 13 ) }, // cyan
	{  true, toTex(  1, 14 ), toTex(  1, 14 ) }, // blue
	{  true, toTex(  2,  7 ), toTex(  2,  7 ) }, // purple                // 8
	{  true, toTex(  2,  8 ), toTex(  2,  8 ) }, // indigo
	{  true, toTex(  2,  9 ), toTex(  2,  9 ) }, // violet
	{  true, toTex(  2, 10 ), toTex(  2, 10 ) }, // magenta
	{  true, toTex(  2, 11 ), toTex(  2, 11 ) }, // pink
	{  true, toTex(  2, 12 ), toTex(  2, 12 ) }, // black
	{  true, toTex(  2, 13 ), toTex(  2, 13 ) }, // grey
	{  true, toTex(  0,  4 ), toTex(  0,  4 ) }, // white,
];

BuildBlockDescriptor woodTile[3] = [
	{  true, toTex(  4,  1 ), toTex(  5,  1 ) }, // normal,                // 0
	{  true, toTex(  4,  7 ), toTex(  5,  1 ) }, // spruce
	{  true, toTex(  5,  7 ), toTex(  5,  1 ) }, // birch
];

BuildBlockDescriptor saplingTile[4] = [
	{ false, toTex( 15,  0 ), toTex( 15,  0 ) }, // normal
	{ false, toTex( 15,  3 ), toTex( 15,  3 ) }, // spruce
	{ false, toTex( 15,  4 ), toTex( 15,  4 ) }, // birch
	{ false, toTex( 15,  0 ), toTex( 15,  0 ) }, // normal
];

BuildBlockDescriptor tallGrassTile[4] = [
	{ false, toTex(  7,  3 ), toTex(  7,  3 ) }, // dead shrub
	{ false, toTex(  7,  2 ), toTex(  7,  2 ) }, // tall grass
	{ false, toTex(  8,  3 ), toTex(  8,  3 ) }, // fern
];

BuildBlockDescriptor craftingTableAltTile =
	{  true, toTex( 12,  3 ), toTex( 11,  2 ) }; // crafting table

BuildBlockDescriptor slabTile[4] = [
	{  true, toTex(  5,  0 ), toTex(  6,  0 ) }, // stone,                // 0
	{  true, toTex(  0, 12 ), toTex(  0, 11 ) }, // sandstone
	{  true, toTex(  4,  0 ), toTex(  4,  0 ) }, // wooden plank
	{  true, toTex(  0,  1 ), toTex(  0,  1 ) }, // clobb
];

BuildBlockDescriptor cropsTile[8] = [
	{ false, toTex(  8,  5 ), toTex(  0,  5 ) }, // crops 0                  // 0
	{ false, toTex(  9,  5 ), toTex(  0,  5 ) }, // crops 1
	{ false, toTex( 10,  5 ), toTex(  0,  5 ) }, // crops 2
	{ false, toTex( 11,  5 ), toTex(  0,  5 ) }, // crops 3
	{ false, toTex( 12,  5 ), toTex(  0,  5 ) }, // crops 4
	{ false, toTex( 13,  5 ), toTex(  0,  5 ) }, // crops 5
	{ false, toTex( 14,  5 ), toTex(  0,  5 ) }, // crops 6
	{ false, toTex( 15,  5 ), toTex(  0,  5 ) }, // crops 7
];

BuildBlockDescriptor farmlandTile[2] = [
	{  true, toTex(  2,  0 ), toTex(  7,  5 ) }, // farmland dry          // 0
	{  true, toTex(  2,  0 ), toTex(  6,  5 ) }, // farmland wet
];

BuildBlockDescriptor furnaceFrontTile[2] = [
	{  true, toTex( 12,  2 ), toTex( 14,  3 ) }, // furnace
	{  true, toTex( 13,  3 ), toTex( 14,  3 ) }, // burning furnace
];

BuildBlockDescriptor dispenserFrontTile =
	{  true, toTex( 14,  2 ), toTex( 14,  3 ) }; // dispenser

BuildBlockDescriptor pumpkinFrontTile =
	{  true, toTex(  7,  7 ), toTex(  6,  6 ) }; // pumpkin

BuildBlockDescriptor jackolanternFrontTile =
	{  true, toTex(  8,  7 ), toTex(  6,  6 ) }; // jack-o-lantern

BuildBlockDescriptor cactusBottomTile =
	{ false, toTex(  7,  4 ), toTex(  7,  4 ) }; // cactus

BuildBlockDescriptor leavesTile[] = [
	{ false, toTex(  4,  3 ), toTex(  4,  3 ) }, // normal leaves
	{ false, toTex(  4,  8 ), toTex(  4,  8 ) }, // spruce leaves

	// (9,9) and (9,10) are created in applyStaticBiome()
	{ false, toTex(  9,  9 ), toTex(  9,  9 ) }, // birch leaves
	{ false, toTex(  9, 10 ), toTex(  9, 10 ) }, // other leaves
];

enum RedstoneWireType {
	Crossover,
	Line,
	Corner,
	Tjunction
};

BuildBlockDescriptor redstoneWireTile[2][4] = [
	// inactive
	[
		{ false, toTex(  4, 10 ), toTex(  4, 10 ) }, // crossover
		{ false, toTex(  5, 10 ), toTex(  5, 10 ) }, // line
		{ false, toTex(  6, 10 ), toTex(  6, 10 ) }, // corner
		{ false, toTex(  7, 10 ), toTex(  7, 10 ) }, // T-junction
	],
	// active
	[
		{ false, toTex(  4, 11 ), toTex(  4, 11 ) }, // crossover
		{ false, toTex(  5, 11 ), toTex(  5, 11 ) }, // line
		{ false, toTex(  6, 11 ), toTex(  6, 11 ) }, // corner
		{ false, toTex(  7, 11 ), toTex(  7, 11 ) }, // T-junction
	]
];

BuildBlockDescriptor cakeTile[2] = [
	{ false, toTex( 11,  7 ), toTex( 11,  7 ) }, // cake cut side
	{ false, toTex( 12,  7 ), toTex( 12,  7 ) }, // cake bottom
];

BuildBlockDescriptor chestTile[6] = [
	{  true, toTex( 10,  1 ), toTex(  9,  1 ) }, // single chest
	{  true, toTex( 11,  1 ), toTex(  9,  1 ) }, // single chest front
	{  true, toTex(  9,  2 ), toTex(  9,  1 ) }, // double chest front left
	{  true, toTex( 10,  2 ), toTex(  9,  1 ) }, // double chest front right
	{  true, toTex(  9,  3 ), toTex(  9,  1 ) }, // double chest back left
	{  true, toTex( 10,  3 ), toTex(  9,  1 ) }, // double chest back right
];

BuildBlockDescriptor railTile[5] = [
	{ false, toTex(  0,  7 ), toTex(  0,  7 ) }, // rails corner
	{ false, toTex(  0,  8 ), toTex(  0,  8 ) }, // rails line
	{ false, toTex(  3, 10 ), toTex(  3, 10 ) }, // powered rail off
	{ false, toTex(  3, 11 ), toTex(  3, 11 ) }, // powered rail on
	{ false, toTex(  3, 12 ), toTex(  3, 12 ) }, // detector rail
];

BuildBlockDescriptor bedTile[6] = [
	{ false, toTex(  0,  0 ), toTex(  6,  8 ) }, // blanket top
	{ false, toTex(  6,  9 ), toTex(  0,  0 ) }, // blanket side
	{ false, toTex(  5,  9 ), toTex(  0,  0 ) }, // blanket back
	{ false, toTex(  0,  0 ), toTex(  7,  8 ) }, // cushion top
	{ false, toTex(  7,  9 ), toTex(  0,  0 ) }, // cushion side
	{ false, toTex(  8,  9 ), toTex(  0,  0 ) }, // cushion front
];

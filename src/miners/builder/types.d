// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.builder.types;


/*
 *
 * Position.
 *
 */


/*
 * Used to convert a chunk block coord into a int and back to a float.
 *
 * That is the builder uses fix precision floating point.
 */
const VERTEX_SIZE_BIT_SHIFT = 4;
const VERTEX_SIZE_DIVISOR = 1 << VERTEX_SIZE_BIT_SHIFT;


/*
 *
 * Normals.
 *
 */


/**
 * The normal of a side.
 */
enum sideNormal : ubyte {
	XN = 0,
	XP = 1,
	YN = 2,
	YP = 3,
	ZN = 4,
	ZP = 5,

// These extended normals are not accepted by most
// functions only the emitters and packers take these.
	XNZN = 6,
	XNZP = 7,
	XPZN = 8,
	XPZP = 9,
}


int normalTable[] = [
	-1, 0, 0,
	 1, 0, 0,
	 0,-1, 0,
	 0, 1, 0,
	 0, 0,-1,
	 0, 0, 1,

// Extended normals
	-1, 0,-1,
	-1, 0, 1,
	 1, 0,-1,
	 1, 0, 1,
];

/**
 * For use together with solid set
 */
enum sideMask {
     XN = 1 << sideNormal.XN,
     XP = 1 << sideNormal.XP,
     YN = 1 << sideNormal.YN,
     YP = 1 << sideNormal.YP,
     ZN = 1 << sideNormal.ZN,
     ZP = 1 << sideNormal.ZP
}


/*
 *
 * UV.
 *
 */


/*
 * Define how many sub devisions there are in a texture tile.
 */
const UV_SIZE_BIT_SHIFT = 4;
const UV_SIZE_DIVISOR = 1 << UV_SIZE_BIT_SHIFT;

/**
 * Which corner of the uv map is this vertex in.
 */
enum uvCoord : ushort {
	LEFT   = 0,
	CENTER = UV_SIZE_DIVISOR / 2,
	RIGHT  = UV_SIZE_DIVISOR,
	TOP    = 0,
	MIDDLE = UV_SIZE_DIVISOR / 2,
	BOTTOM = UV_SIZE_DIVISOR,
};

/**
 * Should the packer manipulate the coords in any way.
 */
enum uvManip {
	NONE,
	HALF_V,
	HALF_U,
	FLIP_U,
	ROT_90,
	ROT_180,
	ROT_270,
	SIZE,
}

/**
 * Pre-made uv coords manipulation
 *
 * TopLeft, BottomLeft, BottomRight, TopRight
 */
uvCoord uvCoords[uvManip.SIZE][4][2] = [
	[ // uvManip.NONE
		[uvCoord.LEFT,  uvCoord.TOP],
		[uvCoord.LEFT,  uvCoord.BOTTOM],
		[uvCoord.RIGHT, uvCoord.BOTTOM],
		[uvCoord.RIGHT, uvCoord.TOP],
	],
	[ // uvManip.HALF_V
		[uvCoord.LEFT,  uvCoord.TOP],
		[uvCoord.LEFT,  uvCoord.MIDDLE],
		[uvCoord.RIGHT, uvCoord.MIDDLE],
		[uvCoord.RIGHT, uvCoord.TOP],
	],
	[ // uvManip.HALF_U
		[uvCoord.LEFT,   uvCoord.TOP],
		[uvCoord.LEFT,   uvCoord.BOTTOM],
		[uvCoord.MIDDLE, uvCoord.BOTTOM],
		[uvCoord.MIDDLE, uvCoord.TOP],
	],
	[ // uvManip.FLIP_U
		[uvCoord.RIGHT, uvCoord.TOP],
		[uvCoord.RIGHT, uvCoord.BOTTOM],
		[uvCoord.LEFT,  uvCoord.BOTTOM],
		[uvCoord.LEFT,  uvCoord.TOP],
	],
	[ // uvManip.ROT_90
		[uvCoord.LEFT,  uvCoord.BOTTOM],
		[uvCoord.RIGHT, uvCoord.BOTTOM],
		[uvCoord.RIGHT, uvCoord.TOP],
		[uvCoord.LEFT,  uvCoord.TOP],
	],
	[ // uvManip.ROT_180
		[uvCoord.RIGHT, uvCoord.BOTTOM],
		[uvCoord.RIGHT, uvCoord.TOP],
		[uvCoord.LEFT,  uvCoord.TOP],
		[uvCoord.LEFT,  uvCoord.BOTTOM],
	],
	[ // uvManip.ROT_270
		[uvCoord.RIGHT, uvCoord.TOP],
		[uvCoord.LEFT,  uvCoord.TOP],
		[uvCoord.LEFT,  uvCoord.BOTTOM],
		[uvCoord.RIGHT, uvCoord.BOTTOM],
	],
];


/*
 *
 * MeshPacker.
 *
 */


/**
 * Describes a block.
 */
struct BlockDescriptor {
	enum Type {
		Air,       /* you think that air you are breathing? */
		Block,     /* simple filled block, no data needed to cunstruct it */
		DataBlock, /* filled block, data needed create*/
		Stuff,     /* unfilled, data may be needed to create */
		NA,        /* Unused */
	}

	bool filled; /* A complete filled block */
	Type type;
	ubyte xzTex;
	ubyte yTex;
	char[] name;

	static ubyte toTex(int u, int v)
	{
		return cast(ubyte)u + v * 16;
	}
};


/**
 * Base struct for all packers.
 */
struct Packer
{
	void function(Packer *p, int x, int y, int z,
		      ubyte texture, ubyte light, sideNormal normal,
		      ushort u, ushort v) pack;
}

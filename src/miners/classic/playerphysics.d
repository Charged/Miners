// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.playerphysics;

import std.stdio : writefln;
import std.math : floor, fmin, fmax;

import charge.math.quatd;
import charge.math.point3d;
import charge.math.vector3d;

import miners.types;


/**
 * Handles player physics interaction against a axis aligned terrain.
 */
class PlayerPhysics
{
public:
	typedef ubyte delegate(int x, int y, int z) BlockDg;

	enum : ubyte {
		AIR    = 0x0,
		FULL   = 0x1,
		HALF   = 0x3,
		LIQUID = 0x2,
	}

	ubyte blockType[256] = [
		AIR,    // Air               //  0
		FULL,   // Stone
		FULL,   // Grass
		FULL,   // Dirt
		FULL,   // Cobblestone
		FULL,   // Wooden plank
		AIR,    // Sapling
		FULL,   // Bedrock
		LIQUID, // Water             //  8
		LIQUID, // Water s.
		LIQUID, // Lava
		LIQUID, // Lava s.
		FULL,   // Sand
		FULL,   // Gravel
		FULL,   // Gold ore
		FULL,   // Iron ore
		FULL,   // Coal ore          // 16
		FULL,   // Wood
		FULL,   // Leaves
		FULL,   // Sponge
		FULL,   // Glass
		FULL,   // Red Cloth
		FULL,   // Orange Cloth
		FULL,   // Yellow Cloth
		FULL,   // Lime Cloth        // 24
		FULL,   // Green Cloth
		FULL,   // Aqua Green Cloth
		FULL,   // Cyan Cloth
		FULL,   // Blue Cloth
		FULL,   // Purple Cloth
		FULL,   // Indigo Cloth
		FULL,   // Violet Cloth
		FULL,   // Magenta Cloth     // 32
		FULL,   // Pink Cloth
		FULL,   // Black Cloth
		FULL,   // Gray Cloth
		FULL,   // White Cloth
		AIR,    // Dandilion
		AIR,    // Rose
		AIR,    // Brow Mushroom
		AIR,    // Red Mushroom      // 40
		FULL,   // Gold Block
		FULL,   // Iron Block
		FULL,   // Double Slabs
		HALF,   // Slab
		FULL,   // Brick Block
		FULL,   // TNT
		FULL,   // Bookshelf
		FULL,   // Moss Stone        // 48
		FULL,   // Obsidian
	];


	const double width = 0.4;
	const double height = 1.4;
	const double camHeight = 1.2;

	bool forward;
	bool backward;
	bool left;
	bool right;
	bool run;
	bool up; // Camera
	bool down; // Camera
	bool jump;
	bool crouch;

protected:
	BlockDg getBlock;


public:
	this(BlockDg getBlock)
	{
		this.getBlock = getBlock;
	}


	Point3d movePlayer(Point3d pos, double heading)
	{
		// Create a rotation, that we can get
		// the different vectors from.
		auto rot = Quatd(heading, 0, 0);

		Vector3d vel = Vector3d();

		if (forward != backward) {
			auto v = rot.rotateHeading();
			if (backward)
				v.scale(-1);
			vel += v;
		}

		if (left != right) {
			auto v = rot.rotateLeft();
			if (right)
				v.scale(-1);
			vel += v;
		}

		// The speed at which we move.
		double velSpeed = run ? 0.4 : 0.1;

		// Normalize function is safe.
		vel.normalize();
		// Scale the speed vector.
		vel.scale(velSpeed);

		if (up)
			vel.y += velSpeed;

		if (down)
			vel.y -= velSpeed;

		return movePlayer(pos, vel);
	}


	Point3d movePlayer(Point3d pos, Vector3d vel)
	{
		// Adjust for the position being the camera.
		pos.y -= camHeight;

		// XXX Physics!
		pos += vel;

		// Adjust back.
		pos += Vector3d(0, camHeight, 0);
		return pos;
	}


protected:
	/**
	 * Check if we collide with this block.
	 *
	 * XXX Treats half blocks as full.
	 */
	final bool collides(int x, int y, int z)
	{
		auto block = getBlock(x, y, z);
		auto type = blockType[block];
		return cast(bool)(type & 0x1);
	}

	/**
	 * Check if the player collides within a range of blocks.
	 */
	bool collidesInRange(int minX, int minY, int minZ,
	                     int maxX, int maxY, int maxZ)
	{
		for (int x = minX; x <= maxX; x++) {
			for (int y = minY; y <= maxY; y++) {
				for (int z = minZ; z <= maxZ; z++) {
					if (collides(x, y, z))
						return true;
				}
			}
		}

		return true;
	}
}

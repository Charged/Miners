// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.playerphysics;

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
	alias ubyte delegate(int x, int y, int z) BlockDg;

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

	const double playerSize = 0.32;
	const double playerHeight = 1.5;
	const double gravity = 9.8 / 2000.0;
	const double jumpFactor = 0.12;

	Vector3d oldVel;

	bool forward;
	bool backward;
	bool left;
	bool right;
	bool run;
	bool up; // Camera
	bool down; // Camera
	bool jump;
	bool crouch;
	bool noClip;


protected:
	BlockDg getBlock;


public:
	this(BlockDg getBlock)
	{
		this.getBlock = getBlock;
	}

	/**
	 * Move the player in the given heading.
	 */
	Point3d movePlayer(Point3d pos, double heading)
	{
		if (noClip)
			return movePlayerNoClip(pos, heading);
		else
			return movePlayerClip(pos, heading);
	}

	/**
	 * Moves the player using a floating camera type mover.
	 */
	Point3d movePlayerNoClip(Point3d pos, double heading)
	{
		Vector3d vel = getMoveVector(heading);

		// The speed at which we move.
		double velSpeed = run ? 1.0 : (4.3/100);

		if (up)
			vel.y += velSpeed;

		if (down)
			vel.y -= velSpeed;

		// No physics.
		pos += vel;

		// Reset
		oldVel = Vector3d();

		return pos;
	}

	/**
	 * Moves the player using physics.
	 *
	 * XXX: No physics yet.
	 */
	Point3d movePlayerClip(Point3d pos, double heading)
	{
		Vector3d vel = getMoveVector(heading);

		// Adjust for the position being the camera.
		double old, v;
		double x = pos.x;
		double y = pos.y - camHeight;
		double z = pos.z;

		double minX = x - playerSize;
		double minY = y;
		double minZ = z - playerSize;
		double maxX = x + playerSize;
		double maxY = y + playerHeight;
		double maxZ = z + playerSize;

		bool ground;
		{
			double cy = getMovedBodyPosition(y, -gravity, 0, 0);
			ground = collidesInRange(
				minX, cy, minZ, maxX, cy, maxZ);
		}

		// Ignore the old velocity if on the ground.
		if (ground) {
			vel.y = ((jump || up) && ground) * jumpFactor - gravity;
		} else {
			vel.scale(0.02);
			vel += oldVel;
			vel.y = vel.y - gravity;
		}

		double limit(double val) {
			return fmax(fmin(val, 0.8), -0.8);
		}

		v = limit(vel.x);
		old = x;
		if (v != 0) {
			double cx = getMovedBodyPosition(x, v, -playerSize, playerSize);
			if (collidesInRange(cx, minY, minZ, cx, maxY, maxZ)) {
				if (v < 0)
					x = cx + 1 + playerSize + 0.00001;
				else
					x = cx - playerSize - 0.00001;
			} else {
				x = x + v;
			}

			minX = x - playerSize;
			maxX = x + playerSize;
			vel.x = x - old;
		}

		v = limit(vel.z);
		old = z;
		if (v != 0) {
			double cz = getMovedBodyPosition(z, v, -playerSize, playerSize);
			if (collidesInRange(minX, minY, cz, maxX, maxY, cz)) {
				if (v < 0)
					z = cz + 1 + playerSize + 0.00001;
				else
					z = cz - playerSize - 0.00001;
			} else {
				z = z + v;
			}

			minZ = z - playerSize;
			maxZ = z + playerSize;
			vel.z = z - old;
		}

		v = limit(vel.y);
		old = y;
		if (v != 0) {
			double cy = getMovedBodyPosition(y, v, 0, playerHeight);
			if (collidesInRange(minX, cy, minZ, maxX, cy, maxZ)) {
				if (v < 0)
					y = cy + 1 + 0.00001;
				else
					y = cy - playerHeight - 0.00001;
			} else {
				y = y + v;
			}

			// Not needed.
			//minY = y - playerSize;
			//maxY = y + playerSize;
			vel.y = y - old;
		}

		pos += vel;
		oldVel = vel;

		return pos;
	}


protected:
	/**
	 * Returns a normalized vector combining the heading and
	 * the left/right/forward/backward movment booleans.
	 */
	Vector3d getMoveVector(double heading)
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

		// Normalize function is safe.
		vel.normalize();

		// The speed at which we move.
		double velSpeed = run ? 1.0 : (4.3/100);

		// Scale the speed vector.
		vel.scale(velSpeed);

		return vel;
	}

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
	 * Simple wrapper around the int version of collidesInRange.
	 */
	final bool collidesInRange(double minX, double minY, double minZ,
	                           double maxX, double maxY, double maxZ)
	{
		return collidesInRange(
			cast(int)minX, cast(int)minY, cast(int)minZ,
			cast(int)maxX, cast(int)maxY, cast(int)maxZ);
	}

	/**
	 * Check if the player collides within a range of blocks.
	 */
	final bool collidesInRange(int minX, int minY, int minZ,
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

		return false;
	}
}

double getMovedBodyPosition(
	double pos, double v, double minVal, double maxVal)
{
	if (v < 0)
		return floor(pos + v + minVal);
	else
		return floor(pos + v + maxVal);
}
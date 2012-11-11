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

	const double camHeight = 1.505;
	const double playerSize = 0.32;
	const double playerHeight = 1.62;
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
	bool flying;
	bool noClip;


protected:
	BlockDg getBlock;


public:
	this(BlockDg getBlock)
	{
		this.getBlock = getBlock;
		oldVel = Vector3d();
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

		// Moving up and down.
		if ((jump || up) ^ down)
			vel.y += down ? -velSpeed : velSpeed;

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
		Aabb current, test;
		Aabb[64] stack;

		// Adjust for the position being the camera.
		double old, v;
		double x = pos.x;
		double y = pos.y - camHeight;
		double z = pos.z;

		current.minX = x - playerSize;
		current.maxX = x + playerSize;
		current.minY = y;
		current.maxY = y + playerHeight;
		current.minZ = z - playerSize;
		current.maxZ = z + playerSize;


		bool ground;
		{
			test = current;
			test.minY -= gravity;
			if (getColliders(test, current, stack) > 0)
				ground = true;
		}

		// Ignore the old velocity if on the ground.
		if (flying) {
			if ((jump || up) ^ down)
				vel.y += down ? -velSpeed : velSpeed;
		} else if (ground) {
			vel.y = (jump || up) * jumpFactor - gravity;
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
			test = current;
			x = x + v;
			if (v < 0)
				test.minX += v;
			else
				test.maxX += v;

			auto num = getColliders(test, current, stack);
			if (v < 0) {
				foreach(ref b; stack[0 .. num]) {
					x = fmax(x, b.maxX + playerSize + 0.00001);
				}
			} else {
				foreach(ref b; stack[0 .. num])
					x = fmin(x, b.minX - playerSize - 0.00001);
			}

			current.minX = x - playerSize;
			current.maxX = x + playerSize;
			vel.x = x - old;
		}

		v = limit(vel.z);
		old = z;
		if (v != 0) {
			test = current;
			z = z + v;
			if (v < 0)
				test.minZ += v;
			else
				test.maxZ += v;

			auto num = getColliders(test, current, stack);
			if (v < 0) {
				foreach(ref b; stack[0 .. num]) {
					z = fmax(z, b.maxZ + playerSize + 0.00001);
				}
			} else {
				foreach(ref b; stack[0 .. num])
					z = fmin(z, b.minZ - playerSize - 0.00001);
			}

			current.minZ = z - playerSize;
			current.maxZ = z + playerSize;
			vel.z = z - old;
		}

		v = limit(vel.y);
		old = y;
		if (v != 0) {
			test = current;
			y = y + v;
			if (v < 0)
				test.minY += v;
			else
				test.maxY += v;

			auto num = getColliders(test, current, stack);
			if (v < 0) {
				foreach(ref b; stack[0 .. num]) {
					y = fmax(y, b.maxY + 0.00001);
				}
			} else {
				foreach(ref b; stack[0 .. num])
					y = fmin(y, b.minY - playerHeight - 0.00001);
			}

			//current.minY = y;
			//current.maxY = y + playerHeight;
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
	 * The speed at which we move.
	 */
	final double velSpeed()
	{
		return run ? 1.0 : (4.3/100);
	}

	static align(16) struct Aabb
	{
		double minX, minY, minZ;
		double maxX, maxY, maxZ;

		bool collides(ref Aabb c)
		{
			if (minX <= c.maxX && maxX > c.minX)
				if (minZ <= c.maxZ && maxZ > c.minZ)
					if (minY <= c.maxY && maxY > c.minY)
						return true;
			return false;
		}
	}

	final int getColliders(ref Aabb inc, ref Aabb excluding, Aabb[] result)
	{
		int num;
		Aabb test;
		int minX = cast(int)floor(inc.minX), minY = cast(int)floor(inc.minY), minZ = cast(int)floor(inc.minZ);
		int maxX = cast(int)floor(inc.maxX), maxY = cast(int)floor(inc.maxY), maxZ = cast(int)floor(inc.maxZ);

		for (int x = minX; x <= maxX; x++) {
			test.minX = x;
			test.maxX = x + 1;
			for (int z = minZ; z <= maxZ; z++) {
				test.minZ = z;
				test.maxZ = z + 1;
				for (int y = minY; y <= maxY; y++) {
					auto t = blockType[getBlock(x, y, z)];
					if (t == HALF) {
						test.maxY = y + .5;
					} else if (t == FULL) {
						test.maxY = y + 1;
					} else {
						continue;
					}
					test.minY = y;

					if (!test.collides(inc))
						continue;

					if (excluding.collides(test))
						continue;

					result[num++] = test;
				}
			}
		}
		return num;
	}
}

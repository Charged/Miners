// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.playerphysics;

import std.math : floor, fmin, fmax, abs;

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

	// Initial values not really used and overwritten by ClassicRunner.
	int speedRun = 1000;
	int speedWalk = 43;

	const double camHeight = 1.505;
	const double playerSize = 0.32;
	const double playerHeight = 1.62;
	const double gravity = 9.8 / 2000.0;
	const double jumpFactor = 0.12;
	const double waterGravity = gravity / 4;
	const double waterJumpFactor = waterGravity * 1.8;

	Vector3d oldVel;
	double ySlideOffset;

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
		ySlideOffset = 0;
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
	 * XXX: No water/lava physics yet.
	 */
	Point3d movePlayerClip(Point3d posIn, double heading)
	{
		Vector3d vel = getMoveVector(heading);
		bool collidesX, collidesY, collidesZ;
		Aabb current;

		// Adjust before copying or we forget about things.
		posIn.y += ySlideOffset;

		// Copy so we can adjust it.
		auto pos = posIn;
		// Adjust for the position being the camera.
		pos.y -= camHeight;

		// Get the current bounding box.
		getCollisionBox(pos, current);

		// Ground status
		bool ground = getIsOnGround(current);

		// Do we touch liquid.
		bool liquid = getTouchLiquid(current);


		// Ignore the old velocity if on the ground.
		if (flying) {
			if ((jump || up) ^ down)
				vel.y += down ? -velSpeed : velSpeed;
		} else if (liquid) {
			ground = false;
			vel.scale(0.02);
			vel += oldVel;
			vel.y = vel.y - waterGravity;

			if (jump || up) {
				ySlideOffset = 0;

				auto test = current;
				test.minY += 0.2;
				if (getTouchLiquid(test))
					vel.y += waterJumpFactor;
				else
					vel.y += jumpFactor / 2;
			}

			vel.scale(0.8);
		} else if (ground) {
			vel.y = -gravity;
			if (jump || up) {
				vel.y += jumpFactor;
				ySlideOffset = 0;
				ground = false;
			}
		} else {
			vel.scale(0.02);
			vel += oldVel;
			vel.y = vel.y - gravity;
		}

		auto fullVel = vel;
		doCollisions(vel, pos, current, collidesX, collidesY, collidesZ);

		if (ground && ySlideOffset < 0.01 && (collidesX || collidesZ)) {
			pos.y += 0.5;
			getCollisionBox(pos, current);

			auto tmp = fullVel;
			doCollisions(tmp, pos, current, collidesX, collidesY, collidesZ);

			// Is kinda smart now, maybe something smarter isn't needed.
			if (abs(vel.x) < abs(tmp.x) ||
			    abs(vel.z) < abs(tmp.z)) {
				vel.x = tmp.x;
				vel.z = tmp.z;
				posIn.y += 0.5;
				ySlideOffset += 0.5;
			}
		}

		if (ground && (jump || up) && ySlideOffset < 0.05)
			ySlideOffset += 0.5;

		ySlideOffset *= 0.9;
		oldVel = vel;
		posIn += vel;

		// Adjust for ySlide when stepping up half steps.
		if (ySlideOffset < 0.05)
			ySlideOffset = 0;
		posIn.y -= ySlideOffset;

		return posIn;
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

		// Scale the speed vector.
		vel.scale(velSpeed());

		return vel;
	}

	/**
	 * The speed at which we move.
	 */
	final double velSpeed()
	{
		return (run ? speedRun : speedWalk) / 1000.0;
	}

	/**
	 * Returns the player collision AABB.
	 */
	final void getCollisionBox(ref Point3d pos, ref Aabb current)
	{
		current.minX = pos.x - playerSize;
		current.maxX = pos.x + playerSize;
		current.minY = pos.y;
		current.maxY = pos.y + playerHeight;
		current.minZ = pos.z - playerSize;
		current.maxZ = pos.z + playerSize;
	}

	/**
	 * Adjusts vel according to collisions, current is also changed.
	 */
	final void doCollisions(ref Vector3d vel, ref Point3d pos, ref Aabb current,
	                        out bool colX, out bool colY, out bool colZ)
	{
		Aabb stack[64] = void;
		Aabb test;
		double v, old;

		v = vel.x;
		old = pos.x;
		if (v != 0) {
			test = current;
			double x = old + v;
			if (v < 0)
				test.minX += v;
			else
				test.maxX += v;

			auto num = getColliders(test, current, stack);
			if (num > 0) {
				if (v < 0) {
					foreach(ref b; stack[0 .. num])
						x = fmax(x, b.maxX + playerSize + 0.00001);
				} else {
					foreach(ref b; stack[0 .. num])
						x = fmin(x, b.minX - playerSize - 0.00001);
				}

				colX = true;
				vel.x = x - old;
			}
			current.minX = x - playerSize;
			current.maxX = x + playerSize;
		}

		v = vel.z;
		old = pos.z;
		if (v != 0) {
			test = current;
			double z = old + v;
			if (v < 0)
				test.minZ += v;
			else
				test.maxZ += v;

			auto num = getColliders(test, current, stack);
			if (num > 0) {
				if (v < 0) {
					foreach(ref b; stack[0 .. num])
						z = fmax(z, b.maxZ + playerSize + 0.00001);
				} else {
					foreach(ref b; stack[0 .. num])
						z = fmin(z, b.minZ - playerSize - 0.00001);
				}

				colZ = true;
				vel.z = z - old;
			}
			current.minZ = z - playerSize;
			current.maxZ = z + playerSize;
		}

		v = vel.y;
		old = pos.y;
		if (v != 0) {
			test = current;
			double y = old + v;
			if (v < 0)
				test.minY += v;
			else
				test.maxY += v;

			auto num = getColliders(test, current, stack);
			if (num > 0) {
				if (v < 0) {
					foreach(ref b; stack[0 .. num])
						y = fmax(y, b.maxY + 0.00001);
				} else {
					foreach(ref b; stack[0 .. num])
						y = fmin(y, b.minY - playerHeight - 0.00001);
				}

				colY = true;
				vel.y = y - old;
			}
			current.minY = y;
			current.maxY = y + playerHeight;
		}
	}

	/**
	 * Checks if the player will touch the ground this frame.
	 */
	bool getIsOnGround(ref Aabb current)
	{
		Aabb[64] stack = void;
		Aabb test;

		test = current;
		test.minY -= gravity;
		if (getColliders(test, current, stack) > 0)
			return true;
		return false;
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

	final bool getTouchLiquid(ref Aabb inc)
	{
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
					if (blockType[getBlock(x, y, z)] != LIQUID)
						continue;

					test.minY = y;
					test.maxY = y + 1;

					if (!test.collides(inc))
						continue;

					return true;
				}
			}
		}
		return false;
	}
}

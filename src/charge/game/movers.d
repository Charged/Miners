// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for Mover helpers.
 */
module charge.game.movers;

import charge.math.movable;


class Mover
{
private
	Movable m;

public:
	bool forward;
	bool backward;
	bool left;
	bool right;
	bool speed;
	bool up;
	bool step;

	this(Movable m)
	{
		this.m = m;
	}

	~this()
	{
		assert(m is null);
	}

	void breakApart()
	{
		m = null;
	}

	abstract void tick();
}

class IsoCameraMover : Mover
{
public:
	int x; int z;

	this(Movable m)
	{
		super(m);
		m.position = Point3d();
	}

	override void tick()
	{
		if (forward != backward) {
			x += forward ? -1 : 1;
			z += forward ? -1 : 1;
		}
		if (left != right) {
			x += left ? -1 : 1;
			z += left ? 1 : -1;
		}

		m.position = Point3d(x * 0.25f, 0, z * 0.25f);
	}
}

class ProjCameraMover : Mover
{
public:
	double normalScale;
	double fastScale;

public:
	this(Movable m)
	{
		super(m);
		this.normalScale = 0.1;
		this.fastScale = 0.6;
	}

	override void tick()
	{
		Vector3d vec = Vector3d(0, 0, 0);

		if (up) vec += Vector3d.Up;
		if (forward) vec += m.rotation.rotateHeading();
		if (backward) vec -= m.rotation.rotateHeading();

		if (left != right) {
			auto v = m.rotation.rotateLeft();
			v.scale(right ? -1 : 1);
			vec += v;
		}

		if (vec.lengthSqrd == 0.0)
			return;

		vec.normalize();

		if (speed)
			vec.scale(fastScale);
		else
			vec.scale(normalScale);

		m.position = m.position + vec;
	}
}

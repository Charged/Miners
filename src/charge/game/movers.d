// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.game.movers;

static import std.random;

import charge.util.vector;

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

	abstract void tick();
}

class IsoCameraMover : public Mover
{
public:
	int x; int z;

	this(Movable m)
	{
		super(m);
		m.position = Point3d();
	}

	void tick()
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

class ProjCameraMover : public Mover
{
public:
	this(Movable m)
	{
		super(m);
	}

	void tick()
	{
		if (forward != backward) {
			auto v = m.rotation.rotateHeading();
			v.scale(backward ? -0.1 : 0.1);
			if (speed)
				v.scale(3.0);
			m.position = m.position + v;
		}

		if (left != right) {
			auto v = m.rotation.rotateLeft();
			v.scale(right ? -0.1 : 0.1);
			if (speed)
				v.scale(3.0);
			m.position = m.position + v;
		}

		if (up) {
			auto v = Vector3d.Up;
			v.scale(0.1);
			if (speed)
				v.scale(3.0);
			m.position = m.position + v;
		}
	}
}

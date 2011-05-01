// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.math.movable;

public {
	import charge.math.point3d;
	import charge.math.quatd;
	import std.math;
}

/**
 * Base class for all movable objects
 */
class Movable
{

	final Point3d position()
	{
		Point3d p;
		getPosition(p);
		return p;
	}

	final Quatd rotation()
	{
		Quatd q;
		getRotation(q);
		return q;
	}

	final void position(Point3d pos) { setPosition(pos); }
	final void rotation(Quatd rot) { setRotation(rot); }

	this()
	{
		pos = Point3d();
		rot = Quatd();
	}

	void getPosition(out Point3d pos)
	{
		pos = this.pos;
	}

	void getRotation(out Quatd rot)
	{
		rot = this.rot;
	}

	void setPosition(ref Point3d pos)
	{
		dirty = true;
		this.pos = pos;
	}

	void setRotation(ref Quatd rot)
	{
		dirty = true;
		this.rot = rot;
	}

protected:
	Point3d pos;
	Quatd rot;
	bool dirty;
}

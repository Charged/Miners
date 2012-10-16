// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for Movable.
 */
module charge.math.movable;

public import charge.math.point3d;
public import charge.math.quatd;


/**
 * Base class for all movable objects.
 *
 * @ingroup Math
 */
class Movable
{
protected:
	Point3d pos;
	Quatd rot;
	bool dirty;

public:
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
}

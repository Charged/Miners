// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for Point3d.
 */
module charge.math.point3d;

import std.math : floor;
import std.string : format;

import charge.math.vector3d;


/**
 * Point in 3D space.
 *
 * @ingroup Math
 */
struct Point3d
{
public:
	double x, y, z;

public:
	static Point3d opCall()
	{
		return Point3d(0.0, 0.0, 0.0);
	}

	static Point3d opCall(double x, double y, double z)
	{
		Point3d p = { x, y, z };
		return p;
	}

	static Point3d opCall(Vector3d vec)
	{
		Point3d p = { vec.x, vec.y, vec.z };
		return p;
	}

	static Point3d opCall(float[3] vec)
	{
		Point3d p = { vec[0], vec[1], vec[2] };
		return p;
	}

	static Point3d opCall(float[4] vec)
	{
		Point3d p = { vec[0], vec[1], vec[2] };
		return p;
	}

	double opIndex(uint index) const
	{
		return (&x)[index];
	}

	Point3d opAdd(Vector3d vec) const
	{
		return Point3d(x + vec.x, y + vec.y, z + vec.z);
	}

	Point3d opAddAssign(Vector3d v)
	{
		x += v.x;
		y += v.y;
		z += v.z;
		return this;
	}

	Vector3d opSub(Point3d p) const
	{
		return Vector3d(x - p.x, y - p.y, z - p.z);
	}

	Point3d opSub(Vector3d v) const
	{
		return Point3d(x - v.x, y - v.y, z - v.z);
	}

	Point3d opNeg() const
	{
		return Point3d(-x, -y, -z);
	}

	Point3d opSubAssign(Vector3d v)
	{
		x -= v.x;
		y -= v.y;
		z -= v.z;
		return this;
	}

	void floor()
	{
		x = cast(double).floor(x);
		y = cast(double).floor(y);
		z = cast(double).floor(z);
	}

	Vector3d vec() const
	{
		return Vector3d(this);
	}

	string toString() const
	{
		return format("(%s, %s, %s)", x, y, z);
	}
}

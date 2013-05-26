// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for Vector3d.
 */
module charge.math.vector3d;

import std.math : sqrt, floor;
import std.string : format;

import charge.math.point3d;


/**
 * Vector in a 3D space. Charge follows the OpenGL convetion for axis
 * so Y+ is up, X+ is right and Z- is forward.
 *
 * @ingroup Math
 */
struct Vector3d
{
public:
	double x, y, z;

	const static Vector3d Up = Vector3d(0.0, 1.0, 0.0);
	const static Vector3d Heading = Vector3d(0.0, 0.0, -1.0);
	const static Vector3d Left = Vector3d(-1.0, 0.0, 0.0);

public:
	static Vector3d opCall()
	{
		return Vector3d(0.0, 0.0, 0.0);
	}

	static Vector3d opCall(double x, double y, double z)
	{
		Vector3d p = { x, y, z };
		return p;
	}

	static Vector3d opCall(Point3d pos)
	{
		Vector3d p = { pos.x, pos.y, pos.z };
		return p;
	}

	static Vector3d opCall(float[3] vec)
	{
		Vector3d p = { vec[0], vec[1], vec[2] };
		return p;
	}

	static Vector3d opCall(float[4] vec)
	{
		Vector3d p = { vec[0], vec[1], vec[2] };
		return p;
	}

	double opIndex(uint index) const
	{
		return (&x)[index];
	}

	Vector3d opAdd(Vector3d vec) const
	{
		return Vector3d(vec.x + x, vec.y + y, vec.z + z);
	}

	Vector3d opAddAssign(Vector3d vec)
	{
		x += vec.x;
		y += vec.y;
		z += vec.z;
		return this;
	}

	Vector3d opSub(Vector3d vec) const
	{
		return Vector3d(vec.x - x, vec.y - y, vec.z - z);
	}

	Vector3d opSubAssign(Vector3d vec)
	{
		x -= vec.x;
		y -= vec.y;
		z -= vec.z;
		return this;
	}

	Point3d opAdd(Point3d vec) const
	{
		return Point3d(vec.x + x, vec.y + y, vec.z + z);
	}

	Vector3d opNeg() const
	{
		Vector3d p = { -x, -y, -z };
		return p;
	}

	Vector3d opMul(Vector3d vec) const
	{
		Vector3d p = {
			y * vec.z - z * vec.y,
			z * vec.x - x * vec.z,
			x * vec.y - y * vec.x,
		};
		return p;
	}

	void scale(double v)
	{
		x *= v;
		y *= v;
		z *= v;
	}

	void floor()
	{
		x = cast(double).floor(x);
		y = cast(double).floor(y);
		z = cast(double).floor(z);
	}

	void normalize()
	{
		double l = length();

		if (l == 0.0)
			return;

		x /= l;
		y /= l;
		z /= l;
	}

	double dot(Vector3d vector) const
	{
		return x*vector.x + y*vector.y + z*vector.z;
	}

	double length() const
	{
		return sqrt(lengthSqrd());
	}

	double lengthSqrd() const
	{
		return x * x + y * y + z * z;
	}

	string toString() const
	{
		return format("(%s, %s, %s)", x, y, z);
	}
}

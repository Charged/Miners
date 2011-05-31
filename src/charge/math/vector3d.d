// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.math.vector3d;

import std.math;

import charge.math.point3d;

struct Vector3d
{
	const static Vector3d Up = Vector3d(0.0, 1.0, 0.0);
	const static Vector3d Heading = Vector3d(0.0, 0.0, -1.0);
	const static Vector3d Left = Vector3d(-1.0, 0.0, 0.0);

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

	double opIndex(uint index)
	{
		return (&x)[index];
	}

	Vector3d opAdd(Vector3d vec)
	{
		return Vector3d(vec.x + x, vec.y + y, vec.z + z);
	}

	Vector3d opAddAssign(Vector3d vec)
	{
		x += vec.x;
		y += vec.y;
		z += vec.z;
		return *this;
	}

	Vector3d opSub(Vector3d vec)
	{
		return Vector3d(vec.x - x, vec.y - y, vec.z - z);
	}

	Vector3d opSubAssign(Vector3d vec)
	{
		x -= vec.x;
		y -= vec.y;
		z -= vec.z;
		return *this;
	}

	Point3d opAdd(Point3d vec)
	{
		return Point3d(vec.x + x, vec.y + y, vec.z + z);
	}

	Vector3d opNeg()
	{
		Vector3d p = { -x, -y, -z };
		return p;
	}

	Vector3d opMul(Vector3d vec)
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

	void normalize()
	{
		double l = length();

		if (l == 0.0)
			return;

		x /= l;
		y /= l;
		z /= l;
	}

	double dot(Vector3d vector)
	{
		return x*vector.x + y*vector.y + z*vector.z;
	}

	double length()
	{
		return sqrt(lengthSqrd());
	}

	double lengthSqrd()
	{
		return x * x + y * y + z * z;
	}

	char[] toString()
	{
		return "(" ~ std.string.toString(x) ~ ", " ~ std.string.toString(y) ~ ", " ~ std.string.toString(z) ~ ")";
	}

	double x, y, z;
}

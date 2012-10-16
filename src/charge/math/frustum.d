// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for Frustum.
 */
module charge.math.frustum;

import std.math : sqrt;
import std.string : format;

import charge.math.movable;
import charge.math.matrix4x4d;


align(16): private void hidden(); /* doxygen is stupid */

/**
 * @struct charge.math.frustum.Vector3f
 * 3D Vector used by the Frustum struct.
 *
 * @ingroup Math
 */
struct Vector3f
{
	float x, y, z;
}

/**
 * Axis aligned 3D box used by the Frustum struct.
 *
 * @ingroup Math
 */
struct ABox
{
	Vector3f min;
	int pad1;
	Vector3f max;
	int pad2;
}

/**
 * 3D Plane used by the Frustum struct.
 *
 * @ingroup Math
 */
struct Planef
{
public:
	union {
		struct {
			float a, b, c, d;
		};
		struct {
			Vector3f vec;
			float vec_length;
		};
		float array[4];
	};

public:
	void normalize()
	{
		auto mag = sqrt(a * a + b * b + c * c);
		a /= mag;
		b /= mag;
		c /= mag;
		d /= mag;
	}

	bool check(ref ABox box)
	{
		Vector3f p = box.min;
		if (a > 0)
			p.x = box.max.x;
		if (b > 0)
			p.y = box.max.y;
		if (c > 0)
			p.z = box.max.z;

		auto tmp = a * p.x + b * p.y + c * p.z;
		if (tmp <= -d)
			return false;
		return true;
	}

	string toString()
	{
		return format("((%s, %s, %s), %s)", a, b, c, d);
	}
}

/**
 * Viewing frustum struct for use when doing Frustum
 * culling in the rendering pipeline.
 *
 * @see http://en.wikipedia.org/wiki/Viewing_frustum
 * @see http://en.wikipedia.org/wiki/Frustum_culling
 * @ingroup Math
 */
struct Frustum
{
public:
	Planef p[6];

	enum Planes {
		Left,
		Right,
		Top,
		Bottom,
		Far,
		Near,
	};

	alias Planes.Left Left;
	alias Planes.Right Right;
	alias Planes.Top Top;
	alias Planes.Bottom Bottom;
	alias Planes.Far Far;
	alias Planes.Near Near;

public:
	void setGLMatrix(ref Matrix4x4d mat)
	{
		p[Left].a = mat.m[0][3] + mat.m[0][0];
		p[Left].b = mat.m[1][3] + mat.m[1][0];
		p[Left].c = mat.m[2][3] + mat.m[2][0];
		p[Left].d = mat.m[3][3] + mat.m[3][0];
		p[Left].normalize();

		p[Right].a = mat.m[0][3] - mat.m[0][0];
		p[Right].b = mat.m[1][3] - mat.m[1][0];
		p[Right].c = mat.m[2][3] - mat.m[2][0];
		p[Right].d = mat.m[3][3] - mat.m[3][0];
		p[Right].normalize();

		p[Top].a = mat.m[0][3] - mat.m[0][1];
		p[Top].b = mat.m[1][3] - mat.m[1][1];
		p[Top].c = mat.m[2][3] - mat.m[2][1];
		p[Top].d = mat.m[3][3] - mat.m[3][1];
		p[Top].normalize();

		p[Bottom].a = mat.m[0][3] + mat.m[0][1];
		p[Bottom].b = mat.m[1][3] + mat.m[1][1];
		p[Bottom].c = mat.m[2][3] + mat.m[2][1];
		p[Bottom].d = mat.m[3][3] + mat.m[3][1];
		p[Bottom].normalize();

		p[Far].a = mat.m[0][3] - mat.m[0][2];
		p[Far].b = mat.m[1][3] - mat.m[1][2];
		p[Far].c = mat.m[2][3] - mat.m[2][2];
		p[Far].d = mat.m[3][3] - mat.m[3][2];
		p[Far].normalize();

		p[Near].a = mat.m[0][3] + mat.m[0][2];
		p[Near].b = mat.m[1][3] + mat.m[1][2];
		p[Near].c = mat.m[2][3] + mat.m[2][2];
		p[Near].d = mat.m[3][3] + mat.m[3][2];
		p[Near].normalize();
	}

	bool check(ref ABox b)
	{
		foreach(p; p)
			if (!p.check(b))
				return false;
		return true;
	}
}

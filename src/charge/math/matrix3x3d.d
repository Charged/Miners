// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for Matrix3x3d.
 */
module charge.math.matrix3x3d;

import charge.math.vector3d;
import charge.math.point3d;
import charge.math.quatd;


/**
 * Matrix often used for rotationtion but more commonly in Charge
 * @link charge.math.quatd.Quatd Quatd @endlink is used instead.
 *
 * @ingroup Math
 */
struct Matrix3x3d
{
public:
	union {
		double[3][3] m;
		struct {
			double a, b, c;
			double d, e, f;
			double g, h, i;
		}
	}

public:
	static Matrix3x3d opCall(Quatd q)
	{
		Matrix3x3d mat = void;
		mat = q;
		return mat;
	}

	void opAssign(Quatd q)
	{
		a = 1 - 2 * q.y * q.y - 2 * q.z * q.z;
		b =     2 * q.x * q.y - 2 * q.w * q.z;
		c =     2 * q.x * q.z + 2 * q.w * q.y;

		d =     2 * q.x * q.y + 2 * q.w * q.z;
		e = 1 - 2 * q.x * q.x - 2 * q.z * q.z;
		f =     2 * q.y * q.z - 2 * q.w * q.x;

		g =     2 * q.x * q.z - 2 * q.w * q.y;
		h =     2 * q.y * q.z + 2 * q.w * q.x;
		i = 1 - 2 * q.x * q.x - 2 * q.y * q.y;
	}

	Vector3d opMul(Vector3d v)
	{
		Vector3d result;
		result.x = v.x * m[0][0] + v.y * m[0][1] + v.z * m[0][2];
		result.y = v.x * m[1][0] + v.y * m[1][1] + v.z * m[1][2];
		result.z = v.x * m[2][0] + v.y * m[2][1] + v.z * m[2][2];
		return result;
	}

	Point3d opMul(Point3d p)
	{
		Point3d result;
		result.x = p.x * m[0][0] + p.y * m[0][1] + p.z * m[0][2];
		result.y = p.x * m[1][0] + p.y * m[1][1] + p.z * m[1][2];
		result.z = p.x * m[2][0] + p.y * m[2][1] + p.z * m[2][2];
		return result;
	}

	void inverse()
	{
		Matrix3x3d temp;

		temp.m[0][0] = m[1][1] * m[2][2] - m[1][2] * m[2][1];
		temp.m[1][0] = m[1][2] * m[2][0] - m[1][0] * m[2][2];
		temp.m[2][0] = m[1][0] * m[2][1] - m[1][1] * m[2][0];
		temp.m[0][1] = m[0][2] * m[2][1] - m[0][1] * m[2][2];
		temp.m[1][1] = m[0][0] * m[2][2] - m[0][2] * m[2][0];
		temp.m[2][1] = m[0][1] * m[2][0] - m[0][0] * m[2][1];
		temp.m[0][2] = m[0][1] * m[1][2] - m[0][2] * m[1][1];
		temp.m[1][2] = m[0][2] * m[1][0] - m[0][0] * m[1][2];
		temp.m[2][2] = m[0][0] * m[1][1] - m[0][1] * m[1][0];

		auto det = m[0][0] * temp.m[0][0] +
			   m[0][1] * temp.m[1][0] +
			   m[0][2] * temp.m[2][0];

		auto invDet = 1 / det;

		m[0][0] = temp.m[0][0] * invDet;
		m[1][0] = temp.m[1][0] * invDet;
		m[2][0] = temp.m[2][0] * invDet;
		m[0][1] = temp.m[0][1] * invDet;
		m[1][1] = temp.m[1][1] * invDet;
		m[2][1] = temp.m[2][1] * invDet;
		m[0][2] = temp.m[0][2] * invDet;
		m[1][2] = temp.m[1][2] * invDet;
		m[2][2] = temp.m[2][2] * invDet;
	}
}

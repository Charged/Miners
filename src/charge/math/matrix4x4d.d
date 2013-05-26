// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for Matrix4x4d.
 */
module charge.math.matrix4x4d;

import std.math : cos, sin, PI;
import std.string : format;

import charge.math.quatd;
import charge.math.point3d;
import charge.math.vector3d;


/**
 * Often used when interacting with OpenGL.
 *
 * @ingroup
 */
struct Matrix4x4d
{
public:
	union {
		double[4][4] m;
		double[16] array;
	};

public:
	static Matrix4x4d opCall(Point3d p, Quatd q)
	{
		Matrix4x4d ret;

		ret.m[0][0] = 1 - 2 * q.y * q.y - 2 * q.z * q.z;
		ret.m[0][1] =     2 * q.x * q.y - 2 * q.w * q.z;
		ret.m[0][2] =     2 * q.x * q.z + 2 * q.w * q.y;
		ret.m[0][3] = p.x;

		ret.m[1][0] =     2 * q.x * q.y + 2 * q.w * q.z;
		ret.m[1][1] = 1 - 2 * q.x * q.x - 2 * q.z * q.z;
		ret.m[1][2] =     2 * q.y * q.z - 2 * q.w * q.x;
		ret.m[1][3] = p.y;

		ret.m[2][0] =     2 * q.x * q.z - 2 * q.w * q.y;
		ret.m[2][1] =     2 * q.y * q.z + 2 * q.w * q.x;
		ret.m[2][2] = 1 - 2 * q.x * q.x - 2 * q.y * q.y;
		ret.m[2][3] = p.z;

		ret.m[3][0] = 0;
		ret.m[3][1] = 0;
		ret.m[3][2] = 0;
		ret.m[3][3] = 1;

		return ret;
	}

	Point3d opMul(Point3d point)
	{
		Point3d result;
		result.x = point.x * m[0][0] + point.y * m[0][1] + point.z * m[0][2] + m[0][3];
		result.y = point.x * m[1][0] + point.y * m[1][1] + point.z * m[1][2] + m[1][3];
		result.z = point.x * m[2][0] + point.y * m[2][1] + point.z * m[2][2] + m[2][3];
		//result.w = point.x * m[3][0] + point.y * m[3][1] + point.z * m[3][2] + m[3][3];
		return result;
	}

	Point3d opDiv(Point3d point)
	{
		Point3d result;
		result.x = point.x * m[0][0] + point.y * m[0][1] + point.z * m[0][2] + m[0][3];
		result.y = point.x * m[1][0] + point.y * m[1][1] + point.z * m[1][2] + m[1][3];
		result.z = point.x * m[2][0] + point.y * m[2][1] + point.z * m[2][2] + m[2][3];
		double w = point.x * m[3][0] + point.y * m[3][1] + point.z * m[3][2] + m[3][3];

		result.x /= w;
		result.y /= w;
		result.z /= w;

		return result;
	}

	Vector3d opMul(Vector3d vector)
	{
		Vector3d result;
		result.x = vector.x * m[0][0] + vector.y * m[0][1] + vector.z * m[0][2];
		result.y = vector.x * m[1][0] + vector.y * m[1][1] + vector.z * m[1][2];
		result.z = vector.x * m[2][0] + vector.y * m[2][1] + vector.z * m[2][2];
		//result.w = vector.x * m[3][0] + vector.y * m[3][1] + vector.z * m[3][2];
		return result;
	}

	void opMulAssign(ref Matrix4x4d b)
	{
		for(int i; i < 4; i++) {
			double a0 = m[i][0], a1 = m[i][1], a2 = m[i][2], a3 = m[i][3];
			m[i][0] = a0 * b.m[0][0] + a1 * b.m[1][0] + a2 * b.m[2][0] + a3 * b.m[3][0];
			m[i][1] = a0 * b.m[0][1] + a1 * b.m[1][1] + a2 * b.m[2][1] + a3 * b.m[3][1];
			m[i][2] = a0 * b.m[0][2] + a1 * b.m[1][2] + a2 * b.m[2][2] + a3 * b.m[3][2];
			m[i][3] = a0 * b.m[0][3] + a1 * b.m[1][3] + a2 * b.m[2][3] + a3 * b.m[3][3];
		}
	}

	void setToIdentity()
	{
		array[0 .. $] = 0;
		m[0][0] = 1;
		m[1][1] = 1;
		m[2][2] = 1;
		m[3][3] = 1;
	}

	/**
	 * Sets the matrix to a lookAt matrix looking at eye + rot * forward.
	 *
	 * Similar to gluLookAt.
	 */
	void setToLookFrom(Point3d eye, Quatd rot)
	{
		Point3d p;
		Quatd q;

		q.x = -rot.x;
		q.y = -rot.y;
		q.z = -rot.z;
		q.w =  rot.w;

		p.x = -eye.x;
		p.y = -eye.y;
		p.z = -eye.z;

		m[0][0] = 1 - 2 * q.y * q.y - 2 * q.z * q.z;
		m[0][1] =     2 * q.x * q.y - 2 * q.w * q.z;
		m[0][2] =     2 * q.x * q.z + 2 * q.w * q.y;
		m[0][3] = p.x * m[0][0] + p.y * m[0][1] + p.z * m[0][2];

		m[1][0] =     2 * q.x * q.y + 2 * q.w * q.z;
		m[1][1] = 1 - 2 * q.x * q.x - 2 * q.z * q.z;
		m[1][2] =     2 * q.y * q.z - 2 * q.w * q.x;
		m[1][3] = p.x * m[1][0] + p.y * m[1][1] + p.z * m[1][2];

		m[2][0] =     2 * q.x * q.z - 2 * q.w * q.y;
		m[2][1] =     2 * q.y * q.z + 2 * q.w * q.x;
		m[2][2] = 1 - 2 * q.x * q.x - 2 * q.y * q.y;
		m[2][3] = p.x * m[2][0] + p.y * m[2][1] + p.z * m[2][2];

		m[3][0] = 0;
		m[3][1] = 0;
		m[3][2] = 0;
		m[3][3] = 1;
	}

	/**
	 * Sets the matrix to the same as gluPerspective does.
	 */
	void setToPerspective(double fovy, double aspect, double near, double far)
	{
		double sine, cotangent, delta;
		double radians = fovy / 2 * PI / 180;

		delta = far - near;
		sine = sin(radians);

		if ((delta == 0) || (sine == 0) || (aspect == 0))
			return;

		cotangent = cos(radians) / sine;

		m[0][0] = cotangent / aspect;
		m[0][1] = 0;
		m[0][2] = 0;
		m[0][3] = 0;

		m[1][0] = 0;
		m[1][1] = cotangent;
		m[1][2] = 0;
		m[1][3] = 0;

		m[2][0] = 0;
		m[2][1] = 0;
		m[2][2] = -(far + near) / delta;
		m[2][3] = -2 * near * far / delta;

		m[3][0] = 0;
		m[3][1] = 0;
		m[3][2] = -1;
		m[3][3] = 0;
	}

	void transpose()
	{
		Matrix4x4d temp;

		temp.array[0] = array[ 0];
		temp.array[1] = array[ 4];
		temp.array[2] = array[ 8];
		temp.array[3] = array[12];
		temp.array[4] = array[ 1];
		temp.array[5] = array[ 5];
		temp.array[6] = array[ 9];
		temp.array[7] = array[13];
		temp.array[8] = array[ 2];
		temp.array[9] = array[ 6];
		temp.array[10] = array[10];
		temp.array[11] = array[14];
		temp.array[12] = array[ 3];
		temp.array[13] = array[ 7];
		temp.array[14] = array[11];
		temp.array[15] = array[15];

		this = temp;
	}

	void inverse()
	{
		Matrix4x4d temp;
		double fA0 = array[ 0]*array[ 5] - array[ 1]*array[ 4];
		double fA1 = array[ 0]*array[ 6] - array[ 2]*array[ 4];
		double fA2 = array[ 0]*array[ 7] - array[ 3]*array[ 4];
		double fA3 = array[ 1]*array[ 6] - array[ 2]*array[ 5];
		double fA4 = array[ 1]*array[ 7] - array[ 3]*array[ 5];
		double fA5 = array[ 2]*array[ 7] - array[ 3]*array[ 6];
		double fB0 = array[ 8]*array[13] - array[ 9]*array[12];
		double fB1 = array[ 8]*array[14] - array[10]*array[12];
		double fB2 = array[ 8]*array[15] - array[11]*array[12];
		double fB3 = array[ 9]*array[14] - array[10]*array[13];
		double fB4 = array[ 9]*array[15] - array[11]*array[13];
		double fB5 = array[10]*array[15] - array[11]*array[14];

		double fDet = fA0*fB5-fA1*fB4+fA2*fB3+fA3*fB2-fA4*fB1+fA5*fB0;

		temp.array[ 0] = + array[ 5]*fB5 - array[ 6]*fB4 + array[ 7]*fB3;
		temp.array[ 4] = - array[ 4]*fB5 + array[ 6]*fB2 - array[ 7]*fB1;
		temp.array[ 8] = + array[ 4]*fB4 - array[ 5]*fB2 + array[ 7]*fB0;
		temp.array[12] = - array[ 4]*fB3 + array[ 5]*fB1 - array[ 6]*fB0;
		temp.array[ 1] = - array[ 1]*fB5 + array[ 2]*fB4 - array[ 3]*fB3;
		temp.array[ 5] = + array[ 0]*fB5 - array[ 2]*fB2 + array[ 3]*fB1;
		temp.array[ 9] = - array[ 0]*fB4 + array[ 1]*fB2 - array[ 3]*fB0;
		temp.array[13] = + array[ 0]*fB3 - array[ 1]*fB1 + array[ 2]*fB0;
		temp.array[ 2] = + array[13]*fA5 - array[14]*fA4 + array[15]*fA3;
		temp.array[ 6] = - array[12]*fA5 + array[14]*fA2 - array[15]*fA1;
		temp.array[10] = + array[12]*fA4 - array[13]*fA2 + array[15]*fA0;
		temp.array[14] = - array[12]*fA3 + array[13]*fA1 - array[14]*fA0;
		temp.array[ 3] = - array[ 9]*fA5 + array[10]*fA4 - array[11]*fA3;
		temp.array[ 7] = + array[ 8]*fA5 - array[10]*fA2 + array[11]*fA1;
		temp.array[11] = - array[ 8]*fA4 + array[ 9]*fA2 - array[11]*fA0;
		temp.array[15] = + array[ 8]*fA3 - array[ 9]*fA1 + array[10]*fA0;

		double fInvDet = (cast(double)1.0)/fDet;

		array[ 0] = temp.array[ 0] * fInvDet;
		array[ 1] = temp.array[ 1] * fInvDet;
		array[ 2] = temp.array[ 2] * fInvDet;
		array[ 3] = temp.array[ 3] * fInvDet;
		array[ 4] = temp.array[ 4] * fInvDet;
		array[ 5] = temp.array[ 5] * fInvDet;
		array[ 6] = temp.array[ 6] * fInvDet;
		array[ 7] = temp.array[ 7] * fInvDet;
		array[ 8] = temp.array[ 8] * fInvDet;
		array[ 9] = temp.array[ 9] * fInvDet;
		array[10] = temp.array[10] * fInvDet;
		array[11] = temp.array[11] * fInvDet;
		array[12] = temp.array[12] * fInvDet;
		array[13] = temp.array[13] * fInvDet;
		array[14] = temp.array[14] * fInvDet;
		array[15] = temp.array[15] * fInvDet;
	}

	string toString()
	{
		return format("(%s, %s, %s, %s)", m[0], m[1], m[2], m[3]);
	}
}

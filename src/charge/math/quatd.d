// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.math.quatd;

import std.math : sin, cos, sqrt;
import std.string : format;

public import charge.math.vector3d;


/**
 * Representing orientations and rotations of objects in three dimensions.
 *
 * Why are using Quaternions instead of much simpler to understand euler-
 * angles, because the latter suffers from gimbal and are actually quite
 * hard to work with for anything other then very simple operations on a
 * single body.
 *
 * While the internal values inside a Quaternions are not at all easy to
 * wrap ones head around, and trying to do so can make it harder to understand
 * how to use them Quaternion.
 *
 * The best thing to see them as a representation of a rotation of a object.
 * Multiplying two together will rotate one by the other, the most important
 * thing to take away from this is that Q1 * Q2 != Q2 * Q1, this is really
 * important.
 *
 * @see http://www.cprogramming.com/tutorial/3d/quaternions.html
 * @see http://en.wikipedia.org/wiki/Gimbal_Lock
 * @see http://en.wikipedia.org/wiki/Quaternions_and_spatial_rotation
 * @see http://en.wikipedia.org/wiki/Slerp
 */
struct Quatd
{
public:
	double w, x, y, z;

public:
	/**
	 * Used when loading from a external source or when you are a math wizard.
	 */
	static Quatd opCall(double w, double x, double y, double z)
	{
		Quatd q;
		q.w = w;
		q.x = x;
		q.y = y;
		q.z = z;
		return q;
	}

	/**
	 * Unit rotation (no rotation).
	 */
	static Quatd opCall()
	{
		Quatd q = { 1.0, 0.0, 0.0, 0.0 };
		return q;
	}

	/**
	 * Convert from Euler (and Tait-Bryan) angles to Quaternion.
	 *
	 * Note in charge the Y axis is and Z points out from the screen.
	 *
	 * @arg heading, TB: yaw, Euler: rotation around the Y axis.
	 * @arg pitch, TB: pitch, Euler: rotation around the X axis.
	 * @arg roll, TB: roll, Euler: rotation around the Z axis.
	 * @see http://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
	 */
	static Quatd opCall(double heading, double pitch, double roll)
	{
		double sinPitch = sin(heading * 0.5);
		double cosPitch = cos(heading * 0.5);
		double sinYaw = sin(roll * 0.5);
		double cosYaw = cos(roll * 0.5);
		double sinRoll = sin(pitch * 0.5);
		double cosRoll = cos(pitch * 0.5);
		double cosPitchCosYaw = cosPitch * cosYaw;
		double sinPitchSinYaw = sinPitch * sinYaw;
		Quatd q;
		q.x = sinRoll * cosPitchCosYaw     - cosRoll * sinPitchSinYaw;
		q.y = cosRoll * sinPitch * cosYaw + sinRoll * cosPitch * sinYaw;
		q.z = cosRoll * cosPitch * sinYaw - sinRoll * sinPitch * cosYaw;
		q.w = cosRoll * cosPitchCosYaw     + sinRoll * sinPitchSinYaw;

		q.normalize();
		return q;
	}

	/**
	 * Construct a rotation from a Euler vector and angle.
	 *
	 * @see http://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
	 */
	static Quatd opCall(double angle, Vector3d vec)
	{
		Quatd q;

		vec.normalize();

		q.w = cos( angle * 0.5 );
		q.x = vec.x * sin( angle * 0.5 );
		q.y = vec.y * sin( angle * 0.5 );
		q.z = vec.z * sin( angle * 0.5 );

		q.normalize();
		return q;
	}

	/**
	 * Return a new quat which is this rotation rotated by the given rotation.
	 */
	Quatd opMul(Quatd quat)
	{
		Quatd result;

		result.w = w*quat.w - x*quat.x - y*quat.y - z*quat.z;
		result.x = w*quat.x + x*quat.w + y*quat.z - z*quat.y;
		result.y = w*quat.y - x*quat.z + y*quat.w + z*quat.x;
		result.z = w*quat.z + x*quat.y - y*quat.x + z*quat.w;

		return result;
	}

	/**
	 * Rotate this rotation by the given rotation.
	 */
	void opMulAssign(Quatd quat)
	{
		auto w = w*quat.w - x*quat.x - y*quat.y - z*quat.z;
		auto x = w*quat.x + x*quat.w + y*quat.z - z*quat.y;
		auto y = w*quat.y - x*quat.z + y*quat.w + z*quat.x;
		auto z = w*quat.z + x*quat.y - y*quat.x + z*quat.w;

		this.w = w;
		this.x = x;
		this.y = y;
		this.z = z;
	}

	/**
	 * Return a copy of the given vector but rotated by this rotation.
	 */
	Vector3d opMul(Vector3d vec)
	{
		Quatd q = {vec.x * x + vec.y * y + vec.z * z,
		           vec.x * w + vec.z * y - vec.y * z,
		           vec.y * w + vec.x * z - vec.z * x,
		           vec.z * w + vec.y * x - vec.x * y};

		auto v = Vector3d(w * q.x + x * q.w + y * q.z - z * q.y,
		                  w * q.y + y * q.w + z * q.x - x * q.z,
		                  w * q.z + z * q.w + x * q.y - y * q.x);

		return v;
	}

	/**
	 * Normalize the rotation, often not needed when using only the
	 * inbuilt functions.
	 */
	void normalize()
	{
		double len = length;
		if (len == 0.0)
			return;

		w /= len;
		x /= len;
		y /= len;
		z /= len;
	}

	double length()
	{
		return sqrt(w*w + x*x + y*y + z*z);
	}

	double sqrdLength()
	{
		return w*w + x*x + y*y + z*z;
	}

	/**
	 * Return a vector pointing forward but rotated by this rotation.
	 */
	Vector3d rotateHeading()
	{
		return opMul(Vector3d.Heading);
	}

	/**
	 * Return a vector pointing upwards but rotated by this rotation.
	 */
	Vector3d rotateUp()
	{
		return opMul(Vector3d.Up);
	}

	/**
	 * Return a vector pointing left but rotated by this rotation.
	 */
	Vector3d rotateLeft()
	{
		return opMul(Vector3d.Left);
	}

	string toString()
	{
		return format("(%s, %s, %s, %s)", w, x, y, z);
	}
}

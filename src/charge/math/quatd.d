// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.math.quatd;

import std.math;

public import charge.math.vector3d;

import std.string;

struct Quatd
{

	static Quatd opCall(double w, double x, double y, double z)
	{
		Quatd q;
		q.w = w;
		q.x = x;
		q.y = y;
		q.z = z;
		return q;
	}

	static Quatd opCall()
	{
		Quatd q = { 1.0, 0.0, 0.0, 0.0 };
		return q;
	}

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

	Quatd opMul(Quatd quat)
	{
		Quatd result;

		result.w = w*quat.w - x*quat.x - y*quat.y - z*quat.z;
		result.x = w*quat.x + x*quat.w + y*quat.z - z*quat.y;
		result.y = w*quat.y - x*quat.z + y*quat.w + z*quat.x;
		result.z = w*quat.z + x*quat.y - y*quat.x + z*quat.w;

		return result;
	}

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

	Vector3d rotateHeading()
	{
		return opMul(Vector3d.Heading);
	}

	Vector3d rotateUp()
	{
		return opMul(Vector3d.Up);
	}

	Vector3d rotateLeft()
	{
		return opMul(Vector3d.Left);
	}

	char[] toString()
	{
		return "(" ~ std.string.toString(w) ~ ", " ~ std.string.toString(x) ~ ", " ~ std.string.toString(y) ~ ", " ~ std.string.toString(z) ~ ")";
	}

	double w, x, y, z;
}

void test()
{
	Vector3d v = { 0.0, 1.0, 0.0 };
	auto q = Quatd(1.0, v);
}

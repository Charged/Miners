// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.gfx.camera;

import std.math : atan, asin, PI, PI_4;

import charge.math.movable;
import charge.math.matrix4x4d;
import charge.gfx.gl;
import charge.gfx.cull;
import charge.sys.logger;

abstract class Camera : public Movable
{
public:
	double near, far;

	this(double near, double far)
	{
		super();
		this.near = near;
		this.far = far;
		pos = Point3d();
		rot = Quatd();
	}

	abstract void transform();

	Cull cull()
	{
		return new Cull(this);
	}
}

class ProjCamera : public Camera
{
public:
	double fov, ratio;

	this()
	{
		this(45.0, 800.0 / 600.0, 1.0, 1000.0);
	}

	this(double fov, double ratio, double near, double far)
	{
		super(near, far);
		this.pos = Point3d();
		this.rot = Quatd();
		this.fov = fov;
		this.ratio = ratio;
	}

	void transform()
	{
		Matrix4x4d mat;

		mat.setToPerspective(fov, ratio, near, far);
		mat.transpose();

		glMatrixMode(GL_PROJECTION);
		glLoadMatrixd(mat.array.ptr);

		mat.setToLookFrom(pos, rot);
		mat.transpose();

		glMatrixMode(GL_MODELVIEW);
		glLoadMatrixd(mat.array.ptr);
	}

	Cull cull()
	{
		return new Cull(this);
	}

	void getMatrixFromGlobalToScreen(uint width, uint height, ref Matrix4x4d mat)
	{
		Matrix4x4d tmp;

		// Bias matrix to go from -1 .. 1 to width, height and 0 .. 1 depth.
		mat.array[] = [
			width / 2.0, .0,  .0,  width / 2.0,
			.0, height / 2.0, .0, height / 2.0,
			.0,    .0,   1 / 2.0,      1 / 2.0,
			.0,    .0,         0,            1
		];

		tmp.setToPerspective(fov, ratio, near, far);

		mat *= tmp;

		tmp.setToLookFrom(pos, rot);

		mat *= tmp;
	}
}

class OrthoCamera : public Camera
{
public:
	double width, height;

	this(double width, double height, double near, double far)
	{
		super(near, far);
		this.pos = Point3d();
		this.rot = Quatd();
		this.width = width;
		this.height = height;
	}

	void transform()
	{
		Matrix4x4d mat;

		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glOrtho(-width / 2, width / 2, -height / 2, height / 2, near, far);

		mat.setToLookFrom(pos, rot);
		mat.transpose();

		glMatrixMode(GL_MODELVIEW);
		glLoadMatrixd(mat.array.ptr);
	}

}

class IsoCamera : public OrthoCamera
{
protected:
	mixin Logging;

public:
	enum AngleType {
		True,
		Thirty,
		TwoToOne,
	};

	AngleType type;

	alias AngleType.True True;
	alias AngleType.Thirty Thirty;
	alias AngleType.TwoToOne TwoToOne;
	alias AngleType.Thirty Isometric;

	const angleTwoToOne = -0.463647609000806116214256231461214402028537054286120263810;

	this(double width, double height, double near, double far, AngleType type = Thirty)
	{
		super(width, height, near, far);
		setRotation(type);
	}

	void setRotation(AngleType type = Thirty)
	{
		this.type = type;
		real rot = 0.0;

		switch (type) {
		case True:
			rot = atan(sin(-PI_4));
			break;
		case Thirty:
			rot = asin(-0.5);
			break;
		case TwoToOne:
			rot = angleTwoToOne;
			break;
		default:
			assert(0);
		}

		this.rot = Quatd(PI/4, rot, 0);
	}

	void setRotation(ref Quatd rotation)
	{
		l.warn("Setting rotation on iso camera is bad!");
	}

}

// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.gfx.camera;

import charge.math.movable;
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
		auto point = pos + rot.rotateHeading();
		auto up = rot.rotateUp();

		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		gluPerspective(fov, ratio, near, far);

		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		gluLookAt(pos.x, pos.y, pos.z,
		          point.x, point.y, point.z,
		          up.x, up.y, up.z);
	}

	Cull cull()
	{
		return new Cull(this);
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
		auto point = pos + rot.rotateHeading();
		auto up = rot.rotateUp();

		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glOrtho(-width / 2, width / 2, -height / 2, height / 2, near, far);

		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		gluLookAt(pos.x, pos.y, pos.z,
		          point.x, point.y, point.z,
		          up.x, up.y, up.z);
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

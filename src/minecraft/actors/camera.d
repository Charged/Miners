// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.actors.camera;

import charge.charge;

import minecraft.world;
import minecraft.actors.sunlight;


class Camera : public GameActor
{
public:
	GfxProjCamera c;

public:
	this(World w)
	{
		super(w);
		c = new GfxProjCamera();
		c.far = SunLight.defaultFogStop;
	}

	~this()
	{
		delete c;
	}

	void setPosition(ref Point3d pos) { c.setPosition(pos); }
	void getPosition(out Point3d pos) { c.getPosition(pos); }
	void setRotation(ref Quatd rot) { c.setRotation(rot); }
	void getRotation(out Quatd rot) { c.getRotation(rot); }
}

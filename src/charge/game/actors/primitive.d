// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.game.actors.primitive;

import charge.math.point3d;
import charge.math.quatd;

static import charge.gfx.cube;
static import charge.gfx.rigidmodel;

static import charge.phy.actor;
static import charge.phy.geom;
static import charge.phy.cube;

import charge.game.world;

class Cube : public Actor, public Ticker
{
protected:
	charge.gfx.cube.Cube gfx;
	charge.phy.cube.Cube phy;

public:
	this(World w)
	{
		super(w);
		w.addTicker(this);

		gfx = new charge.gfx.cube.Cube(w.gfx);
		phy = new charge.phy.cube.Cube(w.phy, Point3d(0.0, 1.0, 0.0));

	}

	~this()
	{
		w.remTicker(this);
		delete phy;
		delete gfx;
	}

	void tick()
	{
		gfx.position = phy.position;
		gfx.rotation = phy.rotation;
	}

}

class StaticCube : public Actor
{
protected:
	charge.gfx.cube.Cube gfx;
	charge.phy.actor.Static phy;

public:
	this(World w, Point3d pos, Quatd rot)
	{
		this(w, pos, rot, 1.0, 1.0, 1.0);
	}

	this(World w, Point3d pos, Quatd rot, double x, double y, double z)
	{
		super(w);
		gfx = new charge.gfx.cube.Cube(w.gfx);
		gfx.position = pos;
		gfx.rotation = rot;
		gfx.setSize(x, y, z);

		phy = new charge.phy.actor.Static(w.phy, new charge.phy.geom.GeomCube(x, y, z));
		phy.position = pos;
		phy.rotation = rot;
	}

	~this()
	{
		delete gfx;
		delete phy;
	}

}

class StaticRigid : public Actor
{
protected:
	charge.gfx.rigidmodel.RigidModel gfx;
	charge.phy.actor.Static phy;

public:
	this(World w, Point3d pos, Quatd rot, string gfxModel, string phyModel)
	{
		super(w);

		gfx = charge.gfx.rigidmodel.RigidModel(w.gfx, gfxModel);
		gfx.position = pos;
		gfx.rotation = rot;

		phy = new charge.phy.actor.Static(w.phy, new charge.phy.geom.GeomMesh(phyModel));
		phy.position = pos;
		phy.rotation = rot;
	}

	~this()
	{
		delete gfx;
		delete phy;
	}

}

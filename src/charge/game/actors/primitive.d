// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.game.actors.primitive;

import charge.math.quatd;
import charge.math.movable;
import charge.math.point3d;

static import charge.gfx.cube;
static import charge.gfx.rigidmodel;

static import charge.phy.actor;
static import charge.phy.geom;
static import charge.phy.cube;

import charge.game.world;


class Primitive : Actor, Ticker
{
protected:
	charge.gfx.world.Actor gfx;
	charge.phy.actor.Body phy;

public:
	this(World w, Point3d pos, Quatd rot,
	     charge.gfx.world.Actor gfx,
	     charge.phy.actor.Body phy)
	{
		super(w);
		w.addTicker(this);

		this.gfx = gfx;
		this.phy = phy;

		gfx.position = pos;
		gfx.rotation = rot;

		phy.position = pos;
		phy.rotation = rot;
	}

	~this()
	{
		assert(gfx is null);
		assert(phy is null);
	}

	void breakApart()
	{
		w.remTicker(this);
		breakApartAndNull(gfx);
		breakApartAndNull(phy);
		super.breakApart();
	}

	void tick()
	{
		gfx.position = phy.position;
		gfx.rotation = phy.rotation;
	}

	void setPosition(ref Point3d pos) { phy.setPosition(pos); gfx.setPosition(pos); }
	void getPosition(out Point3d pos) { phy.getPosition(pos); }
	void setRotation(ref Quatd rot) { phy.setRotation(rot); gfx.setRotation(rot); }
	void getRotation(out Quatd rot) { phy.getRotation(rot); }
}

class Cube : Primitive
{
public:
	this(World w, Point3d pos, Quatd rot)
	{
		super(w, pos, rot,
		      new charge.gfx.cube.Cube(w.gfx),
		      new charge.phy.cube.Cube(w.phy));

		w.addTicker(this);
	}
}

class StaticCube : Actor
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
		assert(gfx is null);
		assert(phy is null);
	}

	void breakApart()
	{
		breakApartAndNull(gfx);
		breakApartAndNull(phy);
		super.breakApart();
	}
}

class StaticRigid : Actor
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

		phy = new charge.phy.actor.Static(w.phy, new charge.phy.geom.GeomMesh(w.phy.pool, phyModel));
		phy.position = pos;
		phy.rotation = rot;
	}

	~this()
	{
		assert(gfx is null);
		assert(phy is null);
	}

	void breakApart()
	{
		breakApartAndNull(gfx);
		breakApartAndNull(phy);
		super.breakApart();
	}
}

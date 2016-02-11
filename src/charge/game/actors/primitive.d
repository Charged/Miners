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

	override void breakApart()
	{
		w.remTicker(this);
		breakApartAndNull(gfx);
		breakApartAndNull(phy);
		super.breakApart();
	}

	override void tick()
	{
		gfx.position = phy.position;
		gfx.rotation = phy.rotation;
	}

	override void setPosition(ref Point3d pos) { phy.setPosition(pos); gfx.setPosition(pos); }
	override void getPosition(out Point3d pos) { phy.getPosition(pos); }
	override void setRotation(ref Quatd rot) { phy.setRotation(rot); gfx.setRotation(rot); }
	override void getRotation(out Quatd rot) { phy.getRotation(rot); }
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

class Static : Actor
{
protected:
	charge.gfx.world.Actor gfx;
	charge.phy.actor.Static phy;

public:
	this(World w, Point3d pos, Quatd rot,
	     charge.gfx.world.Actor gfx,
	     charge.phy.actor.Static phy)
	{
		super(w);

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

	override void breakApart()
	{
		breakApartAndNull(gfx);
		breakApartAndNull(phy);
		super.breakApart();
	}

	override void setPosition(ref Point3d pos) { phy.setPosition(pos); gfx.setPosition(pos); }
	override void getPosition(out Point3d pos) { phy.getPosition(pos); }
	override void setRotation(ref Quatd rot) { phy.setRotation(rot); gfx.setRotation(rot); }
	override void getRotation(out Quatd rot) { phy.getRotation(rot); }
}

class StaticCube : Static
{
public:
	this(World w, Point3d pos, Quatd rot)
	{
		this(w, pos, rot, 1.0, 1.0, 1.0);
	}

	this(World w, Point3d pos, Quatd rot, double x, double y, double z)
	{
		auto gfx = new charge.gfx.cube.Cube(w.gfx);
		gfx.setSize(x, y, z);
		auto phy = new charge.phy.actor.Static(w.phy, new charge.phy.geom.GeomCube(x, y, z));
		super(w, pos, rot, gfx, phy);
	}
}

class StaticRigid : Static
{
public:
	this(World w, Point3d pos, Quatd rot, string gfxModel, string phyModel)
	{
		super(w, pos, rot,
		      charge.gfx.rigidmodel.RigidModel(w.gfx, gfxModel),
		      new charge.phy.actor.Static(w.phy, new charge.phy.geom.GeomMesh(w.phy.pool, phyModel)));
	}
}

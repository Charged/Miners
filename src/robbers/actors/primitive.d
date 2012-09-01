// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module robbers.actors.primitive;

import charge.charge;
import robbers.world;


class FixedCube : GameActor
{
private:
	GfxCube gfx;
	PhyActor phy;

public:

	this(World w, Point3d pos, Quatd rot)
	{
		this(w, pos, rot, 1.0, 1.0, 1.0);
	}

	this(World w, Point3d pos, Quatd rot, double x, double y, double z)
	{
		super(w);
		gfx = new GfxCube(w.gfx);
		gfx.position = pos;
		gfx.rotation = rot;
		gfx.setSize(x, y, z);

		phy = new PhyStatic(w.phy, new PhyGeomCube(x, y, z));
		phy.position = pos;
		phy.rotation = rot;
	}

	~this()
	{
		delete gfx;
		delete phy;
	}

}

class FixedRigid : GameActor
{
private:
	GfxRigidModel gfx;
	PhyActor phy;

public:

	this(World w, Point3d pos, Quatd rot, char[] gfxModel, char[] phyModel)
	{
		super(w);

		gfx = GfxRigidModel(w.gfx, gfxModel);
		gfx.position = pos;
		gfx.rotation = rot;

		phy = new PhyStatic(w.phy, new PhyGeomMesh(phyModel));
		phy.position = pos;
		phy.rotation = rot;
	}

	~this()
	{
		delete gfx;
		delete phy;
	}

}

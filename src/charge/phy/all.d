// Copyright © 2013, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.phy.all;

public
{
	static import charge.phy.phy;
	static import charge.phy.actor;
	static import charge.phy.material;
	static import charge.phy.cube;
	static import charge.phy.sphere;
	static import charge.phy.car;
	static import charge.phy.world;
}

alias charge.phy.phy.phyLoaded phyLoaded;
alias charge.phy.actor.Actor PhyActor;
alias charge.phy.actor.Body PhyBody;
alias charge.phy.actor.Static PhyStatic;
alias charge.phy.material.Material PhyMaterial;
alias charge.phy.geom.Geom PhyGeom;
alias charge.phy.geom.GeomCube PhyGeomCube;
alias charge.phy.geom.GeomSphere PhyGeomSphere;
alias charge.phy.geom.GeomMesh PhyGeomMesh;
alias charge.phy.cube.Cube PhyCube;
alias charge.phy.sphere.Sphere PhySphere;
alias charge.phy.car.Car PhyCar;
alias charge.phy.world.World PhyWorld;

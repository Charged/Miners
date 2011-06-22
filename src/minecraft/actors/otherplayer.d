// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.actors.otherplayer;

import charge.charge;

import minecraft.world;
import minecraft.actors.mob;
import minecraft.actors.helper;

/**
 * Another player on the server.
 */
class OtherPlayer : public Mob
{
public:
	GfxSimpleSkeleton skel;

public:
	this(World w, int id, Point3d pos, double heading, double pitch)
	{
		super(w, id);

		auto b = ResourceStore.playerBones.dup;
		b[0].rot = Quatd(0.3, 0.2, 0);
		b[2].rot = Quatd(-1, Vector3d.Left);
		b[3].rot = Quatd(.2, Vector3d.Left);

		b[4].rot = Quatd( 1, Vector3d.Left);
		b[5].rot = Quatd(-1, Vector3d.Left);

		skel = new typeof(skel)(w.gfx, w.rs.playerSkeleton, b);

		update(pos, heading, pitch);
	}

	~this()
	{
		delete skel;
	}

	void update(Point3d pos, double heading, double pitch)
	{
		skel.position = pos;
		auto rot = Quatd(heading, pitch, 0);

		GameActor.setPosition(pos);
		GameActor.setRotation(rot);

		skel.bones.ptr[0].rot = Quatd(0, pitch, 0);
	}
}

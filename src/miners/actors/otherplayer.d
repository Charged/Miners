// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.actors.otherplayer;

import charge.charge;

import miners.world;
import miners.options;
import miners.actors.mob;


/**
 * Another player on the server.
 */
class OtherPlayer : Mob
{
public:
	GfxSimpleSkeleton skel;
	double heading;
	double pitch;

public:
	this(World w, int id, Point3d pos, double heading, double pitch)
	{
		super(w, id);

		auto b = Options.playerBones.dup;
		b[0].rot = Quatd(0.3, 0.2, 0);
		b[2].rot = Quatd(-1, Vector3d.Left);
		b[3].rot = Quatd(.2, Vector3d.Left);

		b[4].rot = Quatd( 1, Vector3d.Left);
		b[5].rot = Quatd(-1, Vector3d.Left);

		skel = new typeof(skel)(w.gfx, w.opts.playerSkeleton, b);

		update(pos, heading, pitch);
	}

	~this()
	{
		delete skel;
	}

	void update(Point3d pos, double heading, double pitch)
	{
		auto rot = Quatd(heading, pitch, 0);
		this.pos = pos;
		this.rot = rot;
		this.pitch = pitch;
		this.heading = heading;

		skel.position = pos;
		skel.rotation = Quatd(heading, 0, 0);

		skel.bones.ptr[0].rot = Quatd(0, pitch, 0);
	}

	void setPosition(ref Point3d pos)
	{
		update(pos, heading, pitch);
	}

	void setRotation(ref Quatd rot)
	{
		// NOOP
	}
}

// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module robbers.actors.gold;

static import std.random;

import charge.charge;
import robbers.world;


class Gold : GameActor
{
	this(World w, GoldSpawn gs)
	{
		super(w);

		position = gs.position;
		rotation = gs.rotation;
	}
}

class GoldManager : GameActor
{
private:
	static Vector!(GoldSpawn) spawns;

public:
	this(World w)
	{
		super(w);
	}

	static GoldSpawn random()
	{
		if (spawns.length > 0)
			return spawns[std.random.rand() % spawns.length];
		return null;
	}

	GoldSpawn newSpawn(Point3d pos, Quatd rot)
	{
		auto gs = new GoldSpawn(cast(World)w, pos, rot);
		spawns ~= gs;
		return gs;
	}
}

class GoldSpawn : GameActor
{
protected:
	this(World w, Point3d pos, Quatd rot)
	{
		super(w);

		this.pos = pos;
		this.rot = rot;
	}

}

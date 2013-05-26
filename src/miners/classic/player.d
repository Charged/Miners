// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.otherplayer;

import charge.charge;

import miners.world;
import miners.importer.network;
import miners.actors.otherplayer;


class ClassicPlayer : OtherPlayer, GameTicker
{
public:
	char[] name;
	GfxDynamicTexture text;
	Point3d curPos;
	int ticks;

	/// fCraft likes to hide players far away.
	bool isHidden;


public:
	this(World w, int id, char[] name, Point3d pos, double heading, double pitch)
	{
		this.name = name;
		this.curPos = pos;
		super(w, id, pos, heading, pitch);

		w.addTicker(this);

		if (text is null) {
			text = GfxDynamicTexture();
			w.opts.classicFont().render(text, name);
		}

		if (name !is null) {
			auto t = w.opts.getSkin(removeColorTags(name));
			skel.getMaterial().setTexture("tex", t);
		}
	}

	void breakApart()
	{
		w.remTicker(this);
		sysReference(&text, null);
		super.breakApart();
	}

	void update(Point3d pos, double heading, double pitch)
	{
		this.heading = heading;
		this.pitch = pitch;
		this.pos = pos;

		vel = (this.pos - curPos);
		vel.scale(0.2);
		ticks = 4;
	}

	void tick()
	{
		if (ticks > -1) {
			auto vel = this.vel;
			vel.scale(ticks);

			auto tmp = this.pos;

			curPos = this.pos - vel;
			super.update(curPos, heading, pitch);

			this.pos = tmp;

			ticks--;
		}
	}
}

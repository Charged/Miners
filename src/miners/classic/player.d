// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.player;

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
	double curHeading, curPitch;
	double diffHeading, diffPitch;
	int ticks;

	/// fCraft likes to hide players far away.
	bool isHidden;


public:
	this(World w, int id, char[] name, Point3d pos, double heading, double pitch)
	{
		this.name = name;
		this.curPos = pos;
		this.curHeading = heading;
		this.curPitch = pitch;
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

		diffHeading = this.heading - curHeading;
		diffHeading *= 0.2;

		diffPitch = this.pitch - curPitch;
		diffPitch *= 0.2;

		ticks = 4;
	}

	void tick()
	{
		if (ticks > -1) {
			auto vel = this.vel;
			vel.scale(ticks);

			auto savePos = this.pos;
			auto saveHeading = this.heading;
			auto savePitch = this.pitch;

			curPos = this.pos - vel;
			curHeading = this.heading - (diffHeading * ticks);
			curPitch = this.pitch - (diffPitch * ticks);

			super.update(curPos, curHeading, curPitch);

			this.pos = savePos;
			this.heading = saveHeading;
			this.pitch = savePitch;

			ticks--;
		}
	}
}

// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.player;

import charge.charge;

import miners.world;
import miners.importer.network;
import miners.actors.otherplayer;

import std.math;
import std.stdio;


class ClassicPlayer : OtherPlayer, GameTicker
{
public:
	string name;
	GfxDynamicTexture text;
	Point3d curPos;
	double curHeading, curPitch;
	double diffHeading, diffPitch;
	bool moving;
	int ticks;
	int idleTicks;
	int animTicks;
	int resetTicks;

	Vector3d diffBone2;
	Vector3d diffBone3;
	Vector3d diffBone4;
	Vector3d diffBone5;

	/// fCraft likes to hide players far away.
	bool isHidden;


public:
	this(World w, int id, string name, Point3d pos, double heading, double pitch)
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

	override void breakApart()
	{
		w.remTicker(this);
		sysReference(&text, null);
		super.breakApart();
	}

	override void update(Point3d pos, double heading, double pitch)
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

	override void tick()
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

			if (vel.x || vel.z)
				idleTicks = 0;
		}

		if (ticks < 0 || (!vel.x && !vel.z)) {
			idleTicks = (idleTicks < 16) ? idleTicks + 1 : idleTicks;
		}

		if (idleTicks < 15) {
			animTicks++;

			skel.bones.ptr[2].rot = Quatd(0, cos(animTicks * 0.18f * 0.6662f + 3.141593f) * 2.0f * 0.5f, 0);
			skel.bones.ptr[3].rot = Quatd(0, cos(animTicks * 0.18f * 0.6662f) * 2.0f * 0.5f, 0);
			skel.bones.ptr[4].rot = Quatd(0, cos(animTicks * 0.18f * 0.6662f) * 2.0f * 0.5f, 0);
			skel.bones.ptr[5].rot = Quatd(0, cos(animTicks * 0.18f * 0.6662f + 3.141593f) * 2.0f * 0.5f, 0);
		} else if (idleTicks == 15) {
			animTicks = 0;
			resetTicks = 19;
			
			diffBone2 = Vector3d(0, cos(animTicks * 0.18f * 0.6662f + 3.141593f) * 2.0f * 0.5f, 0);
			diffBone3 = Vector3d(0, cos(animTicks * 0.18f * 0.6662f) * 2.0f * 0.5f, 0);
			diffBone4 = Vector3d(0, cos(animTicks * 0.18f * 0.6662f) * 2.0f * 0.5f, 0);
			diffBone5 = Vector3d(0, cos(animTicks * 0.18f * 0.6662f + 3.141593f) * 2.0f * 0.5f, 0);

			diffBone2.scale(-0.05);
			diffBone3.scale(-0.05);
			diffBone4.scale(-0.05);
			diffBone5.scale(-0.05);
		} else if (resetTicks > -1) {
			auto tmp2 = diffBone2;
			auto tmp3 = diffBone3;
			auto tmp4 = diffBone4;
			auto tmp5 = diffBone5;

			tmp2.scale(resetTicks);
			tmp3.scale(resetTicks);
			tmp4.scale(resetTicks);
			tmp5.scale(resetTicks);

			skel.bones.ptr[2].rot = Quatd(tmp2.x, tmp2.y, tmp2.z);
			skel.bones.ptr[3].rot = Quatd(tmp3.x, tmp3.y, tmp3.z);
			skel.bones.ptr[4].rot = Quatd(tmp4.x, tmp4.y, tmp4.z);
			skel.bones.ptr[5].rot = Quatd(tmp5.x, tmp5.y, tmp5.z);

			resetTicks--;
		}
	}
}

// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.classic.otherplayer;

import charge.charge;

import miners.world;
import miners.importer.network;
import actors = miners.actors.otherplayer;


class OtherPlayer : actors.OtherPlayer
{
public:
	char[] name;
	GfxDynamicTexture text;

	/// fCraft likes to hide players far away.
	bool isHidden;


public:
	this(World w, int id, char[] name, Point3d pos, double heading, double pitch)
	{
		this.name = name;
		super(w, id, pos, heading, pitch);

		if (text is null) {
			text = new GfxDynamicTexture(null);
			w.opts.classicFont().render(text, name);
		}

		if (name !is null) {
			auto t = w.opts.getSkin(removeColorTags(name));
			skel.getMaterial().setTexture("tex", t);
		}
	}

	~this()
	{
		sysReference(&text, null);
	}
}

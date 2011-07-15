// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.actors.sunlight;

import charge.charge;

import minecraft.world;


/**
 * Represents the minecraft sun light, also controls the fog.
 */
class SunLight : public GameActor
{
public:
	GfxSimpleLight gfx;
	GfxFog fog;

	const defaultFogStart = 150;
	const defaultFogStop = 250;
	const defaultFogColor = Color4f(89.0/255, 178.0/255, 220.0/255);

public:
	this(World w)
	{
		super(w);
		gfx = new GfxSimpleLight();
		w.gfx.add(gfx);

		fog = new GfxFog();
		w.gfx.fog = fog;

		fog.start = defaultFogStart;
		fog.stop = defaultFogStop;
		fog.color = defaultFogColor;

		w.opts.shadow ~= &shadow;
		shadow = w.opts.shadow();
	}

	~this()
	{
		w.gfx.remove(gfx);
		w.gfx.fog = null;

		delete gfx;
		delete fog;
	}

	final void shadow(bool shadow)
	{
		gfx.shadow = shadow;
	}

	final bool shadow()
	{
		return gfx.shadow;
	}

	void setPosition(ref Point3d pos) { gfx.setPosition(pos); }
	void getPosition(out Point3d pos) { gfx.getPosition(pos); }
	void setRotation(ref Quatd rot) { gfx.setRotation(rot); }
	void getRotation(out Quatd rot) { gfx.getRotation(rot); }
}

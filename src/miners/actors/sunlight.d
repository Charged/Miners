// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.actors.sunlight;

import charge.charge;

import miners.world;


/**
 * Represents the minecraft sun light, also controls the fog.
 */
class SunLight : GameActor
{
public:
	GfxSimpleLight gfx;
	GfxFog fog;
	double _procent;

	const defaultFogProcent = 0.35;
	const defaultFogColor = Color4f(89.0/255, 178.0/255, 220.0/255);

public:
	this(World w)
	{
		super(w);
		gfx = new GfxSimpleLight(w.gfx);

		fog = new GfxFog();
		fog.stop = w.opts.viewDistance();
		fog.color = defaultFogColor;
		procent = defaultFogProcent;

		w.gfx.fog = w.opts.fog() ? fog : null;

		shadow = w.opts.shadow();

		w.opts.fog ~= &setFog;
		w.opts.shadow ~= &shadow;
		w.opts.viewDistance ~= &setViewDistance;
	}

	~this()
	{
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

	final void procent(double p)
	{
		_procent = p;
		fog.start = fog.stop - fog.stop * p;
	}

	final double procent()
	{
		return _procent;
	}

	void setPosition(ref Point3d pos) { gfx.setPosition(pos); }
	void getPosition(out Point3d pos) { gfx.getPosition(pos); }
	void setRotation(ref Quatd rot) { gfx.setRotation(rot); }
	void getRotation(out Quatd rot) { gfx.getRotation(rot); }

private:
	void setViewDistance(double dist)
	{
		fog.stop = dist;
		procent = _procent;
	}

	void setFog(bool b)
	{
		w.gfx.fog = b ? fog : null;
	}

}

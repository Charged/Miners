// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.gfx.manager;

import charge.charge;

import miners.types;
import miners.gfx.renderer;


/**
 * Class for managing the different renderers.
 */
class RenderManager
{
public:
	GfxDefaultTarget defaultTarget;
	GfxDoubleTarget dt;

	GfxRenderer r; // Current renderer
	GfxRenderer ifr; // Inbuilt forward renderer
	MinecraftDeferredRenderer mdr; // Special deferred renderer
	MinecraftForwardRenderer mfr; // Special forward renderer
	GfxRenderer[5] rs; // Null terminated list of renderer
	TerrainBuildTypes[5] rsbt; // A list of build types for the renderers
	string[5] rss; // List of renderer names
	TerrainBuildTypes bt; // Current build type
	string s; // Current name of renderer
	int num_renderers;
	int current_renderer;

	bool failsafe;

	bool canDoForward;
	bool canDoDeferred;
	bool textureArray; /**< Is the texture array version of the terrain needed */

	bool aa;

private:
	mixin SysLogging;

public:
	this(bool failsafe)
	{
		this.failsafe = failsafe;

		canDoForward = MinecraftForwardRenderer.check();
		canDoDeferred = MinecraftDeferredRenderer.check();

		if (!canDoForward && !canDoDeferred)
			throw new Exception("Can not run any renderer!");

		defaultTarget = GfxDefaultTarget();
		setupRenderers();

		// We might end up in a really weird state where we
		// support deferred but not forward, but that is not likely.
		textureArray = canDoDeferred || (!failsafe && canDoForward &&
		               mfr.textureArraySupported);
		// Need to propegate this back.
		if (mfr !is null && mfr.textureArraySupported)
			mfr.textureArraySupported = textureArray;

		// Try to set AA.
		setAa(true);
	}

	~this()
	{
		//delete ifr;
		//delete mfr;
		//delete mdr;
	}

	void switchRenderer()
	{
		current_renderer++;
		if (current_renderer >= num_renderers)
			current_renderer = 0;

		r = rs[current_renderer];
		s = rss[current_renderer];
		bt = rsbt[current_renderer];
	}

	void render(GfxWorld w, GfxCamera c)
	{
		render(w, c, defaultTarget);
	}

	void render(GfxWorld w, GfxCamera c, GfxRenderTarget rt)
	{
		if (aa && (dt is null || rt.width != dt.width/2 || rt.height != dt.height/2))
			dt = new GfxDoubleTarget(rt.width, rt.height);

		r.target = aa ? cast(GfxRenderTarget)dt : cast(GfxRenderTarget)rt;

		r.render(c, w);

		if (aa)
			dt.resolve(rt);

	}

	final void setAa(bool aa)
	{
		this.aa = !failsafe && aa && GfxDoubleTarget.check;
	}

protected:
	void setupRenderers()
	{
		GfxRenderer.init();

		if (canDoForward) {
			try {
				mfr = new MinecraftForwardRenderer();
				rsbt[num_renderers] = TerrainBuildTypes.CompactMesh;
				rss[num_renderers]  = "Adv. Forward";
				rs[num_renderers++] = mfr;
			} catch (Exception e) {
				canDoForward = false;
				l.warn("No fancy renderer \"%s\"", e);
			}
		}

		if (canDoDeferred) {
			try {
				if (failsafe)
					throw new Exception("Failsafe mode");

				MinecraftDeferredRenderer.init();

				mdr = new MinecraftDeferredRenderer();
				rsbt[num_renderers] = TerrainBuildTypes.CompactMesh;
				rss[num_renderers]  = "Adv. Deferred";
				rs[num_renderers++] = mdr;
			} catch (Exception e) {
				canDoDeferred = false;
				l.warn("No fancy renderer \"%s\"", e);
			}
		}

		// Pick the most advanced renderer
		current_renderer = num_renderers - 1;
		r = rs[current_renderer];
		s = rss[current_renderer];
		bt = rsbt[current_renderer];
	}
}

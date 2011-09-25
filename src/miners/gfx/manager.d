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
	GfxRenderer ifc; // Inbuilt fixed func
	GfxRenderer ifr; // Inbuilt forward renderer
	MinecraftDeferredRenderer mdr; // Special deferred renderer
	MinecraftForwardRenderer mfr; // Special forward renderer
	GfxRenderer rs[5]; // Null terminated list of renderer
	TerrainBuildTypes rsbt[5]; // A list of build types for the renderers
	char rss[5][]; // List of renderer names
	TerrainBuildTypes bt; // Current build type
	char[] s; // Current name of renderer
	int num_renderers;
	int current_renderer;

	bool canDoForward;
	bool canDoDeferred;
	bool textureArray; /**< Is the texture array version of the terrain needed */

	bool aa;

private:
	mixin SysLogging;

public:
	this()
	{
		auto sanity = GfxFixedRenderer.check();
		canDoForward = MinecraftForwardRenderer.check();
		canDoDeferred = MinecraftDeferredRenderer.check();

		if (!sanity && !canDoForward && !canDoDeferred)
			throw new Exception("Can not run any renderer!");

		defaultTarget = GfxDefaultTarget();
		setupRenderers();

		textureArray = mfr.textureArraySupported && (canDoForward || canDoDeferred);

		aa = true;
	}

	~this()
	{
		delete ifc;
		delete ifr;
		delete mfr;
		delete mdr;
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
		this.aa = aa;
	}

protected:
	void setupRenderers()
	{
		GfxRenderer.init();
		ifc = new GfxFixedRenderer();
		rsbt[num_renderers] = TerrainBuildTypes.RigidMesh;
		rss[num_renderers]  = "Fixed";
		rs[num_renderers++] = ifc;

		if (canDoForward) {
			ifr = new GfxForwardRenderer();
			rsbt[num_renderers] = TerrainBuildTypes.RigidMesh;
			rss[num_renderers]  = "Forward";
			rs[num_renderers++] = ifr;
		}

		if (canDoForward) {
			try {
				mfr = new MinecraftForwardRenderer();
				rsbt[num_renderers] = TerrainBuildTypes.CompactMesh;
				rss[num_renderers]  = "Adv. Forward";
				rs[num_renderers++] = mfr;
			} catch (Exception e) {
				l.warn("No fancy renderer \"%s\"", e);
			}
		}

		if (canDoDeferred) {
			try {
				MinecraftDeferredRenderer.init();

				mdr = new MinecraftDeferredRenderer();
				rsbt[num_renderers] = TerrainBuildTypes.CompactMesh;
				rss[num_renderers]  = "Adv. Deferred";
				rs[num_renderers++] = mdr;
			} catch (Exception e) {
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

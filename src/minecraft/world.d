// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.world;

import std.math;

import charge.charge;
import charge.platform.homefolder;

import minecraft.terrain.data;
import minecraft.terrain.beta;
import minecraft.terrain.chunk;
import minecraft.terrain.common;
import minecraft.actors.helper;
import minecraft.importer.info;

abstract class World : public GameWorld
{
public:
	RenderManager rm; /** Shared with other worlds */
	ResourceStore rs; /** Shared with other worlds */
	Terrain t;
	Point3d spawn;

private:
	mixin SysLogging;

public:
	this(RenderManager rm, ResourceStore rs)
	{
		super();
		this.rm = rm;
		this.rs = rs;
	}

	~this()
	{
		delete t;
	}

	void switchRenderer()
	{
		rm.switchRenderer();
		t.setBuildType(rm.bt);
	}

protected:

}

class BetaWorld : public World
{
public:
	BetaTerrain bt;
	char[] dir;

public:
	this(MinecraftLevelInfo *info, RenderManager rm, ResourceStore rs)
	{
		this.spawn = info ? info.spawn : Point3d(0, 64, 0);
		this.dir = info ? info.dir : null;
		super(rm, rs);

		bt = new BetaTerrain(this, dir, rs);
		t = bt;
		t.buildIndexed = MinecraftForwardRenderer.textureArraySupported;
		t.setBuildType(rm.bt);

		// Find the actuall spawn height
		auto x = cast(int)spawn.x;
		auto y = cast(int)spawn.y;
		auto z = cast(int)spawn.z;
		auto xPos = x < 0 ? (x - 15) / 16 : x / 16;
		auto zPos = z < 0 ? (z - 15) / 16 : z / 16;

		bt.setCenter(xPos, zPos);
		bt.loadChunk(xPos, zPos);

		auto p = bt.getPointerY(x, z);
		for (int i = y; i < 128; i++) {
			if (tile[p[i]].filled)
				continue;
			if (tile[p[i+1]].filled)
				continue;

			spawn.y = i;
			break;
		}
	}
}


import minecraft.gfx.renderer;

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
	BetaTerrain.BuildTypes rsbt[5]; // A list of build types for the renderers
	BetaTerrain.BuildTypes bt; // Current build type
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
		canDoForward = MinecraftForwardRenderer.check();
		canDoDeferred = MinecraftDeferredRenderer.check();

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

protected:
	void setupRenderers()
	{
		GfxRenderer.init();
		ifc = new GfxFixedRenderer();
		rsbt[num_renderers] = BetaTerrain.BuildTypes.RigidMesh;
		rs[num_renderers++] = ifc;

		if (canDoForward) {
			ifr = new GfxForwardRenderer();
			rsbt[num_renderers] = BetaTerrain.BuildTypes.RigidMesh;
			rs[num_renderers++] = ifr;
		}

		if (canDoForward) {
			try {
				mfr = new MinecraftForwardRenderer();
				rsbt[num_renderers] = BetaTerrain.BuildTypes.CompactMesh;
				rs[num_renderers++] = mfr;
			} catch (Exception e) {
				l.warn("No fancy renderer \"%s\"", e);
			}
		}

		if (canDoDeferred) {
			try {
				MinecraftDeferredRenderer.init();

				mdr = new MinecraftDeferredRenderer();
				rsbt[num_renderers] = BetaTerrain.BuildTypes.CompactMesh;
				rs[num_renderers++] = mdr;
			} catch (Exception e) {
				l.warn("No fancy renderer \"%s\"", e);
			}
		}

		// Pick the most advanced renderer
		current_renderer = num_renderers - 1;
		r = rs[current_renderer];
		bt = rsbt[current_renderer];
	}
}

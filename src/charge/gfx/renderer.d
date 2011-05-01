// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.gfx.renderer;

import std.math;
import std.stdio;
static import std.string;

import charge.math.color;
import charge.math.point3d;
import charge.math.vector3d;
import charge.math.matrix4x4d;
import charge.sys.logger;
import charge.gfx.light;
import charge.gfx.camera;
import charge.gfx.cull;
import charge.gfx.renderqueue;
import charge.gfx.deferred;
import charge.gfx.fixed;
import charge.gfx.target;
import charge.gfx.shader;
import charge.gfx.texture;
import charge.gfx.material;
import charge.gfx.world;
import charge.gfx.zone;

public abstract class Renderer
{
private:
	//mixin Logging;

protected:
	RenderTarget renderTarget;
	static bool deferred;
	static bool initilized;
	static bool fixed;

public:
	static void init()
	{
		deferred = DeferredRenderer.init();
		fixed = FixedRenderer.init();

		initilized = true;
	}

	this()
	{
		if (!initilized)
			throw new Exception("Rendering system not initalized");
	}

	static Renderer create()
	{
		if (deferred)
			return new DeferredRenderer();
		else
			return new FixedRenderer();
	}

	RenderTarget target()
	{
		return renderTarget;
	}

	void target(RenderTarget rt)
	{
		renderTarget = rt;
	}

	void render(Camera c, World w)
	{
		auto rq = new RenderQueue();
		Cull cull;
		Zone z;

		c.transform();
		cull = c.cull();

		foreach(a; w.actors)
		{
			a.build();
			a.cullAndPush(cull, rq);
		}

		render(c, rq, w);
	}

protected:
	abstract void render(Camera c, RenderQueue rq, World w);
}

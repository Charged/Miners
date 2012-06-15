// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.background;

import charge.charge;

import miners.types;
import miners.runner;
import miners.options;
import miners.interfaces;


/**
 * Base class for all Background runners.
 *
 * Only used to display something when nothing is being runned.
 */
abstract class BackgroundRunner : public Runner
{
protected:
	Router router;

	GfxDraw d;

public:
	this(Router r)
	{
		this.router = r;

		d = new GfxDraw();
	}

	bool build()
	{
		return false;
	}

	abstract void close();

	abstract void render(GfxRenderTarget rt);
	void logic() {}
	void assumeControl() {}
	void dropControl() {}
	void resize(uint w, uint h) {}
}

/**
 * Used during startup before all resources are found.
 */
class SafeBackgroundRunner : public BackgroundRunner
{
public:
	this(Router r)
	{
		super(r);
	}

	void close() {}

	void render(GfxRenderTarget rt)
	{
		d.target = rt;
		d.start();
		d.fill(Color4f.Black, false, 0, 0, rt.width, rt.height);
		d.stop();
	}
}

/**
 * Used after startup has completed.
 */
class DirtBackgroundRunner : public BackgroundRunner
{
private:
	Options opts;

	GfxTexture dirt;

public:
	this(Router r, Options opts)
	{
		this.opts = opts;
		super(r);
		sysReference(&dirt, opts.dirt());
	}

	void close()
	{
		sysReference(&dirt, null);
	}

	void render(GfxRenderTarget rt)
	{
		d.target = rt;
		d.start();

		d.blit(dirt, Color4f.White, false,
		       0, 0, rt.width / 2, rt.height / 2,
		       0, 0, rt.width, rt.height);

		d.stop();
	}
}

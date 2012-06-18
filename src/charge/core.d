// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.core;


import charge.sys.properties;


enum coreFlag
{
	CTL  = (1 << 0),
	GFX  = (1 << 1),
	SFX  = (1 << 2),
	NET  = (1 << 3),
	PHY  = (1 << 4),
	AUTO = (1 << 5),
}

/**
 * Get a new core created with the given flags.
 */
extern(C) Core chargeCore(coreFlag flags);

/**
 * Signal a quit a condition, this function mearly pushes
 * a quit event on the event queue and then returns.
 */
extern(C) void chargeQuit();


abstract class Core
{
public:
	const int defaultWidth = 800;
	const int defaultHeight = 600;
	const bool defaultFullscreen = false;
	const bool defaultFullscreenAutoSize = true;
	const char[] defaultTitle = "Charged Miners";
	const bool defaultForceResizeEnable = false;

	coreFlag flags;
	bool resizeSupported;

public:
	static Core opCall()
	{
		assert(instance !is null);
		return instance;
	}

	static Core opCall(coreFlag flags)
	{
		assert(flags != 0);

		instance = chargeCore(flags);
		return instance;
	}

	abstract void close();


	/*
	 *
	 * Misc
	 *
	 */


	abstract void resize(uint w, uint h);
	abstract void resize(uint w, uint h, bool fullscreen);
	abstract void size(out uint w, out uint h, out bool fullscreen);

	abstract void screenShot();

	abstract Properties properties();

protected:
	this(coreFlag flags)
	{
		this.flags = flags;
	}

private:
	static Core instance;
}

// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file containing Core and CoreOptions.
 */
module charge.core;

import charge.util.properties;


/**
 * Enum for selecting subsystems.
 */
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
extern(C) Core chargeCore(CoreOptions opts);

/**
 * Signal a quit a condition, this function mearly pushes
 * a quit event on the event queue and then returns.
 */
extern(C) void chargeQuit();

/**
 * Options at initialization.
 */
class CoreOptions
{
public:
	string title;
	coreFlag flags;

public:
	this()
	{
		this.flags = coreFlag.AUTO;
		this.title = Core.defaultTitle;
	}
}

/**
 * Class holding the entire thing together.
 */
abstract class Core
{
public:
	const int defaultWidth = 800;
	const int defaultHeight = 600;
	const bool defaultFullscreen = false;
	const bool defaultFullscreenAutoSize = true;
	const string defaultTitle = "Charge Game Engine";
	const bool defaultForceResizeEnable = false;

	coreFlag flags;
	bool resizeSupported;


protected:
	static void function()[] initFuncs;
	static void function()[] closeFuncs;


private:
	static Core instance;


public:
	static Core opCall()
	{
		assert(instance !is null);
		return instance;
	}

	static Core opCall(CoreOptions opts)
	in {
		assert(opts !is null);
		assert(instance is null);
		assert(opts.flags != 0);
		assert(opts.title !is null);
	}
	body {
		return chargeCore(opts);
	}

	/**
	 * Shutsdown everything, make sure you have freed all resources before
	 * calling this function. It is not supported to initialize Core again
	 * after a call to this function.
	 */
	abstract void close();

	/**
	 * Initialize a subsystem. Only a single subsystem can be initialized
	 * a time. Will throw Exception upon failure.
	 *
	 * XXX: Most Cores are bit picky when it comes which subsystems can be
	 * initialized after a general initialization, generally speaking
	 * SFX and PHY should always work.
	 */
	abstract void initSubSystem(coreFlag flags);

	/**
	 * These functions are run just after Core is initialize and
	 * right before Core is closed.
	 */
	static void addInitAndCloseRunners(void function() init, void function() close)
	{
		if (init !is null)
			initFuncs ~= init;

		if (close !is null)
			closeFuncs ~= close;
	}

	/**
	 * Display a panic message, usually a dialogue box, then
	 * calls exit(-1), so this function does not return.
	 */
	abstract void panic(string message);


	/*
	 *
	 * Misc
	 *
	 */


	/**
	 * Returns text from the clipboard, should any be in it.
	 */
	abstract string getClipboardText();

	abstract void resize(uint w, uint h);
	abstract void resize(uint w, uint h, bool fullscreen);
	abstract void size(out uint w, out uint h, out bool fullscreen);

	abstract void screenShot();

	abstract Properties properties();


protected:
	this(coreFlag flags)
	{
		this.flags = flags;
		instance = this;
	}
}

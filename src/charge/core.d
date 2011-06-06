// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.core;

extern(C) Core chargeCore();

abstract class Core
{
public:
	const int defaultWidth = 800;
	const int defaultHeight = 600;
	const bool defaultFullscreen = false;
	const char[] defaultTitle = "Charged Miners";

	bool resizeSupported;

public:
	static Core opCall()
	{
		return chargeCore();
	}

	abstract bool init();
	abstract bool close();


	/*
	 *
	 * Misc
	 *
	 */


	abstract void resize(uint w, uint h);
	abstract void resize(uint w, uint h, bool fullscreen);

	abstract void screenShot();
}

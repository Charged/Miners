// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.background;

import charge.charge;

import miners.types;
import miners.options;


/**
 * Used during and after startup has completed. Deals with not all resources
 * being available found via the initOptions function.
 */
class BackgroundScene : GameBackgroundScene
{
private:
	Options opts;

	GfxTexture background;

public:
	this(Options opts)
	{
		super();
		this.opts = opts;

		opts.background ~= &newBackground;
		opts.backgroundTiled ~= &changeOption;
		opts.backgroundDoubled ~= &changeOption;

		newBackground(opts.background());
		changeOption(opts.backgroundDoubled());
	}

	override void close()
	{
		opts.background -= &newBackground;
		opts.backgroundTiled -= &changeOption;
		opts.backgroundDoubled -= &changeOption;

		super.close();
	}

	void changeOption(bool)
	{
		bool tiled = opts.backgroundTiled();
		bool doubled = opts.backgroundDoubled();

		if (tiled)
			mode = doubled ? Mode.TiledDoubled : Mode.TiledCenterSeem;
		else
			mode = doubled ? Mode.CenterDoubled : Mode.Center;
	}
}

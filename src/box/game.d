// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module box.game;

import charge.charge;


/**
 * Main hub of the box game.
 */
class Game : GameRouterApp
{
private:
	mixin SysLogging;


public:
	this(string[] args)
	{
		/* This will initalize Core and other important things */
		auto opts = new CoreOptions();
		opts.title = "Box";
		opts.flags = coreFlag.PHY;
		super(opts);

		push(new ServerRunner(this));
	}

	void close()
	{
		super.close();
	}
}

/**
 * Server runner.
 */
class ServerRunner : GameRunner
{
public:
	GameRouter r;


public:
	this(GameRouter r)
	{
		super(GameRunner.Type.Game);
		this.r = r;
	}

	void close()
	{

	}

	void logic()
	{

	}

	void assumeControl()
	{

	}

	void dropControl()
	{

	}

	void render(GfxRenderTarget rt) { assert(false); }
}

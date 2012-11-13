// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module box.game;

import charge.charge;
import charge.game.actors.primitive;


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
		opts.flags = coreFlag.AUTO;
		super(opts);

		push(new ClientRunner(this));
	}

	void close()
	{
		super.close();
	}
}

/**
 * Box World.
 */
class World : GameWorld
{
	this()
	{
		super(SysPool());
	}
}

/**
 * Client runner.
 */
class ClientRunner : GameRunner
{
public:
	World w;

	GameRouter r;
	GfxRenderer renderer;
	GfxCamera cam;
	GfxSimpleLight light;

	CtlKeyboard keyboard;
	CtlMouse mouse;


public:
	this(GameRouter r)
	{
		super(GameRunner.Type.Game);
		this.r = r;

		keyboard = CtlInput().keyboard;
		mouse = CtlInput().mouse;

		w = new World();
		cam = new GfxProjCamera();
		light = new GfxSimpleLight(w.gfx);
		renderer = GfxRenderer.create();

		assert(w !is null);
		assert(w.gfx !is null);
		assert(w.phy !is null);

		new GameStaticCube(w, Point3d(0.0, -5.0, 0.0), Quatd(), 200.0, 10.0, 200.0);

		auto c = new Cube(w);
		c.position = Point3d(0, 10, 0);

		c = new Cube(w);
		c.position = Point3d(.3, 16, .4);

		light.rotation = Quatd(45, -40, 0);
		cam.position = Point3d(0, 5, 20);
		cam.rotation = Quatd();
	}

	void close()
	{
		breakApartAndNull(w);
		breakApartAndNull(cam);
	}

	void logic()
	{
		w.tick();
	}

	void render(GfxRenderTarget rt)
	{
		renderer.target = rt;
		renderer.render(cam, w.gfx);
	}

	void assumeControl()
	{
		keyboard.down ~= &this.keyDown;
	}

	void dropControl()
	{
		keyboard.down -= &this.keyDown;
	}


protected:
	void keyDown(CtlKeyboard kb, int sym, dchar unicode, char[] str)
	{
		if (sym == 27)
			r.quit();
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

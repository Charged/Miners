// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module box.game;

import std.stdio : writefln;
import std.math : PI;
import charge.charge;
import charge.game.actors.primitive;


/**
 * Main hub of the box game.
 */
class Game : GameRouterApp
{
private:
	mixin SysLogging;

	bool server;
	string address = "localhost";
	ushort port = 21337;

public:
	this(string[] args)
	{
		parseArgs(args);

		/* This will initalize Core and other important things */
		auto opts = new CoreOptions();
		opts.title = "Box";
		opts.flags = server ? coreFlag.PHY : coreFlag.AUTO;
		super(opts);



		if (!server)
			push(new ClientRunner(this, address, port));
		else
			push(new ServerRunner(this, port));
	}

	void close()
	{
		super.close();
	}

	void parseArgs(string[] args)
	{
		foreach(a; args) {
			if (a == "-server")
				server = true;
		}
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
class ClientRunner : GameRunner, NetConnectionListener
{
public:
	World w;

	NetClient client;

	GameRouter r;
	GfxRenderer renderer;
	GfxCamera cam;
	GfxSimpleLight light;

	CtlKeyboard keyboard;
	CtlMouse mouse;

	Cube c1, c2;


public:
	this(GameRouter r, string address, ushort port)
	{
		super(GameRunner.Type.Game);
		this.r = r;

		client = new NetClient(this);
		writefln("Connecting to %s:%s", address, port);
		client.connect(address, port);


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

		c1 = new Cube(w);
		c1.position = Point3d(0, 10, 0);

		c2 = new Cube(w);
		c2.position = Point3d(.3, 16, .4);

		light.position = Point3d();
		light.rotation = Quatd(-PI/6, -PI/4.2, 0);
		light.shadow = true;
		cam.position = Point3d(0, 5, 20);
		cam.rotation = Quatd();
		cam.far = 512;
	}

	void close()
	{
		client.close();
		breakApartAndNull(cam);
		breakApartAndNull(c1);
		breakApartAndNull(c2);
		breakApartAndNull(w);
	}

	void logic()
	{
		client.tick();
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


	/*
	 *
	 * Network
	 *
	 */


	void packet(NetConnection c, NetPacket p)
	{
		writefln("Packet");
	}

	void opened(NetConnection c)
	{
		writefln("Connected");
	}

	void closed(NetConnection c)
	{
		writefln("Disconnected");
		r.quit();
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
class ServerRunner : GameRunner, NetConnectionListener
{
public:
	World w;

	GameRouter r;
	NetServer server;
	NetConnection con;

	uint counter;
	PhyStatic cube;
	PhyCube c1, c2;


public:
	this(GameRouter r, ushort port)
	{
		super(GameRunner.Type.Game);
		this.r = r;
		server = new NetServer(port, this);
		writefln("Listening on port %s", port);

		w = new World();

		assert(w !is null);
		assert(w.phy !is null);

		cube = new PhyStatic(w.phy, new PhyGeomCube(200.0, 10.0, 200.0));
		cube.position = Point3d(0.0, -5.0, 0.0);

		c1 = new PhyCube(w.phy);
		c2 = new PhyCube(w.phy);
	}

	void close()
	{
		server.close();
		breakApartAndNull(c1);
		breakApartAndNull(c2);
		breakApartAndNull(cube);
	}

	void logic()
	{
		w.tick();
		server.tick();

		if (counter++ >= 240) {
			c1.position = Point3d(0, 10, 0);
			c2.position = Point3d(.3, 11.1, .4);
			counter = 0;
		}

		if (counter % 10 == 0 && con !is null) {

		}
	}

	void assumeControl()
	{

	}

	void dropControl()
	{

	}

	void render(GfxRenderTarget rt) { assert(false); }


	/*
	 *
	 * Network
	 *
	 */


	void packet(NetConnection c, NetPacket p)
	{
		writefln("Packet");
	}

	void opened(NetConnection c)
	{
		writefln("Connected %s", c.address);
		if (con !is null)
			con.close();
		con = c;
	}

	void closed(NetConnection c)
	{
		writefln("Disconnected %s", c.address);

		if (c is con)
			con = null;
	}
}

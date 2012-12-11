// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module box.client;

import std.math : PI;
import charge.charge;

import box.cube;
import box.world;
import box.network;


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

	SyncData sync1, sync2;


private:
	mixin SysLogging;


public:
	this(GameRouter r, string address, ushort port)
	{
		super(GameRunner.Type.Game);
		this.r = r;

		client = new NetClient(this);
		l.info("Connecting to %s:%s", address, port);
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
		static bool t;
		t = !t;
		if (t) {
			sync1.predict();
			sync1.readDiff(p.data[8 .. $]);
			sync1.readCube(c1.phy);
		} else {
			sync2.predict();
			sync2.readDiff(p.data[8 .. $]);
			sync2.readCube(c2.phy);
		}
	}

	void opened(NetConnection c)
	{
		l.info("Connected");
	}

	void closed(NetConnection c)
	{
		l.info("Disconnected");
		r.quit();
	}


protected:
	void keyDown(CtlKeyboard kb, int sym, dchar unicode, char[] str)
	{
		if (sym == 27)
			r.quit();
	}
}

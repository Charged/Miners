// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module box.server;

import charge.charge;
import box.world;
import box.network;


/**
 * Server scene.
 */
class ServerScene : GameScene, NetConnectionListener
{
public:
	World w;

	GameSceneManager r;
	NetServer server;
	NetConnection con;

	uint counter;
	PhyStatic cube;
	PhyCube c1, c2;

	SyncData sync1;
	SyncData sync2;
private:
	mixin SysLogging;


public:
	this(GameSceneManager r, ushort port)
	{
		super(Type.Game);
		this.r = r;
		server = new NetServer(port, this);
		l.info("Listening on port %s", port);

		w = new World();

		assert(w !is null);
		assert(w.phy !is null);

		cube = new PhyStatic(w.phy, new PhyGeomCube(200.0, 10.0, 200.0));
		cube.position = Point3d(0.0, -5.0, 0.0);

		c1 = new PhyCube(w.phy);
		c2 = new PhyCube(w.phy);
	}

	override void close()
	{
		server.close();
		breakApartAndNull(c1);
		breakApartAndNull(c2);
		breakApartAndNull(cube);
	}

	override void logic()
	{
		w.tick();
		server.tick();

		if (++counter >= 240) {
			c1.position = Point3d(0, 10, 0);
			c2.position = Point3d(.3, 11.1, .4);
			counter = 0;
		}

		void doSync(SyncData *sync, PhyCube c) {
			SyncData n;
			n.count = sync.count;
			n.writeCube(c);

			sync.predict();
			auto p = sync.diff(&n);
			if (p !is null)
				server.sendAll(p);
			*sync = n;
			// So that the client and server match exactly.
			sync.readCube(c);
		}

		if (counter % SyncData.numSteps == 0 && con !is null) {
			doSync(&sync1, c1);
			doSync(&sync2, c2);
		}
	}

	override void assumeControl()
	{

	}

	override void dropControl()
	{

	}

	override void render(GfxRenderTarget rt) { assert(false); }


	/*
	 *
	 * Network
	 *
	 */


	override void packet(NetConnection c, NetPacket p)
	{
	}

	override void opened(NetConnection c)
	{
		l.info("Connected %s", c.address);

		if (con !is null)
			con.close();
		con = c;
		sync1.reset();
		sync2.reset();
	}

	override void closed(NetConnection c)
	{
		l.info("Disconnected %s", c.address);

		if (c is con)
			con = null;
	}
}

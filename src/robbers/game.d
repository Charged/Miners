// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module robbers.game;

import std.string;
import std.math;

import lib.sdl.sdl;

import charge.charge;
import robbers.world;
import robbers.player;
import robbers.network;
import robbers.loader;

import robbers.actors.car;
import robbers.actors.cube;
import robbers.actors.primitive;

bool running = false;

class Game : GameApp, NetConnectionListener
{
private:
	mixin SysLogging;

	alias charge.net.connection.AddressKey Key;
	Player[Key] players;

	World w;

	GfxRenderer r;
	GfxDefaultTarget rt;
	GfxDraw d;
	GfxTexture sidebar;
	GfxDynamicTexture sb_header;
	GfxDynamicTexture sb_dyn;

	NetClient c;
	NetServer s;
	NetworkSender ns;
	SysZipFile basePackage;

	Player player;

	double fps;
	double usage;
	double usage_gfx;
	double usage_logic;

	uint stepLength;
	bool running;
	bool server;
	ushort port;
	string address;

public:
	this(string[] arg)
	{
		// Defaults
		server = false;
		address = "localhost";
		port = 6112;
		stepLength = 10;

		parseArgs(arg);

		auto opts = new CoreOptions();
		opts.title = "Charged Robbers";
		super(opts);

		basePackage = SysZipFile("base.chz");

		if (server) {
			l.info("Server listening on ", port);
			s = new NetServer(port, this);
		} else {
			l.info("Client connecting to ", address, ":", port);
			c = new NetClient(this);
			c.connect(address, port);
		}

		ns = new NetworkSender(s, c);

		running = true;

		GfxRenderer.init();

		w = new World(ns, server);
		rt = GfxDefaultTarget();
		w.camera = new GfxProjCamera(45.0, cast(double)rt.width / rt.height, .1, 250);

		loadLevel();

		if (server) {
			auto p = new Player(w, null, true, true);
			player = p;

			uint id = ns.newId();
			Car car = new Car(w, id, true);
			player.setCar(car, id);
		}

		r = GfxRenderer.create();
		d = new GfxDraw();
		//sidebar = GfxTexture("res/test.bmp");
		sidebar = GfxTexture("res/sidebar.png");

		sb_header = new GfxDynamicTexture("sb_header");
		sb_dyn = new GfxDynamicTexture("sb_speed");

		gfxDefaultFont.render(sb_header, "Information");

		CtlInput().quit ~= &quit;
		CtlKeyboard keyboard = CtlInput().keyboards[0];
		keyboard.down ~= &keyboardDown;
		keyboard.up ~= &keyboardUp;

		/// TODO All below this is a hack
		w.camera.position = Point3d(0.0, 10.0, 25.0);
	}


	~this()
	{
		delete w;
		delete basePackage;
	}


	void loop()
	{
		double now = cast(double)SDL_GetTicks();
		double step = stepLength;
		double where = now;
		double temp = now;
		double last = now;

		double used_logic = 0;
		double used_gfx = 0;
		double used = 0;

		int steps;
		bool changed;

		while(running) {
			now = SDL_GetTicks();

			input();

			network();

			temp = cast(double)SDL_GetTicks();
			while(where < now) {
				input();

				logic();

				network();

				where = where + step;

				changed = true;
				steps++;
			}
			used_logic += cast(double)SDL_GetTicks() - temp;

			temp = cast(double)SDL_GetTicks();
			if (changed) {
				render();
				changed = false;
			}
			used_gfx += cast(double)SDL_GetTicks() - temp;

			temp = (cast(double)SDL_GetTicks());
			used += temp - now;
			if (steps > 50) {
				usage = round(used / (temp - last) * 100);
				usage_gfx = round(used_gfx / (temp - last) * 100);
				usage_logic = round(used_logic / (temp - last) * 100);
				steps = 0;
				used = 0;
				used_gfx = 0;
				used_logic = 0;
				last = cast(double)SDL_GetTicks();
			}

			SDL_Delay(1);
		}

		if (s !is null)
			s.close();

		if (c !is null)
			c.close();

		if (server) {
			if (player !is null)
				delete player;
		}

		player = null;

		foreach(k; players.keys) {
			auto p = players[k];
			delete p;
			players.remove(k);
		}
		foreach(a; w.actors.adup) {
			delete a;
		}
		delete w;
	}

protected:
	void loadLevel()
	{
		robbers.loader.Loader.load(w, "res/level.xml");
	}

	void packet(NetConnection c, NetPacket pa)
	{
		if (pa.data.length < 12) {
			l.warn("Got too small package ignoring");
			return;
		}

		auto id = (cast(uint*)pa.ptr)[2];
		if (pa.debugPrint)
			l.bug("packet to id ", id);

		if (id == 0)
			myPacket(c, pa);
		else if (id == 1) {
			auto p = c.key in players;
			if (p is null) {
				l.warn("no player with that key");
				return;
			}
			p.packet(pa);
		} else {
			auto o = ns.get(id);
			if (o !is null)
				o.netPacket = pa;
			else
				l.warn("packet to unkown recipeint ", id);
        }
	}

	void myPacket(NetConnection c, NetPacket p)
	{
		if (server) {
			l.warn("The server game should not receive packages");
			return;
		}
		uint to;
		uint cmd;
		uint id;
		uint type;
		scope auto o = new NetInStream(p);
		o >> to;
		o >> cmd;
		o >> id;

		//l.trace("cmd: ", cmd, " id: ", id, " type: ", type);

		if (cmd == 1) {
			if (ns.get(id) !is null) {
				l.error("object was allready created badness will happen");
				return;
			}
			o >> type;
			if (type == 1)
				new Car(w, id, server);
			else if (type == 2)
				new Cube(w, id, server);
			else
				l.info("wrong type ", type);
			//l.info("server told me to create object with id ", id, " and ", type);
		} else if (cmd == 2) {
			auto obj = ns.get(id);
			delete obj;
			//l.info("server told me to delete object with id ", id);
		} else if (cmd == 3) {
			//l.info("server told me physics generation is ", id);
			if (abs(cast(int)(w.gen - (id - 2))) > 2)
				w.updateGeneration(id - 1);
		} else {
			l.fatal("unknown command!");
		}
	}

	void closed(NetConnection c)
	{
		l.info("Connection closed ", c.address);
		if (!server) {
			running = false;
			return;
		}

		auto key = c.key;
		Player *p = key in players;
		if (p is null) {
			l.warn("no player with that key!");
		}

		players.remove(key);
		auto car = p.getCar();

		delete car;
		delete *p;
	}

	void opened(NetConnection c)
	{
		if (server) {
			l.bug("Player Connected");
			auto p = new Player(w, c, true, false);
			players[c.key] = p;

			// Create all the current objects on the new player
			foreach(obj; w.net.objects.values) {
				auto pa = obj.netCreateOnClient(4+4);
				scope auto o = new NetOutStream(pa);
				o << 0u; // To game on the otherside
				o << 1u; // Create
				p.net.send(pa);
			}
	
			uint id = ns.newId();
			Car car = new Car(w, id, true);
			p.setCar(car, id);

			l.bug("Added car with id ", id);

			{
				auto pa = new RealiblePacket(4+4+4);
				scope auto o = new NetOutStream(pa);
				uint gen = w.gen;
				o << 0u; // To game on the otherside
				o << 3u; // Update generation
				o << gen;
				p.net.send(pa);
			}
		} else {
			l.bug("Connected to server");
			player = new Player(w, c, false, true);
			players[c.key] = player;
		}
	}



private:

	void createCube()
	{
		uint id = ns.newId();
		auto cube = new Cube(w, id, true);
	}

	void parseArgs(string[] arg)
	{
		for(int i; i < arg.length; i++) {
			if (arg[i] == "-server")
				server = true;
			else if (arg[i] == "-port")
				port = cast(ushort)atoi(arg[++i]); 
			else if (arg[i] == "-address")
				address = arg[++i];
		}

	}

	void input()
	{
		CtlInput().tick;
	}

	void quit()
	{
		running = false;
	}

	void keyboardDown(CtlKeyboard key, int sym, dchar unicode, char[] str)
	{
		if (player is null)
			return;
		player.keydown = sym;
	}

	void keyboardUp(CtlKeyboard key, int sym)
	{
		if (player is null)
			return;
		player.keyup = sym;
	}

	void network()
	{
		if (s !is null)
			s.tick();
		if (c !is null)
			c.tick();
	}

	void logic()
	{
		w.tick();

		// Tell clients which physical generation
		// the server is currently on
		static int count = 8;
		if (server && count-- < 0) {
			auto pa = new RealiblePacket(4+4+4);
			scope auto o = new NetOutStream(pa);
			uint gen = w.gen;
			o << 0u; // To game on the otherside
			o << 3u; // Update generation
			o << gen;
			// Send to all clients
			ns.send(pa);
			count = 8;
		}
	}

	void render()
	{
		rt.clear();
		r.target = rt;
		d.target = rt;

		r.render(w.camera, w.gfx);

		d.start();

		/* Draw the sidebar and text */
		int x, y;
		x = rt.width - sidebar.width - 2;
		y = 2;
		d.blit(sidebar, x, y);
		d.blit(sb_header, x + 4, y + 5);


		x += 4;
		y += 28;
/*
		GfxFont.render(sb_dyn, format("FPS: %s", fps));
		d.blit(sb_dyn, x, y);
		y += 11;

		GfxFont.render(sb_dyn, format("Usage: %s", usage));
		d.blit(sb_dyn, x, y);
		y += 11;
*/

		gfxDefaultFont.render(sb_dyn, format("Usage GFX: %s", usage_gfx));
		d.blit(sb_dyn, x, y);
		y += 11;
/*
		GfxFont.render(sb_dyn, format("Usage Logic: %s", usage_logic));
		d.blit(sb_dyn, x, y);
		y += 11;

		GfxFont.render(sb_dyn, format("Usage Misc: %s", usage));
		d.blit(sb_dyn, x, y);
		y += 11;
*/
		gfxDefaultFont.render(sb_dyn, format("Generation: %s", w.gen));
		d.blit(sb_dyn, x, y);
		y += 11;
/*
		if (player !is null && player.getCar !is null) {
			auto car = player.getCar;
			auto vel = round(car.velocity.length * 3.6);
			auto altitude = round(car.position.y * 10 - 2.7) / 10;


			GfxFont.render(sb_dyn, format("  Speed: %s km/h", vel));
			d.blit(sb_dyn, x, y);
			y += 11;

			GfxFont.render(sb_dyn, format("  Altitude: %s", altitude));
			d.blit(sb_dyn, x, y);
			y += 11;
		}
*/
		d.stop();
		rt.swap();
	}
}

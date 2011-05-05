// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.game;

import std.math;
import std.file;
import std.c.stdlib;
import lib.sdl.sdl;

import charge.charge;

import minecraft.lua;
import minecraft.terrain.chunk;
import minecraft.terrain.vol;
import minecraft.gfx.renderer;

class GameLogic
{
public:
	GameWorld w;

	/* Light related */
	GfxSimpleLight sl;
	double light_heading;
	double light_pitch;
	bool light_moveing;

	/* Camera related */
	GfxCamera cam;
	GameMover m;
	double cam_heading;
	double cam_pitch;
	bool cam_moveing;

private:
	mixin SysLogging;

public:
	this(GameWorld w)
	{
		this.w = w;

		GfxDefaultTarget rt = GfxDefaultTarget();
		cam = new GfxProjCamera(45.0, cast(double)rt.width / rt.height, .1, 250);
		m = new GameProjCameraMover(cam);
		cam.position = Point3d(0.0, 5.0, 15.0);
		cam_heading = 0.0;
		cam_pitch = 0.0;

		//cam = new GfxIsoCamera(800/16f, 600/16f, -200, 200);
		//m = new GameIsoCameraMover(cam);

		sl = new GfxSimpleLight();
		// Night
		//sl.diffuse = Color4f(0.0/255, 3.0/255, 30.0/255);
		//sl.ambient = Color4f(0.0/255, 3.0/255, 30.0/255);

		// Day
		sl.diffuse = Color4f(200.0/255, 200.0/255, 200.0/255);
		sl.ambient = Color4f(65.0/255, 65.0/255, 65.0/255);
		sl.shadow = true;

		// Test
		//sl.diffuse = Color4f(1.0, 1.0, 1.0);
		//sl.ambient = Color4f(0.0, 0.0, 0.0);

		light_heading = PI/3;
		light_pitch = -PI/6;
		sl.rotation = Quatd(light_heading, light_pitch, 0);
		w.gfx.add(sl);

		w.gfx.fog = new GfxFog();
		w.gfx.fog.start = 150;
		w.gfx.fog.stop = 250;
		w.gfx.fog.color = Color4f(89.0/255, 178.0/255, 220.0/255);

		auto kb = CtlInput().keyboard;
		kb.up ~= &this.keyUp;
		kb.down ~= &this.keyDown;

		auto m = CtlInput().mouse;
		m.up ~= &this.mouseUp;
		m.down ~= &this.mouseDown;
		m.move ~= &this.mouseMove;
	}

	~this()
	{
		auto kb = CtlInput().keyboard;
		kb.up.disconnect(&this.keyUp);
		kb.down.disconnect(&this.keyDown);

		auto m = CtlInput().mouse;
		m.up.disconnect(&this.mouseUp);
		m.down.disconnect(&this.mouseDown);
		m.move.disconnect(&this.mouseMove);
	}

	void keyDown(CtlKeyboard kb, int sym)
	{
		switch(sym) {
		case SDLK_v:
			sl.shadow = !sl.shadow;
			break;
		case SDLK_w:
			m.forward = true;
			break;
		case SDLK_s:
			m.backward = true;
			break;
		case SDLK_a:
			m.left = true;
			break;
		case SDLK_d:
			m.right = true;
			break;
		case SDLK_LSHIFT:
			m.speed = true;
			break;
		case SDLK_SPACE:
			m.up = true;
			break;
		default:
		}
	}

	void keyUp(CtlKeyboard kb, int sym)
	{
		switch(sym) {
		case SDLK_w:
			m.forward = false;
			break;
		case SDLK_s:
			m.backward = false;
			break;
		case SDLK_a:
			m.left = false;
			break;
		case SDLK_d:
			m.right = false;
			break;
		case SDLK_LSHIFT:
			m.speed = false;
			break;
		case SDLK_SPACE:
			m.up = false;
			break;
		default:
		}
	}

	void mouseMove(CtlMouse mouse, int ixrel, int iyrel)
	{
		if (cam_moveing) {
			double xrel = ixrel;
			double yrel = iyrel;
			cam_heading += xrel / 500.0;
			cam_pitch += yrel / 500.0;
			cam.rotation = Quatd(cam_heading, cam_pitch, 0);
		}

		if (light_moveing) {
			double xrel = ixrel;
			double yrel = iyrel;
			light_heading += xrel / 500.0;
			light_pitch += yrel / 500.0;
			sl.rotation = Quatd(light_heading, light_pitch, 0);
		}
	}

	void mouseDown(CtlMouse m, int button)
	{
		if (button == 1)
			cam_moveing = true;
		if (button == 3)
			light_moveing = true;
	}

	void mouseUp(CtlMouse m, int button)
	{
		if (button == 1)
			cam_moveing = false;
		if (button == 3)
			light_moveing = false;
	}

	void logic()
	{
		m.tick();
	}
}

class Game : public GameSimpleApp
{
private:
	/* program args */
	char[] level;
	bool build_all;


	charge.game.app.TimeKeeper buildTime;

	GameWorld w;

	GameLogic gl;
	ScriptRunner sr;

	VolTerrain vt;

	/*
	 * For managing the rendering.
	 */
	GfxTexture tex;
	GfxTextureArray ta;

	GfxRenderer r; // Current renderer
	GfxRenderer dr; // Inbuilt deferred or Fixed func
	MinecraftDeferredRenderer mdr; // Special deferred renderer
	MinecraftForwardRenderer mfr; // Special forward renderer
	GfxRenderer rs[4]; // Null terminated list of renderer
	VolTerrain.BuildTypes rsbt[4]; // A list of build types for the renderers
	int num_renderers;
	int current_renderer;

	bool canDoForward;
	bool canDoDeferred;

	bool aa;

	/*
	 * For tracking the camera
	 */
	GfxCamera camera;
	int x; int z;


	bool built; /**< Have we built a chunk */

	int ticks;
	int start;
	int num_frames;

public:
	mixin SysLogging;

	this(char[][] args)
	{
		super(args);
		parseArgs(args);
		l.fatal("-license         - print licenses");
		l.fatal("-level <level>   - to specify level directory");
		l.fatal("-all             - build all chunks near the camera on start");

		running = true;

		canDoForward = MinecraftForwardRenderer.check();
		canDoDeferred = MinecraftDeferredRenderer.check();

		setupTextures();
		setupRenderers();

		w = new GameWorld();

		guessLevel();

		if (!checkLevel(level))
			throw new Exception("Invalid level");

		vt = new VolTerrain(w, level, tex);
		vt.buildIndexed = MinecraftForwardRenderer.textureArraySupported;
		vt.setBuildType(rsbt[current_renderer]);

		if (build_all) {
			l.fatal("Building all, please wait...");
			auto t1 = SDL_GetTicks();
			vt.buildAll();
			auto t2 = SDL_GetTicks();
			l.fatal("Build time: %s seconds", (t2 - t1) / 1000.0);
		}


		auto scriptName = "res/script.lua";
		try {
			sr = new ScriptRunner(w, scriptName);
			camera = sr.c.c;
		} catch (Exception e) {
			l.fatal("Could not find or run \"%s\"", scriptName);
			gl = new GameLogic(w);
			camera = gl.cam;
		}

		auto kb = CtlInput().keyboard;
		kb.up ~= &this.keyUp;

		start = SDL_GetTicks();
	}

	~this()
	{
		if (ta !is null) {
			ta.dereference();
			ta = null;
		}
		if (tex !is null) {
			tex.dereference();
			tex = null;
		}
		delete sr;
		delete gl;
		delete w;

		auto kb = CtlInput().keyboard;
		kb.up.disconnect(&this.keyUp);
	}

protected:
	void parseArgs(char[][] arg)
	{
		for(int i; i < arg.length; i++) {
			if (arg[i] == "-level")
				level = arg[++i];
			else if (arg[i] == "-all")
				build_all = true;
		}

	}

	bool checkLevel(char[] level)
	{
		auto dat = std.string.format(level, "/level.dat");
		auto region = std.string.format(level, "/region");

		if (!exists(dat)) {
			l.fatal("Could not find level.dat in the level directory");
			l.fatal("This probably isn't a level, exiting the viewer.");
			l.fatal("looked for this file: %s", dat);
			return false;
		}

		if (!exists(region)) {
			l.fatal("Could not find the region folder in the level directory");
			l.fatal("This probably isn't a level, exiting the viewer.");
			l.fatal("looked for this folder: %s", region);
			return false;
		}

		return true;
	}

	void setupTextures()
	{
		auto pic = Picture("mc/terrain", "res/terrain.png");

		// Doesn't support biomes right now fixup the texture before use.
		applyStaticBiome(pic);

		tex = GfxTexture("mc/terrain", pic);
		tex.filter = GfxTexture.Filter.Nearest; // Or we get errors near the block edges

		if (mfr.textureArraySupported && (canDoForward || canDoDeferred)) {
			ta = ta.fromTileMap("mc/terrain", pic, 16, 16);
			ta.filter = GfxTexture.Filter.NearestLinear;
		}

		pic.dereference();
		pic = null;
	}

	void setupRenderers()
	{
		GfxRenderer.init();
		r = new GfxFixedRenderer();
		rsbt[num_renderers] = VolTerrain.BuildTypes.RigidMesh;
		rs[num_renderers++] = r;

		if (canDoForward) {
			try {
				mfr = new MinecraftForwardRenderer(tex, ta);
				rsbt[num_renderers] = VolTerrain.BuildTypes.CompactMesh;
				rs[num_renderers++] = mfr;
			} catch (Exception e) {
				l.warn("No fancy renderer \"%s\"", e);
			}
		}

		if (canDoDeferred) {
			try {
				MinecraftDeferredRenderer.init();

				mdr = new MinecraftDeferredRenderer(ta);
				rsbt[num_renderers] = VolTerrain.BuildTypes.Array;
				rs[num_renderers++] = mdr;
			} catch (Exception e) {
				l.warn("No fancy renderer \"%s\"", e);
			}
		}

		// Pick the most advanced renderer
		current_renderer = num_renderers - 1;
		r = rs[current_renderer];
	}

	void guessLevel()
	{
		if (level is null) {
			auto home = std.string.toString(getenv("HOME"));
			if (home is null) {
				auto str = "could not guess default level location (HOME env not found)";
				l.fatal(str);
				throw new Exception("");
			}

			level = std.string.format(home, "/.minecraft/saves/World1");
			l.fatal(`Guessing level location: "%s"`, level);
		}
	}

	void keyUp(CtlKeyboard kb, int sym)
	{
		switch(sym) {
		case SDLK_o:
			Core().screenShot();
			break;
		case SDLK_b:
			aa = !aa;
			break;
		case SDLK_r:
			current_renderer++;
			if (current_renderer >= num_renderers)
				current_renderer = 0;

			r = rs[current_renderer];
			vt.setBuildType(rsbt[current_renderer]);
			break;
		case SDLK_i:
			static int i = 1;
			vt.setCenter(0, i++);
			break;
		default:
		}
	}

	void logic()
	{
		// This make sure we at least always
		// builds at least one chunk per frame.
		built = false;

		w.tick();

		if (gl !is null)
			gl.logic();

		if (sr !is null)
			sr.logic();

		// Center the map around the camera.
		{
			auto p = camera.position;
			int x = cast(int)p.x;
			int z = cast(int)p.z;
			x = p.x < 0 ? (x - 16) / 16 : x / 16;
			z = p.z < 0 ? (z - 16) / 16 : z / 16;
			
			if (this.x != x || this.z != z)
				vt.setCenter(x, z);
			this.x = x;
			this.z = z;
		}

		ticks++;

		auto elapsed = SDL_GetTicks() - start;
		if (elapsed > 1000) {
			l.bug("FPS: %s",
				cast(double)num_frames /
				(cast(double)elapsed / 1000.0));
			num_frames = 0;

			l.bug("INFO\n\tgfx:   %# 2.3s%%\n\tgame:  %# 2.3s%%\n"
				"\tnet:   %# 2.3s%%\n\tidle:  %# 2.3s%%\n"
				"\tctl:   %# 2.3s%%\n\tbuild: %# 2.3s%%",
				renderTime.calc(elapsed), logicTime.calc(elapsed),
				networkTime.calc(elapsed), idleTime.calc(elapsed),
				inputTime.calc(elapsed), buildTime.calc(elapsed));

			start = elapsed + start;
			const double MB = 1024 * 1024;
			l.bug("Used VBO mem: %sMB", charge.gfx.vbo.VBO.used / MB);
			l.trace("Used Chunk mem: %sMB", Chunk.used_mem / MB);
		}
	}

	void render()
	{
		if (ticks < 2)
			return;

		num_frames++;

		ticks = 0;

		static charge.gfx.target.DoubleTarget dt;
		GfxDefaultTarget rt = GfxDefaultTarget();
		if (aa && dt is null)
			dt = new charge.gfx.target.DoubleTarget(rt.width, rt.height);
		rt.clear();
		r.target = aa ? cast(GfxRenderTarget)dt : cast(GfxRenderTarget)rt;

		r.render(camera, w.gfx);

		if (aa)
			dt.resolve(rt);
		rt.swap();
	}

	void idle(long time)
	{
		// If we have built at least one chunk this frame and have very little
		// time left don't build again. But we always build one each frame.
		if (built && time < 10)
			return super.idle(time);

		// Account this time for build instead of idle
		idleTime.stop();
		buildTime.start();

		// Do the build
		built = vt.buildOne();

		// Delete unused resources
		charge.sys.resource.Pool().collect();

		// Switch back to idle
		buildTime.stop();
		idleTime.start();

		if (!built)
			super.idle(time);
	}

	void network()
	{
	}

	void close()
	{
	}

	/*
	 * Functions for manipulating the terrain.png picture.
	 */

	void applyStaticBiome(Picture pic)
	{
		//auto grass = Color4b(88, 190, 55, 255);
		auto grass = Color4b(102, 180, 68, 255);
		auto leaves = Color4b(91, 139, 23, 255);

		modulateColor(pic, 0, 0, grass); // Top grass
		modulateColor(pic, 6, 2, grass); // Side grass blend
		modulateColor(pic, 4, 3, leaves); // Tree leaves

		// Blend the now colored side grass onto the used side
		blendTiles(pic, 3, 0, 6, 2);

		// When we are doing mipmaping, soften the edges.
		fillEmptyWithAverage(pic, 4, 3); // Leaves
		fillEmptyWithAverage(pic, 1, 3); // Glass
		fillEmptyWithAverage(pic, 1, 4); // Moster-spawn
	}

	void modulateColor(Picture pic, uint tile_x, uint tile_y, Color4b color)
	{
		uint tile_size = pic.width / 16;
		tile_x *= tile_size;
		tile_y *= tile_size;

		for (int x; x < tile_size; x++) {
			for (int y; y < tile_size; y++) {
				auto ptr = &pic.pixels[(x + tile_x) + (y + tile_y) * pic.width];
				ptr.modulate(color);
			}
		}
	}

	void blendTiles(Picture pic, uint dst_x, uint dst_y, uint src_x, uint src_y)
	{
		uint tile_size = pic.width / 16;
		dst_x *= tile_size;
		dst_y *= tile_size;
		src_x *= tile_size;
		src_y *= tile_size;

		for (int x; x < tile_size; x++) {
			for (int y; y < tile_size; y++) {
				auto dst = &pic.pixels[(x + dst_x) + (y + dst_y) * pic.width];
				auto src = &pic.pixels[(x + src_x) + (y + src_y) * pic.width];
				dst.blend(*src);
			}
		}
	}

	void fillEmptyWithAverage(Picture pic, uint dst_x, uint dst_y)
	{
		uint tile_size = pic.width / 16;
		dst_x *= tile_size;
		dst_y *= tile_size;

		uint num;
		double r = 0, g = 0, b = 0;

		for (int x; x < tile_size; x++) {
			for (int y; y < tile_size; y++) {
				auto dst = &pic.pixels[(x + dst_x) + (y + dst_y) * pic.width];
				if (dst.a == 0)
					continue;

				r += dst.r;
				g += dst.g;
				b += dst.b;
				num++;
			}
		}

		Color4b avrg;

		if (num == 0) {
			avrg = Color4b.Black;
			avrg.a = 0;
		} else {
			avrg.r = cast(ubyte)(r / num);
			avrg.g = cast(ubyte)(g / num);
			avrg.b = cast(ubyte)(b / num);
			avrg.a = 0;
		}

		for (int x; x < tile_size; x++) {
			for (int y; y < tile_size; y++) {
				auto dst = &pic.pixels[(x + dst_x) + (y + dst_y) * pic.width];
				if (dst.a != 0)
					continue;
				*dst = avrg;
			}
		}
	}
}

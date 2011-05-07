// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.game;

import std.math;
import std.file;
import std.c.stdlib;
import lib.sdl.sdl;

import charge.charge;

import minecraft.lua.runner;
import minecraft.world;
import minecraft.runner;
import minecraft.terrain.chunk;
import minecraft.terrain.vol;
import minecraft.gfx.renderer;



class Game : public GameSimpleApp
{
private:
	/* program args */
	char[] level;
	bool build_all;

	charge.game.app.TimeKeeper luaTime;
	charge.game.app.TimeKeeper buildTime;

	World w;
	RenderManager rm;

	GameLogic gl;
	ScriptRunner sr;

	/*
	 * For tracking the camera
	 */
	GfxCamera camera;
	int x; int z;


	bool built; /**< Have we built a chunk */

	int ticks;
	int start;
	int num_frames;


	GfxDraw d;
	GfxDynamicTexture text;

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

		guessLevel();

		if (!checkLevel(level))
			throw new Exception("Invalid level");

		rm = new RenderManager();

		w = new World(level, rm);

		if (build_all) {
			l.fatal("Building all, please wait...");
			auto t1 = SDL_GetTicks();
			w.vt.buildAll();
			auto t2 = SDL_GetTicks();
			l.fatal("Build time: %s seconds", (t2 - t1) / 1000.0);
		}

		auto scriptName = "res/script.lua";
		try {
			sr = new ScriptRunner(w, scriptName);
			camera = sr.c.c;
		} catch (Exception e) {
			l.fatal("Could not find or run \"%s\" (%s)", scriptName, e);
			gl = new GameLogic(w);
			camera = gl.cam;
		}

		start = SDL_GetTicks();

 		d = new GfxDraw();
		text = new GfxDynamicTexture("mc/text");
	}

	~this()
	{
		delete sr;
		delete gl;
		delete w;
		delete rm;

		delete d;
		text.dereference();
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

	/*
	 *
	 * Callback functions
	 *
	 */

	void resize(uint w, uint h)
	{
		super.resize(w, h);

		if (sr !is null)
			sr.resize(w, h);
	}

	void logic()
	{
		// This make sure we at least always
		// builds at least one chunk per frame.
		built = false;

		w.tick();

		if (gl !is null)
			gl.logic();

		if (sr !is null) {
			logicTime.stop();
			luaTime.start();
			sr.logic();
			luaTime.stop();
			logicTime.start();
		}

		// Center the map around the camera.
		{
			auto p = camera.position;
			int x = cast(int)p.x;
			int z = cast(int)p.z;
			x = p.x < 0 ? (x - 16) / 16 : x / 16;
			z = p.z < 0 ? (z - 16) / 16 : z / 16;
			
			if (this.x != x || this.z != z)
				w.vt.setCenter(x, z);
			this.x = x;
			this.z = z;
		}

		ticks++;

		auto elapsed = SDL_GetTicks() - start;
		if (elapsed > 1000) {
			const double MB = 1024 * 1024;
			char[] info = std.string.format(
				"FPS: %s\n"
				"VBO mem: %sMB\n"
				"Chunk mem: %sMB\n"
				"Time:\n"
				"\tgfx:   %# 2.3s%%\n\tgame:  %# 2.3s%%\n"
				"\tnet:   %# 2.3s%%\n\tidle:  %# 2.3s%%\n"
				"\tctl:   %# 2.3s%%\n\tbuild: %# 2.3s%%\n"
				"\tlua:   %# 2.3s%%\n",
				cast(double)num_frames / (cast(double)elapsed / 1000.0),
				charge.gfx.vbo.VBO.used / MB,
				Chunk.used_mem / MB,
				renderTime.calc(elapsed), logicTime.calc(elapsed),
				networkTime.calc(elapsed), idleTime.calc(elapsed),
				inputTime.calc(elapsed), buildTime.calc(elapsed),
				luaTime.calc(elapsed));

			GfxFont.render(text, info);

			num_frames = 0;
			start = elapsed + start;
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
		if (rm.aa && dt is null)
			dt = new charge.gfx.target.DoubleTarget(rt.width, rt.height);
		rt.clear();
		rm.r.target = rm.aa ? cast(GfxRenderTarget)dt : cast(GfxRenderTarget)rt;

		rm.r.render(camera, w.gfx);

		if (rm.aa)
			dt.resolve(rt);

		debug {
			d.target = rt;

			d.blit(text, 8, 8);
		}

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
		built = w.vt.buildOne();

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
}

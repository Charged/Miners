// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.game;

import std.math;
import std.file;
import std.stdio;
import std.string;
import std.c.stdlib;

import lib.sdl.sdl;

import charge.charge;
import charge.sys.file;
import charge.platform.homefolder;

import minecraft.runner;
import minecraft.lua.runner;
import minecraft.world;
import minecraft.viewer;
import minecraft.menu;
import minecraft.terrain.beta;
import minecraft.terrain.chunk;
import minecraft.actors.helper;
import minecraft.gfx.renderer;
import minecraft.importer.info;
import minecraft.importer.texture;



/**
 * Main hub of the minecraft game.
 */
class Game : public GameSimpleApp, public Router
{
private:
	/* program args */
	char[] level;
	bool build_all;

	charge.game.app.TimeKeeper luaTime;
	charge.game.app.TimeKeeper buildTime;

	ResourceStore rs;
	RenderManager rm;
	GfxDefaultTarget defaultTarget;

	MenuRunner mr;
	ScriptRunner sr;
	Runner runner;

	Runner[] deleteRunner;
	Runner nextRunner;

	bool built; /**< Have we built a chunk */

	int ticks;
	int start;
	int num_frames;

	GfxDraw d;
	GfxDynamicTexture debugText;
	GfxDynamicTexture cameraText;
	GfxTextureTarget infoTexture;

	// Extracted files from minecraft
	void[] terrainFile;
	const terrainFilename = "%terrain.png";

public:
	mixin SysLogging;

	this(char[][] args)
	{
		super(args);

		running = true;

		parseArgs(args);

		if (!running)
			return;

		defaultTarget = GfxDefaultTarget();

		try {
			doInit();
		} catch (GameException ge) {
			nextRunner = new MenuRunner(this, ge);
		} catch (Exception e) {
			nextRunner = new MenuRunner(this, new GameException(null, e));
		}

		manageRunners();

		start = SDL_GetTicks();

 		d = new GfxDraw();
		debugText = new GfxDynamicTexture("mc/debugText");
		cameraText = new GfxDynamicTexture("mc/cameraText");
	}

	~this()
	{
		if (sr !is null)
			deleteMe(sr);
		if (mr !is null)
			deleteMe(mr);

		manageRunners();

		if (runner !is null)
			deleteMe(runner);

		manageRunners();

		delete rs;
		delete rm;
		delete d;

		if (debugText !is null)
			debugText.dereference();
		if (cameraText !is null)
			cameraText.dereference();

		if (terrainFile !is null) {
			auto fm = FileManager();
			fm.remBuiltin(terrainFilename);
			std.c.stdlib.free(terrainFile.ptr);
		}
	}

protected:
	/**
	 * Initialize everything.
	 *
	 * Throw GameException if something went wrong.
	 * Throw Exception if something went horribly wrong.
	 */
	void doInit()
	{
		// Borrow terrain.png from minecraft.jar if it can be found.
		setupMinecraftTexture();

		// Most common problem people have is missing terrain.png
		Picture pic = getMinecraftTexture();
		if (pic is null) {
			auto t = format(terrainNotFoundText, chargeConfigFolder);
			throw new GameException(t, null);
		}

		// Another comment that I made after the one below.
		rs = new ResourceStore();

		// I just wanted a comment here to make the code look prettier.
		rm = new RenderManager(pic);

		// Need to manipulate the texture a bit
		rs.setTextures(rm.tex, rm.ta);

		// Not needed anymore.
		pic.dereference();

		// Run the level selector if we where not given a level.
		if (level is null) {
			nextRunner = new MenuRunner(this);
		} else {
			if (!checkLevel(level))
				throw new GameException("Invalid level given", null);
			nextRunner = loadLevel(level);
		}
	}

	void parseArgs(char[][] args)
	{
		for(int i = 1; i < args.length; i++) {
			switch(args[i]) {
			case "-l":
			case "-level":
			case "--level":
				if (++i < args.length) {
					level = args[i];
					break;
				}
				writefln("Expected argument to level switch");
				throw new Exception("");
			case "-a":
			case "-all":
			case "--all":
				build_all = true;
				break;
			default:
				l.fatal("Unknown argument %s", args[i]);
				writefln("Unknown argument %s", args[i]);
			case "-h":
			case "-help":
			case "--help":
				writefln("   -a, --all             - build all chunks near the camera on start");
				writefln("   -l, --level <level>   - to specify level directory");
				writefln("       --license         - print licenses");
				running = false;
				break;
			}
		}
	}

	void setupMinecraftTexture()
	{
		try {
			terrainFile = extractMinecraftTexture();
		} catch (Exception e) {
			l.info("Could not extract terrain.png from minecraft.jar because:");
			l.bug(e.classinfo.name, " ", e);
		}

		if (terrainFile is null)
			return;

		auto fm = FileManager();
		fm.addBuiltin(terrainFilename, terrainFile);
	}

	/**
	 * Load the Minecraft texture.
	 */
	Picture getMinecraftTexture()
	{
		char[][] locations = [
			"terrain.png",
			"res/terrain.png",
			chargeConfigFolder ~ "/terrain.png",
			terrainFilename
		];

		// Skip the imported texture if it was not found
		if (terrainFile is null)
			locations.length = locations.length - 1;

		foreach(l; locations) {
			auto pic = Picture("mc/terrain", l);
			if (pic !is null)
				return pic;
		}

		return null;
	}

	bool checkLevel(char[] level)
	{
		auto ni = checkMinecraftLevel(level);

		if (ni is null) {
			l.fatal("Could not find level.dat in the level directory");
			l.fatal("This probably isn't a level, exiting the viewer.");
			l.fatal("looked in this folder %s", level);
			return false;
		}

		if (!ni.beta) {
			l.fatal("Could not find the region folder in the level directory");
			l.fatal("This probably isn't a beta level, exiting the viewer.");
			l.fatal("looked in this folder %s", level);
			return false;
		}

		return true;
	}

	/*
	 *
	 * Callback functions
	 *
	 */

	void resize(uint w, uint h)
	{
		super.resize(w, h);

		if (runner !is null)
			runner.resize(w, h);
	}

	void logic()
	{
		// Delete and switch runners.
		manageRunners();

		// If we have no runner stop running.
		if (runner is null) {
			running = false;
			return;
		}

		// This make sure we at least always
		// builds at least one chunk per frame.
		built = false;

		// Special case lua runner.
		if (sr !is null) {
			logicTime.stop();
			luaTime.start();
			sr.logic();
			luaTime.stop();
			logicTime.start();
		} else if (runner !is null) {
			runner.logic();
		}

		ticks++;

		auto elapsed = SDL_GetTicks() - start;
		if (elapsed > 1000) {
			const double MB = 1024 * 1024;
			char[] info = std.string.format(
				"Charge%7.1fFPS\n"
				"\n"
				"Memory:\n"
				"   VBO%7.1fMB\n"
				" Chunk%7.1fMB\n"
				"\n"
				"Time:\n"
				"\tgfx   %5.1f%%\n\tctl   %5.1f%%\n"
				"\tnet   %5.1f%%\n\tgame  %5.1f%%\n"
				"\tlua   %5.1f%%\n\tbuild %5.1f%%\n"
				"\tidle  %5.1f%%",
				cast(double)num_frames / (cast(double)elapsed / 1000.0),
				charge.gfx.vbo.VBO.used / MB,
				Chunk.used_mem / MB,
				renderTime.calc(elapsed), inputTime.calc(elapsed),
				networkTime.calc(elapsed), logicTime.calc(elapsed),
				luaTime.calc(elapsed), buildTime.calc(elapsed),
				idleTime.calc(elapsed));

			GfxFont.render(debugText, info);

			num_frames = 0;
			start = elapsed + start;
		}
	}

	void render()
	{
		if (ticks < 2)
			return;
		ticks = 0;

		num_frames++;

		if (runner is null)
			return;

		auto rt = defaultTarget;

		runner.render(rt);

		if (false) {
			d.target = rt;
			d.start();

			auto w = debugText.width + 16;
			auto h = debugText.height + 16;
			auto x = rt.width - debugText.width - 16 - 8;
			d.fill(Color4f(0, 0, 0, .8), true, x, 8, w, h);
			d.blit(debugText, x+8, 16);

			auto grd = cast(GameRunnerBase)runner;
			if (grd !is null) {
				auto p = grd.cam.position;
				char[] info = std.string.format("Camera (%.1f, %.1f, %.1f)", p.x, p.y, p.z);
				GfxFont.render(cameraText, info);

				w = cameraText.width + 16;
				h = cameraText.height + 16;
				d.fill(Color4f(0, 0, 0, .8), true, 8, 8, w, h);
				d.blit(cameraText, 16, 16);
			}

			d.stop();
		}

		rt.swap();
	}

	void idle(long time)
	{
		// If we have built at least one chunk this frame and have very little
		// time left don't build again. But we always build one each frame.
		if (built && time < 10 || runner is null)
			return super.idle(time);

		// Account this time for build instead of idle
		idleTime.stop();
		buildTime.start();

		// Do the build
		built = runner.build();

		// Delete unused resources
		charge.sys.resource.Pool().collect();

		// Switch back to idle
		buildTime.stop();
		idleTime.start();

		// Didn't build anything, just sleep.
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
	 *
	 * Managing runners functions.
	 *
	 */

	void switchTo(GameRunner gr)
	{
		auto r = cast(Runner)gr;
		assert(r !is null);

		nextRunner = r;
	}

	void deleteMe(GameRunner gr)
	{
		auto r = cast(Runner)gr;
		assert(r !is null);

		deleteRunner ~= r;
	}

	Runner loadLevel(char[] dir)
	{
		Runner r;
		BetaWorld w;
		auto info = checkMinecraftLevel(dir);
		if (info is null)
			return null;

		w = new BetaWorld(info, rm, rs);

		auto scriptName = "res/script.lua";
		try {
			r = new ScriptRunner(this, w, rm, scriptName);
		} catch (Exception e) {
			l.fatal("Could not find or run \"%s\" (%s)", scriptName, e);
			r = new ViewerRunner(this, w, rm);
		}

		// No other place to put it.
		if (build_all) {
			l.fatal("Building all, please wait...");
			auto t1 = SDL_GetTicks();
			w.bt.buildAll();
			auto t2 = SDL_GetTicks();
			l.fatal("Build time: %s seconds", (t2 - t1) / 1000.0);
		}

		return r;
	}

	void manageRunners()
	{
		// Delete any pending runners.
		if (deleteRunner.length) {
			foreach(r; deleteRunner) {
				if (r is runner)
					runner = null;
				if (r is sr)
					sr = null;
				if (r is mr)
					mr = null;
				delete r;
			}
			deleteRunner = null;
		}

		// Do the switch of runners.
		if (nextRunner !is null) {
			if (runner !is null)
				runner.dropControl();

			runner = nextRunner;
			sr = cast(ScriptRunner)runner;
			mr = cast(MenuRunner)runner;

			runner.assumeControl();

			nextRunner = null;
		}
	}

	/*
	 *
	 * Error messages.
	 *
	 */

	const char[] terrainNotFoundText =
`Could not find terrain.png! You have a couple of options, easiest is just to
install Minecraft and Charged Miners will get it from there. Another option is
to get one from a texture pack and place it in either the working directory of
the executable. Or in the Charged Miners config folder located here:

%s`;
}

// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.game;

import std.math;
import std.file;
import std.conv;
import std.stdio;
import std.regexp;
import std.string;
import std.c.stdlib;

import lib.sdl.sdl;

import charge.charge;
import charge.sys.file;
import charge.platform.homefolder;

import miners.types;
import miners.world;
import miners.runner;
import miners.viewer;
import miners.options;
import miners.lua.runner;
import miners.lua.builtin;
import miners.gfx.manager;
import miners.beta.world;
import miners.isle.world;
import miners.menu.runner;
import miners.terrain.beta;
import miners.terrain.chunk;
import miners.classic.world;
import miners.classic.runner;
import miners.importer.info;
import miners.importer.network;
import miners.importer.texture;
import miners.importer.classicinfo;


/**
 * Main hub of the minecraft game.
 */
class Game : public GameSimpleApp, public Router
{
private:
	/* program args */
	char[] level;
	bool build_all;
	bool classic;
	bool classicNetwork;
	bool classicHttp;
	char[] username; /**< webpage username */
	char[] password; /**< webpage password */

	/* Classic server information */
	ClassicServerInfo csi;

	/** Regexp for extracting information out of a mc url */
	RegExp mcUrl;
	/** Regexp for extracting information out of a http url */
	RegExp httpUrl;

	/* time keepers */
	charge.game.app.TimeKeeper luaTime;
	charge.game.app.TimeKeeper buildTime;

	Options opts;
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
		mcUrl = RegExp(mcUrlStr);
		httpUrl = RegExp(httpUrlStr);

		// Some defaults
		csi = new ClassicServerInfo();
		csi.username = "Username";
		csi.hostname = "localhost";
		csi.port = 25565;

		running = true;

		parseArgs(args);

		if (!running)
			return;

		/* This will initalize Core and other important things */
		super(coreFlag.AUTO);

		defaultTarget = GfxDefaultTarget();

		try {
			doInit();
		} catch (GameException ge) {
			if (mr is null)
				throw ge;

			mr.displayError(ge, true);
		} catch (Exception e) {
			if (mr is null)
				throw e;

			auto ge = new GameException(null, e);
			mr.displayError(ge, true);
		}

		if (nextRunner is null)
			nextRunner = mr;

		manageRunners();

		start = SDL_GetTicks();

 		d = new GfxDraw();
		debugText = new GfxDynamicTexture("mc/debugText");
		cameraText = new GfxDynamicTexture("mc/cameraText");
	}

	~this()
	{
	}

	void close()
	{
		if (sr !is null)
			deleteMe(sr);
		if (mr !is null)
			deleteMe(mr);

		manageRunners();

		if (runner !is null)
			deleteMe(runner);

		manageRunners();

		delete opts;
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
		GfxTexture dirt;
		Runner r;

		// First init options
		opts = new Options();

		// The menu is used to display error messages
		mr = new MenuRunner(this, opts);

		// Setup the inbuilt script files
		initLuaBuiltins();

		// Most common problem people have is missing terrain.png
		Picture pic = getMinecraftTexture();
		if (pic is null) {
			auto text = format(terrainNotFoundText, chargeConfigFolder);
			throw new GameException(text, null);
		}

		// I just wanted a comment here to make the code look prettier.
		rm = new RenderManager();

		// Another comment that I made after the one above.
		opts.rendererString = rm.s;
		opts.rendererBuildType = rm.bt;
		opts.rendererBuildIndexed = rm.textureArray;
		opts.changeRenderer = &changeRenderer;
		opts.aa = true;
		opts.aa ~= &rm.setAa;
		rm.setAa(opts.aa());
		opts.viewDistance = 256;
		opts.shadow = true;

		// Extract the dirt texture
		Picture dirtPic = getTileAsSeperate(pic, "mc/dirt", 2, 0);
		dirt = GfxTexture("mc/dirt", dirtPic);
		dirt.filter = GfxTexture.Filter.Nearest;
		opts.dirt = dirt;
		dirtPic.dereference();
		dirt.dereference();

		// Do the manipulation of the texture to fit us
		manipulateTexture(pic);
		createTextures(pic, true);

		// Get a texture that works with classic
		manipulateTextureClassic(pic);
		createTextures(pic, false);

		// Not needed anymore.
		pic.dereference();

		// Should we use classic
		if (classic) {
			if (!classicNetwork)
				r = new ClassicRunner(this, opts);
			else if (!classicHttp)
				mr.connect(csi);
			else
				mr.connect(username, password, csi);
		}

		if (r is null && level !is null) {
			r = loadLevel(level);
		}

		// Run the level selector if no other level where given
		if (r is null)
			nextRunner = mr;
		else
			mr.manageThis(r);
	}

	void parseArgs(char[][] args)
	{
		for(int i = 1; i < args.length; i++) {
			switch(args[i]) {
			case "-c":
			case "-classic":
			case "--classic":
				classic = true;
				break;
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
				if (tryArgUrl(args[i]))
					break;

				l.fatal("Unknown argument %s", args[i]);
				writefln("Unknown argument %s", args[i]);
			case "-h":
			case "-help":
			case "--help":
				writefln("   -a, --all             - build all chunks near the camera on start");
				writefln("   -l, --level <level>   - to specify level directory");
				writefln("   -c, --classic         - start a classic level (WIP)");
				writefln("       --license         - print licenses");
				running = false;
				break;
			}
		}
	}

	/**
	 * Try both Urls.
	 */
	bool tryArgUrl(char[] arg)
	{
		return tryArgHttpUrl(arg) || tryArgMcUrl(arg) || tryArgHtml(arg);
	}

	/**
	 * Is this argument a Minecraft http Url?
	 * If so set all the game arguments and switch to classic.
	 */
	bool tryArgHttpUrl(char[] arg)
	{
		auto r = httpUrl.exec(arg);
		if (r.length < 5)
			return false;

		username = r[1];
		password = r[3];
		csi.webId = r[5];

		classic = true;
		classicNetwork = true;
		classicHttp = true;

		l.info("Url http://%s:<redacted>@mc.net/classic/play/%s",
		       username, csi.webId);

		return true;
	}

	/**
	 * Is this argument a Minecraft Url?
	 * If so set all the game arguments and switch to classic.
	 */
	bool tryArgMcUrl(char[] arg)
	{
		auto r = mcUrl.exec(arg);
		if (r.length < 8)
			return false;

		csi.hostname = r[1];

		if (r[5].length > 0)
			csi.username = r[5];
		if (r[7].length > 0)
			csi.verificationKey = r[7];

		try {
			if (r[3].length > 0)
				csi.port = cast(ushort)toUint(r[3]);
		} catch (Exception e) {
		}

		classic = true;
		classicNetwork = true;

		l.info("Url mc://%s:%s/%s/<redacted>",
		       csi.hostname, csi.port, csi.username);

		return true;
	}

	/**
	 * Is this argument a classic play html page? If so extract the
	 * info, set all the game arguments and switch to classic.
	 */
	bool tryArgHtml(char[] arg)
	{
		if (arg.length <= 5)
			return false;

		if (arg[$ - 5 .. $] != ".html")
			return false;

		try {
			auto txt = cast(char[])std.file.read(arg);

			getClassicServerInfo(csi, txt);
		} catch (Exception e) {
			return true;
		}

		classic = true;
		classicNetwork = true;

		l.info("Html mc://%s:%s/%s/<redacted>",
		       csi.hostname, csi.port, csi.username);

		return true;
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
		];

		foreach(l; locations) {
			auto pic = Picture("mc/terrain", l);
			if (pic is null)
				continue;

			this.l.info("Found terrain.png please ignore above warnings");
			return pic;
		}

		// If we can't find a minecraft terrain.png,
		// load it from minecraft.jar
		try {
			terrainFile = extractMinecraftTexture();
			assert(terrainFile !is null);
			l.info("Using borrowed terrain.png from minecraft.jar");
			l.info("Please ignore above warnings");
		} catch (Exception e) {
			l.info("Could not extract terrain.png from minecraft.jar because:");
			l.bug(e.classinfo.name, " ", e);
			return null;
		}

		auto fm = FileManager();
		fm.addBuiltin(terrainFilename, terrainFile);

		return Picture(terrainFilename);
	}

	void createTextures(Picture pic, bool betaTerrain)
	{
		char[] name = betaTerrain ? "mc/terrain" : "mc/classicTerrain";
		GfxTexture t;
		GfxTextureArray ta;

		t = GfxTexture(name, pic);
		// Or we get errors near the block edges
		t.filter = GfxTexture.Filter.Nearest;

		if (betaTerrain)
			opts.terrain = t;
		else
			opts.classicTerrain = t;
		t.dereference();

		if (rm.textureArray) {
			ta = ta.fromTileMap(name, pic, 16, 16);
			ta.filter = GfxTexture.Filter.NearestLinear;

			if (betaTerrain)
				opts.terrainArray = ta;
			else
				opts.classicTerrainArray = ta;
			ta.dereference();
		}
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
			try {
				runner.logic();
			} catch (Exception e) {
				displayError(e, false);
			}
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

		if (opts.showDebug()) {
			d.target = rt;
			d.start();

			auto w = debugText.width + 16;
			auto h = debugText.height + 16;
			auto x = rt.width - debugText.width - 16 - 8;
			d.fill(Color4f(0, 0, 0, .8), true, x, 8, w, h);
			d.blit(debugText, x+8, 16);

			auto grd = cast(GameRunnerBase)runner;
			if (grd !is null && grd.centerer !is null) {
				auto p = grd.centerer.position;
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

	void render(GfxWorld w, GfxCamera cam, GfxRenderTarget rt)
	{
		rm.render(w, cam, rt);
	}

	void changeRenderer()
	{
		rm.switchRenderer();
		opts.setRenderer(rm.bt, rm.s);
	}


	/*
	 *
	 * Error display functions.
	 *
	 */


	void displayError(Exception e, bool panic)
	{
		if (mr is null)
			throw e;
		mr.displayError(e, panic);
	}

	void displayError(char[][] texts, bool panic)
	{
		if (mr is null)
			throw new Exception("Menu runner not running!");
		mr.displayError(texts, panic);
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

	Runner loadLevel(char[] level)
	{
		Runner r;
		World w;

		if (level is null) {
			w = new IsleWorld(opts);
		} else if (isdir(level)) {
			auto info = checkMinecraftLevel(level);

			// XXX Better warning
			if (!info || !info.beta)
				throw new GameException("Invalid Level Given", null);

			w = new BetaWorld(info, opts);
		} else {
			w = new ClassicWorld(opts, level);
		}

		auto scriptName = "script/main-level.lua";
		try {
			r = new ScriptRunner(this, opts, w, scriptName);
		} catch (Exception e) {
			l.fatal("Could not find or run \"%s\" (%s)", scriptName, e);
			r = new ViewerRunner(this, opts, w);
		}

		if (build_all) {
			int times = 5;
			ulong total;

			l.info("Building all %s times, please wait...", times);
			writefln("Building all %s times, please wait...", times);

			for (int i; i < times; i++) {
				w.t.unbuildAll();
				charge.sys.resource.Pool().collect();

				auto t1 = SDL_GetTicks();
				while(w.t.buildOne()) { }
				auto t2 = SDL_GetTicks();

				auto diff = t2 - t1;
				total += i > 0 ? diff : 0;

				l.info("Build time: %s seconds", diff / 1000.0);
				writefln("Build time: %s seconds", diff / 1000.0);
			}

			l.info("Average time: %s seconds", total / (times - 1) / 1000.0);
			writefln("Average time: %s seconds", total / (times - 1) / 1000.0);
		}

		return r;
	}

	void manageRunners()
	{
		// Delete any pending runners.
		if (deleteRunner.length) {
			foreach(r; deleteRunner) {
				// Disable the current runner.
				if (r is runner) {
					runner.dropControl();
					runner = null;
				}

				if (r is nextRunner)
					nextRunner = null;
				if (r is sr)
					sr = null;
				if (r is mr)
					mr = null;

				// The menu might have a reference.
				if (mr !is null)
					mr.notifyDelete(r);

				// To avoid nasty deadlocks with GC.
				r.close();

				// Finally delete it.
				delete r;
			}
			deleteRunner = null;
		}

		// Default to the MenuRunner
		if (runner is null && nextRunner is null) {
			nextRunner = mr;
		}

		// Do the switch of runners.
		if (nextRunner !is null) {
			if (runner !is null)
				runner.dropControl();

			runner = nextRunner;
			sr = cast(ScriptRunner)runner;

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

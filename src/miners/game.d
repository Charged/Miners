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

static import std.gc;
static import gcstats;

import lib.sdl.sdl;

import charge.charge;
import charge.sys.file;
import charge.sys.memory;
import charge.util.memory;
import charge.platform.homefolder;

import miners.types;
import miners.error;
import miners.world;
import miners.runner;
import miners.viewer;
import miners.options;
import miners.interfaces;
import miners.ion.runner;
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

			// Make sure we panic at init.
			ge.panic = true;
			mr.displayError(ge, true);
		} catch (Exception e) {
			if (mr is null)
				throw e;
			mr.displayError(e, true);
		}

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

		auto p = Core().properties;
		p.add(opts.aaName, opts.aa());
		p.add(opts.fogName, opts.fog());
		p.add(opts.shadowName, opts.shadow());
		p.add(opts.useCmdPrefixName, opts.useCmdPrefix());
		p.add(opts.viewDistanceName, opts.viewDistance());

		delete opts;
		delete rm;
		delete d;

		sysReference(&debugText, null);
		sysReference(&cameraText, null);

		if (terrainFile !is null) {
			auto fm = FileManager();
			fm.remBuiltin(terrainFilename);
			cFree(terrainFile.ptr);
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

		// Properties
		auto p = Core().properties;
		p.addIfNotSet(opts.aaName, opts.aaDefault);
		p.addIfNotSet(opts.fogName, opts.fogDefault);
		p.addIfNotSet(opts.shadowName, opts.shadowDefault);
		p.addIfNotSet(opts.viewDistanceName, opts.viewDistanceDefault);
		p.addIfNotSet(opts.useCmdPrefixName, opts.useCmdPrefixDefault);

		double viewDistance = p.getDouble(opts.viewDistanceName, opts.viewDistanceDefault);
		viewDistance = fmax(32, viewDistance);
		viewDistance = fmin(viewDistance, short.max);

		// First init options
		opts = new Options();
		opts.aa = p.getBool(opts.aaName, opts.aaDefault);
		opts.fog = p.getBool(opts.fogName, opts.fogDefault);
		opts.shadow = p.getBool(opts.shadowName, opts.shadowDefault);
		opts.useCmdPrefix = p.getBool(opts.useCmdPrefixName, opts.useCmdPrefixDefault);
		opts.viewDistance = viewDistance;
		debug { opts.showDebug = true; }


		// The menu is used to display error messages
		mr = new MenuRunner(this, opts);

		// Setup the inbuilt script files
		initLuaBuiltins();

		// Most common problem people have is missing terrain.png
		Picture pic = getMinecraftTexture();
		if (pic is null) {
			auto text = format(terrainNotFoundText, chargeConfigFolder);
			throw new GameException(text, null, true);
		}

		// I just wanted a comment here to make the code look prettier.
		rm = new RenderManager();

		// Another comment that I made after the one above.
		opts.rendererString = rm.s;
		opts.rendererBuildType = rm.bt;
		opts.rendererBuildIndexed = rm.textureArray;
		opts.changeRenderer = &changeRenderer;
		opts.aa ~= &rm.setAa;
		rm.setAa(opts.aa());

		// Extract the dirt texture
		Picture dirtPic = getTileAsSeperate(pic, "mc/dirt", 2, 0);
		dirt = GfxTexture("mc/dirt", dirtPic);
		dirt.filter = GfxTexture.Filter.Nearest;
		opts.dirt = dirt;

		sysReference(&dirtPic, null);
		sysReference(&dirt, null);

		// Do the manipulation of the texture to fit us
		manipulateTexture(pic);
		createTextures(pic);

		// Get a texture that works with classic
		manipulateTextureClassic(pic);
		createTextures(pic, true);

		// Not needed anymore.
		sysReference(&pic, null);

		// Should we use classic
		if (classicNetwork) {
			if (!classicHttp)
				mr.connectToClassic(csi);
			else
				mr.connectToClassic(username, password, csi);
		}

		if (level !is null)
			loadLevel(level, false);
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
				if (tryArgUrl(args[i]))
					break;

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

		if (arg[$ - 4 .. $] != ".htm" &&
		    arg[$ - 5 .. $] != ".html")
			return false;

		try {
			auto txt = cast(char[])std.file.read(arg);

			getClassicServerInfo(csi, txt);
		} catch (Exception e) {
			return true;
		}

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

	/**
	 * Create textures and set the option terrain textures. Handleds
	 * both beta- and classic-textures, default is beta. Does not do
	 * any manipulation.
	 *
	 * @classic should the classic options terrain textures be set.
	 */
	void createTextures(Picture pic, bool classic = false)
	{
		char[] name = classic ? "mc/classicTerrain" : "mc/terrain";
		GfxTexture t;
		GfxTextureArray ta;

		t = GfxTexture(name, pic);
		// Or we get errors near the block edges
		t.filter = GfxTexture.Filter.Nearest;

		if (!classic)
			opts.terrain = t;
		else
			opts.classicTerrain = t;
		sysReference(&t, null);

		if (rm.textureArray) {
			ta = ta.fromTileMap(name, pic, 16, 16);
			ta.filter = GfxTexture.Filter.NearestLinear;

			if (!classic)
				opts.terrainArray = ta;
			else
				opts.classicTerrainArray = ta;
			sysReference(&ta, null);
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

		// Run the menu.
		if (mr !is null && mr.active)
			mr.logic();

		ticks++;

		auto elapsed = SDL_GetTicks() - start;
		if (elapsed > 1000) {

			gcstats.GCStats stats;
			std.gc.getStats(stats);

			const double MB = 1024 * 1024;
			char[512] tmp;
			char[] info = sformat(tmp,
				"Charge%7.1fFPS\n"
				"\n"
				"Memory:\n"
				"     C%7.1fMB\n"
				"     D%7.1fMB\n"
				"   Lua%7.1fMB\n"
				"   VBO%7.1fMB\n"
				" Chunk%7.1fMB\n"
				"\n"
				"GC:\n"
				"  used%7.1fMB\n"
				"  pool%7.1fMB\n"
				"  free%7.1fMB\n"
				" pages% 7s\n"
				"  free% 7s\n"
				"\n"
				"Time:\n"
				"\tgfx   %5.1f%%\n\tctl   %5.1f%%\n"
				"\tnet   %5.1f%%\n\tgame  %5.1f%%\n"
				"\tlua   %5.1f%%\n\tbuild %5.1f%%\n"
				"\tidle  %5.1f%%",
				cast(double)num_frames / (cast(double)elapsed / 1000.0),
				charge.sys.memory.MemHeader.getMemory() / MB,
				stats.usedsize / MB,
				lib.lua.state.State.getMemory() / MB,
				charge.gfx.vbo.VBO.used / MB,
				Chunk.used_mem / MB,
				stats.usedsize / MB,
				stats.poolsize / MB,
				stats.freelistsize / MB,
				stats.pageblocks,
				stats.freeblocks,
				renderTime.calc(elapsed), inputTime.calc(elapsed),
				networkTime.calc(elapsed), logicTime.calc(elapsed),
				luaTime.calc(elapsed), buildTime.calc(elapsed),
				idleTime.calc(elapsed));

			GfxFont.render(debugText, info);

			delete info;

			num_frames = 0;
			start = elapsed + start;
		}

		// Do nothing if no runner is running.
		if (runner is null)
			return;

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
				mr.displayError(e, false);
			}
		}
	}

	void render()
	{
		if (ticks < 2)
			return;
		ticks = 0;

		num_frames++;

		auto rt = defaultTarget;

		// Draw dirt background if no runner is running.
		if (runner is null) {
			auto t = opts.dirt();
			d.target = rt;
			d.start();
			d.blit(t, Color4f(1, 1, 1, 1), false,
				0, 0, rt.width / 2, rt.height / 2,
				0, 0, rt.width, rt.height);
			d.stop();
		} else {
			runner.render(rt);
		}

		if (mr !is null && mr.active)
			mr.render(rt);

		if (opts.showDebug()) {
			auto w = debugText.width + 16;
			auto h = debugText.height + 16;
			auto x = rt.width - debugText.width - 16 - 8;

			d.target = rt;
			d.start();
			d.fill(Color4f(0, 0, 0, .8), true, x, 8, w, h);
			d.blit(debugText, x+8, 16);

			auto grd = cast(GameRunnerBase)runner;
			if (grd !is null && grd.centerer !is null) {
				auto p = grd.centerer.position;
				char[256] tmp;
				char[] info = sformat(tmp, "Camera (%.1f, %.1f, %.1f)", p.x, p.y, p.z);
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
	 * Managing runners functions.
	 *
	 */


	void quit()
	{
		running = false;
	}

	MenuManager menu()
	{
		return mr;
	}

	void switchTo(Runner r)
	{
		if (r is null)
			return;
		nextRunner = r;
	}

	void deleteMe(Runner r)
	{
		if (r is null)
			return;

		foreach(dr; deleteRunner)
			if (dr is r)
				return;

		deleteRunner ~= r;
	}

	void backgroundCurrent()
	{
		if (runner !is null)
			runner.dropControl();
		if (mr !is null)
			mr.assumeControl();
	}

	void foregroundCurrent()
	{
		if (runner !is null) {
			runner.assumeControl();
			if (mr !is null)
				mr.dropControl();
		}
	}

	void chargeIon()
	{
		// Close the menu and old runner.
		menu.closeMenu();
		deleteMe(runner);

		switchTo(new IonRunner(this, opts, null));
	}

	void connectedTo(ClassicConnection cc, uint x, uint y, uint z, ubyte[] data)
	{
		auto r = new ClassicRunner(this, opts, cc, x, y, z, data);
		menu.closeMenu();
		deleteMe(runner);

		switchTo(r);
	}

	void loadLevel(char[] level, bool classic = false)
	{
		auto r = doLoadLevel(level, classic);

		// Close the menu and old runner.
		menu.closeMenu();
		deleteMe(runner);

		switchTo(r);
	}

	Runner doLoadLevel(char[] level, bool classic)
	{
		Runner r;
		World w;

		if (classic) {
			if (level is null)
				return new ClassicRunner(this, opts);
			else
				return new ClassicRunner(this, opts, level);
		}


		if (level is null) {
			w = new IsleWorld(opts);
		} else if (isdir(level)) {
			auto info = checkMinecraftLevel(level);

			// XXX Better warning
			if (!info || !info.beta)
				throw new GameException("Invalid Level Given", null, false);

			w = new BetaWorld(info, opts);
		} else {
			w = new ClassicWorld(opts, level);
		}

		auto scriptName = "script/main-level.lua";
		try {
			r = new ScriptRunner(this, opts, w, scriptName);
		} catch (Exception e) {
			l.fatal("Could not find or run \"%s\" (%s)", scriptName, e);
		}

		if (r is null)
			r = new ViewerRunner(this, opts, w);

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

				// To avoid nasty deadlocks with GC.
				r.close();

				// Finally delete it.
				delete r;
			}
			deleteRunner = null;
		}

		// Default to the MenuRunner
		if (runner is null && nextRunner is null &&
		    mr !is null && !mr.active)
			mr.displayMainMenu();

		// Do the switch of runners.
		if (nextRunner !is null) {
			if (runner !is null)
				runner.dropControl();
			if (mr !is null)
				mr.dropControl();

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

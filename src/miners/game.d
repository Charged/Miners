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
import charge.sys.memory;
import charge.util.memory;
import charge.platform.homefolder;

import miners.skin;
import miners.types;
import miners.error;
import miners.world;
import miners.runner;
import miners.viewer;
import miners.options;
import miners.interfaces;
import miners.background;
import miners.ion.runner;
import miners.lua.runner;
import miners.lua.builtin;
import miners.gfx.font;
import miners.gfx.manager;
import miners.beta.world;
import miners.isle.world;
import miners.menu.base;
import miners.menu.main;
import miners.menu.beta;
import miners.menu.list;
import miners.menu.error;
import miners.menu.pause;
import miners.menu.classic;
import miners.menu.blockselector;
import miners.terrain.beta;
import miners.terrain.chunk;
import miners.classic.data;
import miners.classic.world;
import miners.classic.runner;
import miners.classic.startup;
import miners.importer.info;
import miners.importer.network;
import miners.importer.texture;
import miners.importer.classicinfo;

static import miners.builder.classic;


/**
 * Main hub of the minecraft game.
 */
class Game : public GameRouterApp, public Router
{
private:
	/* program args */
	char[] level;
	bool build_all;
	bool classicNetwork;
	bool classicHttp;
	bool classicMc;

	char[] username; /**< webpage username */
	char[] password; /**< webpage password */
	char[] playSessionCookie; /**< webpage cookie */
	char[] launcherPath; /**< Launch this on logout */

	/* Classic server information */
	ClassicServerInfo csi;

	/** Regexp for extracting information out of a mc url */
	RegExp mcUrl;
	/** Regexp for extracting information out of a http url */
	RegExp httpUrl;
	/**
	 * Regexp for extracting information out of a http url,
	 * with username and password.
	 */
	RegExp httpUserPassUrl;
	/** Regexp for extracting the play session cookie */
	RegExp playSessionCookieExp;
	/** Regexp for extracting the launcher path */
	RegExp launcherPathExp;


	/* time keepers */
	charge.game.app.TimeKeeper buildTime;

	Options opts;
	RenderManager rm;
	GfxDefaultTarget defaultTarget;

	SkinDownloader skin;

	bool built; /**< Have we built a chunk */

	int ticks;

	GfxDraw d;

	// Extracted files from minecraft
	void[] terrainFile;
	const terrainFilename = "%terrain.png";

	alias bool delegate() BuilderDg;
	Vector!(BuilderDg) builders;

public:
	mixin SysLogging;

	this(char[][] args)
	{
		mcUrl = RegExp(mcUrlStr);
		httpUrl = RegExp(httpUrlStr);
		httpUserPassUrl = RegExp(httpUserPassUrlStr);
		playSessionCookieExp = RegExp(playSessionCookieStr);
		launcherPathExp = RegExp(launcherPathStr);

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
		auto opts = new CoreOptions();
		opts.title = "Charged Miners";
		super(opts);

		defaultTarget = GfxDefaultTarget();

		try {
			doInit();
		} catch (GameException ge) {
			// Make sure we panic at init.
			ge.panic = true;
			displayError(ge, true);
		} catch (Exception e) {
			displayError(e, true);
		}

		manageRunners();

 		d = new GfxDraw();
	}

	~this()
	{
		assert(builders.length == 0);
	}

	void close()
	{
		deleteAll();

		manageRunners();

		deleteAll();

		manageRunners();

		if (skin !is null) {
			skin.close();
			delete skin;
		}

		auto p = Core().properties;
		p.add(opts.aaName, opts.aa());
		p.add(opts.fogName, opts.fog());
		p.add(opts.shadowName, opts.shadow());
		p.add(opts.useCmdPrefixName, opts.useCmdPrefix());
		p.add(opts.viewDistanceName, opts.viewDistance());
		p.add(opts.lastClassicServerName, opts.lastClassicServer());

		delete opts;
		delete rm;
		delete d;

		if (terrainFile !is null) {
			auto fm = FileManager();
			fm.remBuiltin(terrainFilename);
			cFree(terrainFile.ptr);
		}

		super.close();
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
		// This needs to be done first,
		// so errors messages can be displayed.
		BackgroundRunner br = new BackgroundRunner();
		push(br);

		GfxTexture dirt;

		// For options
		auto p = Core().properties;

		// Have to validate the view distance value.
		double viewDistance = p.getIfNotFoundSet(opts.viewDistanceName, opts.viewDistanceDefault);
		viewDistance = fmax(32, viewDistance);
		viewDistance = fmin(viewDistance, short.max);

		// First init options
		opts = new Options();
		opts.playSessionCookie = playSessionCookie;
		opts.aa = p.getIfNotFoundSet(opts.aaName, opts.aaDefault);
		opts.fog = p.getIfNotFoundSet(opts.fogName, opts.fogDefault);
		opts.shadow = p.getIfNotFoundSet(opts.shadowName, opts.shadowDefault);
		opts.useCmdPrefix = p.getIfNotFoundSet(opts.useCmdPrefixName, opts.useCmdPrefixDefault);
		opts.lastClassicServer = p.getIfNotFoundSet(opts.lastClassicServerName, opts.lastClassicServerDefault);
		opts.viewDistance = viewDistance;
		debug { opts.showDebug = true; }
		for (int i; i < opts.keyNames.length; i++)
			opts.keyArray[i] =  p.getIfNotFoundSet(opts.keyNames[i], opts.keyDefaults[i]);

		// Setup the inbuilt script files
		initLuaBuiltins();

		auto defSkin = GfxColorTexture(Color4f.White);
		skin = new SkinDownloader(defSkin);
		opts.getSkin = &skin.getSkin;
		sysReference(&defSkin, null);

		// Most common problem people have is missing terrain.png
		Picture pic = getMinecraftTexture();
		if (pic is null) {
			auto text = format(terrainNotFoundText, chargeConfigFolder);
			throw new GameException(text, null, true);
		}

		// Now lets poke around with gfx stuff.
		opts.aa = opts.aa() && GfxDoubleTarget.check;

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
		opts.background = dirt;
		opts.backgroundDoubled = true;

		sysReference(&dirtPic, null);
		sysReference(&dirt, null);

		// Do the manipulation of the texture to fit us
		manipulateTexture(pic);
		createTextures(pic);

		// Get a texture that works with classic
		manipulateTextureClassic(pic);
		createTextures(pic, true);

		assert(classicBlocks.length == opts.classicSides.length);

		foreach (int i, ref tex; opts.classicSides) {
			if (!classicBlocks[i].placable)
				continue;

			// Get the location of the block
			ubyte index = miners.builder.classic.tile[i].xzTex;
			int x = index % 16;
			int y = index / 16;

			auto texPic = getTileAsSeperate(pic, null, x, y);

			// XXX Hack for half slabs
			if (i == 44) {
				auto d = texPic.pixels[0 .. texPic.width * texPic.height];
				d[$ / 2 .. $] = d[0 .. $ / 2];
				d[0 .. $ / 2] = Color4b(0, 0, 0, 0);
			}

			tex = GfxTexture(null, texPic);
			tex.filter = tex.width <= 32 ? GfxTexture.Filter.Nearest :
			                               GfxTexture.Filter.NearestLinear;

			sysReference(&texPic, null);
		}

		// Not needed anymore.
		sysReference(&pic, null);

		// Install the classic font handler.
		auto cf = ClassicFont("res/font.png");
		opts.classicFont = cf;
		sysReference(&cf, null);

		// Update the background.
		br.initOpts(opts);

		// Should we use classic
		if (classicNetwork) {
			if (classicMc) {
				return connectToClassic(csi);
			} else if (classicHttp) {
				if (playSessionCookie !is null)
					return getClassicServerInfoAndConnect(csi);
				else
					return connectToClassic(username, password, csi);
			} else if (playSessionCookie !is null) {
				return startClassicStartup();
			}
		}

		if (level !is null)
			return loadLevel(level, false);

		return displayMainMenu();
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
				if (tryArgs(args[i]))
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
	 * Try all arguments.
	 */
	bool tryArgs(char[] arg)
	{
		return tryArgHttpUrl(arg) || tryArgMcUrl(arg) ||
		       tryArgHtml(arg)    || tryArgCookie(arg) ||
		       tryArgLauncherPath(arg);
	}

	void checkHttpMc()
	{
		if (classicHttp || classicMc) {
			l.warn("Error: multiple url/mc/html-page arguemnts");
			writefln("Error: multiple url/mc/html-page arguemnts");
			running = false;
		}
	}

	/**
	 * Is this argument a Minecraft http Url?
	 * If so set all the game arguments and switch to classic.
	 */
	bool tryArgHttpUrl(char[] arg)
	{
		auto r = httpUrl.exec(arg);
		if (r.length < 2)
			return false;

		csi.webId = r[2];

		classicNetwork = true;
		classicHttp = true;

		l.info("Url http://minecraft.net/classic/play/%s", csi.webId);

		return true;
	}

	/**
	 * Is this argument a Minecraft http Url?
	 * If so set all the game arguments and switch to classic.
	 */
	bool tryArgHttpUserPassUrl(char[] arg)
	{
		auto r = httpUserPassUrl.exec(arg);
		if (r.length < 5)
			return false;

		username = r[1];
		password = r[3];
		csi.webId = r[5];

		checkHttpMc();

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

		checkHttpMc();

		classicNetwork = true;
		classicMc = true;

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
			return false;
		}

		checkHttpMc();

		classicNetwork = true;
		classicMc = true;

		l.info("Html mc://%s:%s/%s/<redacted>",
		       csi.hostname, csi.port, csi.username);

		return true;
	}

	/**
	 * Is this argument a Minecraft PLAY_SESSION cookie?
	 */
	bool tryArgCookie(char[] arg)
	{
		auto r = playSessionCookieExp.exec(arg);
		if (r.length < 2)
			return false;

		playSessionCookie = r[1];

		classicNetwork = true;

		l.info("PLAY_SESSION=<redacted>");

		return true;
	}

	/**
	 * Is this argument a LAUNCHER_PATH info string?
	 */
	bool tryArgLauncherPath(char[] arg)
	{
		auto r = launcherPathExp.exec(arg);
		if (r.length < 2)
			return false;

		launcherPath = r[1];

		l.info("LAUNCHER_PATH=%s", launcherPath);

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

		//if (runner !is null)
		//	runner.resize(w, h);
	}

	void logic()
	{
		ticks++;

		// This make sure we at least always
		// builds at least one chunk per frame.
		built = false;

		GameRouterApp.logic();
	}

	void render()
	{
		if (ticks < 2)
			return;
		ticks = 0;

		GameRouterApp.render();
	}

	void idle(long time)
	{
		// If we have built at least one chunk this frame and have very little
		// time left don't build again. But we always build one each frame.
		if (built && time < 5 || builders.length == 0)
			return super.idle(time);

		// Account this time for build instead of idle
		idleTime.stop();
		buildTime.start();

		// Do the build
		foreach(b; builders)
			built = b() || built;

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

	void addBuilder(bool delegate() dg)
	{
		builders ~= dg;
	}

	void removeBuilder(bool delegate() dg)
	{
		builders.remove(dg);
	}

	void startClassicStartup()
	{
		push(new ClassicStartup(this, opts));
	}

	void chargeIon()
	{
		Runner r;

		try {
			r = new IonRunner(this, opts, null);
		} catch (Exception e) {
			displayError(e, false);
			return;
		}

		push(r);
	}

	void connectedTo(ClassicConnection cc, uint x, uint y, uint z, ubyte[] data)
	{
		auto r = new ClassicRunner(this, opts, cc, x, y, z, data);
		push(r);
	}

	void loadLevel(char[] level, bool classic = false)
	{
		auto r = doLoadLevel(level, classic);

		// Close the menu and old runner.
		push(r);
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


	/*
	 *
	 * MenuManager functions.
	 *
	 */


	void displayMainMenu()
	{
		push(new MainMenu(this, opts));
	}

	void displayPauseMenu()
	{
		push(new PauseMenu(this, opts));
	}

	void displayLevelSelector()
	{
		try {
			auto lm = new LevelMenu(this, opts);
			push(lm);
		} catch (Exception e) {
			displayError(e, false);
		}
	}

	void displayClassicBlockSelector(void delegate(ubyte) selectedDg)
	{
		push(new ClassicBlockMenu(this, opts, selectedDg));
	}

	void displayClassicMenu()
	{
		auto psc = opts.playSessionCookie();

		push(new WebpageInfoMenu(this, opts, psc));
	}

	void displayClassicList(ClassicServerInfo[] csis)
	{
		push(new ClassicServerListMenu(this, opts, csis));
	}

	void getClassicServerInfoAndConnect(ClassicServerInfo csi)
	{
		auto psc = opts.playSessionCookie();

		push(new WebpageInfoMenu(this, opts, psc, csi));
	}

	void connectToClassic(char[] usr, char[] pwd, ClassicServerInfo csi)
	{
		push(new WebpageInfoMenu(this, opts, usr, pwd, csi));
	}

	void connectToClassic(ClassicServerInfo csi)
	{
		push(new ClassicConnectingMenu(this, opts, csi));
	}

	void classicWorldChange(ClassicConnection cc)
	{
		push(new ClassicConnectingMenu(this, opts, cc));
	}

	void displayInfo(char[] header, char[][] texts,
	                 char[] buttonText, void delegate() dg)
	{
		push(new InfoMenu(this, opts, header, texts, buttonText, dg));
	}

	void displayError(Exception e, bool panic)
	{
		// Always handle exception via the game exception.
		auto ge = cast(GameException)e;
		if (ge is null)
			ge = new GameException(null, e, panic);


		char[][] texts;
		auto next = ge.next;

		if (next is null) {
			texts = [ge.toString()];
		} else {
			texts = [
				ge.toString(),
				next.classinfo.name,
				next.toString()
			];
		}

		displayError(texts, ge.panic);
	}

	void displayError(char[][] texts, bool panic)
	{
		push(new ErrorMenu(this, texts, panic));
	}
}

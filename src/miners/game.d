// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.game;

import std.file : isfile, isdir;
import std.conv : toUint;
import std.stdio : writefln;
import std.regexp : RegExp;
import std.string : format;

import lib.sdl.sdl;

import charge.charge;
import charge.sys.file;
import charge.sys.memory;
import charge.util.png;
import charge.util.memory;
import charge.platform.homefolder;

import miners.skin;
import miners.types;
import miners.error;
import miners.world;
import miners.runner;
import miners.viewer;
import miners.defines;
import miners.startup;
import miners.options;
import miners.debugger;
import miners.interfaces;
import miners.background;
import miners.ion.runner;
import miners.lua.runner;
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
import miners.classic.world;
import miners.classic.runner;
import miners.importer.info;
import miners.importer.network;
import miners.importer.texture;
import miners.importer.classicinfo;

static import miners.builder.classic;


/**
 * Main hub of the minecraft game.
 */
class Game : GameRouterApp, Router
{
private:
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

	Options opts;
	RenderManager rm;
	GfxDefaultTarget defaultTarget;

	SkinDownloader skin;

	DebugRunner dr;

	GfxDraw d;

public:
	mixin SysLogging;

	this(string[] args)
	{
		mcUrl = RegExp(mcUrlStr);
		httpUrl = RegExp(httpUrlStr);
		httpUserPassUrl = RegExp(httpUserPassUrlStr);
		playSessionCookieExp = RegExp(playSessionCookieStr);
		launcherPathExp = RegExp(launcherPathStr);

		running = true;

		// Arguments stored on options.
		opts = new Options();

		// Some defaults
		auto csi = opts.classicServerInfo = new ClassicServerInfo();
		csi.username = "Username";
		csi.hostname = "localhost";
		csi.port = 25565;

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

	void close()
	{
		deleteMe(dr);
		dr = null;

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
		p.add(opts.fovName, opts.fov());
		p.add(opts.fogName, opts.fog());
		p.add(opts.shadowName, opts.shadow());
		p.add(opts.uiSizeName, opts.uiSize());
		p.add(opts.speedRunName, opts.speedRun());
		p.add(opts.speedWalkName, opts.speedWalk());
		p.add(opts.failsafeName, opts.failsafe);
		p.add(opts.lastMcUrlName, opts.lastMcUrl());
		p.add(opts.useCmdPrefixName, opts.useCmdPrefix());
		p.add(opts.viewDistanceName, opts.viewDistance());
		p.add(opts.lastClassicServerName, opts.lastClassicServer());
		p.add(opts.lastClassicServerHashName, opts.lastClassicServerHash());

		breakApartAndNull(opts);

		delete rm;
		delete d;

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
		BackgroundRunner br = new BackgroundRunner(opts);
		push(br);

		auto p = Core().properties;
		opts.failsafe = p.getIfNotFoundSet(opts.failsafeName, false);

		// Setup the renderer manager.
		rm = new RenderManager(opts.failsafe);
		opts.rendererString = rm.s;
		opts.rendererBuildType = rm.bt;
		opts.rendererBackground = rm.canDoDeferred;
		opts.rendererBuildIndexed = rm.textureArray;
		opts.changeRenderer = &changeRenderer;
		opts.aa ~= &rm.setAa;
		rm.setAa(opts.aa());

		// Always create the debug runner,
		// only use it on debug builds.
		dr = new DebugRunner(this);
		opts.showDebug ~= &showDebug;
		// Will push the runner now if debug build.
		debug { opts.showDebug = true; }

		// Setup the skin loader.
		auto defSkin = GfxColorTexture(SysPool(), Color4f.White);
		opts.defaultSkin = defSkin;
		skin = new SkinDownloader(opts);
		opts.getSkin = &skin.getSkin;
		sysReference(&defSkin, null);

		return push(new StartupRunner(this, opts, &doneStartup));
	}

	void doneStartup()
	{
		// Should we use classic
		if (opts.isClassicNetwork) {
			auto csi = opts.classicServerInfo;
			if (opts.isClassicMcUrl) {
				return connectToClassic(csi);
			} else if (opts.isClassicResume) {
				auto ret = tryArgMcUrl(opts.lastMcUrl());
				if (!ret)
					throw new GameException(
						"Invalid mcUlr to resume from.", null, true);
				return connectToClassic(csi);
			} else if (opts.isClassicHttp) {
				if (opts.playSessionCookie !is null)
					return getClassicServerInfoAndConnect(csi);
				else
					return connectToClassic(
						opts.username,
						opts.password,
						csi);
			} else if (opts.classicServerList !is null) {
				return displayClassicList(opts.classicServerList);
			} else {
				throw new GameException("Classic arguments in wrong state", null, true);
			}
		}

		if (opts.levelPath !is null)
			return loadLevelModern(opts.levelPath);

		return displayMainMenu();
	}

	void parseArgs(string[] args)
	{
		for(int i = 1; i < args.length; i++) {
			switch(args[i]) {
			case "-l":
			case "-level":
			case "--level":
				if (++i < args.length) {
					opts.levelPath = args[i];
					break;
				}
				writefln("Expected argument to level switch");
				throw new Exception("");
			case "-a":
			case "-all":
			case "--all":
				opts.shouldBuildAll = true;
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
			case "--resume":
				opts.isClassicResume = true;
				opts.isClassicNetwork = true;
				opts.inhibitClassicListLoad = true;
				break;
			}
		}
	}

	/**
	 * Try all arguments.
	 */
	bool tryArgs(string arg)
	{
		return tryArgHttpUrl(arg) || tryArgMcUrl(arg) ||
		       tryArgHtml(arg)    || tryArgCookie(arg) ||
		       tryArgLauncherPath(arg);
	}

	void checkHttpMcUrl()
	{
		if (opts.isClassicHttp || opts.isClassicMcUrl) {
			l.warn("Error: multiple url/mc/html-page arguemnts");
			writefln("Error: multiple url/mc/html-page arguemnts");
			running = false;
		}
	}

	/**
	 * Is this argument a Minecraft http Url?
	 * If so set all the game arguments and switch to classic.
	 */
	bool tryArgHttpUrl(string arg)
	{
		auto r = httpUrl.exec(arg);
		if (r.length < 2)
			return false;

		checkHttpMcUrl();

		auto csi = opts.classicServerInfo;
		csi.webId = r[2];

		opts.isClassicNetwork = true;
		opts.isClassicHttp = true;
		opts.inhibitClassicListLoad = true;

		l.info("Url http://minecraft.net/classic/play/%s", csi.webId);

		return true;
	}

	/**
	 * Is this argument a Minecraft http Url?
	 * If so set all the game arguments and switch to classic.
	 */
	bool tryArgHttpUserPassUrl(string arg)
	{
		auto r = httpUserPassUrl.exec(arg);
		if (r.length < 5)
			return false;

		checkHttpMcUrl();

		auto csi = opts.classicServerInfo;
		csi.webId = r[5];

		opts.username = r[1];
		opts.password = r[3];

		opts.isClassicNetwork = true;
		opts.isClassicHttp = true;
		opts.inhibitClassicListLoad = true;

		l.info("Url http://%s:<redacted>@mc.net/classic/play/%s",
		       opts.username, csi.webId);

		return true;
	}

	/**
	 * Is this argument a Minecraft Url?
	 * If so set all the game arguments and switch to classic.
	 */
	bool tryArgMcUrl(string arg)
	{
		auto r = mcUrl.exec(arg);
		if (r.length < 8)
			return false;

		checkHttpMcUrl();

		auto csi = opts.classicServerInfo;
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

		opts.isClassicNetwork = true;
		opts.isClassicMcUrl = true;
		opts.inhibitClassicListLoad = true;

		l.info("Url mc://%s:%s/%s/<redacted>",
		       csi.hostname, csi.port, csi.username);

		return true;
	}

	/**
	 * Is this argument a classic play html page? If so extract the
	 * info, set all the game arguments and switch to classic.
	 */
	bool tryArgHtml(string arg)
	{
		if (arg.length <= 5)
			return false;

		if (arg[$ - 4 .. $] != ".htm" &&
		    arg[$ - 5 .. $] != ".html")
			return false;

		checkHttpMcUrl();

		auto csi = opts.classicServerInfo;
		try {
			auto txt = cast(char[])std.file.read(arg);

			getClassicServerInfo(csi, txt);
		} catch (Exception e) {
			return false;
		}

		opts.isClassicNetwork = true;
		opts.isClassicMcUrl = true;
		opts.inhibitClassicListLoad = true;

		l.info("Html mc://%s:%s/%s/<redacted>",
		       csi.hostname, csi.port, csi.username);

		return true;
	}

	/**
	 * Is this argument a Minecraft PLAY_SESSION cookie?
	 */
	bool tryArgCookie(string arg)
	{
		auto r = playSessionCookieExp.exec(arg);
		if (r.length < 2)
			return false;

		opts.playSessionCookie = r[1];

		opts.isClassicNetwork = true;

		l.info("PLAY_SESSION=<redacted>");

		return true;
	}

	/**
	 * Is this argument a LAUNCHER_PATH info string?
	 */
	bool tryArgLauncherPath(string arg)
	{
		auto r = launcherPathExp.exec(arg);
		if (r.length < 2)
			return false;

		opts.launcherPath = r[1];

		l.info("LAUNCHER_PATH=%s", opts.launcherPath);

		return true;
	}

	bool checkLevel(string level)
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


	void logic()
	{
		if (skin !is null)
			skin.doTick();

		super.logic();
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

	void showDebug(bool value)
	{
		if (value)
			push(dr);
		else
			remove(dr);
	}


	/*
	 *
	 * Managing runners functions.
	 *
	 */


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

	void loadLevelModern(string level)
	{
		Runner r;
		World w;

		if (level is null) {
			w = new IsleWorld(opts);
		} else if (isdir(level)) {
			auto info = checkMinecraftLevel(level);

			// XXX Better warning
			if (!info || !info.beta)
				throw new GameException("Invalid Level Given", null, false);

			w = new BetaWorld(info, opts);
		} else {
			throw new GameException("Level needs to be a directory", null, false);
		}

		auto scriptName = "script/main-level.lua";
		try {
			r = new ScriptRunner(this, opts, w, scriptName);
		} catch (Exception e) {
			l.fatal("Could not find or run \"%s\" (%s)", scriptName, e);
		}

		if (r is null)
			r = new ViewerRunner(this, opts, w);

		if (opts.shouldBuildAll) {
			int times = 5;
			ulong total;

			l.info("Building all %s times, please wait...", times);
			writefln("Building all %s times, please wait...", times);

			for (int i; i < times; i++) {
				w.t.unbuildAll();
				SysPool().collect();

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

		push(r);
	}

	void loadLevelClassic(string level)
	{
		Runner r;

		if (level is null)
			r = new ClassicRunner(this, opts);
		else if (isfile(level))
			r = new ClassicRunner(this, opts, level);
		else
			throw new GameException("Level must be a file", null, false);

		push(r);
	}


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
		push(new PauseMenu(this, opts, null));

	}

	void displayClassicPauseMenu(Runner part)
	{
		push(new PauseMenu(this, opts, part));
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
		auto psc = opts.playSessionCookie;

		push(new WebpageInfoMenu(this, opts, psc));
	}

	void displayClassicList(ClassicServerInfo[] csis)
	{
		push(new ClassicServerListMenu(this, opts, csis));
	}

	void getClassicServerInfoAndConnect(ClassicServerInfo csi)
	{
		auto psc = opts.playSessionCookie;

		push(new WebpageInfoMenu(this, opts, psc, csi));
	}

	void connectToClassic(string usr, string pwd, ClassicServerInfo csi)
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

	void displayInfo(string header, string[] texts,
	                 string buttonText, void delegate() dg)
	{
		push(new InfoMenu(this, opts, header, texts, buttonText, dg));
	}

	void displayError(Exception e, bool panic)
	{
		// Always handle exception via the game exception.
		auto ge = cast(GameException)e;
		if (ge is null)
			ge = new GameException(null, e, panic);


		string[] texts;
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

	void displayError(string[] texts, bool panic)
	{
		push(new ErrorMenu(this, texts, panic));
	}
}

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
import miners.defines;
import miners.startup;
import miners.options;
import miners.interfaces;
import miners.background;
import miners.gfx.manager;
import miners.menu.base;
import miners.menu.main;
import miners.menu.list;
import miners.menu.error;
import miners.menu.pause;
import miners.menu.classic;
import miners.menu.blockselector;
import miners.classic.world;
import miners.classic.scene;
import miners.classic.interfaces;
import miners.importer.parser;
import miners.importer.network;

static import miners.builder.classic;


/**
 * Main hub of the minecraft game.
 */
class Game : GameSceneManagerApp, Router
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
	/** Regexp for extracting ClassiCube option */
	RegExp useClassiCubeExp;

	Options opts;
	RenderManager rm;
	GfxDefaultTarget defaultTarget;

	SkinDownloader skin;

	GameDebuggerScene dr;

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
		useClassiCubeExp = RegExp(useClassiCubeStr);

		running = true;

		// Arguments stored on options.
		opts = new Options();

		// Some defaults
		auto csi = opts.classicServerInfo = new ClassicServerInfo();
		csi.username = "Username";
		csi.hostname = "localhost";
		csi.port = 25565;

		parseArgs(args);

		if (!running) {
			auto opts = new CoreOptions();
			opts.title = "Charged Miners";
			opts.flags = coreFlag.CTL;
			super(opts);
			running = false;
			return;
		}

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

		manageScenes();

 		d = new GfxDraw();
	}

	override void close()
	{
		deleteMe(dr);
		dr = null;

		deleteAll();

		manageScenes();

		deleteAll();

		manageScenes();

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
		BackgroundScene br = new BackgroundScene(opts);
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

		// Always create the debug scene,
		// only use it on debug builds.
		dr = new GameDebuggerScene();
		opts.showDebug ~= &showDebug;
		// Will push the scene now if debug build.
		debug { opts.showDebug = true; }

		// Setup the skin loader.
		auto defSkin = GfxColorTexture(SysPool(), Color4f.White);
		opts.defaultSkin = defSkin;
		skin = new SkinDownloader(opts);
		opts.getSkin = &skin.getSkin;
		sysReference(&defSkin, null);

		return push(new StartupScene(this, opts, &doneStartup));
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
		       tryArgLauncherPath(arg) || tryArgUseClassiCube(arg);
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

	/**
	 * Is this argument a USE_CLASSICUBE string?
	 */
	bool tryArgUseClassiCube(string arg)
	{
		auto r = useClassiCubeExp.exec(arg);
		if (r.length < 2)
			return false;

		opts.useClassiCube = (r[1] == "true");

		l.info("USE_CLASSICUBE=%s", r[1]);

		return true;
	}


	/*
	 *
	 * Callback functions
	 *
	 */


	override void logic()
	{
		if (skin !is null)
			skin.doTick();

		super.logic();
	}

	override void render(GfxWorld w, GfxCamera cam, GfxRenderTarget rt)
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
	 * Managing scenes functions.
	 *
	 */


	void connectedTo(ClassicClientConnection cc, uint x, uint y, uint z, ubyte[] data)
	{
		auto r = new ClassicScene(this, opts, cc, x, y, z, data);
		push(r);
	}

	void loadLevelClassic(string level)
	{
		Scene r;

		if (level is null)
			r = new ClassicScene(this, opts);
		else if (isfile(level))
			r = new ClassicScene(this, opts, level);
		else
			throw new GameException("Level must be a file", null, false);

		push(r);
	}


	/*
	 *
	 * MenuManager functions.
	 *
	 */


	override void displayMainMenu()
	{
		push(new MainMenu(this, opts));
	}

	void displayPauseMenu()
	{
		push(new PauseMenu(this, opts, null));

	}

	override void displayClassicPauseMenu(Scene part)
	{
		push(new PauseMenu(this, opts, part));
	}

	override void displayClassicBlockSelector(void delegate(ubyte) selectedDg)
	{
		push(new ClassicBlockMenu(this, opts, selectedDg));
	}

	override void displayClassicMenu()
	{
		auto psc = opts.playSessionCookie;

		push(new WebpageInfoMenu(this, opts, psc));
	}

	override void displayClassicList(ClassicServerInfo[] csis)
	{
		push(new ClassicServerListMenu(this, opts, csis));
	}

	override void getClassicServerInfoAndConnect(ClassicServerInfo csi)
	{
		if (csi.hostname !is null && csi.username !is null &&
		    csi.verificationKey !is null && csi.port != 0) {
			connectToClassic(csi);
			return;
		}

		auto psc = opts.playSessionCookie;

		push(new WebpageInfoMenu(this, opts, psc, csi));
	}

	override void connectToClassic(string usr, string pwd, ClassicServerInfo csi)
	{
		push(new WebpageInfoMenu(this, opts, usr, pwd, csi));
	}

	override void connectToClassic(ClassicServerInfo csi)
	{
		push(new ClassicConnectingMenu(this, opts, csi));
	}

	override void classicWorldChange(ClassicClientConnection cc)
	{
		push(new ClassicConnectingMenu(this, opts, cc));
	}

	override void displayInfo(string header, string[] texts,
	                          string buttonText, void delegate() dg)
	{
		push(new InfoMenu(this, opts, header, texts, buttonText, dg));
	}

	override void displayError(Exception e, bool panic)
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

	override void displayError(string[] texts, bool panic)
	{
		push(new ErrorMenu(this, texts, panic));
	}
}

// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.startup;

import std.math : fmax, fmin;

import charge.charge;

import charge.platform.homefolder;
static import charge.game.startup;
import charge.game.gui.container;

import miners.logo;
import miners.types;
import miners.runner;
import miners.options;
import miners.interfaces;
import miners.gfx.font;
import miners.classic.data;
import miners.classic.webpage;
import miners.importer.texture;


alias charge.game.startup.Task GameTask;
alias charge.game.startup.StartupRunner GameStartupRunner;

/**
 * StartupRunner specialized for Miners,
 * launches main menu when it is done.
 */
class StartupRunner : GameStartupRunner
{
public:
	Router r;
	Options opts;

	alias void delegate() DoneDg;
	DoneDg dg;


private:
	bool switchedBackground;


public:
	this(Router r, Options opts, DoneDg dg)
	{
		this.r = r;
		this.dg = dg;
		this.opts = opts;
		super(r);

		if (opts.playSessionCookie !is null)
			addTask(new ClassicGetList(this, opts));

		addTask(new CreateLogo(this, opts));
	}


protected:
	void handleNoTaskLeft()
	{
		if (!switchedBackground) {
			switchedBackground = true;
			return addTask(new CreateTiledBackground(this, opts));
		}

		if (errors !is null)
			r.displayError(errors, false);
		else if (dg !is null)
			dg();
		else
			r.displayMainMenu();
		r.deleteMe(this);
	}

	void handleEscapePressed()
	{
		r.quit();
	}
}

/**
 * Tiny helper class.
 */
class OptionsTask : GameTask
{
protected:
	Options opts;
	StartupRunner startup;


public:
	this(StartupRunner startup, Options opts)
	{
		this.opts = opts;
		this.startup = startup;
		super(startup);
	}
}

/**
 * Creates the logo and sets it as the background.
 */
class CreateLogo : OptionsTask
{
	this(StartupRunner startup, Options opts)
	{
		text = "Creating logo";
		super(startup, opts);
	}

	void close() {}

	bool build()
	{
		auto tex = GfxTexture("background.png");
		if (tex !is null) {
			setBackground(tex);
			sysReference(&tex, null);
			return done();
		}

		auto logo = new Logo(null, 0, 0);
		auto aat = new AntiAliasingContainer(null, 0, 0, logo.w, logo.h);
		auto tt = new TextureContainer(logo.w, logo.h);

		aat.add(logo);
		tt.add(aat);

		aat.paintTexture();
		tt.paintTexture();

		setBackground(tt.texture);
		tt.breakApart();

		return done();
	}

	bool done()
	{
		signalDone();

		nextTask(new OptionsLoader(startup, opts));

		return true;
	}

	void setBackground(GfxTexture tex)
	{
		opts.background = tex;
		opts.backgroundTiled = false;
		opts.backgroundDoubled = false;
	}
}

/**
 * Loads options.
 */
class OptionsLoader : OptionsTask
{
	this(StartupRunner startup, Options opts)
	{
		text = "Loading options";
		super(startup, opts);
	}

	void close() {}

	bool build()
	{
		// Initialize the shared resources.
		opts.allocateResources();

		// For options
		auto p = Core().properties;

		// Have to validate the view distance value.
		double viewDistance = p.getIfNotFoundSet(
			opts.viewDistanceName, opts.viewDistanceDefault);
		viewDistance = fmax(32, viewDistance);
		viewDistance = fmin(viewDistance, short.max);

		// First init options
		opts.aa = p.getIfNotFoundSet(opts.aaName, opts.aaDefault);
		opts.fov = p.getIfNotFoundSet(opts.fovName, opts.fovDefault);
		opts.fog = p.getIfNotFoundSet(opts.fogName, opts.fogDefault);
		opts.shadow = p.getIfNotFoundSet(opts.shadowName, opts.shadowDefault);
		opts.useCmdPrefix = p.getIfNotFoundSet(
			opts.useCmdPrefixName, opts.useCmdPrefixDefault);
		opts.lastClassicServer = p.getIfNotFoundSet(
			opts.lastClassicServerName, opts.lastClassicServerDefault);
		opts.viewDistance = viewDistance;
		for (int i; i < opts.keyNames.length; i++)
			opts.keyArray[i] =  p.getIfNotFoundSet(
				opts.keyNames[i], opts.keyDefaults[i]);

		signalDone();

		nextTask(new LoadModernTexture(startup, opts));

		return true;
	}
}

/**
 * Loads the terrain texture.
 */
class LoadModernTexture : OptionsTask
{
	mixin SysLogging;

	this(StartupRunner startup, Options opts)
	{
		text = "Loading Modern Texture";
		super(startup, opts);
	}

	void close() {}

	bool build()
	{
		auto pic = getModernTerrainTexture();
		if (pic is null) {
			signalError(["Could not load terrain.png"]);
			return false;
		} else {
			l.info("Found terrain.png please ignore above warnings");
		}

		// Do the manipulation of the texture to fit us
		manipulateTextureModern(pic);

		opts.modernTerrainPic = pic;
		opts.modernTextures = createTextures(pic, opts.rendererBuildIndexed);

		sysReference(&pic, null);

		signalDone();
		nextTask(new LoadClassicTexture(startup, opts));

		return true;
	}
}

/**
 * Loads the classic terrain texture.
 */
class LoadClassicTexture : OptionsTask
{
	mixin SysLogging;

	this(StartupRunner startup, Options opts)
	{
		text = "Loading Classic Texture";
		super(startup, opts);
	}

	void close() {}

	bool build()
	{
		// Get a texture that works with classic
		auto pic = getClassicTerrainTexture();
		if (pic is null) {
			// Copy and manipulate
			pic = Picture(null, opts.modernTerrainPic());
			manipulateTextureClassic(pic);
		}
		opts.classicTerrainPic = pic;
		opts.classicTextures = createTextures(pic, opts.rendererBuildIndexed);

		sysReference(&pic, null);

		signalDone();
		nextTask(new LoadClassicIcons(startup, opts));

		return true;
	}
}

/**
 * Loads the classic icons textures.
 */
class LoadClassicIcons : OptionsTask
{
	int pos;

	this(StartupRunner startup, Options opts)
	{
		text = "Loading Classic Icons";
		super(startup, opts);
	}

	void close() {}

	bool build()
	{
		auto pic = opts.classicTerrainPic();

		// Create the textures for the classic block selector
		static assert(classicBlocks.length == opts.classicSides.length);
		foreach (int i, ref outTex; opts.classicSides) {
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

			auto tex = GfxTexture(null, texPic);
			tex.filter = tex.width <= 32 ? GfxTexture.Filter.Nearest :
			                               GfxTexture.Filter.NearestLinear;

			sysReference(&outTex, tex);
			sysReference(&tex, null);
			sysReference(&texPic, null);
		}

		signalDone();

		nextTask(new LoadClassicFont(startup, opts));

		return true;
	}
}

/**
 * Loads the classic font.
 */
class LoadClassicFont : OptionsTask
{
	int pos;

	this(StartupRunner startup, Options opts)
	{
		text = "Loading Classic Font";
		super(startup, opts);
	}

	void close() {}

	bool build()
	{
		// Install the classic font handler.
		auto cf = ClassicFont("res/font.png");
		opts.classicFont = cf;
		sysReference(&cf, null);

		signalDone();

		return true;
	}
}

/**
 * Creates the cog pattern background and sets it as background.
 *
 * Last thing that happens during load, to switch background.
 */
class CreateTiledBackground : OptionsTask
{
	this(StartupRunner startup, Options opts)
	{
		text = "Loading Background";
		super(startup, opts);
	}

	void close() {}

	bool build()
	{
		// See if the user has overridden the background.
		auto tex = GfxTexture("background.tiled.png");
		if (tex !is null) {
			setBackground(tex, true);
			sysReference(&tex, null);
			return done();
		}

		// Try the other one as well.
		tex = GfxTexture("background.png");
		if (tex !is null) {
			setBackground(tex, false);
			sysReference(&tex, null);
			return done();
		}

		auto cog = new Cogwheel(null, 0, 0, 32, 32, 26, 12);
		auto aat = new AntiAliasingContainer(null, 0, 0, cog.w, cog.h);
		auto tt = new TextureContainer(cog.w, cog.h);

		aat.add(cog);
		tt.add(aat);

		aat.paintTexture();
		tt.paintTexture();

		opts.background = tt.texture;
		opts.backgroundTiled = true;
		opts.backgroundDoubled = false;

		tt.breakApart();

		return done();
	}

	bool done()
	{
		signalDone();

		return false;
	}

	void setBackground(GfxTexture tex, bool tiled)
	{
		opts.background = tex;
		opts.backgroundTiled = tiled;
		opts.backgroundDoubled = false;
	}
}

class ClassicGetList : public OptionsTask, public ClassicWebpageListener
{
private:
	WebpageConnection wc;


public:
	this(StartupRunner startup, Options opts)
	{
		text = "Connecting";
		super(startup, opts);

		wc = new WebpageConnection(this, opts.playSessionCookie);
	}

	~this()
	{
		assert(wc is null);
	}

	void close()
	{
		if (wc !is null) {
			wc.close();
			delete wc;
		}
	}

	bool build()
	{
		if (wc !is null)
			wc.doTick();

		// Don't want to be called again this frame.
		return false;
	}


	/*
	 *
	 * Webpage related functions.
	 *
	 */


	void shutdownConnection()
	{
		if (wc !is null) {
			try {
				wc.close();
			} catch (Exception e) {
				cast(void)e;
			}

			delete wc;
		}
	}

	void authenticate()
	{
		assert(false, "Can not authenticate!");
	}

	void getServerList()
	{
		wc.getServerList();

		text = "Retriving server list";

		percentage(0);
	}


	/*
	 *
	 * Webpage connection callbacks
	 *
	 */


	void connected()
	{
		if (opts.playSessionCookie is null)
			authenticate();
		else
			getServerList();
	}

	void percentage(int p)
	{
		completed = p;
	}

	void authenticated()
	{
		assert(false, "Does not deal with authentication");
	}

	void serverList(ClassicServerInfo[] csis)
	{
		shutdownConnection();

		opts.classicServerList = csis;
		signalDone();
	}

	void serverInfo(ClassicServerInfo csi)
	{
		assert(false, "Does not deal with server info");
	}

	void error(Exception e)
	{
		shutdownConnection();

		signalError(["Disconnected", e.toString()]);
	}

	void disconnected()
	{
		// The server closed the connection peacefully.
		shutdownConnection();

		signalError(["Disconnected"]);
	}
}

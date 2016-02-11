// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.startup;

import std.string : format;
import std.math : fmax, fmin;
import std.file : write;

import charge.charge;
import charge.math.ints : imax, imin;
import charge.util.png : pngDecode;
import charge.util.memory : cFree;

import charge.platform.homefolder;
static import charge.game.scene.startup;
import charge.game.gui.container;

import miners.logo;
import miners.types;
import miners.options;
import miners.defines;
import miners.interfaces;
import miners.gfx.font;
import miners.classic.data;
import miners.classic.webpage;
import miners.importer.texture;


/**
 * StartupScene specialized for Miners,
 * launches main menu when it is done.
 */
class StartupScene : GameStartupScene
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

		addTask(new CreateLogo(this, opts));
	}


protected:
	override void handleNoTaskLeft()
	{
		if (!switchedBackground) {
			switchedBackground = true;
			return addTask(new CreateTiledBackground(this, opts));
		}

		if (errors !is null) {
			r.displayError(errors, true);
		} else if (dg !is null) {
			try {
				dg();
			} catch(Exception e) {
				r.displayError(e, true);
			}
		} else {
			r.displayMainMenu();
		}

		r.deleteMe(this);
	}

	override void handleEscapePressed()
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
	StartupScene startup;


public:
	this(StartupScene startup, Options opts)
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
	this(StartupScene startup, Options opts)
	{
		text = "Creating logo";
		super(startup, opts);
	}

	override void close() {}

	override bool build()
	{
		auto p = SysPool();
		p.suppress404 = true;
		scope(exit)
			p.suppress404 = false;

		auto tex = GfxTexture(p, "background.png");
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
	this(StartupScene startup, Options opts)
	{
		text = "Loading options";
		super(startup, opts);
	}

	override void close() {}

	override bool build()
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

		// Have to validate the fov value
		int fov = p.getIfNotFoundSet(opts.fovName, opts.fovDefault);
		fov = imax(40, fov);
		fov = imin(fov, 120);

		int uiSize = p.getIfNotFoundSet(opts.uiSizeName, opts.uiSizeDefault);
		uiSize = imax(1, uiSize);
		uiSize = imin(uiSize, 4);

		// First init options
		opts.aa = p.getIfNotFoundSet(opts.aaName, opts.aaDefault);
		opts.fov = fov;
		opts.fog = p.getIfNotFoundSet(opts.fogName, opts.fogDefault);
		opts.shadow = p.getIfNotFoundSet(opts.shadowName, opts.shadowDefault);
		opts.uiSize = uiSize;
		opts.speedRun = p.getIfNotFoundSet(opts.speedRunName, opts.speedRunDefault);
		opts.speedWalk = p.getIfNotFoundSet(opts.speedWalkName, opts.speedWalkDefault);
		opts.lastMcUrl = p.getIfNotFoundSet(
				opts.lastMcUrlName, opts.lastMcUrlDefault);
		opts.useCmdPrefix = p.getIfNotFoundSet(
			opts.useCmdPrefixName, opts.useCmdPrefixDefault);
		opts.lastClassicServer = p.getIfNotFoundSet(
			opts.lastClassicServerName, opts.lastClassicServerDefault);
		opts.lastClassicServerHash = p.getIfNotFoundSet(
			opts.lastClassicServerHashName, opts.lastClassicServerHashDefault);
		opts.viewDistance = viewDistance;

		for (int i; i < opts.keyNames.length; i++)
			opts.keyArray[i] =  p.getIfNotFoundSet(
				opts.keyNames[i], opts.keyDefaults[i]);

		if (!checkCommonErrors())
			return false;

		signalDone();

		// This is done here to make sure that options are
		// loaded before any error is raised by this task.
		if (opts.playSessionCookie !is null &&
		    !opts.inhibitClassicListLoad)
			startup.addTask(new ClassicGetList(startup, opts));

		nextTask(new LoadDefaultSkin(startup, opts));

		return true;
	}

	bool checkCommonErrors()
	{
		string gfxError =
			"Your graphics card does not provide the features\n"
			"necessary to run Charged Miners, sorry. You can\n"
			"try to update your drivers to the latest one.\n"
			"Even modern Intel cards are know to have problems.";

		// Some cards can't support the forward renderer needed.
		if (opts.rendererBuildType != TerrainBuildTypes.CompactMesh) {
			signalError([gfxError]);
			return false;
		}

		return true;
	}
}

/**
 * Loads and downloads the default skin.
 */
class LoadDefaultSkin : OptionsTask, NetDownloadListener
{
public:
	const string path = "/images/char.png";
	const string hostname = "minecraft.net";
	const ushort port = 80;
	const string filename = "skin.png";


private:
	NetDownloadConnection dl;

	mixin SysLogging;


public:
	this(StartupScene startup, Options opts)
	{
		text = "Loading default skin";
		super(startup, opts);
	}

	override void close()
	{
		if (dl !is null) {
			dl.close();
			dl = null;
		}
	}

	override bool build()
	{
		if (dl !is null) {
			dl.doTick();
			return false;
		}

		GfxTexture defSkin;

		try {
			defSkin = GfxTexture(SysPool(), filename);
		} catch (Exception e) {
			signalError(["Could not load default skin", e.toString]);
			return false;
		}

		if (defSkin is null) {
			dl = new NetDownloadConnection(this, hostname, port);
			return true;
		}

		defSkin.filter = GfxTexture.Filter.NearestLinear;
		opts.defaultSkin = defSkin;
		sysReference(&defSkin, null);

		signalDone();

		nextTask(new LoadDefaultClassicTerrain(startup, opts));

		return true;
	}

	override void connected()
	{
		dl.getDownload(path);
	}

	override void percentage(int p)
	{
		completed = p;
	}

	override void downloaded(void[] data)
	{
		l.warn("D %s", data.length);

		write(filename, data);
		dl.close();
		dl = null;
	}

	override void error(Exception e)
	{
		signalError([e.toString]);
	}

	override void disconnected()
	{
		signalError(["Got disconnected when downloading default skin"]);
	}
}

/**
 * Loads and downloads the default classic terrain.
 */
class LoadDefaultClassicTerrain : OptionsTask, NetDownloadListener
{
public:
	const string path = "/releases/terrain.default.png";
	const string hostname = "cm-cdn.fcraft.net";
	const ushort port = 80;


private:
	NetDownloadConnection dl;

	mixin SysLogging;


public:
	this(StartupScene startup, Options opts)
	{
		text = "Loading default terrain";
		super(startup, opts);
	}

	override void close()
	{
		if (dl !is null) {
			dl.close();
			dl = null;
		}
	}

	override bool build()
	{
		if (dl !is null) {
			dl.doTick();
			return false;
		}

		Picture defTerrain;

		try {
			defTerrain = Picture(SysPool(), defaultClassicTerrainTexture);
		} catch (Exception e) {
			signalError(["Could not load default terrain", e.toString]);
			return false;
		}

		if (defTerrain is null) {
			dl = new NetDownloadConnection(this, hostname, port);
			return true;
		}

		opts.defaultClassicTerrain = defTerrain;
		sysReference(&defTerrain, null);

		signalDone();

		nextTask(new LoadModernTexture(startup, opts));

		return true;
	}

	override void connected()
	{
		dl.getDownload(path);
	}

	override void percentage(int p)
	{
		completed = p;
	}

	override void downloaded(void[] data)
	{
		l.warn("D %s", data.length);

		write(defaultClassicTerrainTexture, data);
		dl.close();
		dl = null;
	}

	override void error(Exception e)
	{
		signalError(["Could not download default terrain", e.toString]);
	}

	override void disconnected()
	{
		signalError(["Got disconnected when downloading default terrain"]);
	}
}

/**
 * Loads the terrain texture.
 */
class LoadModernTexture : OptionsTask
{
	mixin SysLogging;

	this(StartupScene startup, Options opts)
	{
		text = "Loading Modern Texture";
		super(startup, opts);
	}

	override void close() {}

	override bool build()
	{
		auto p = SysPool();
		p.suppress404 = true;
		scope(exit)
			p.suppress404 = false;

		if (opts.borrowedModernTerrainPic() is null)
			borrowModernTerrainTexture();

		auto pic = getModernTerrainTexture(p);
		if (pic is null) {
			l.info("Found no modern terrain.png, trying to load classic ones.");
			signalDone();
			nextTask(new LoadClassicTexture(startup, opts));
			return true;
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

	/**
	 * Borrow the modern terrain.png form minecraft.jar.
	 */
	void borrowModernTerrainTexture()
	{
		// Try and load the terrain png file from minecraft.jar.
		try {
			auto data = extractModernMinecraftTexture();
			scope(exit)
				cFree(data.ptr);

			auto img = pngDecode(data, true);
			scope(exit)
				delete img;

			auto pic = Picture(SysPool(), borrowedModernTerrainTexture, img);
			scope(exit)
				sysReference(&pic, null);

			opts.borrowedModernTerrainPic = pic;
			l.info("Found terrain.png in minecraft.jar, might use it.");
		} catch (Exception e) {
			l.info("Could not extract terrain.png from minecraft.jar because:");
			l.info(e.classinfo.name, " ", e);
			return;
		}
	}
}

/**
 * Loads the classic terrain texture.
 */
class LoadClassicTexture : OptionsTask
{
	mixin SysLogging;

	this(StartupScene startup, Options opts)
	{
		text = "Loading Classic Texture";
		super(startup, opts);
	}

	override void close() {}

	override bool build()
	{
		auto p = SysPool();
		p.suppress404 = true;
		scope(exit)
			p.suppress404 = false;

		if (opts.borrowedClassicTerrainPic() is null)
			borrowClassicTerrainTexture();

		// Get a texture that works with classic
		auto pic = getClassicTerrainTexture(p);
		if (pic is null) {
			sysReference(&pic, opts.defaultClassicTerrain());
		}

		if (pic is null) {
			if (opts.modernTerrainPic() is null) {
					auto text = format(terrainNotFoundText, chargeConfigFolder);
					signalError([text]);
					return false;
			}

			// Copy and manipulate
			pic = Picture(opts.modernTerrainPic());
			manipulateTextureClassic(pic);

			l.info("Using a modified modern terrain.png for classic terrain.");
		}

		opts.classicTerrainPic = pic;
		opts.classicTextures = createTextures(pic, opts.rendererBuildIndexed);

		sysReference(&pic, null);

		signalDone();
		nextTask(new LoadClassicIcons(startup, opts));

		return true;
	}

	/**
	 * Borrow the modern terrain.png form minecraft.jar.
	 */
	void borrowClassicTerrainTexture()
	{
		// Try and load the terrain png file from minecraft.jar.
		try {
			auto data = extractClassicMinecraftTexture();
			scope(exit)
				cFree(data.ptr);

			auto img = pngDecode(data, true);
			scope(exit)
				delete img;

			auto pic = Picture(SysPool(), borrowedClassicTerrainTexture, img);
			scope(exit)
				sysReference(&pic, null);

			opts.borrowedClassicTerrainPic = pic;
			l.info("Found terrain.png in minecraft.jar, might use it.");
		} catch (Exception e) {
			l.info("Could not extract terrain.png from minecraft.jar because:");
			l.info(e.classinfo.name, " ", e);
			return;
		}
	}

	const string terrainNotFoundText =
`Could not find terrain.png! You have a couple of options, easiest is just to
install Minecraft and Charged Miners will get it from there. Another option is
to get one from a texture pack and place it in either the working directory of
the executable. Or in the Charged Miners config folder located here:

%s`;
}

/**
 * Loads the classic icons textures.
 */
class LoadClassicIcons : OptionsTask
{
	int pos;

	this(StartupScene startup, Options opts)
	{
		text = "Loading Classic Icons";
		super(startup, opts);
	}

	override void close() {}

	override bool build()
	{
		auto pic = opts.classicTerrainPic();

		// Create the textures for the classic block selector
		static assert(classicBlocks.length == opts.classicSides.length);
		foreach (int i, ref outTex; opts.classicSides) {
			// Get the location of the block
			ubyte index = miners.builder.classic.tile[i].xzTex;
			int x = index % 16;
			int y = index / 16;

			auto texPic = getTileAsSeperate(pic, x, y);

			// XXX Hack for half slabs
			if (i == 44) {
				auto d = texPic.pixels[0 .. texPic.width * texPic.height];
				d[$ / 2 .. $] = d[0 .. $ / 2];
				d[0 .. $ / 2] = Color4b(0, 0, 0, 0);
			}

			auto tex = GfxTexture(texPic);
			tex.filter = GfxTexture.Filter.NearestLinear;

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

	static class ClassicFontHandler
	{
		Options opts;

		final void newUiSize(int size)
		{
			// Install the classic font.
			auto cf = ClassicFont(SysPool(), "res/font.png", opts.uiSize());
			opts.classicFont = cf;
			sysReference(&cf, null);
		}
	}

	this(StartupScene startup, Options opts)
	{
		text = "Loading Classic Font";
		super(startup, opts);
	}

	override void close() {}

	override bool build()
	{
		auto cfh = new ClassicFontHandler();
		cfh.opts = opts;
		cfh.newUiSize(opts.uiSize());

		// Install the classic font handler.
		opts.uiSize ~= &cfh.newUiSize;

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
	this(StartupScene startup, Options opts)
	{
		text = "Loading Background";
		super(startup, opts);
	}

	override void close() {}

	override bool build()
	{
		auto p = SysPool();
		p.suppress404 = true;
		scope(exit)
			p.suppress404 = false;

		// See if the user has overridden the background.
		auto tex = GfxTexture(p, "background.tiled.png");
		if (tex !is null) {
			setBackground(tex, true);
			sysReference(&tex, null);
			return done();
		}

		// Try the other one as well.
		tex = GfxTexture(p, "background.png");
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

class ClassicGetList : OptionsTask, ClassicWebpageListener
{
private:
	WebpageConnection wc;


public:
	this(StartupScene startup, Options opts)
	{
		text = "Connecting";
		super(startup, opts);

		wc = new WebpageConnection(this, opts.playSessionCookie, opts.useClassiCube);
	}

	~this()
	{
		assert(wc is null);
	}

	override void close()
	{
		if (wc !is null) {
			wc.close();
			delete wc;
		}
	}

	override bool build()
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


	override void connected()
	{
		if (opts.playSessionCookie is null)
			authenticate();
		else
			getServerList();
	}

	override void percentage(int p)
	{
		completed = p;
	}

	override void authenticated()
	{
		assert(false, "Does not deal with authentication");
	}

	override void serverList(ClassicServerInfo[] csis)
	{
		shutdownConnection();

		if (csis.length == 0)
			return signalError([
				"Did not get any servers from server list!",
				"Probably failed to parse the list.",
				"Or you didn't supply the correct PLAY_SESSION cookie."]);

		opts.classicServerList = csis;
		signalDone();
	}

	override void serverInfo(ClassicServerInfo csi)
	{
		assert(false, "Does not deal with server info");
	}

	override void error(Exception e)
	{
		shutdownConnection();

		signalError(["Disconnected", e.toString()]);
	}

	override void disconnected()
	{
		// The server closed the connection peacefully.
		shutdownConnection();

		signalError(["Disconnected"]);
	}
}

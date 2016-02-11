// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for CommonCore.
 */
module charge.platform.core.common;

import lib.loader;
import lib.al.al;
import lib.al.loader;
import lib.ode.ode;
import lib.ode.loader;

import charge.core;
import charge.sfx.sfx;
import charge.phy.phy;
import charge.sys.logger;
import charge.sys.file;
import charge.sys.resource;
import charge.util.properties;
import charge.platform.homefolder;


class CommonCore : Core
{
protected:
	// Not using mixin, because we are pretending to be Core.
	static Logger l;

	string settingsFile;
	Properties p;

	/* run time libraries */
	Library ode;
	Library openal;
	Library alut;

	/* for sound, should be move to sfx */
	ALCdevice* alDevice;
	ALCcontext* alContext;

	bool odeLoaded; /**< did we load the ODE library */
	bool openalLoaded; /**< did we load the OpenAL library */

	/* name of libraries to load */
	version(Windows)
	{
		const string[] libODEname = ["ode.dll"];
		const string[] libOpenALname = ["OpenAL32.dll"];
		const string[] libALUTname = ["alut.dll"];
	}
	else version(linux)
	{
		const string[] libODEname = ["libode.so"];
		const string[] libOpenALname = ["libopenal.so", "libopenal.so.1"];
		const string[] libALUTname = ["libalut.so"];
	}
	else version(darwin)
	{
		const string[] libODEname = ["./libode.dylib"];
		const string[] libOpenALname = ["OpenAL.framework/OpenAL"];
		const string[] libALUTname = ["./libalut.dylib"];
	}


protected:
	static this()
	{
		// Pretend to be the Core class when logging.
		l = Logger(Core.classinfo);
	}

	this(coreFlag flags)
	{
		super(flags);

		const phyFlags = coreFlag.PHY | coreFlag.AUTO;
		const sfxFlags = coreFlag.SFX | coreFlag.AUTO;

		initSettings();

		resizeSupported = p.getBool("forceResizeEnable", defaultForceResizeEnable);

		// Load libraries
		if (flags & phyFlags)
			loadPhy();

		if (flags & sfxFlags)
			loadSfx();

		// Init sub system
		if (flags & phyFlags)
			initPhy(p);

		if (flags & sfxFlags)
			initSfx(p);
	}

	override void initSubSystem(coreFlag flag)
	{
		const not = coreFlag.PHY | coreFlag.SFX;

		if (flag & ~not)
			throw new Exception("Flag not supported");

		if (flag == not)
			throw new Exception("More then one flag not supported");

		if (flag & coreFlag.PHY) {
			if (phyLoaded)
				return;

			flags |= coreFlag.PHY;
			loadPhy();
			initPhy(p);

			if (phyLoaded)
				return;

			flags &= ~coreFlag.PHY;
			throw new Exception("Could not load PHY");
		}

		if (flag & coreFlag.SFX) {
			if (sfxLoaded)
				return;

			flags |= coreFlag.SFX;
			loadSfx();
			initSfx(p);

			if (sfxLoaded)
				return;

			flags &= ~coreFlag.SFX;
			throw new Exception("Could not load SFX");
		}
	}

	void notLoaded(coreFlag mask, string name)
	{
		if (flags & mask)
			l.fatal("Could not load %s, crashing bye bye!", name);
		else
			l.info("%s not found, this not an error.", name);
	}

	override Properties properties()
	{
		return p;
	}


	/*
	 *
	 * Init and close functions
	 *
	 */


	void loadPhy()
	{
		if (odeLoaded)
			return;

		version(DynamicODE) {
			ode = Library.loads(libODEname);
			if (ode is null) {
				notLoaded(coreFlag.PHY, "ODE");
			} else {
				loadODE(&ode.symbol);
				odeLoaded = true;
			}
		} else {
			odeLoaded = true;
		}
	}

	void loadSfx()
	{
		if (openalLoaded)
			return;

		openal = Library.loads(libOpenALname);
		alut = Library.loads(libALUTname);

		if (!openal) {
			notLoaded(coreFlag.SFX, "OpenAL");
		} else {
			openalLoaded = true;
			loadAL(&openal.symbol);
		}

		if (!alut)
			l.info("ALUT not found, this is not an error.");
		else
			loadALUT(&alut.symbol);
	}

	void initSettings()
	{
		settingsFile = chargeConfigFolder ~ "/settings.ini";
		p = Properties(settingsFile);

		if (p is null) {
			l.warn("Failed to load settings useing defaults");

			p = new Properties;
		} else {
			l.info("Settings loaded: %s", settingsFile);
		}

		p.addIfNotSet("w", defaultWidth);
		p.addIfNotSet("h", defaultHeight);
		p.addIfNotSet("fullscreen", defaultFullscreen);
		p.addIfNotSet("fullscreenAutoSize", defaultFullscreenAutoSize);
		p.addIfNotSet("forceResizeEnable", defaultForceResizeEnable);
	}

	void saveSettings()
	{
		auto ret = p.save(settingsFile);
		if (ret)
			l.info("Settings saved: %s", settingsFile);
		else
			l.error("Failed to save settings file %s", settingsFile);
	}


	/*
	 *
	 * Init and close functions for subsystems
	 *
	 */


	void initPhy(Properties p)
	{
		if (!odeLoaded)
			return;

		dInitODE2(0);
		dAllocateODEDataForThread(dAllocateMaskAll);

		phyLoaded = true;
	}

	void closePhy()
	{
		if (!phyLoaded)
			return;

		dCloseODE();

		phyLoaded = false;
	}

	void initSfx(Properties p)
	{
		if (!openalLoaded)
			return;

		alDevice = alcOpenDevice(null);

		if (alDevice) {
			alContext = alcCreateContext(alDevice, null);
			alcMakeContextCurrent(alContext);

			sfxLoaded = true;
		}
	}

	void closeSfx()
	{
		if (!openalLoaded)
			return;

		if (alContext)
			alcDestroyContext(alContext);
		if (alDevice)
			alcCloseDevice(alDevice);

		sfxLoaded = false;
	}
}

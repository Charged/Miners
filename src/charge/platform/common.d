// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.platform.common;

import lib.loader;
import lib.al.al;
import lib.ode.ode;

import charge.core;
import charge.sfx.sfx;
import charge.phy.phy;
import charge.sys.logger;
import charge.sys.properties;
import charge.sys.file;
import charge.sys.resource;
import charge.platform.homefolder;

class CommonCore : public Core
{
protected:
	static Logger l;

	char[] settingsFile;
	Properties p;


	/* run time libraries */
	Library ode;
	Library openal;
	Library alut;

	/* for sound, should be move to sfx */
	ALCdevice* alDevice;
	ALCcontext* alContext;

	bool odeLoaded; /**< did we load the ODE library */

	/* name of libraries to load */
	version(Windows)
	{
		const char[][] libODEname = ["ode.dll"];
		const char[][] libOpenALname = ["OpenAL32.dll"];
		const char[][] libALUTname = ["alut.dll"];
	}
	else version(linux)
	{
		const char[][] libODEname = ["libode.so"];
		const char[][] libOpenALname = ["libopenal.so", "libopenal.so.1"];
		const char[][] libALUTname = ["libalut.so"];
	}
	else version(darwin)
	{
		const char[][] libODEname = ["./libode.dylib"];
		const char[][] libOpenALname = ["OpenAL.framework/OpenAL"];
		const char[][] libALUTname = ["./libalut.dylib"];
	}


protected:
	static this()
	{
		// Pretend to be the Core class when logging.
		l = Logger(Core.classinfo);
	}


	/*
	 *
	 * Init and close functions
	 *
	 */


	void loadLibraries()
	{
		openal = Library.loads(libOpenALname);
		alut = Library.loads(libALUTname);

		if (!openal)
			l.fatal("Could not load OpenAL, crashing bye bye!");

		if (!alut)
			l.info("ALUT not found, this is not an error.");

		version(DynamicODE) {
			ode = Library.loads(libODEname);
			if (ode is null) {
				l.info("ODE not found, this not an error.");
			} else {
				loadODE(&ode.symbol);
				odeLoaded = true;
			}
		} else {
			odeLoaded = true;
		}
	}

	void initBuiltins()
	{
		auto fm = FileManager();

		void[] defaultPicture = import("default.png");

		fm.addBuiltin("res/default.png", defaultPicture);
		fm.addBuiltin("res/spotlight.png", defaultPicture);
	}

	void initSettings()
	{
		settingsFile = chargeConfigFolder ~ "/settings.ini";
		p = Properties(settingsFile);

		if (p is null) {
			l.warn("Failed to load settings useing defaults");

			p = new Properties;
			p.add("w", defaultWidth);
			p.add("h", defaultHeight);
			p.add("fullscreen", defaultFullscreen);
			p.add("title", defaultTitle);
		}
	}

	void saveSettings()
	{
		p.save(settingsFile);
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
		loadAL(&openal.symbol);
		alDevice = alcOpenDevice(null);

		if (alDevice) {
			alContext = alcCreateContext(alDevice, null);
			alcMakeContextCurrent(alContext);

			sfxLoaded = true;
		}

		if (alut !is null && sfxLoaded)
			loadALUT(&alut.symbol);
	}

	void closeSfx()
	{
		if (alContext)
			alcDestroyContext(alContext);
		if (alDevice)
			alcCloseDevice(alDevice);

		sfxLoaded = false;
	}
}

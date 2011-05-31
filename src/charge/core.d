// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.core;

private
{
	static import std.string;
	import std.file;
	import std.stdio;
	import std.string;

	import lib.loader;
	import lib.al.al;
	import lib.gl.gl;
	import lib.ode.ode;
	import lib.sdl.sdl;
	import lib.sdl.image;
	import lib.sdl.ttf;

	import charge.sfx.sfx;
	import charge.gfx.gfx;
	import charge.gfx.target;
	import charge.phy.phy;
	import charge.sys.logger;
	import charge.sys.properties;
	import charge.sys.file;
	import charge.sys.resource;
	import charge.platform.homefolder;
}

class Core
{
public:
	const int defaultWidth = 800;
	const int defaultHeight = 600;
	const bool defaultFullscreen = false;
	const char[] defaultTitle = "Charged Miners";

private:
	mixin Logging;
	static Core instance;

	char[] settingsFile;
	Properties p;

	int screenshotNum;
	uint width, height;
	bool fullscreen;
	bool resizeSupported;

	/* surface for window */
	SDL_Surface *s;

	/* run time libraries */
	Library ode;
	Library glu;
	Library sdl;
	Library ttf;
	Library image;
	Library openal;
	Library alut;

	/* for sound, should be move to sfx */
	ALCdevice* alDevice;
	ALCcontext* alContext;

	/* name of libraries to load */
	version(Windows)
	{
		const char[][] libSDLname = ["SDL.dll"];
		const char[][] libSDLImage = ["SDL_image.dll"];
		const char[][] libSDLttf = ["SDL_ttf.dll"];
		const char[][] libODEname = ["ode.dll"];
		const char[][] libGLUname = ["glu32.dll"];
		const char[][] libOpenALname = ["OpenAL32.dll"];
		const char[][] libALUTname = ["alut.dll"];
	}
	else version(linux)
	{
		const char[][] libSDLname = ["libSDL.so", "libSDL-1.2.so.0"];
		const char[][] libSDLImage = ["libSDL_image.so", "libSDL_image-1.2.so.0"];
		const char[][] libSDLttf = ["libSDL_ttf.so", "libSDL_ttf-2.0.so.0"];
		const char[][] libODEname = ["libode.so"];
		const char[][] libGLUname = ["libGLU.so", "libGLU.so.1"];
		const char[][] libOpenALname = ["libopenal.so", "libopenal.so.1"];
		const char[][] libALUTname = ["libalut.so"];
	}
	else version(darwin)
	{
		const char[][] libSDLname = ["SDL.framework/SDL"];
		const char[][] libSDLImage = ["SDL_image.framework/SDL_image"];
		const char[][] libSDLttf = ["SDL_ttf.framework/SDL_ttf"];
		const char[][] libODEname = ["./libode.dylib"];
		const char[][] libGLUname = ["OpenGL.framework/OpenGL"];
		const char[][] libOpenALname = ["OpenAL.framework/OpenAL"];
		const char[][] libALUTname = ["./libalut.dylib"];
	}


	static this()
	{
		instance = new Core();
	}

	this()
	{

	}

public:
	void screenShot()
	{
		char[] filename;
		ubyte *pixels;

		// Find the first free screenshot name
		do {
			filename = format("screenshot-%03s.bmp", screenshotNum++);
		} while(exists(filename));

		// Surface where we will store the fliped image and save from.
		auto temp = SDL_CreateRGBSurface(
			SDL_SWSURFACE, width, height, 24,
			0x000000FF, 0x0000FF00, 0x00FF0000, 0);

		if (temp == null)
			return;
		scope(exit)
			SDL_FreeSurface(temp);

		pixels = cast(ubyte*)std.c.stdlib.malloc(3 * width * height);
		if (pixels == null)
			return;
		scope(exit)
			std.c.stdlib.free(pixels);

		// Read the image from GL
		glReadPixels(0, 0, width, height,
			     GL_RGB, GL_UNSIGNED_BYTE, pixels);

		// Flip image
		for (int i = 0; i < height; i++) {
			size_t len = width * 3;
			auto dst = cast(ubyte*)temp.pixels + temp.pitch * i;
			auto src = pixels + 3 * width * (height - i - 1);
			dst[0 .. len] = src[0 .. len];
		}

		// Save the image to disk
		SDL_SaveBMP(temp, toStringz(filename));
	}

	static Core opCall()
	{
		return instance;
	}

	bool init()
	{
		initBuiltins();
		initSettings();

		loadLibraries();

		initSfx(p);
		initGfx(p);
		initPhy(p);

//		SDL_WM_IconifyWindow();
		return true;
	}

	void resize(uint w, uint h)
	{
		resize(w, h, fullscreen);
	}

	void resize(uint w, uint h, bool fullscreen)
	{
		if (!resizeSupported)
			return;

		l.info("Resizing window (%s, %s) %s", w, h,
			fullscreen ? "fullscren" : "windowed");
		this.fullscreen = fullscreen;
		width = w; height = h;
		SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

		uint bits = SDL_OPENGL | SDL_RESIZABLE;
		if (fullscreen)
			bits |= SDL_FULLSCREEN;

		s = SDL_SetVideoMode(
				w,
				h,
				0,
				bits
			);

		width = w = s.w;
		height = h = s.h;

		DefaultTarget.initDefaultTarget(w, h);
	}

	bool close()
	{
		saveSettings();

		Pool().clean();

		closeSfx();
		closePhy();
		closeGfx();

		return true;
	}

private:
	/*
	 *
	 * Init and close functions
	 *
	 */

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

	void loadLibraries()
	{
		sdl = Library.loads(libSDLname);
		ttf = Library.loads(libSDLttf);
		image = Library.loads(libSDLImage);
		openal = Library.loads(libOpenALname);
		alut = Library.loads(libALUTname);

		if (!sdl)
			l.fatal("Could not load SDL, crashing bye bye!");

		if (!ttf)
			l.fatal("Could not load SDL-ttf, crashing bye bye!");

		if (!image)
			l.fatal("Could not load SDL-image, crashing bye bye!");

		if (!openal)
			l.fatal("Could not load OpenAL, crashing bye bye!");

		if (!alut)
			l.bug("ALUT not found, nothing to see here move along.");
	}

	/*
	 *
	 * Init and close functions for subsystems
	 *
	 */

	void initPhy(Properties p)
	{
		version(DynamicODE) {
			ode = Library.loads(libODEname);
			if (ode is null) {
				l.info("Didn't load ODE, this not an error.");
				return;
			}
			loadODE(&ode.symbol);
		}

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

	void initGfx(Properties p)
	{
		loadSDL(&sdl.symbol);
		loadSDLttf(&ttf.symbol);
		loadSDLImage(&image.symbol);

		SDL_Init(SDL_INIT_VIDEO);
		TTF_Init();

		width = p.getUint("w", defaultWidth);
		height = p.getUint("h", defaultHeight);
		fullscreen = p.getBool("fullscreen", defaultFullscreen);
		char* title = p.getStringz("title", defaultTitle);

		l.bug("w: ", width, " h: ", height);

		SDL_WM_SetCaption(title, title);

		SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);

		uint bits = SDL_OPENGL;
		if (resizeSupported)
 			bits |= SDL_RESIZABLE;
		if (fullscreen)
			bits |= SDL_FULLSCREEN;

		s = SDL_SetVideoMode(
				width,
				height,
				0,
				bits
			);

		// Readback size
		width = s.w;
		height = s.h;

		loadGL(&loadFunc);

		glu = Library.loads(libGLUname);
		if (!glu)
			l.fatal("Could not load GLU, crashing bye bye!");
		loadGLU(&glu.symbol);

		DefaultTarget.initDefaultTarget(width, height);

		gfxLoaded = true;
	}

	void closeGfx()
	{
		SDL_Quit();
		gfxLoaded = false;
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

		if (alut !is null)
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

	void* loadFunc(char[] c)
	{
		return SDL_GL_GetProcAddress(std.string.toStringz(c));
	}

}

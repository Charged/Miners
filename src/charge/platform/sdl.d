// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.platform.sdl;

import std.file;
import std.string;

import charge.core;
import charge.gfx.gfx;
import charge.gfx.target;
import charge.sys.logger;
import charge.sys.resource;
import charge.sys.properties;
import charge.platform.common;
import charge.platform.homefolder;

import lib.loader;
import lib.gl.gl;
import lib.sdl.sdl;
import lib.sdl.image;

extern(C) Core chargeCore()
{
	return CoreSDL();
}

class CoreSDL : public CommonCore
{
private:
	mixin Logging;
	static CoreSDL instance;

	int screenshotNum;
	uint width, height;
	bool fullscreen;

	/* surface for window */
	SDL_Surface *s;

	/* run time libraries */
	Library glu;
	Library sdl;
	Library image;


	/* name of libraries to load */
	version(Windows)
	{
		const char[][] libSDLname = ["SDL.dll"];
		const char[][] libSDLImage = ["SDL_image.dll"];
		const char[][] libGLUname = ["glu32.dll"];
	}
	else version(linux)
	{
		const char[][] libSDLname = ["libSDL.so", "libSDL-1.2.so.0"];
		const char[][] libSDLImage = ["libSDL_image.so", "libSDL_image-1.2.so.0"];
		const char[][] libGLUname = ["libGLU.so", "libGLU.so.1"];
	}
	else version(darwin)
	{
		const char[][] libSDLname = ["SDL.framework/SDL"];
		const char[][] libSDLImage = ["SDL_image.framework/SDL_image"];
		const char[][] libGLUname = ["OpenGL.framework/OpenGL"];
	}


	static this()
	{
		instance = new CoreSDL();
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

	void loadLibraries()
	{
		super.loadLibraries();

		version (darwin) {
			auto libSDLnames = [privateFrameworksPath ~ "/" ~ libSDLname[0]] ~ libSDLname;
			auto libSDLImages = [privateFrameworksPath ~ "/" ~ libSDLImage[0]] ~ libSDLImage;
		} else {
			alias libSDLname libSDLnames;
			alias libSDLImage libSDLImages;
		}

		sdl = Library.loads(libSDLnames);
		image = Library.loads(libSDLImages);

		if (!sdl)
			l.fatal("Could not load SDL, crashing bye bye!");

		if (!image)
			l.fatal("Could not load SDL-image, crashing bye bye!");
	}


	/*
	 *
	 * Init and close functions for subsystems
	 *
	 */


	void initGfx(Properties p)
	{
		loadSDL(&sdl.symbol);
		loadSDLImage(&image.symbol);

		SDL_Init(SDL_INIT_VIDEO);

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

	void* loadFunc(char[] c)
	{
		return SDL_GL_GetProcAddress(std.string.toStringz(c));
	}
}

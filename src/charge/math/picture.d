// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.math.picture;

import std.string;
import std.stdio;

import lib.sdl.sdl;
import lib.sdl.image;

import charge.math.color;
import charge.sys.resource;
import charge.sys.logger;
import charge.sys.file;


class Picture : public Resource
{
public:
	const char[] uri = "pic://";

	Color4b *pixels;

	uint width;
	uint height;

protected:
	SDL_Surface *surf;

private:
	mixin Logging;

public:
	static Picture opCall(char[] filename)
	{
		auto p = Pool();
		if (filename is null)
			return null;
		
		auto r = p.resource(uri, filename);
		auto pic = cast(Picture)r;
		if (r !is null) {
			assert(pic !is null);
			return pic;
		}

		auto s = getSurface(filename);
		if (s is null)
			return null;

		return new Picture(p, filename, s, false);
	}

	static Picture opCall(char[] name, char[] filename)
	{
		auto s = getSurface(filename);
		if (s is null)
			return null;

		return new Picture(Pool(), name, s, true);
	}

protected:
	this(Pool p, char[] name, uint w, uint h, bool dynamic)
	{
		super(p, uri, name, dynamic);

		width = w;
		height = h;
		pixels = cast(Color4b*)std.c.stdlib.malloc(w*h*Color4b.sizeof);
	}

	this(Pool p, char[] name, SDL_Surface *surf, bool dynamic)
	{
		if (dynamic || surf.pitch != width * Color4b.sizeof) {
			// Use other contructor to alloc memory
			this(p, name, surf.w, surf.h, dynamic);

			// Copy pixels
			Color4b *src = cast(Color4b*)surf.pixels;
			size_t nblocksx = surf.pitch / Color4b.sizeof;
			for (int i; i < height; i++) {
				pixels[width * i .. width * (i+1)] =
					src[nblocksx * i .. nblocksx * (i+1)];
			}

			// Free the loaded surface
			SDL_FreeSurface(surf);
		} else {
			// Call base calss constructor
			super(p, uri, name, dynamic);

			this.width = surf.w;
			this.height = surf.h;
			this.pixels = cast(Color4b*)surf.pixels;
			this.surf = surf;
		}
	}

	~this()
	{
		if (surf)
			SDL_FreeSurface(surf);
		else
			std.c.stdlib.free(pixels);
	}


	static bool needsConverting(SDL_Surface *s)
	{
		auto f = s.format;

		if (f.BitsPerPixel != 32 || f.BytesPerPixel != 4)
			return true;

		/* Loss and shift is covered by mask */
		if (f.Rmask != 0x000000ff || f.Gmask != 0x0000ff00 || f.Bmask != 0x00ff0000 || f.Amask != 0xff000000)
			return true;

		return false;
	}

	static SDL_Surface* convertSurface(SDL_Surface *s)
	{
		SDL_PixelFormat f;
		f.BitsPerPixel = 32;
		f.BytesPerPixel = 4;
		f.Rmask = 0x000000ff;
		f.Gmask = 0x0000ff00;
		f.Bmask = 0x00ff0000;
		f.Amask = 0xff000000;

		f.Rshift = 0;
		f.Gshift = 8;
		f.Bshift = 16;
		f.Ashift = 24;

		return SDL_ConvertSurface(s, &f, SDL_SWSURFACE);
	}

	static SDL_Surface* getSurface(char[] filename)
	{
		SDL_PixelFormat *f;
		SDL_Surface* sl;
		SDL_Surface* s;
		File file;

		file = FileManager(filename);
		if (file is null) {
			l.warn("Failed to load %s: file not found", filename);
			return null;
		}
		scope(exit)
			delete file;

		auto sdl_file = file.getSDL;

		sl = IMG_Load_RW(sdl_file, 1);
		if (sl is null) {
			l.warn("Failed to load %s: file invalid format", filename);
			return null;
		}

		if (needsConverting(sl)) {
			s = convertSurface(sl);
			SDL_FreeSurface(sl);
		} else {
			s = sl;
		}

		return s;
	}

}

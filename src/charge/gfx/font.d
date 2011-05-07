// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.gfx.font;

import std.string;
import lib.sdl.sdl;
import lib.sdl.ttf;

import charge.gfx.gl;
import charge.gfx.texture;
import charge.sys.logger;
import charge.sys.file;

class Font
{
private:
	mixin Logging;
	TTF_Font *t;

public:
	void render(DynamicTexture dt, char[] text)
	{
		char* textz = toStringz(text);
		SDL_Surface* s;
		SDL_Color fg;
		/* Red and Blue are swapped */
		fg.r = 255;
		fg.g = 255;
		fg.b = 255;

		s = TTF_RenderUTF8_Blended(t, textz, fg);
		delete textz;

		if (s is null) {
			// Uncomment this when we have stable text rendering.
			//l.warn("Failed to print text \"%s\".", text);
			return;
		}

		scope(exit)
			SDL_FreeSurface(s);

 		uint id = textureFromSurface(s);

		dt.update(id, s.w, s.h);
	}

package:
	this(TTF_Font *font)
	{
		t = font;
	}

	static int textureFromSurface(SDL_Surface *s)
	{
		int glFormat = GL_RGBA;
		int glComponents = 4;
		float a;
		uint id;

		glGenTextures(1, cast(GLuint*)&id);

		glBindTexture(GL_TEXTURE_2D, id);

		glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_TRUE);
		glTexImage2D(
			GL_TEXTURE_2D,    //target
			0,                //level
			glComponents,     //internalformat
			s.w,              //width
			s.h,              //height
			0,                //border
			glFormat,         //format
			GL_UNSIGNED_BYTE, //type
			s.pixels);        //pixels
		glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_FALSE);

		return id;
	}
}

class FontManager
{
private:
	mixin Logging;
	Font[char[]] map;
	static FontManager instance;

public:
	static FontManager opCall()
	{
		if (instance is null)
			instance = new FontManager();
		return instance;
	}

	static Font opCall(char[] filename, uint size)
	{
		return FontManager().get(filename, size);
	}

	Font get(char[] filename, uint size)
	{
		if (filename is null || size == 0)
			return null;

		auto name = format("%s|%s", size, filename);
		// Should clean up the file path.
		auto f = name in map;
		if (f !is null)
			return *f;

		return load(name, filename, size);
	}

private:
	Font load(char[] name, char[] filename, uint size)
	{
		TTF_Font *font;
		File file;

		file = FileManager(filename);
		if (file is null) {
			l.warn("Failed to load %s: file not found", filename);
			return null;
		}
		scope(exit) delete file;

		auto sdl_file = file.peekSDL();

		font = TTF_OpenFontRW(sdl_file, true, size);
		if (font is null) {
			l.warn("Failed to load %s: file invalid format", filename);
			return null;
		}

		l.info("Loaded font %s at size %s", filename, size);
		auto f = new Font(font);
		map[name] = f;

		return f;
	}

}

// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.gfx.font;

import std.string;
import lib.picofont.pico;

import charge.gfx.gl;
import charge.gfx.texture;
import charge.sys.logger;
import charge.sys.file;

class Font
{
public:
	static void render(DynamicTexture dt, char[] text)
	{
		int glTarget = GL_TEXTURE_2D;
		int glFormat = GL_ALPHA;
		int glInternalFormat = GL_ALPHA;
		uint id;
		ubyte *pixels;
		uint w;
		uint h;

		pixels = FNT_RenderMax(text.ptr, cast(uint)text.length, &w, &h);
		scope(exit) std.c.stdlib.free(pixels);

		if (pixels is null)
			return;

		id = dt.id;

		if (!glIsTexture(id))
			glGenTextures(1, cast(GLuint*)&id);

		glBindTexture(glTarget, id);
		glTexParameteri(glTarget, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(glTarget, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexParameterf(glTarget, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glTexParameterf(glTarget, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

		glTexImage2D(
			glTarget,         //target
			0,                //level
			glInternalFormat, //internalformat
			w,                //width
			h,                //height
			0,                //border
			glFormat,         //format
			GL_UNSIGNED_BYTE, //type
			pixels);          //pixels

		glBindTexture(glTarget, 0);

		dt.update(id, w, h);
	}
}

// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.gfx.font;

import lib.picofont.pico;

import charge.core;
import charge.sys.file;
import charge.sys.logger;
import charge.sys.resource;
import charge.gfx.gl;
import charge.gfx.gfx;
import charge.gfx.draw;
import charge.gfx.texture;


class BitmapFont : public Resource
{
public:
	const char[] uri = "bf://";

	/**
	 * Default inbuilt font, will always be available as long as
	 * the core is initialized and gfx has been loaded.
	 */
	static BitmapFont defaultFont;

	uint width;
	uint height;

private:
	Texture tex;
	GLuint fbo;

	const float offset = (1.0 / 16.0);

	mixin Logging;

public:
	void draw(Draw d, int x, int y, char[] text, bool shaded = false)
	{
		if (x != 0 || y != 0) {
			d.translate(x, y);
			drawLayoutedText(text, shaded);
			d.translate(-x, -y);
		} else {
			drawLayoutedText(text, shaded);
		}
	}

	void buildSize(char[] text, out uint width, out uint height)
	{
		if (text is null)
			return;

		int max, x, y;
		foreach(c; text) {
			switch(c) {
			case '\t':
				x += 4 - (x % 4);
				break;
			case '\n':
				y++;
			case '\r':
				x = 0;
				break;
			default:
				max = x > max ? x : max;
				x++;
				break;
			}
		}

		width = (max + 1) * this.width;
		height = (y + 1) * this.height;
	}

	void render(DynamicTexture dt, char[] text)
	{
		GLint oldFbo;

		glMatrixMode(GL_MODELVIEW);
		glPushMatrix();
		glMatrixMode(GL_PROJECTION);
		glPushMatrix();
		glPushAttrib(GL_ALL_ATTRIB_BITS);
		glGetIntegerv(GL_FRAMEBUFFER_BINDING_EXT, &oldFbo);
		scope(exit) {
			glMatrixMode(GL_MODELVIEW);
			glPopMatrix();
			glMatrixMode(GL_PROJECTION);
			glPopMatrix();
			glPopAttrib();
			glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, oldFbo);
		}

		uint w, h;
		Font.buildSize(text, w, h);

		remakeDynamicTexture(dt, w, h);

		glDisable(GL_COLOR_MATERIAL);
		glDisable(GL_DEPTH_TEST);
		glDisable(GL_LIGHTING);

		glDisable(GL_BLEND);

		glActiveTexture(GL_TEXTURE0);

		static GLenum buffers[1] = [
			GL_COLOR_ATTACHMENT0_EXT,
		];
		gluFrameBufferBind(fbo, buffers, w, h);
		glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, dt.id, 0);

		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();

		gluOrtho2D(0.0, w, 0.0, h);

		glClearColor(0, 0, 0, 0);
		glClear(GL_COLOR_BUFFER_BIT);

		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

		drawLayoutedText(text, false);

		glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, 0, 0);
	}

	static BitmapFont opCall(char[] filename)
	{
		auto p = Pool();
		if (filename is null)
			return null;

		auto r = p.resource(uri, filename);
		auto bf = cast(BitmapFont)r;
		if (r !is null) {
			assert(bf !is null);
			return bf;
		}

		auto tex = Texture(filename);
		// Error reporting already taken care of.
		if (tex is null) {
			if (filename is "res/font.png")
				tex = loadBackupFont();
			else
				return null;
		}
		scope(failure)
			reference(&tex, null);

		if (tex.width % 16 != 0 ||
		    tex.height % 16 != 0) {
			const str = "Width and Height of font must be mutliple of 16";
			l.error(str);
			throw new Exception(str);
		}

		tex.filter = Texture.Filter.Nearest;
		return new BitmapFont(p, filename, tex);
	}


protected:
	this(Pool p, char[] name, Texture tex)
	{
		glGenFramebuffersEXT(1, &fbo);

		this.width = tex.width / 16;
		this.height = tex.height / 16;
		this.tex = tex;
		super(p, uri, name);
	}

	~this()
	{
		glDeleteFramebuffersEXT(1, &fbo);
		tex.reference(&tex, null);
	}

	void drawLayoutedText(char[] text, bool shaded)
	{
		// This is all the state we need to setup,
		// the rest is handled by draw or the render function.
		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, tex.id);

		glEnable(GL_BLEND);

		glBegin(GL_QUADS);

		if (shaded) {
			glColor4ub(0, 0, 0, 255);

			void offseted(int x, int y, char c) {
				drawChar(x+1, y+1, c);
			}

			doLayoutLoop(text, &offseted);
		}

		glColor4ub(255, 255, 255, 255);
		doLayoutLoop(text, &drawChar);

		glEnd();

		glBindTexture(GL_TEXTURE_2D, 0);
	}

	void doLayoutLoop(char[] text, void delegate(int x, int y, char c) dg)
	{
		int x, y;
		foreach(c; text) {
			switch(c) {
			case '\t':
				x += (4 - (x % 4));
				break;
			case '\n':
				y++;
			case '\r':
				x = 0;
				break;
			default:
				dg(x*width, y*height, c);
				x++;
				break;
			}
		}
	}

	final void drawChar(int x, int y, char c)
	{
		float srcX = offset * (c % 16);
		float srcY = offset * (c / 16);

		glTexCoord2f(       srcX,        srcY);
		glVertex2i  (          x,           y);
		glTexCoord2f(       srcX, srcY+offset);
		glVertex2i  (          x,    height+y);
		glTexCoord2f(srcX+offset, srcY+offset);
		glVertex2i  (    width+x,    height+y);
		glTexCoord2f(srcX+offset,        srcY);
		glVertex2i  (    width+x,           y);
	}

	final void remakeDynamicTexture(DynamicTexture dt, uint w, uint h)
	{
		GLint id = dt.id;

		if (!glIsTexture(id))
			glGenTextures(1, cast(GLuint*)&id);

		glBindTexture(GL_TEXTURE_2D, id);
		glTexImage2D(GL_TEXTURE_2D, 0, 4, w, h, 0, GL_RGBA, GL_FLOAT, null);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glBindTexture(GL_TEXTURE_2D, 0);

		dt.update(id, w, h);
	}

private:
	static this()
	{
		Core.addInitAndCloseRunners(&initFunc, &closeFunc);
	}

	static void initFunc()
	{
		if (gfxLoaded)
			defaultFont = BitmapFont("res/font.png");
	}

	static void closeFunc()
	{
		reference(&defaultFont, null);
	}

	static Texture loadBackupFont()
	{
		int glTarget = GL_TEXTURE_2D;
		int glFormat = GL_ALPHA;
		int glInternalFormat = GL_ALPHA;
		ubyte *pixels;
		uint w;
		uint h;

		char[17*16-1] arr;
		for (int i; i < 16; i++) {
			int start = i * 17;
			for (int k; k < 16; k++) {
				char c = cast(char)(i * 16 + k);
				if (c == '\t' || c == '\r' || c == '\n' || c == '\0')
					c = ' ';
				arr[start+k] = c;
			}
			if (i < 15)
				arr[start+16] = '\n';
		}

		pixels = FNT_RenderMax(arr.ptr, cast(uint)arr.length, &w, &h);
		// This should be stdlib.free.
		scope(exit) std.c.stdlib.free(pixels);

		assert(pixels !is null);

		auto dt = new DynamicTexture(null);

		GLint id = dt.id;

		if (!glIsTexture(id))
			glGenTextures(1, cast(GLuint*)&id);

		glBindTexture(glTarget, id);
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
		glTexParameteri(glTarget, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(glTarget, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexParameterf(glTarget, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glTexParameterf(glTarget, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

		dt.update(id, w, h);

		return dt;
	}
}

/**
 * XXX Legacy, for backwards compat.
 */
class Font
{
public:
	static void render(DynamicTexture dt, char[] text)
	{
		BitmapFont.defaultFont.render(dt, text);
	}

	static void buildSize(char[] text, out uint width, out uint height)
	{
		BitmapFont.defaultFont.buildSize(text, width, height);
	}
}

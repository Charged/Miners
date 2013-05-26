// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for BitmapFont.
 */
module charge.gfx.font;

import charge.core;
import charge.sys.file;
import charge.sys.logger;
import charge.sys.resource;
import charge.gfx.gl;
import charge.gfx.gfx;
import charge.gfx.draw;
import charge.gfx.texture;


/**
 * Simple Bitmap font, doesn't handle UTF-8.
 *
 * @ingroup Resource
 */
class BitmapFont : Resource
{
public:
	const string uri = "bf://";

	/**
	 * Default inbuilt font, will always be available as long as
	 * the core is initialized and gfx has been loaded.
	 */
	static BitmapFont defaultFont;

	uint width;
	uint height;
	uint shadowOffset;

protected:
	Texture tex;
	const float offset = (1.0 / 16.0);

private:
	GLuint fbo;

	mixin Logging;

public:
	void draw(Draw d, int x, int y, const(char)[] text, bool shaded = false)
	{
		if (x != 0 || y != 0) {
			d.translate(x, y);
			drawLayoutedText(text, shaded);
			d.translate(-x, -y);
		} else {
			drawLayoutedText(text, shaded);
		}
	}

	void buildSize(const(char)[] text, out uint width, out uint height)
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
				goto case '\r';
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

	void render(DynamicTexture dt, const(char)[] text)
	{
		GLint oldFbo;

		glGetIntegerv(GL_FRAMEBUFFER_BINDING_EXT, &oldFbo);
		glPushAttrib(GL_VIEWPORT_BIT);

		glMatrixMode(GL_MODELVIEW);
		glPushMatrix();
		glMatrixMode(GL_PROJECTION);
		glPushMatrix();

		scope(exit) {
			glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, oldFbo);

			glMatrixMode(GL_MODELVIEW);
			glPopMatrix();
			glMatrixMode(GL_PROJECTION);
			glPopMatrix();

			glPopAttrib();
		}

		uint w, h;
		buildSize(text, w, h);

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

	static BitmapFont opCall(Pool p, string filename)
	in {
		assert(p !is null);
		assert(filename !is null);
	}
	body {
		if (filename is null)
			return null;

		auto r = p.resource(uri, filename);
		auto bf = cast(BitmapFont)r;
		if (r !is null) {
			assert(bf !is null);
			return bf;
		}

		auto tex = Texture(p, filename);
		// Error reporting already taken care of.
		if (tex is null)
			return null;
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
	this(Pool p, string name, Texture tex)
	{
		this(p, uri, name, tex);
	}

	this(Pool p, string uri, string name, Texture tex)
	{
		glGenFramebuffersEXT(1, &fbo);

		this.shadowOffset = 1;
		this.width = tex.width / 16;
		this.height = tex.height / 16;
		this.tex = tex;
		super(p, uri, name);
	}

	~this()
	{
		glDeleteFramebuffersEXT(1, &fbo);
		reference(&tex, null);
	}

	void drawLayoutedText(const(char)[] text, bool shaded)
	{
		// This is all the state we need to setup,
		// the rest is handled by draw or the render function.
		glEnable(GL_BLEND);
		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, tex.id);

		glBegin(GL_QUADS);

		if (shaded) {
			glColor4ub(0, 0, 0, 255);

			void offseted(int x, int y, char c) {
				drawChar(x+shadowOffset, y+shadowOffset, c);
			}

			doLayoutLoop(text, &offseted);
		}

		glColor4ub(255, 255, 255, 255);
		doLayoutLoop(text, &drawChar);

		glEnd();

		glBindTexture(GL_TEXTURE_2D, 0);
		glDisable(GL_TEXTURE_2D);
		glDisable(GL_BLEND);
	}

	void doLayoutLoop(const(char)[] text, void delegate(int x, int y, char c) dg)
	{
		int x, y;
		foreach(c; text) {
			switch(c) {
			case '\t':
				x += (4 - (x % 4));
				break;
			case '\n':
				y++;
				goto case '\r';
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
			defaultFont = BitmapFont(Pool(), "res/font.png");
	}

	static void closeFunc()
	{
		reference(&defaultFont, null);
	}
}

// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.gfx.target;

import lib.sdl.sdl;

import charge.math.color;
import charge.sys.logger;
import charge.gfx.gl;

interface RenderTarget
{
	void setTarget();
	uint width();
	uint height();
}

class DefaultTarget : public RenderTarget
{
private:
	Color4f clearColor;
	static DefaultTarget instance;

	uint w;
	uint h;

public:
	static DefaultTarget opCall()
	{
		return instance;
	}

	void clear()
	{
		glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glEnable(GL_DEPTH_TEST);		
	}

	void swap()
	{
		SDL_GL_SwapBuffers();
	}

	void setTarget()
	{
		if (GL_EXT_framebuffer_object) {
			static GLenum buffers[1] = [
				GL_BACK_LEFT,
			];
			gluFrameBufferBind(0, buffers, w, h);
		}
	}

	static void initDefaultTarget(uint w, uint h)
	{
		//assert(instance is null);
		if (instance is null)
			instance = new DefaultTarget(w, h);
		instance.w = w;
		instance.h = h;
	}

	uint width()
	{
		return w;
	}

	uint height()
	{
		return h;
	}

private:
	this(uint w, uint h)
	{
		this.w = w;
		this.h = h;
	}

}

class DoubleTarget : public RenderTarget
{
private:
	mixin Logging;

	uint w;
	uint h;
	uint colorTex;
	uint depthTex;
	uint fbo;

	static bool checked;
	static bool checkStatus;
	static bool initialized;
	static GLint probedFormat;

public:
	static bool check()
	{
		if (checked)
			return checkStatus;

		checked = true;
		probedFormat = 0;

		try {
			if (!GL_EXT_framebuffer_object)
				throw new Exception("GL_EXT_framebuffer_object not supported");

			Exception eSaved;

			// Try different formats to find one that works.
			foreach(f; [GL_DEPTH_COMPONENT24, GL_DEPTH_COMPONENT32]) {
				try {
					auto dt = new DoubleTarget(15, 15, f);
					delete dt;
					probedFormat = f;
				} catch (Exception e) {
					eSaved = e;
				}
			}

			if (probedFormat == 0)
				throw eSaved;

		} catch (Exception e) {
			l.warn("Double target not supported (%s)", e);
			return false;
		}

		checkStatus = true;
		return true;
	}

	this(uint w, uint h)
	{
		if (!check)
			throw new Exception("Double target not supported");

		this(w, h, probedFormat);
	}

private:
	this(uint w, uint h, GLint depthFormat)
	{


		w *= 2;
		h *= 2;
		this.w = w;
		this.h = h;
		uint colorFormat;

		colorFormat = GL_RGBA8;

		glGenTextures(1, &colorTex);
		glGenTextures(1, &depthTex);
		glGenFramebuffersEXT(1, &fbo);

		scope(failure) {
			glDeleteFramebuffersEXT(1, &fbo);
			glDeleteTextures(1, &colorTex);
			glDeleteTextures(1, &depthTex);
			fbo = colorTex = depthTex = 0;
		}

		glBindTexture(GL_TEXTURE_2D, colorTex);
		glTexImage2D(GL_TEXTURE_2D, 0, colorFormat, w, h, 0, GL_RGBA, GL_FLOAT, null);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

		glBindTexture(GL_TEXTURE_2D, depthTex);
		glTexImage2D(GL_TEXTURE_2D, 0, depthFormat, w, h, 0, GL_DEPTH_COMPONENT, GL_FLOAT, null);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

		glBindTexture(GL_TEXTURE_2D, 0);

		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fbo);
		glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, colorTex, 0);
		glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_TEXTURE_2D, depthTex, 0);

		GLenum status = cast(GLenum)glCheckFramebufferStatusEXT(GL_FRAMEBUFFER_EXT);

		if (status != GL_FRAMEBUFFER_COMPLETE_EXT)
			throw new Exception("DoubleTarget framebuffer not complete " ~ std.string.toString(status));

		glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
	}

public:
	~this()
	{
		if (fbo || colorTex || depthTex) {
			glDeleteFramebuffersEXT(1, &fbo);
			glDeleteTextures(1, &colorTex);
			glDeleteTextures(1, &depthTex);
		}
	}

	void setTarget()
	{
		static GLenum buffers[3] = [
			GL_COLOR_ATTACHMENT0_EXT,
		];
		gluFrameBufferBind(fbo, buffers, w, h);

	}

	int color()
	{
		return colorTex;
	}

	int depth()
	{
		return depthTex;
	}

	uint width()
	{
		return w;
	}

	uint height()
	{
		return h;
	}

	void resolve(RenderTarget rt)
	{
		rt.setTarget();
		
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();

		gluTexUnitEnableBind(GL_TEXTURE_2D, 0, colorTex);

		glBegin(GL_QUADS);
		glColor3f(    1.0f,  1.0f,  1.0f);
		glTexCoord2f( 0.0f,  0.0f);
		glVertex3f(  -1.0f, -1.0f,  0.0f);
		glTexCoord2f( 1.0f,  0.0f);
		glVertex3f(   1.0f, -1.0f,  0.0f);
		glTexCoord2f( 1.0f,  1.0f);
		glVertex3f(   1.0f,  1.0f,  0.0f);
		glTexCoord2f( 0.0f,  1.0f);
		glVertex3f(  -1.0f,  1.0f,  0.0f);
		glEnd();

		gluTexUnitDisableUnbind(GL_TEXTURE_2D, 0);
	}

}

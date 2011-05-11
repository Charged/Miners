// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.gfx.draw;

import charge.math.color;
import charge.sys.logger;
import charge.gfx.texture;
import charge.gfx.target;
import charge.gfx.gl;

/**
 * Provides simple 2d rendering functionallity
 */
final class Draw
{
private:
	mixin Logging;
	RenderTarget rt;

public:
	this()
	{

	}

	void target(RenderTarget rt)
	{
		this.rt = rt;
	}

	RenderTarget target()
	{
		return rt;
	}

	/**
	 * Start drawing operations.
	 */
	void start()
	{
		if (rt is null)
			return;

		rt.setTarget();

		glDisable(GL_COLOR_MATERIAL);
		glDisable(GL_DEPTH_TEST);
		glDisable(GL_LIGHTING);

		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

		glActiveTexture(GL_TEXTURE0);

		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();

		// Need to flip the coords if rendering to a FBO.
		if (rt !is DefaultTarget())
			gluOrtho2D(0.0, rt.width, 0.0, rt.height);
		else
			gluOrtho2D(0.0, rt.width, rt.height, 0.0);
	}

	/**
	 * Start drawing operations.
	 */
	void stop()
	{
		if (rt is null)
			return;

		glDisable(GL_BLEND);
	}

	/**
	 * Blit entire texture to set target
	 */
	void blit(Texture t, int x, int y)
	{
		blit(t, Color4f.White, true, x, y);
	}

	/**
	 * Blit entire texture to set target
	 */
	void blit(Texture t, bool blend, int x, int y)
	{
		blit(t, Color4f.White, blend, x, y);
	}

	/**
	 * Blit entire texture to set target, blend with given color.
	 */
	void blit(Texture t, Color4f color, bool blend, int x, int y)
	{
		if (rt is null || t is null)
			return;

		blit(t, color, blend,
		     0, 0, t.width, t.height,
		     x, y, t.width, t.height
		     );
	}

	void blit(Texture t, Color4f color, bool blend,
		  int srcX, int srcY, uint srcW, uint srcH,
		  int dstX, int dstY, uint dstW, uint dstH)
	{
		if (rt is null || t is null || !t.width || !t.height)
			return;

		if (blend)
			glEnable(GL_BLEND);
		else
			glDisable(GL_BLEND);

		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, t.id);

		float srcX1, srcX2, srcY1, srcY2;
		srcX1 = cast(float)srcX / t.width;
		srcY1 = cast(float)srcY / t.height;
		srcX2 = cast(float)(srcX + srcW) / t.width;
		srcY2 = cast(float)(srcY + srcH) / t.height;

		glColor4fv(color.ptr);
		glBegin(GL_QUADS);
		glTexCoord2f(      srcX1,       srcY1);
		glVertex2f  (       dstX,        dstY);
		glTexCoord2f(      srcX1,       srcY2);
		glVertex2f  (       dstX, dstY + dstH);
		glTexCoord2f(      srcX2,       srcY2);
		glVertex2f  (dstX + dstW, dstY + dstH);
		glTexCoord2f(      srcX2,       srcY1);
		glVertex2f  (dstX + dstW,        dstY);
		glEnd();

		glBindTexture(GL_TEXTURE_2D, 0);
		glDisable(GL_TEXTURE_2D);
	}

	void fill(Color4f color, bool blend, int x, int y, uint w, uint h)
	{
		if (blend)
			glEnable(GL_BLEND);
		else
			glDisable(GL_BLEND);

		glColor4fv(color.ptr);
		glBegin(GL_QUADS);
		glVertex2f(    x,     y);
		glVertex2f(    x, y + h);
		glVertex2f(x + w, y + h);
		glVertex2f(x + w,     y);
		glEnd();
	}
}

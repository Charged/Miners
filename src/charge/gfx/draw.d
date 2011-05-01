// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.gfx.draw;

import charge.sys.logger;
import charge.gfx.texture;
import charge.gfx.target;
import charge.gfx.gl;

/**
 * Provides simple 2d rendering functionallity
 */
class Draw
{
private:
	mixin Logging;
	RenderTarget rt;

public:
	this()
	{

	}

	/**
	 * Blit entire texture to set target
	 */
	void blit(Texture t, int x, int y)
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

		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, t.id);

		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		gluOrtho2D(0.0, rt.width, rt.height, 0.0);

		glColor4f(1.0, 1.0, 1.0, 1.0);
		glBegin(GL_QUADS);
		glTexCoord2f(0.0,         0.0         );
		glVertex2f  (x,           y           );
		glTexCoord2f(0.0,         1.0         );
		glVertex2f  (x,           y + t.height);
		glTexCoord2f(1.0,         1.0         );
		glVertex2f  (x + t.width, y + t.height);
		glTexCoord2f(1.0,         0.0         );
		glVertex2f  (x + t.width, y           );
		glEnd();

		glBindTexture(GL_TEXTURE_2D, 0);
		glDisable(GL_TEXTURE_2D);
		glDisable(GL_BLEND);
	}

	void target(RenderTarget rt)
	{
		this.rt = rt;
	}

	RenderTarget target()
	{
		return rt;
	}

}

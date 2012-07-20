// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.game.background;

import charge.math.color;
import charge.sys.resource;
import charge.gfx.draw;
import charge.gfx.target;
import charge.gfx.texture;

import charge.game.runner;

alias charge.sys.resource.Resource.reference sysReference;


/**
 * Only used to display something when nothing is being runned.
 */
class BackgroundRunner : public Runner
{
public:
	Color4f color;

	bool backgroundTiledDoubled;
	bool backgroundTiledCenter;

protected:
	Texture background;

	Draw d;

public:
	this()
	{
		super(Type.Background);
		this.color = Color4f.Black;

		d = new Draw();
	}

	void close()
	{
		sysReference(&this.background, null);
	}

	void newBackground(Texture background)
	{
		sysReference(&this.background, background);
	}

	void render(RenderTarget rt)
	{
		d.target = rt;
		d.start();

		if (background is null) {

			// Fill everything with a single color
			d.fill(color, false, 0, 0, rt.width, rt.height);

		} else if (backgroundTiledDoubled) {

			// Just a normal tile
			d.blit(background, Color4f.White, false,
			       0, 0, rt.width / 2, rt.height / 2,
			       0, 0, rt.width, rt.height);

		} else if (backgroundTiledCenter) {

			// Tile with a seem in the middle
			uint bW = background.width * 100;
			uint bH = background.height * 100;

			int offX = (bW - rt.width) / 2;
			int offY = (bH - rt.height) / 2;

			d.blit(background, Color4f.White, false,
			       0, 0, bW, bH,
			       -offX, -offY, bW, bH);
		} else {

			// Center the picture
			int w = rt.width / 2 - background.width / 2;
			int h = rt.height / 2 - background.height / 2;

			d.fill(color, false, 0, 0, rt.width, rt.height);
			d.blit(background, Color4f.White, false, w, h);
		}

		d.stop();
	}

	void logic() {}
	void assumeControl() { assert(false); }
	void dropControl() { assert(false); }
	void resize(uint w, uint h) {}
}

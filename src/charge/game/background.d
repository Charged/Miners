// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.game.background;

import charge.math.color;
import charge.sys.resource : reference;
import charge.gfx.draw;
import charge.gfx.target;
import charge.gfx.texture;

import charge.game.runner;


/**
 * Only used to display something when nothing is being runned.
 */
class BackgroundRunner : Runner
{
public:
	Color4f color;

	enum Mode {
		Color,
		Center,
		CenterDoubled,
		Tiled,
		TiledDoubled,
		TiledCenterSeem,
	}

	Mode mode;

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
		reference(&this.background, null);
	}

	void newBackground(Texture background)
	{
		reference(&this.background, background);
	}

	void render(RenderTarget rt)
	{
		d.target = rt;
		d.start();

		auto mode = background is null ? Mode.Color : this.mode;

		switch(mode) {
		case Mode.Color:
			// Fill everything with a single color
			d.fill(color, false, 0, 0, rt.width, rt.height);
			break;
		case Mode.Center:
			// Center the picture
			int x = rt.width / 2 - background.width / 2;
			int y = rt.height / 2 - background.height / 2;

			d.fill(color, false, 0, 0, rt.width, rt.height);
			d.blit(background, Color4f.White, false, x, y);
			break;
		case Mode.CenterDoubled:
			// Centered and doubled
			int x = rt.width / 2 - background.width;
			int y = rt.height / 2 - background.height;

			d.fill(color, false, 0, 0, rt.width, rt.height);
			d.blit(background, Color4f.White, false,
			       0, 0, background.width, background.height,
			       x, y, background.width * 2, background.height * 2);
			break;
		case Mode.Tiled:
			// Just a normal tile
			d.blit(background, Color4f.White, false,
			       0, 0, rt.width, rt.height,
			       0, 0, rt.width, rt.height);
			break;
		case Mode.TiledDoubled:
			// Like normal but dubbled.
			d.blit(background, Color4f.White, false,
			       0, 0, rt.width / 2, rt.height / 2,
			       0, 0, rt.width, rt.height);
			break;
		case Mode.TiledCenterSeem:
			// Tile with a seem in the middle
			uint bW = background.width * 100;
			uint bH = background.height * 100;

			int offX = (bW - rt.width) / 2;
			int offY = (bH - rt.height) / 2;

			d.blit(background, Color4f.White, false,
			       0, 0, bW, bH,
			       -offX, -offY, bW, bH);
			break;
		default:
			assert(false);
		}

		d.stop();
	}

	void logic() {}
	void assumeControl() { assert(false); }
	void dropControl() { assert(false); }
	void resize(uint w, uint h) {}
}

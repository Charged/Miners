// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.game.gui.messagelog;

import charge.math.color;
import charge.gfx.font;
import charge.gfx.draw;
import charge.gfx.texture;
import charge.sys.resource : reference;
import charge.game.gui.component;
import charge.game.gui.container;


class MessageLog : Component
{
protected:
	uint colums;
	uint rows;
	uint rowHeight;
	uint columWidth;
	uint spacingX;
	uint spacingY;

	uint current;
	DynamicTexture glyphs;

	string[] text;
	size_t cur;

	BitmapFont bf;

public:
	this(Container p, int x, int y, uint colums, uint rows, uint spacingX, uint spacingY)
	{
		this.spacingX = spacingX;
		this.spacingY = spacingY;
		this.colums = colums;
		this.rows = rows;

		text.length = rows;

		repack();

		super(p, x, y, colums * columWidth, rows * rowHeight);
	}

	void repack()
	{
		makeResources();

		columWidth = bf.width + spacingX;
		rowHeight = bf.height + spacingY;
		w = colums * columWidth;
		h = rows * rowHeight;
	}

	void releaseResources()
	{
		reference(&bf, null);
		reference(&glyphs, null);
	}

	void message(string msg)
	{
		text[cur++] = msg;
		if (cur >= text.length)
			cur = 0;
		repaint();
	}

	void paint(Draw d)
	{
		if (glyphs is null)
			makeResources();

		int i;
		foreach(row; text[cur .. $])
			drawRow(d, (i++)*rowHeight, row);
		foreach(row; text[0 .. cur])
			drawRow(d, (i++)*rowHeight, row);
	}

protected:
	void drawRow(Draw d, int y, string row)
	{
		uint w = bf.width;
		uint h = bf.height;

		foreach(uint k, c; row) {
			if (k >= colums)
				break;

			d.blit(glyphs, Color4f.White, true,
				c*w, 0, w, h,
				k*w, y, w, h);
		}
	}

	void makeResources()
	{
		reference(&bf, BitmapFont.defaultFont);
		if (glyphs !is null)
			return;

		glyphs = new DynamicTexture(null);

		char[256] text;
		foreach(int i, t; text)
			text[i] = cast(ubyte)i;

		text['\0'] = text['\r'] = text['\t'] = text['\n'] = ' ';

		bf.render(glyphs, text);
	}
}

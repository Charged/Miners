// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.game.gui.messagelog;


import charge.math.color;
import charge.gfx.font;
import charge.gfx.draw;
import charge.gfx.texture;
import charge.game.gui.component;
import charge.game.gui.container;


class MessageLog : public Component
{
protected:
	uint colums;
	uint rows;

	uint current;
	DynamicTexture glyphs;

	char[][] text;
	size_t cur;

public:
	this(Container p, int x, int y, uint colums, uint rows)
	{
		this.colums = colums;
		this.rows = rows;

		text.length = rows;

		repack();

		super(p, x, y, colums * 8, rows * 8);

	}

	void repack()
	{
		w = colums * 8;
		h = rows * 8;
	}

	void releaseResources()
	{
		if (glyphs is null)
			return;

		glyphs.dereference();
		glyphs = null;
	}

	void message(char[] msg)
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
			drawRow(d, (i++)*8, row);
		foreach(row; text[0 .. cur])
			drawRow(d, (i++)*8, row);
	}

protected:
	void drawRow(Draw d, int y, char[] row)
	{
		foreach(uint k, c; row) {
			if (k >= colums)
				break;

			d.blit(glyphs, Color4f.White, true,
				c*8, 0, 8, 8,
				k*8, y, 8, 8);
		}
	}

	void makeResources()
	{
		glyphs = new DynamicTexture(null);

		char[256] text;
		foreach(int i, t; text)
			text[i] = cast(ubyte)i;

		text['\0'] = text['\r'] = text['\t'] = text['\n'] = ' ';

		Font.render(glyphs, text);
	}
}

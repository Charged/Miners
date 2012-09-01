// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.game.gui.text;

import charge.math.color;
import charge.gfx.font;
import charge.gfx.draw;
import charge.gfx.texture;

import charge.game.gui.component;
import charge.game.gui.container;


/**
 * Baseclass for managing text.
 */
class Text : Component
{
protected:
	string t;
	bool shaded;

public:
	this(Container c, int x, int y, string text, bool shaded)
	{
		this.shaded = shaded;
		this(c, x, y, text);
	}

	this(Container c, int x, int y, string text)
	{
		super(c, x, y, 0, 0);
		this.t = text;

		repack();
	}

	void setText(string text)
	{
		this.t = text;
		repack();
		repaint();
	}

	void repack()
	{
		BitmapFont.defaultFont.buildSize(t, w, h);
	}

	void paint(Draw d)
	{
		BitmapFont.defaultFont.draw(d, 0, 0, t, shaded);
	}

	void releaseResources()
	{

	}
}

/**
 * Double sized text.
 */
class DoubleText : Text
{
public:
	this(Container c, int x, int y, string text, bool shaded)
	{
		super(c, x, y, text, shaded);
	}

	this(Container c, int x, int y, string text)
	{
		super(c, x, y, text);
	}

	void repack()
	{
		super.repack();
		w *= 2;
		h *= 2;
	}

	void paint(Draw d)
	{
		d.scale(2, 2);
		super.paint(d);
	}
}

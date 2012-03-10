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
class BaseText : public Component
{
protected:
	char[] t;
	bool dirty;
	DynamicTexture gfx;

public:
	this(Container c, int x, int y, char[] text)
	{
		super(c, x, y, 0, 0);
		this.t = text;

		repack();
	}

	~this()
	{
		assert(gfx is null);
	}

	void repack()
	{
		Font.buildSize(t, w, h);
	}

	void paint(Draw d)
	{
		if (gfx is null || dirty)
			makeGfx();
		d.blit(gfx, 0, 0);
	}

	void releaseResources()
	{
		if (gfx !is null) {
			gfx.dereference();
			gfx = null;
		}
	}

protected:
	void setText(char[] text)
	{
		dirty = true;
		this.t = text;
		repack();
		repaint();
	}

	void makeGfx()
	{
		if (gfx is null)
			gfx = new DynamicTexture(null);
		Font.render(gfx, t);
		dirty = false;
	}
}

/**
 * Just plain text.
 */
class Text : public BaseText
{
public:
	char[] text;

public:
	this(Container c, int x, int y, char[] text)
	{
		super(c, x, y, text);
		this.text = text;
	}

	void setText(char[] text)
	{
		this.text = text;
		super.setText(text);
	}
}

/**
 * Double sized text.
 */
class DoubleText : public Text
{
public:
	this(Container c, int x, int y, char[] text)
	{
		super(c, x, y, text);
	}

	void repack()
	{
		Font.buildSize(t, w, h);
		w *= 2;
		h *= 2;
	}

	void paint(Draw d)
	{
		if (gfx is null || dirty)
			makeGfx();

		d.blit(gfx, Color4f.White, true,
		       0, 0, w/2, h/2,  // srcX, srcY, srcW, srcH
		       0, 0,   w,   h); // dstX, dstY, dstW, dstH
	}
}

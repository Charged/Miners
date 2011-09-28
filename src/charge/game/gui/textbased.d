// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.game.gui.textbased;

import std.math;

import charge.util.signal;

import charge.math.color;
import charge.gfx.font;
import charge.gfx.draw;
import charge.gfx.texture;

public import charge.game.gui.component;
public import charge.game.gui.container;

/*
 *
 * These functions create gui elements of text to be used with the font
 * rendering charge.gfx.font. Since that currently doesn't accept uft-8
 * text, this code does not generate valid utf-8 strings.
 *
 */

/*
 * Single line.
 *
 * const char textGuiTopLeft = 218;
 * const char textGuiTopRight = 191;
 * const char textGuiBottomLeft = 192;
 * const char textGuiBottomRight = 217;
 * const char textGuiHorizontalLine = 196;
 * const char textGuiVerticalLine = 179;
 */

/*
 * Double line.
 *
 * const char textGuiTopLeft = 201;
 * const char textGuiTopRight = 187;
 * const char textGuiBottomLeft = 200;
 * const char textGuiBottomRight = 188;
 * const char textGuiHorizontalLine = 205;
 * const char textGuiVerticalLine = 186;
 */

const char textGuiTopLeft = 201;
const char textGuiTopRight = 187;
const char textGuiBottomLeft = 200;
const char textGuiBottomRight = 188;
const char textGuiHorizontalLine = 205;
const char textGuiVerticalLine = 186;

char[] makeTextGuiButton(char[] text, uint minwidth = 0)
{
	size_t width = text.length;
	if (width < minwidth)
		width = minwidth;
	size_t stride = width+3;

	char[] ret;
	ret.length = stride*3-1;

	// Top row
	ret[0] = textGuiTopLeft;
	for (int i = 1; i < stride-2; i++)
		ret[i] = textGuiHorizontalLine;
	ret[stride-2] = textGuiTopRight;
	ret[stride-1] = '\n';

	// Middle row
	ret[stride] = textGuiVerticalLine;
	size_t pos = ((stride-1)/2)-(text.length/2)+stride;
	ret[pos .. pos+text.length] = text[0 .. $];
	ret[stride*2-2] = textGuiVerticalLine;
	ret[stride*2-1] = '\n';

	// Bottom row
	ret[stride*2] = textGuiBottomLeft;
	for (size_t i = stride*2+1; i < stride*3-2; i++)
		ret[i] = textGuiHorizontalLine;
	ret[stride*3-2] = textGuiBottomRight;

	return ret;
}

/**
 * Baseclass for managing text.
 */
class BaseText : public Component
{
private:
	char[] t;
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
		if (gfx !is null)
			gfx.dereference();
	}

	void repack()
	{
		Font.buildSize(t, w, h);
	}

	void paint(Draw d)
	{
		if (gfx is null)
			makeGfx();
		d.blit(gfx, 0, 0);
	}

protected:
	void makeGfx()
	{
		if (gfx is null)
			gfx = new DynamicTexture("charge/game/gui/basetext");
		Font.render(gfx, t);
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
}

/**
 * A simple button.
 */
class Button : public BaseText
{
public:
	char[] text;
	uint minwidth;
	Signal!(Button) pressed;

public:
	this(Container c, int x, int y, char[] text, uint minwidth = 0)
	{
		this.text = text;
		this.minwidth = minwidth;

		auto t = makeTextGuiButton(text, minwidth);
		super(c, x, y, t);
	}

	~this()
	{
		pressed.destruct();
	}

	void mouseDown(Mouse m, int x, int y, uint button)
	{
		pressed(this);
	}
}

/**
 * A simple container.
 */
class ColorContainer : public TextureContainer
{
public:
	Color4f bg;

public:
	this(Color4f bg, uint w, uint h)
	{
		super(null, 0, 0, w, h);
		this.bg = bg;
	}

protected:
	void paintBackground(Draw d)
	{
		d.fill(bg, false, 0, 0, w, h);
	}
}

class HeaderContainer : public ColorContainer
{
public:
	char[] headerText;
	Container plane;
	DynamicTexture headerGfx;
	Color4f headerBG;
	uint center;

public:
	this(Color4f bg, char[] headerText, Color4f headerBG)
	{
		super(bg, 0, 0);
		this.plane = new Container(null, 0, 0, 1, 1);
		Container.add(this.plane);
		this.headerText = headerText;
		this.headerBG = headerBG;
	}

	~this()
	{
		if (headerGfx !is null)
			headerGfx.dereference();
	}

	Component[] getChildren()
	{
		return plane.getChildren();
	}

	bool add(Component c)
	{
		return plane.add(c);
	}

	bool remove(Component c)
	{
		return plane.remove(c);
	}

	void repack()
	{
		w = 0;
		h = 0;

		plane.repack();

		foreach(c; plane.getChildren()) {
			w = cast(int)fmax(w, c.x + c.w);
			h = cast(int)fmax(h, c.y + c.h);
		}

		uint headerGfxHeight;
		uint headerGfxWidth;
		Font.buildSize(headerText, headerGfxWidth, headerGfxHeight);

		w = 8 + cast(int)fmax(4 + headerGfxWidth * 2 + 4, w) + 8;
		h = 8 + 4 + headerGfxHeight * 2 + 4 + 8 + h + 8;
		center = w / 2;

		plane.x = 8;
		plane.y = 8 + 4 + headerGfxHeight * 2 + 4 + 8;
		plane.w = w - 16;
		plane.h = h - plane.y - 8;
	}

protected:
	void paintComponents(Draw d)
	{
		if (headerGfx is null) {
			headerGfx = new DynamicTexture("charge/game/gui/headertext");
			Font.render(headerGfx, headerText);
		}

		// Title bar background
		d.fill(headerBG, false,
		       8, 8, w-16, headerGfx.height*2+8);

		d.blit(headerGfx, Color4f.White, true,
		       0, 0,                                       // srcX, srcY
		       headerGfx.width, headerGfx.height,          // srcW, srcH
		       center - headerGfx.width, 8 + 4,            // dstX, dstY
		       headerGfx.width * 2, headerGfx.height * 2); // dstW, dstH

		// Children
		d.save();
		//d.translate(8, 8+4+headerGfx.height*2+4+8);
		super.paintComponents(d);
		d.restore();
	}
}

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
public import charge.game.gui.text;


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

	void setText(char[] text, int minwidth = -1)
	{
		if (minwidth >= 0)
			this.minwidth = cast(uint)minwidth;

		super.setText(makeTextGuiButton(text, this.minwidth));
	}

	void mouseDown(Mouse m, int x, int y, uint button)
	{
		pressed(this);
	}
}


/*
 *
 * Containers.
 *
 */


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
	Container plane;
	DoubleText headerText;
	Color4f headerBG;

public:
	this(Color4f bg, char[] headerText, Color4f headerBG)
	{
		super(bg, 0, 0);
		this.plane = new Container(null, 0, 0, 1, 1);
		this.headerText = new DoubleText(null, 0, 0, headerText);
		Container.add(this.plane);
		Container.add(this.headerText);
		this.headerBG = headerBG;
	}

	void replacePlane(Container c)
	{
		assert(c !is null);

		plane.breakApart();
		super.remove(plane);

		plane = c;
		Container.add(plane);
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
		Container.repack();
		w = plane.w;
		h = plane.h;

		w = 8 + cast(int)fmax(4 + headerText.w + 4, w) + 8;
		h = 8 + 4 + headerText.h + 4 + 8 + h + 8;
		uint center = w / 2;

		headerText.x = center - headerText.w/2;
		headerText.y = 8+4;

		plane.x = 8;
		plane.y = 8 + 4 + headerText.h + 4 + 8;
		plane.w = w - 16;
		plane.h = h - plane.y - 8;
	}

protected:
	void paintBackground(Draw d)
	{
		// First fill the background.
		super.paintBackground(d);

		// Title bar background.
		d.fill(headerBG, false, 8, 8, w-16, headerText.h + 8);
	}
}

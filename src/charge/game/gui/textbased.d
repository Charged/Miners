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

enum ElmGui {
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_RIGHT,
	VERTICAL_LINE,
	HORIZONTAL_LINE,
}

const char[] singelGuiElememts = [
	218, // top left
	191, // top right
	192, // bottom left
	217, // bottom right
	179, // vertical line
	196, // horizontal line
];

const char[] doubleGuiElememts = [
	201, // top left
	187, // top right
	200, // bottom left
	188, // bottom right
	186, // vertical line
	205, // horizontal line
];

char[] makeFrame(char[] elm, uint width, uint height)
{
	size_t stride = width+1; // Newline

	char[] ret;
	ret.length = stride*height-1; // Remove last newline

	// Top row
	ret[0] = elm[ElmGui.TOP_LEFT];
	ret[1 .. stride-2] = elm[ElmGui.HORIZONTAL_LINE];
	ret[stride-2] = elm[ElmGui.TOP_RIGHT];
	ret[stride-1] = '\n';

	// Middle row
	for (int i = 1; i < height-1; i++) {
		size_t pos = stride * i;
		ret[pos] = elm[ElmGui.VERTICAL_LINE];
		ret[pos+1 .. pos+stride-2] = ' ';
		ret[pos+stride-2] = elm[ElmGui.VERTICAL_LINE];
		ret[pos+stride-1] = '\n';
	}


	// Bottom row
	ret[$ - stride + 1] = elm[ElmGui.BOTTOM_LEFT];
	ret[$ - stride + 2 .. $ - 1] = elm[ElmGui.HORIZONTAL_LINE];
	ret[$ - 1] = elm[ElmGui.BOTTOM_RIGHT];

	return ret;

}

char[] makeTextGuiButton(char[] text, uint minwidth = 0)
{
	int width = cast(uint)text.length;
	if (width < minwidth)
		width = minwidth;
	int stride = width+3;

	char[] ret = makeFrame(doubleGuiElememts, stride-1, 3);

	size_t pos = ((stride-1)/2)-(text.length/2)+stride;
	ret[pos .. pos+text.length] = text[0 .. $];

	return ret;
}

/**
 * A simple button.
 */
class Button : public Text
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

	void breakApart()
	{
		pressed.destruct();
		super.breakApart();
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

class HeaderContainer : public TextureContainer
{
public:
	Container plane;
	DoubleText headerText;
	Color4f headerBG;

public:
	this(Color4f bg, char[] headerText, Color4f headerBG)
	{
		super(0, 0, bg);
		this.plane = new Container(null, 0, 0, 1, 1);
		this.headerText = new DoubleText(null, 0, 0, headerText, true);
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

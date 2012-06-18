// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.list;

import lib.gl.gl;

import charge.charge;
import charge.game.gui.textbased;
import charge.game.gui.input;

import miners.types;
import miners.interfaces;
import miners.menu.base;


class ClassicServerListMenu : public MenuBase
{
private:
	ListView lv;

	const char[] header = `Classic`;

public:
	this(Router r, ClassicServerInfo[] csis)
	{
		super(r, header, Buttons.QUIT);

		lv = new ListView(this, 0, 0, csis);

		repack();
	}
}

class ListView : public Component
{
private:
	Router r;

	const darkGrey = Color4f(0.05, 0.05, 0.05, 0.8);
	const lightGrey = Color4f(0.7, 0.7, 0.7, 1);
	const red = Color4f(1, .3, .3, 1);
	const green = Color4f(.3, 1, .3, 1);
	alias Color4f.White white;
	alias Color4f.Black black;

	const uint rows = 32;
	const uint rowSize = 11;
	const uint colums = 160;
	const uint charSize = 8;
	const uint charOffsetFromTop = 2;

	int start;
	ClassicServerInfo[] csis;

	GfxDynamicTexture glyphs;

	const int buttonSize = 14; //< For scrollbar layout

public:
	this(ClassicServerListMenu cm, int x, int y, ClassicServerInfo[] csis)
	{
		super(cm, x, y, 424, rowSize*rows);

		this.r = cm.r;
		this.csis = csis;
	}

	~this()
	{
		assert(glyphs is null);
	}

	void repack() {}


	/*
	 *
	 * Input
	 *
	 */


protected:
	void mouseDown(Mouse m, int x, int y, uint b)
	{
		if (b != 1)
			return;

		if (x < w - buttonSize) {
			int which = (y / rowSize) + start;

			if (which >= csis.length)
				return;

			r.menu.getClassicServerInfoAndConnect(csis[which]);
		} else {
			if (y < h / 2) {
				if (y < buttonSize)
					start--;
				else
					start -= 13;
			} else {
				if (y > (h - buttonSize))
					start++;
				else
					start += 13;
			}

			if (start + rows >= csis.length)
				start = cast(int)csis.length - rows;

			if (start < 0)
				start = 0;

			repaint();
		}
	}


	/*
	 *
	 * Graphics
	 *
	 */


	void paint(GfxDraw d)
	{
		if (glyphs is null)
			makeResources();

		glDisable(GL_BLEND);
		glColor4fv(darkGrey.ptr);

		glBegin(GL_QUADS);
		for (int i; i < rows; i++) {
			if (((i + start) % 4) >= 2)
				continue;

			int y1 = i*rowSize;
			int y2 = y1 + rowSize;
			int w = this.w - buttonSize;

			glVertex2i( 0, y1 );
			glVertex2f( 0, y2 );
			glVertex2f( w, y2 );
			glVertex2f( w, y1 );
		}


		{
			int runnerLength = h - buttonSize * 2;
			int l, offset;
			if (csis.length <= rows) {
				l = runnerLength;
			} else {
				l = cast(int)(runnerLength * rows / cast(float)csis.length);
				offset = cast(int)((runnerLength - l) * (start / cast(float)(csis.length - rows)));
			}

			int x1 = w - buttonSize;
			int x2 = x1 + buttonSize;

			int y1 = buttonSize + offset;
			int y2 = y1 + l;

			glColor4fv(white.ptr);
			glVertex2i( x1,  0 );
			glVertex2f( x1, buttonSize - 1);
			glVertex2f( x2, buttonSize - 1);
			glVertex2f( x2,  0 );

			glVertex2i( x1, h - buttonSize + 1 );
			glVertex2f( x1, h );
			glVertex2f( x2, h );
			glVertex2f( x2, h - buttonSize + 1);

			glVertex2i( x1, y1 );
			glVertex2f( x1, y2 );
			glVertex2f( x2, y2 );
			glVertex2f( x2, y1 );
		}
		glEnd();

		glEnable(GL_BLEND);
		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, glyphs.id);

		glBegin(GL_QUADS);

		foreach(uint i, csi; csis[start .. $]) {
			if (i >= rows)
				break;

			int y = i * rowSize + charOffsetFromTop;

			if (csi.webName == "fCraft.net Freebuild [ENG]")
				glColor4fv(Color4f(1, .3, .3, 1).ptr);
			else
				glColor4fv(lightGrey.ptr);

			foreach(uint k, c; csi.webName) {
				if (k >= colums)
					break;

				int x =  k * charSize + charSize;

				if (c == '[')
					glColor4fv(green.ptr);

				draw(x, y, c);

				if (c == ']')
					glColor4fv(lightGrey.ptr);
			}
		}

		glColor4fv(black.ptr);
		draw(w - buttonSize + (buttonSize - charSize) / 2,      3, 30);
		draw(w - buttonSize + (buttonSize - charSize) / 2, h - 10, 31);

		glEnd();

		glBindTexture(GL_TEXTURE_2D, 0);
		glDisable(GL_TEXTURE_2D);
	}

	void makeResources()
	{
		glyphs = new GfxDynamicTexture(null);

		char[256] text;
		foreach(int i, t; text)
			text[i] = cast(ubyte)i;

		text['\0'] = text['\r'] = text['\t'] = text['\n'] = ' ';

		GfxFont.render(glyphs, text);
	}

	void releaseResources()
	{
		sysReference(&glyphs, null);
	}

	static void draw(int x1, int y1, char c)
	{
		float t1 = (c  ) / 256f;
		float t2 = (c+1) / 256f;

		int x2 = x1 + charSize;
		int y2 = y1 + charSize;


		glTexCoord2f( t1,  0 );
		glVertex2i  ( x1, y1 );
		glTexCoord2f( t1,  1 );
		glVertex2f  ( x1, y2 );
		glTexCoord2f( t2,  1 );
		glVertex2f  ( x2, y2 );
		glTexCoord2f( t2,  0 );
		glVertex2f  ( x2, y1 );
	}
}

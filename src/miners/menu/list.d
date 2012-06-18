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


const char[] header = `Classic`;
const uint childHeight = 424;
const uint childWidth = 9*16;


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

	const uint colums = 160;
	int start;
	ClassicServerInfo[] csis;

	GfxDynamicTexture glyphs;

	const int buttonSize = 14; //< For scrollbar layout

public:
	this(ClassicServerListMenu cm, int x, int y, ClassicServerInfo[] csis)
	{
		super(cm, x, y, 424, 9*16);

		this.r = cm.r;
		this.csis = csis;
	}

	~this()
	{
		assert(glyphs is null);
	}

	void repack() {}

protected:
	void paint(GfxDraw d)
	{

		if (glyphs is null)
			makeResources();

		glDisable(GL_BLEND);
		glColor4fv(Color4f(0.05, 0.05, 0.05, 0.8).ptr);

		glBegin(GL_QUADS);
		for (int i; i < 16; i++) {
			if (((i + start) % 4) >= 2)
				continue;

			int y1 = i*9;
			int y2 = y1 + 9;
			int w = this.w - buttonSize;

			glVertex2i( 0, y1 );
			glVertex2f( 0, y2 );
			glVertex2f( w, y2 );
			glVertex2f( w, y1 );
		}


		{
			int runnerLength = h - buttonSize * 2;
			int l, offset;
			if (csis.length < 17) {
				l = runnerLength;
			} else {
				l = cast(int)(runnerLength * 16f / cast(float)csis.length);
				offset = cast(int)((runnerLength - l) * (start / cast(float)(csis.length - 16)));
			}

			int x1 = w - buttonSize;
			int x2 = x1 + buttonSize;

			int y1 = buttonSize + offset;
			int y2 = y1 + l;

			glColor4fv(Color4f.White.ptr);
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

		glColor4fv(Color4f.White.ptr);
		glBegin(GL_QUADS);

		foreach(uint i, csi; csis[start .. $]) {
			if (i >= 16)
				break;

			int y = i*9+1;

			if (csi.webName == "fCraft.net Freebuild [ENG]")
				glColor4fv(Color4f(1, .3, .3, 1).ptr);
			else
				glColor4fv(Color4f.White.ptr);

			foreach(uint k, c; csi.webName) {
				if (k >= colums)
					break;

				int x =  k * 8 + 8;

				draw(x, y, c);
			}
		}

		glColor4fv(Color4f.Black.ptr);
		draw(w - buttonSize + (buttonSize - 8) / 2,    3, 30);
		draw(w - buttonSize + (buttonSize - 8) / 2, h-10, 31);

		glEnd();

		glBindTexture(GL_TEXTURE_2D, 0);
		glDisable(GL_TEXTURE_2D);
	}

	void mouseDown(Mouse m, int x, int y, uint b)
	{
		if (b != 1)
			return;

		if (x < w - buttonSize) {
			int which = (y / 9) + start;

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

			if (start + 16 >= csis.length)
				start = cast(int)csis.length - 16;

			if (start < 0)
				start = 0;

			repaint();
		}
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

	static void draw(int x1, int y1, char c) {
		float t1 = (c  ) / 256f;
		float t2 = (c+1) / 256f;

		int x2 = x1 + 8;
		int y2 = y1 + 8;

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

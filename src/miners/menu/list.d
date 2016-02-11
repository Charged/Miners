// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.menu.list;

import std.string : ifind;

import lib.gl.gl;

import charge.charge;
import charge.math.ints : imax;
import charge.game.gui.text;
import charge.game.gui.input;
import charge.game.gui.component;
import charge.game.gui.container;
import charge.game.gui.textbased;

import miners.types;
import miners.options;
import miners.interfaces;
import miners.menu.base;


class ClassicServerListMenu : MenuSceneBase
{
private:
	ListView lv;
	MenuBase mb;
	SearchField sf;

	const string header = `Classic`;

public:
	this(Router r, Options opts, ClassicServerInfo[] csis)
	{
		mb = new MenuBase(header, MenuBase.Buttons.QUIT);
		lv = new ListView(mb, 0, 0, r, opts, csis, &connect);
		sf = new SearchField(mb, 0, 0, lv);

		mb.button.pressed ~= &quit;
		lv.y = sf.h;

		mb.repack();

		super(r, opts, mb);
	}

	void quit(Button b)
	{
		r.quit();
	}

	void connect(ClassicServerInfo csi)
	{
		r.getClassicServerInfoAndConnect(csi);
		r.deleteMe(this);
	}
}


/**
 * Field that users can input a search term, to search for servers.
 */
class SearchField : Text
{
private:
	bool inFocus; //< XXX Hack
	ListView lv;

	const typingCursor = 219;
	const numLetters = 20;

	char[] typed; /**< Typed text. */
	char[] showing; /**< Text including the cursor. */
	char[] typedBuffer; /**< Cache for stuff */

public:
	this(Container p, int x, int y, ListView lv)
	{
		super(p, x, y, "Search: ");
		this.lv = lv;

		typedBuffer.length = numLetters;
		incArrays();
	}

	override void repack()
	{
		w = 424; h = gfxDefaultFont.height + 4 + 4;
	}

	void setListView(ListView lv)
	{
		this.lv = lv;
	}

	override void breakApart()
	{
		super.breakApart();

		auto input = getInput();
		if (input !is null) {
			input.focus(null);
			inFocus = false;
		}

		lv = null;
	}

	override void paint(GfxDraw d)
	{
		// XXX Mega hack
		if (!inFocus) {
			auto input = getInput();
			if (input !is null) {
				input.focus(this);
				inFocus = true;
			}
		}

		int x = w - numLetters * gfxDefaultFont.width - 4;
		int y = 0;
		int w = this.w - x;
		int h = gfxDefaultFont.height + 4;

		d.fill(Color4f.White, false, x, y, w, h);
		d.fill(Color4f(0, 0, 0, .8), false, x + 1, y + 1, w - 2, h - 2);
		d.translate(x + 2 - 7 * gfxDefaultFont.width, y + 2);
		super.paint(d);
	}

	override void keyDown(CtlKeyboard k, int sym, dchar unicode, char[] str)
	{
		// Backspace, remove one character.
		if (sym == 0x08) {
			if (typed.length == 0)
				return;

			return decArrays();
		}

		// New line
		if (sym == 0x0D)
			return;

		// Some chars don't display that well,
		if (!validateChar(unicode))
			return;

		// Don't add any more once the buffer is full.
		if (showing.length >= typedBuffer.length)
			return;

		typedBuffer[typed.length] = cast(char)unicode;
		incArrays();
	}

protected:
	void update(char[] showing)
	{
		setText("Search " ~ showing);

		lv.newSearch(typed.dup);

		repaint();
	}

	bool validateChar(dchar unicode)
	{
		if (unicode == '\t' ||
		    unicode == '\n' ||
		    unicode > 0x7F ||
		    unicode == 0)
			return false;
		return true;
	}

	void incArrays()
	{
		showing = typedBuffer[0 .. showing.length + 1];
		showing[$-1] = typingCursor;
		typed = showing[0 .. $-1];

		update(showing);
	}

	void decArrays()
	{
		showing = typedBuffer[0 .. showing.length - 1];
		showing[$-1] = typingCursor;
		typed = showing[0 .. $-1];

		update(showing);
	}
}


/**
 * Shows a list of servers.
 */
class ListView : Component
{
private:
	Options opts;

	const darkGrey = Color4f(0.05, 0.05, 0.05, 0.8);
	const lightGrey = Color4f(0.7, 0.7, 0.7, 1);
	const red = Color4f(1, .3, .3, 1);
	const green = Color4f(.3, 1, .3, 1);
	alias Color4f.White white;
	alias Color4f.Black black;

	const uint rows = 32;
	uint rowSize = 11;
	const uint colums = 160;
	const uint charOffsetFromTop = 2;

	uint charWidth;
	uint charHeight;

	int start;
	ClassicServerInfo[] csis;
	ClassicServerInfo[] fullList;

	string oldSearch;

	GfxDynamicTexture glyphs;

	const int buttonSize = 14; //< For scrollbar layout

	void delegate(ClassicServerInfo csi) dg;

public:
	this(Container c, int x, int y, Router r,
	     Options opts, ClassicServerInfo[] csis,
	     void delegate(ClassicServerInfo) dg)
	{
		rowSize = gfxDefaultFont.height + 3;
		super(c, x, y, 424, rowSize*rows);

		this.dg = dg;
		this.opts = opts;
		this.csis = csis;
		this.fullList = csis;
	}

	~this()
	{
		assert(glyphs is null);
	}

	override void repack() {}

	void newSearch(string search)
	{
		if (search is null) {
			csis = fullList;
			return;
		}

		// Reuse old list, for faster search?
		auto s = ifind(search, oldSearch) < 0 ? fullList : csis;

		// Create a new list to populate with matching servers.
		csis = new ClassicServerInfo[fullList.length];

		int i;
		foreach(c; s) {
			if (ifind(c.webName, search) < 0)
				continue;
			csis[i++] = c;
		}

		oldSearch = search;
		csis.length = i;

		int myRows = rows;
		if (start >= i - myRows)
			start = imax(i - myRows, 0);

		repaint();
	}


	/*
	 *
	 * Input
	 *
	 */


protected:
	override void mouseDown(Mouse m, int x, int y, uint b)
	{
		if (b != 1)
			return;

		if (x < w - buttonSize) {
			int which = (y / rowSize) + start;

			if (which >= csis.length)
				return;

			dg(csis[which]);
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


	override void paint(GfxDraw d)
	{
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
			int sceneLength = h - buttonSize * 2;
			int l, offset;
			if (csis.length <= rows) {
				l = sceneLength;
			} else {
				l = cast(int)(sceneLength * rows / cast(float)csis.length);
				offset = cast(int)((sceneLength - l) * (start / cast(float)(csis.length - rows)));
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

		auto lastPlayed = opts.lastClassicServerHash();

		void setDefault(ClassicServerInfo csi) {
			if (csi.webId == lastPlayed)
				glColor4fv(red.ptr);
			else
				glColor4fv(lightGrey.ptr);
		}

		foreach(uint i, csi; csis[start .. $]) {
			if (i >= rows)
				break;

			int y = i * rowSize + charOffsetFromTop;

			setDefault(csi);

			foreach(uint k, c; csi.webName) {
				if (k >= colums)
					break;

				int x =  (k + 1) * gfxDefaultFont.width;

				if (c == '[')
					glColor4fv(green.ptr);

				draw(x, y, c);

				if (c == ']')
					setDefault(csi);
			}
		}

		glColor4fv(black.ptr);
		draw(w - buttonSize + (buttonSize - gfxDefaultFont.width) / 2,      3, 30);
		draw(w - buttonSize + (buttonSize - gfxDefaultFont.width) / 2, h - 10, 31);

		glEnd();

		glBindTexture(GL_TEXTURE_2D, 0);
		glDisable(GL_TEXTURE_2D);
	}

	void makeResources()
	{
		if (glyphs !is null)
			return;

		glyphs = GfxDynamicTexture();

		char[256] text;
		foreach(int i, t; text)
			text[i] = cast(ubyte)i;

		text['\0'] = text['\r'] = text['\t'] = text['\n'] = ' ';

		gfxDefaultFont.render(glyphs, text);
	}

	override void releaseResources()
	{
		sysReference(&glyphs, null);
	}

	final void draw(int x1, int y1, char c)
	{
		float t1 = (c  ) / 256f;
		float t2 = (c+1) / 256f;

		int x2 = x1 + gfxDefaultFont.width;
		int y2 = y1 + gfxDefaultFont.height;


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

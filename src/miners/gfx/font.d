// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.gfx.font;

import charge.math.color;
import charge.sys.resource;
import charge.gfx.texture;
import charge.gfx.font;
import charge.gfx.draw;

import miners.gfx.imports;


class ClassicFont : BitmapFont
{
public:
	const string uri = "bfc://";


public:
	void draw(Draw, int x, int y, string text, bool shaded = false)
	{
		drawLayoutedText(x, y, text);
	}

	void buildSize(string text, out uint width, out uint height)
	{
		bool colorSelect;
		int max, x, y;

		foreach(c; text) {
			if (colorSelect) {
				colorSelect = false;
				int index = charToIndex(c);
				if (index >= 0)
					continue;
			} else if (c == '&') {
				colorSelect = true;
				continue;
			}
			switch(c) {
			case '\t':
				x += 4 - (x % 4);
				break;
			case '\n':
				y++;
			case '\r':
				x = 0;
				break;
			default:
				max = x > max ? x : max;
				x++;
			}
		}

		width = (max + 1) * this.width;
		height = (y + 1) * this.height;
	}

	static ClassicFont opCall(string filename)
	{
		auto p = Pool();
		if (filename is null)
			return null;

		auto r = p.resource(uri, filename);
		auto cf = cast(ClassicFont)r;
		if (r !is null) {
			assert(cf !is null);
			return cf;
		}

		auto tex = Texture(filename);
		// Error reporting already taken care of.
		if (tex is null)
			return null;
		scope(failure)
			reference(&tex, null);

		if (tex.width % 16 != 0 ||
		    tex.height % 16 != 0) {
			const str = "Width and Height of font must be mutliple of 16";
			l.error(str);
			throw new Exception(str);
		}

		tex.filter = Texture.Filter.Nearest;
		return new ClassicFont(p, filename, tex);
	}


protected:
	void drawLayoutedText(string text, bool shaded)
	{
		drawLayoutedText(0, 0, text);
	}

	void drawLayoutedText(int startX, int startY, string text)
	{
		uint w = width;
		uint h = height;
		auto color = &colors[15];
		bool colorSelect;
		int x, y;

		glEnable(GL_BLEND);

		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, tex.id);

		glBegin(GL_QUADS);

		colorSelect = false;
		x = startX + shadowOffset;
		y = startY + shadowOffset;
		glColor4fv(Color4f.Black.ptr);
		foreach(c; text) {
			if (colorSelect) {
				colorSelect = false;
				int index = charToIndex(c);
				if (index >= 0)
					continue;
			} else if (c == '&') {
				colorSelect = true;
				continue;
			}
			switch(c) {
			case '\t':
				x += (4 - (x % 4)) + 1;
				break;
			case '\n':
				y += height;
			case '\r':
				x = startX + 1;
				break;
			default:
				drawChar(x, y, c);
				x += width;
			}
		}

		colorSelect = false;
		x = startX; y = startY;
		glColor4fv(color.ptr);
		foreach(c; text) {
			if (colorSelect) {
				colorSelect = false;
				int index = charToIndex(c);
				if (index >= 0) {
					color = &colors[index];
					glColor4fv(color.ptr);
					continue;
				}
			} else if (c == '&') {
				colorSelect = true;
				continue;
			}
			switch(c) {
			case '\t':
				x += 4 - (x % 4);
				break;
			case '\n':
				y += height;
			case '\r':
				x = startX;
				break;
			default:
				drawChar(x, y, c);
				x += width;
			}
		}

		glEnd();

		glBindTexture(GL_TEXTURE_2D, 0);
		glDisable(GL_BLEND);
	}

	int charToIndex(char c)
	{
		if (c >= 'a' && c <= 'f')
			return c - 'a' + 10;
		if (c >= '0' && c <= '9')
			return c - '0';
		return -1;
	}

	const Color4f colors[16] = [
		Color4f( 32/255f,  32/255f,  32/255f, 1),
		Color4f( 45/255f, 100/255f, 200/255f, 1),
		Color4f( 50/255f, 126/255f,  54/255f, 1),
		Color4f(  0/255f, 170/255f, 170/255f, 1),
		Color4f(188/255f,  75/255f,  45/255f, 1),
		Color4f(172/255f,  56/255f, 172/255f, 1),
		Color4f(200/255f, 175/255f,  45/255f, 1),
		Color4f(180/255f, 180/255f, 200/255f, 1),
		Color4f(100/255f, 100/255f, 100/255f, 1),
		Color4f( 72/255f, 125/255f, 247/255f, 1),
		Color4f( 85/255f, 255/255f,  85/255f, 1),
		Color4f( 85/255f, 255/255f, 255/255f, 1),
		Color4f(255/255f,  85/255f,  85/255f, 1),
		Color4f(255/255f,  85/255f, 255/255f, 1),
		Color4f(255/255f, 255/255f,  85/255f, 1),
		Color4f.White,
	];


private:
	this(Pool p, string name, Texture tex)
	{
		super(p, uri, name, tex);
	}
}

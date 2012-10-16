// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.game.dcpu.lem1802;

import lib.gl.gl;

import charge.math.color;
import charge.gfx.draw;
import charge.gfx.texture;
import charge.sys.resource : reference;

import charge.game.gui.component;
import charge.game.gui.container;

import lib.dcpu.dcpu;
import charge.game.dcpu.cpu;


/**
 * Implementation of a NYA ELEKTRISKA LEM1802.
 */
class Lem1802 : Component, DcpuHw
{
public:
	const hwId = 0x7349F615;
	const hwVersion = 0x1802;
	const hwManufacturer = 0x1C6C8B36;

	const width = 32;
	const height = 12;
	const glyphWidth = 4;
	const glyphHeight = 8;

	const numColors = 16;
	const numGlyphs = 128;
	const numVram = width * height;

	const borderSize = 4;

	enum {
		LEM1802_MEM_MAP_SCREEN,
		LEM1802_MEM_MAP_FONT,
		LEM1802_MEM_MAP_PALETTE,
		LEM1802_SET_BORDER_COLOR,
		LEM1802_MEM_DUMP_FONT,
		LEM1802_MEM_DUMP_PALETTE,
	}


protected:
	TextureContainer container;

	ushort videoRam[];
	ushort fontRam[];
	ushort paletteRam[];

	DynamicTexture glyphs;

	Dcpu c;
	DcpuHwInfo info;

	ushort index;
	ushort borderColorIndex;


public:
	this(Dcpu c)
	{
		super(null, 0, 0,
		      width * glyphWidth + borderSize * 2,
		      height * glyphHeight + borderSize * 2);

		container = new TextureContainer(w, h);
		container.add(this);

		paletteRam = defaultPaletteRam;
		fontRam = defaultFontRam;
		videoRam = c.ram[0x8000 .. 0x8000 + numVram];

		this.c = c;
		info.id = hwId;
		info.ver = hwVersion;
		info.manufacturer = hwManufacturer;

		c.register(this);
	}

	void destruct()
	{
		container.breakApart();
	}

	Texture texture()
	{
		return container.texture();
	}

	void paintTexture()
	{
		repaint();

		container.paintTexture();
	}


	/*
	 *
	 * DcpuHw
	 *
	 */


protected:
	void interupt()
	{
		auto a = c.reg(REG_A);
		auto b = c.reg(REG_B);

		switch(a) {
		case LEM1802_MEM_MAP_SCREEN:
			videoRam = c.getSliceSafe(b, numVram, null);
			break;

		case LEM1802_MEM_MAP_FONT:
			fontRam = c.getSliceSafe(b, numGlyphs*2, defaultFontRam);
			break;

		case LEM1802_MEM_MAP_PALETTE:
			paletteRam = c.getSliceSafe(b, numColors, defaultPaletteRam);
			break;

		case LEM1802_SET_BORDER_COLOR:
			borderColorIndex = b & 0x000f;
			break;

		case LEM1802_MEM_DUMP_FONT:
			c.addSleep(256);
			auto dst = c.getSliceSafe(b, numGlyphs*2, null);
			if (dst is null)
				return;
			dst[] = defaultFontRam;
			break;

		case LEM1802_MEM_DUMP_PALETTE:
			c.addSleep(16);
			auto dst = c.getSliceSafe(b, numColors, null);
			if (dst is null)
				return;
			dst[] = defaultPaletteRam[];
			break;

		default:
		}
	}

	void notifyUnregister()
	{
		videoRam = null;
		paletteRam = defaultPaletteRam;
		fontRam = defaultFontRam;
	}

	DcpuHwInfo* getHwInfo()
	{
		return &info;
	}


	/*
	 *
	 * Component
	 *
	 */


	void repack() {}

	void releaseResources()
	{
		reference(&glyphs, null);
	}

	void paint(Draw d)
	{
		Color4f colors[16];
		foreach(int i, p; paletteRam) {
			colors[i] = Color4f(
				(0x0f & (p >> 8)) / 16f,
				(0x0f & (p >> 4)) / 16f,
				(0x0f & (p >> 0)) / 16f,
				1);
		}

		d.fill(colors[borderColorIndex], false, 0, 0, w, h);

		// On error draw nothing.
		if (videoRam is null)
			return;

		// Update the glyphs.
		makeGlyphs();

		int top = borderSize;
		int bottom = top + glyphHeight;
		int left = borderSize;
		int right = left + glyphWidth;

		glDisable(GL_BLEND);
		glBegin(GL_QUADS);
		foreach (int i, c; videoRam) {
			int bg = (c & 0x0f00) >> 8;

			glColor4fv(colors[bg].ptr);
			glVertex2i( left,    top);
			glVertex2i( left, bottom);
			glVertex2i(right, bottom);
			glVertex2i(right,    top);


			if (i % 32 == 31) {
				top += glyphHeight;
				bottom = top + glyphHeight;
				left = borderSize;
				right = left + glyphWidth;
			} else {
				left += glyphWidth;
				right = left + glyphWidth;
			}
		}
		glEnd();


		top = borderSize;
		bottom = top + glyphHeight;
		left = borderSize;
		right = left + glyphWidth;

		glEnable(GL_BLEND);
		glEnable(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, glyphs.id);
		glBegin(GL_QUADS);
		foreach (int i, c; videoRam) {
			int fg = (c & 0xf000) >>  12;
			int te = (c & 0x007f) >>  0;

			float srcY1, srcY2;
			srcY1 =     te / cast(float)numGlyphs;
			srcY2 = (te+1) / cast(float)numGlyphs;

			glColor4fv(colors[fg].ptr);
			glTexCoord2f(    0,  srcY2);
			glVertex2i(   left,    top);
			glTexCoord2f(    1,  srcY2);
			glVertex2i(   left, bottom);
			glTexCoord2f(    1,  srcY1);
			glVertex2i(  right, bottom);
			glTexCoord2f(    0,  srcY1);
			glVertex2i(  right,    top);

			if (i % 32 == 31) {
				top += glyphHeight;
				bottom = top + glyphHeight;
				left = borderSize;
				right = left + glyphWidth;
			} else {
				left += glyphWidth;
				right = left + glyphWidth;
			}
		}

		glEnd();
		glBindTexture(GL_TEXTURE_2D, 0);
		glDisable(GL_TEXTURE_2D);
	}

	void makeGlyphs()
	{
		int glTarget = GL_TEXTURE_2D;
		int glFormat = GL_ALPHA;
		int glInternalFormat = GL_ALPHA;
		uint w;
		uint h;

		const numShifts = 16;
		ubyte[glyphWidth*glyphHeight*numGlyphs] pixels;
		static assert(pixels.length % numShifts == 0);

		ushort *ptr = cast(ushort*)fontRam.ptr;
		for(int i, k; i < pixels.length; k++) {
			auto v = ptr[k ^ 1];
			for(int j; j < numShifts; j++)
				pixels[i++] = cast(ubyte)(((v >> j) & 0x01) ? 0xff : 0x00);
		}

		if (glyphs is null)
			glyphs = new DynamicTexture(null);

		GLint id = glyphs.id;

		if (!glIsTexture(id))
			glGenTextures(1, cast(GLuint*)&id);

		glBindTexture(glTarget, id);
		// Yes width and height should be swapped.
		glTexImage2D(
			glTarget,               //target
			0,                      //level
			glInternalFormat,       //internalformat
			glyphHeight,            //width
			glyphWidth * numGlyphs, //height
			0,                      //border
			glFormat,               //format
			GL_UNSIGNED_BYTE,       //type
			pixels.ptr);            //pixels
		glTexParameteri(glTarget, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(glTarget, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		glTexParameterf(glTarget, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		glTexParameterf(glTarget, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

		glyphs.update(id, w, h);

		glBindTexture(glTarget, 0);
	}


public:
	const ushort defaultPaletteRam[numColors] = [
		0x0000, 0x000A, 0x00A0, 0x00AA,
		0x0A00, 0x0A0A, 0x0A50, 0x0AAA,
		0x0555, 0x055F, 0x05F5, 0x05FF,
		0x0F55, 0x0F5F, 0x0FF5, 0x0FFF
	];

	const ushort[numGlyphs*2] defaultFontRam = [
		0xb79e, 0x388e, 0x722c, 0x75f4,
		0x19bb, 0x7f8f, 0x85f9, 0xb158,
		0x242e, 0x2400, 0x082a, 0x0800,
		0x0008, 0x0000, 0x0808, 0x0808,
		0x00ff, 0x0000, 0x00f8, 0x0808,
		0x08f8, 0x0000, 0x080f, 0x0000,
		0x000f, 0x0808, 0x00ff, 0x0808,
		0x08f8, 0x0808, 0x08ff, 0x0000,
		0x080f, 0x0808, 0x08ff, 0x0808,
		0x6633, 0x99cc, 0x9933, 0x66cc,
		0xfef8, 0xe080, 0x7f1f, 0x0701,
		0x0107, 0x1f7f, 0x80e0, 0xf8fe,
		0x5500, 0xaa00, 0x55aa, 0x55aa,
		0xffaa, 0xff55, 0x0f0f, 0x0f0f,
		0xf0f0, 0xf0f0, 0x0000, 0xffff,
		0xffff, 0x0000, 0xffff, 0xffff,
		0x0000, 0x0000, 0x005f, 0x0000,
		0x0300, 0x0300, 0x3e14, 0x3e00,
		0x266b, 0x3200, 0x611c, 0x4300,
		0x3629, 0x7650, 0x0002, 0x0100,
		0x1c22, 0x4100, 0x4122, 0x1c00,
		0x1408, 0x1400, 0x081c, 0x0800,
		0x4020, 0x0000, 0x0808, 0x0800,
		0x0040, 0x0000, 0x601c, 0x0300,
		0x3e49, 0x3e00, 0x427f, 0x4000,
		0x6259, 0x4600, 0x2249, 0x3600,
		0x0f08, 0x7f00, 0x2745, 0x3900,
		0x3e49, 0x3200, 0x6119, 0x0700,
		0x3649, 0x3600, 0x2649, 0x3e00,
		0x0024, 0x0000, 0x4024, 0x0000,
		0x0814, 0x2200, 0x1414, 0x1400,
		0x2214, 0x0800, 0x0259, 0x0600,
		0x3e59, 0x5e00, 0x7e09, 0x7e00,
		0x7f49, 0x3600, 0x3e41, 0x2200,
		0x7f41, 0x3e00, 0x7f49, 0x4100,
		0x7f09, 0x0100, 0x3e41, 0x7a00,
		0x7f08, 0x7f00, 0x417f, 0x4100,
		0x2040, 0x3f00, 0x7f08, 0x7700,
		0x7f40, 0x4000, 0x7f06, 0x7f00,
		0x7f01, 0x7e00, 0x3e41, 0x3e00,
		0x7f09, 0x0600, 0x3e61, 0x7e00,
		0x7f09, 0x7600, 0x2649, 0x3200,
		0x017f, 0x0100, 0x3f40, 0x7f00,
		0x1f60, 0x1f00, 0x7f30, 0x7f00,
		0x7708, 0x7700, 0x0778, 0x0700,
		0x7149, 0x4700, 0x007f, 0x4100,
		0x031c, 0x6000, 0x417f, 0x0000,
		0x0201, 0x0200, 0x8080, 0x8000,
		0x0001, 0x0200, 0x2454, 0x7800,
		0x7f44, 0x3800, 0x3844, 0x2800,
		0x3844, 0x7f00, 0x3854, 0x5800,
		0x087e, 0x0900, 0x4854, 0x3c00,
		0x7f04, 0x7800, 0x047d, 0x0000,
		0x2040, 0x3d00, 0x7f10, 0x6c00,
		0x017f, 0x0000, 0x7c18, 0x7c00,
		0x7c04, 0x7800, 0x3844, 0x3800,
		0x7c14, 0x0800, 0x0814, 0x7c00,
		0x7c04, 0x0800, 0x4854, 0x2400,
		0x043e, 0x4400, 0x3c40, 0x7c00,
		0x1c60, 0x1c00, 0x7c30, 0x7c00,
		0x6c10, 0x6c00, 0x4c50, 0x3c00,
		0x6454, 0x4c00, 0x0836, 0x4100,
		0x0077, 0x0000, 0x4136, 0x0800,
		0x0201, 0x0201, 0x0205, 0x0200
	];
}

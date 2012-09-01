// Donated by feep from the dglut project under the CC0 license,
// mangled by Jakob Bornecrantz and upgraded to GPLv2 only.
// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.util.png;

import std.math;
import charge.util.zip;
import charge.util.memory;

class PngImage
{
	uint width;
	uint height;
	uint channels; /**< 1 Intensity, 2 N/A, 3 RGB, 4 RGBA */
	cMemoryArray!(ubyte) pixels;

	this(uint width, uint height, uint channels)
	{
		assert(channels != 2);
		assert(channels <= 4);

		this.width = width;
		this.height = height;
		this.channels = channels;
		this.pixels.length = width * height * channels;
	}

	~this()
	{
		pixels.free();
	}
}

PngImage pngDecode(void[] _data, bool convert = false)
{
	uint width, height, depth, color;
	ubyte[3][] palette;
	ubyte[] compressed;
	ubyte[] data;

	data = cast(ubyte[])_data;

	// Is this a png image
	if (data[0..8] != [cast(ubyte)137, 80, 78, 71, 13, 10, 26, 10])
		return null;

	// Advance
	data = data[8..$];

	while (data.length) {
		auto len = chip!(uint, true)(data);

		char[4] type = cast(char[])data[0 .. 4];

		len += 4;
		auto chunk = data[4 .. len];
		data = data[len .. $];
		auto crc = chip!(uint)(data);
		switch (type) {
		case "IDAT":
			compressed ~= chunk;
			break;
		case "PLTE":
			palette = cast(ubyte[3][]) chunk;
			break;
		case "bKGD":
			//logln("Background data: ", chunk);
			break;
		case "IHDR":
			width = chip!(uint, true)(chunk);
			height = chip!(uint, true)(chunk);
			depth = chip!(ubyte)(chunk);
			color = chip!(ubyte)(chunk);
			// Truecolor non-indexed (2), indexed(3), non-indexed with alpha (6)
			auto compm = chip!(ubyte)(chunk);
			auto filterm = chip!(ubyte)(chunk);
			auto interlace = chip!(ubyte)(chunk);
			break;
		case "tEXt":
			break;
		case "IEND":
			data.length = 0;
			break; // discard the rest
		default:
		}
	}

	assert(data.length == 0);

	cMemoryArray!(ubyte) decompData;
	decompData.steal = cast(ubyte[])cUncompress(compressed);
	scope(exit)
		decompData.free();
	auto decomp = decompData[];

	int bpp;
	switch(color) {
	case 0:
		bpp = depth / 8;
		break;
	case 2:
		bpp = 3 * (depth / 8);
		break;
	case 3:	
		bpp = depth / 8;
		break;
	case 6:
		bpp = 4 * (depth / 8);
		break;
	default:
	}

	ubyte[][] lines;
	lines.length = height;
	auto scanwidth = width * bpp;

	for (int y = 0; y < height; ++y) {
		ubyte filter = chip!(ubyte)(decomp);
		auto scanline = decomp[0 .. scanwidth]; decomp = decomp[scanwidth .. $];
		switch (filter) {
		case 0:
			break;
		// sub: add previous pixel
		case 1:
			foreach (i, ref entry; scanline) {
				ubyte left = 0;
				if (i !< bpp)
					left = scanline[i - bpp];
				entry = limit(entry + left);
			}
			break;
		// up: add previous line
		case 2:
			foreach (i, ref entry; scanline) {
				ubyte up = 0;
				if (lines.length) up = lines[y - 1][i];
					entry = limit(entry + up);
			}
			break;
		// average: (sub + up) / 2
		case 3:
			foreach (i, ref entry; scanline) {
				ubyte left = 0;
				if (i !< bpp)
					left = scanline[i - bpp];
				ubyte up = 0;
				if (lines.length)
					up = lines[y - 1][i];
				entry = limit(entry + (left + up) / 2);
			}
			break;
		// paeth: magic
		case 4:
			foreach (i, ref entry; scanline) {
				ubyte up = 0;
				ubyte left = 0;
				ubyte upleft = 0;

				if (i !< bpp)
					left = scanline[i - bpp];

				if (lines.length) {
					up = lines[y - 1][i];
					if (i !< bpp)
						upleft = lines[y - 1][i - bpp];
				}

				entry = limit(entry + paethPredictor(left, up, upleft));
			}
			break;
		default:
			assert(false);
		}
		lines[y] = scanline;
	}

	assert(decomp.length == 0);

	PngImage result;
	if (depth != 8)
		return result;

	if (convert && color != 6) {
		result = new PngImage(width, height, 4);
		auto ptr = result.pixels.ptr;

		if (color == 0) {
			foreach (y, line; lines) {
				foreach (x, pixel; line) {
					auto i = (y*width + x) * 4;
					ptr[i+0] = pixel;
					ptr[i+1] = pixel;
					ptr[i+2] = pixel;
					ptr[i+3] = 255;
				}
			}
		} else if (color == 2) {
			foreach (y, line; lines) {
				for (int x; x < line.length / 3; x++) {
					auto dst = (y * width + x) * 4;
					auto src = x * 3;
					ptr[dst .. dst + 3] = line[src .. src + 3];
					ptr[dst + 3] = 255;
				}
			}
		} else if (color == 3) {
			foreach (y, line; lines) {
				foreach (x, pixel; line) {
					auto i = (y*width + x) * 4;
					ptr[i .. i + 3] = palette[pixel];
					ptr[i + 3] = 255;
				}
			}
		} else
			assert(false);
	// Handle Palette
	} else if (color == 3) {
		result = new PngImage(width, height, 3);
		auto target = result.pixels[];

		foreach (y, line; lines) {
			foreach (x, pixel; line) {
				auto i = (y*width + x)*3;
				target[i .. i+3] = palette[pixel];
			}
		}
	} else {
		if (color == 0)
			result = new PngImage(width, height, 1);
		else if (color == 2)
			result = new PngImage(width, height, 3);
		else if (color == 6)
			result = new PngImage(width, height, 4);
		else
			assert(false);

		auto target = result.pixels[];
		foreach (line; lines) {
			target[0 .. line.length] = line;
			target = target[line.length .. $];
		}
	}

	return result;
}

private:

T chip(T, bool reverse = false)(ref ubyte[] data)
{
	T ret;

	// Reverse
	static if (reverse) {
		ubyte[T.sizeof] temp = data[0 .. T.sizeof];
		temp.reverse;
		ret = *cast(T*)temp.ptr;
	} else {
		ret = *cast(T*)data.ptr;
	}

	// Advance data read
	data = data[T.sizeof .. $];
	return ret;
}

ubyte limit(int v)
{
	while (v < 0)
		v += 256;
	return cast(ubyte)v;
}

// taken from the RFC literally
ubyte paethPredictor(ubyte a, ubyte b, ubyte c)
{
	//a = left, b = above, c = upper left
	auto p = a + b - c; // initial estimate
	auto pa = abs(p - a); // distances to a, b, c
	auto pb = abs(p - b);
	auto pc = abs(p - c);

	//return nearest of a,b,c,
	//breaking ties in order a,b,c.
	if (pa <= pb && pa <= pc)
		return a;
	else if (pb <= pc)
		return b;
	else
		return c;
}

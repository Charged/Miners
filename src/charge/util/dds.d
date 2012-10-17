// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for Dds image loader functions.
 */
module charge.util.dds;

import charge.math.ints;


struct DdsHeader
{
	uint magicUint;
	uint size;
	uint flags;
	uint height;
	uint width;
	uint pitchOrLinearSize;
	uint depth;
	uint mipMapCount;
	uint reserved1[11];
	DdsPixelFormat pf;
	uint caps;
	uint caps2;
	uint caps3;
	uint caps4;
	uint reserved2;

	char[] magic()
	{
		return (cast(char*)&magicUint)[0 .. 4];
	}
}

struct DdsPixelFormat
{
	uint size;
	uint flags;
	uint fourCCUint;
	uint rgbBitCount;
	uint rBitMask;
	uint gBitMask;
	uint bBitMask;
	uint aBitMask;

	char[] fourCC()
	{
		return (cast(char*)&fourCCUint)[0 .. 4];
	}
}

enum DdsFlags {
	CAPS        = 0x1,
	HEIGHT      = 0x2,
	WIDTH       = 0x4,
	PITCH       = 0x8,
	PIXELFORMAT = 0x1000,
	MIPMAPCOUNT = 0x20000,
	LINEARSIZE  = 0x80000,
	DEPTH       = 0x800000,
}

enum DdsCaps {
	COMPLEX = 0x8,
	TEXTURE = 0x1000,
	MIPMAP  = 0x400000,
}


/**
 * Validate data that it is a valid DdsHeader.
 */
DdsHeader* checkHeader(void data[])
{
	if (data.length <= DdsHeader.sizeof)
		throw new Exception("File to small");

	auto h = cast(DdsHeader*)data.ptr;

	if (h.magic != "DDS ")
		throw new Exception("DdsHeader magic wrong");

	if (h.size != 124)
		throw new Exception("DdsHeader size wrong");

	if (h.pf.size != 32)
		throw new Exception("DdsPixelFormat size wrong");

	return h;
}


/**
 * Return array of all the image data that follows the header.
 */
void[][] extractBytes(void data[])
{
	auto h = checkHeader(data);

	if (h.flags != (DdsFlags.CAPS | DdsFlags.HEIGHT | DdsFlags.WIDTH |
	    DdsFlags.PIXELFORMAT | DdsFlags.MIPMAPCOUNT | DdsFlags.LINEARSIZE))
		throw new Exception("Unsupported DdsFlags");

	if (h.caps != (DdsCaps.TEXTURE | DdsCaps.COMPLEX | DdsCaps.MIPMAP))
		throw new Exception("Unsupported DdsCaps");

	uint blockSize;

	switch(h.pf.fourCC) {
	case "DXT1":
		blockSize = 8;
		break;
	case "DXT5":
		blockSize = 16;
		break;
	default:
		throw new Exception("Unsupported fourCC format");
	}

	auto where = DdsHeader.sizeof;
	void ret[][];

	for(int i; i < h.mipMapCount; i++) {
		auto width = minify(imax(1, h.width), i);
		auto height = minify(imax(1, h.height), i);

		auto calcSize = nblocks(width, 4) * nblocks(height, 4) * blockSize;

		if (where + calcSize > data.length)
			throw new Exception("File size is to small");

		ret ~= data[where .. where + calcSize];
		where += calcSize;
	}

	return ret;
}

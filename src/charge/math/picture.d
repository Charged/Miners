// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for Picture.
 */
module charge.math.picture;

import charge.math.color;
import charge.sys.resource;
import charge.sys.logger;
import charge.sys.file;
import charge.util.png;
import charge.util.memory;


/**
 * 2D Picture.
 *
 * @ingroup Resource
 */
class Picture : Resource
{
public:
	enum string uri = "pic://";

	Color4b *pixels;

	uint width;
	uint height;

private:
	mixin Logging;

public:
	static Picture opCall(Pool p, string filename)
	in {
		assert(p !is null);
		assert(filename !is null);
	}
	body {
		auto r = p.resource(uri, filename);
		auto pic = cast(Picture)r;
		if (r !is null) {
			assert(pic !is null);
			return pic;
		}

		auto i = getImage(p, filename);
		if (i is null)
			return null;

		return new Picture(p, filename, i);
	}

	static Picture opCall(Pool p, string name, string filename)
	in {
		assert(p !is null);
		assert(name !is null);
	}
	body {
		auto i = getImage(p, filename);
		if (i is null)
			return null;

		return new Picture(p, name, i);
	}

	static Picture opCall(PngImage pic)
	{
		return new Picture(null, null, pic);
	}

	static Picture opCall(Picture pic)
	{
		return new Picture(null, null, pic);
	}

	static Picture opCall(uint width, uint height)
	{
		return new Picture(null, null, width, height);
	}

	static Picture opCall(Pool p, string name, uint width, uint height)
	in {
		assert(p !is null);
		assert(name !is null);
	}
	body {
		return new Picture(p, name, width, height);
	}

	static Picture opCall(Pool p, string name, PngImage pic)
	in {
		assert(p !is null);
		assert(name !is null);
	}
	body {
		return new Picture(p, name, pic);
	}

	static Picture opCall(Pool p, string name, Picture pic)
	in {
		assert(p !is null);
		assert(name !is null);
	}
	body {
		return new Picture(p, name, pic);
	}


protected:
	this(Pool p, string name, uint w, uint h)
	{
		super(p, uri, name);

		width = w;
		height = h;
		pixels = cast(Color4b*)cMalloc(calcImageSize());
	}

	this(Pool p, string name, PngImage image)
	{
		// Call base calss constructor
		super(p, uri, name);

		if (image.channels != 4) {
			throw new Exception("png image must have 4 channels or be converted.");
		}

		this.width = image.width;
		this.height = image.height;

		if (image.imageSize != calcImageSize()) {
			throw new Exception("png image storage is not large enough");
		}

		this.pixels = cast(Color4b*)image.steal();
	}

	this(Pool p, string name, Picture image)
	{
		// Allocs pixels
		this(p, name, image.width, image.height);

		size_t size = image.width * image.height;
		pixels[0 .. size] = image.pixels[0 .. size];
	}

	~this()
	{
		cFree(pixels);
	}

	static PngImage getImage(Pool p, string filename)
	{
		auto file = p.load(filename);
		if (file is null)
			return null;
		scope(exit)
			delete file;

		return pngDecode(file.peekMem, true);
	}

	size_t calcImageSize()
	{
		return width * height * Color4b.sizeof;
	}
}

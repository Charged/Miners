// Copyright © 2011-2017, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for PngImage loading.
 */
module charge.util.png;

import charge.util.memory;


class PngImage
{
	uint width;
	uint height;
	uint channels; /**< 1 Intensity, 2 N/A, 3 RGB, 4 RGBA */

	uint imageSize;
	ubyte* ptr;

	this(uint width, uint height, uint channels, ubyte* ptr)
	{
		assert(channels != 2);
		assert(channels <= 4);

		this.width = width;
		this.height = height;
		this.channels = channels;
		this.ptr = ptr;
		this.imageSize = width * height * channels;
	}

	~this()
	{
		if (ptr !is null) {
			stbi_image_free(cast(void*)ptr);
		}
	}

	ubyte* steal()
	{
		if (ptr is null) {
			return null;
		}

		auto ret = cast(ubyte*)cMalloc(imageSize);
		ret[0 .. imageSize] = ptr[0 .. imageSize];

		// Do the actual stealing.
		stbi_image_free(cast(void*)ptr);
		ptr = null;

		return ret;
	}
}

PngImage pngDecode(void[] data, bool convert = false)
{
	int x, y, comp;
	auto ptr = stbi_load_from_memory(data, x, y, comp, STBI_rgb_alpha);
	if (ptr is null) {
		return null;
	}

	return new PngImage(cast(int)x, cast(int)y, cast(int)comp, ptr);
}

private:

alias stbi_uc = ubyte;

enum {
	STBI_default = 0,

	STBI_grey = 1,
	STBI_grey_alpha = 2,
	STBI_rgb = 3,
	STBI_rgb_alpha = 4
}

stbi_uc* stbi_load_from_memory(void[] data, out int x, out int y, out int comp, int req_comp)
{
	return stbi_load_from_memory(cast(stbi_uc*)data.ptr, cast(int)data.length, &x, &y, &comp, req_comp);
}

extern(C) {
	const(char)* stbi_failure_reason();
	void stbi_set_flip_vertically_on_load(int flag_true_if_should_flip);
	stbi_uc* stbi_load_from_memory(const(stbi_uc)*, int, int*, int*, int*, int);
	void stbi_image_free(void*);
}

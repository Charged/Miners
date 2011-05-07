// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.sfx.buffermanager;

import std.stdio;
import std.string;

import lib.sdl.sdl;

import charge.sys.logger;
import charge.sys.file;
import charge.sfx.buffer;
import charge.sfx.al;

class BufferManager
{
private:
	mixin Logging;
	static BufferManager instance;
	Buffer[char[]] map;

public:

	static Buffer opCall(char[] filename)
	{
		return get.get(filename);
	}

	static BufferManager get()
	{
		if (instance is null)
			instance = new BufferManager();
		return instance;
	}

	Buffer get(char[] filename)
	{
		if (filename is null)
			return null;

		if (filename in map)
			return map[filename];

		return load(filename);
	}

private:
	Buffer load(char[] filename)
	{
		ALuint id;
		SDL_AudioSpec spec;
		SDL_AudioSpec *ret;
		SDL_RWops *ops;
		Uint8 *data;
		File file;
		uint len;

		file = FileManager(filename);

		if (file is null) {
			l.warn("Failed to open file ", filename);
			return null;
		}
		scope(exit) delete file;

		auto sdl_file = file.peekSDL;

		if (!SDL_LoadWAV_RW(sdl_file, 1, &spec, &data, &len)) {
			l.warn("Invalid format in file ", filename);
			return null;
		}

		/* Dont forget to free */
		scope(exit) SDL_FreeWAV(data);

		if (spec.format != 0x0008 || spec.channels != 1) {
			l.warn("Bad format due to lazy programer ", filename);
			return null;
		}

		alGenBuffers(1, &id);
		alBufferData(id, AL_FORMAT_MONO8, data, len, spec.freq);

		ALint bits;
		ALint size;
		ALint channels;
		ALint frequency;

		alGetBufferi(id, AL_BITS, &bits);
		alGetBufferi(id, AL_SIZE, &size);
		alGetBufferi(id, AL_CHANNELS, &channels);
		alGetBufferi(id, AL_FREQUENCY, &frequency);

		l.info("Loaded ", filename, " with size: ", size, ", bits: ", bits,
			", channels: ", channels, ", frequency: ", frequency);

		auto b = new Buffer(id);

		map[filename] = b;

		return b;
	}

}

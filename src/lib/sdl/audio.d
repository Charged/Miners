// This file is a hand mangled header file from SDL.
// See copyright in src/lib/sdl/sdl.d (LGPLv2+).
module lib.sdl.audio;

import lib.loader;
import lib.sdl.types;
import lib.sdl.rwops;

extern(C):

struct SDL_AudioSpec
{
	int    freq;
	Uint16 format;
	Uint8  channels;
	Uint8  silence;
	Uint16 samples;
	Uint16 padding;
	Uint32 size;

	extern (C) void (*callback)(void *userdata, Uint8 *stream, int len);
	void *userdata;
}

const AUDIO_U8     = 0x0008;
const AUDIO_S8     = 0x8008;
const AUDIO_U16LSB = 0x0010; /* little */
const AUDIO_S16LSB = 0x8010;
const AUDIO_U16MSB = 0x1010; /* big */
const AUDIO_S16MSB = 0x9010;

version(LittleEndian)
{
	const AUDIO_U16SYS = AUDIO_U16LSB;
	const AUDIO_S16SYS = AUDIO_S16LSB;
}
else
{
	const AUDIO_U16SYS = AUDIO_U16MSB;
	const AUDIO_S16SYS = AUDIO_S16MSB;
}

void loadSDL_audio(Loader l)
{
	loadFunc!(SDL_LoadWAV_RW)(l);
	loadFunc!(SDL_FreeWAV)(l);
}

extern(C):

SDL_AudioSpec* (*SDL_LoadWAV_RW)(SDL_RWops *src, int freesrc, SDL_AudioSpec *spec, Uint8 **audio_buf, Uint32 *audio_len);
void (*SDL_FreeWAV)(Uint8 *audio_buf);

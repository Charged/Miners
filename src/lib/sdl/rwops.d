// This file is a hand mangled header file from SDL.
// See copyright in src/lib/sdl/sdl.d (LGPLv2+).
module lib.sdl.rwops;

import std.c.stdio : FILE;

import lib.sdl.types;


struct SDL_RWops
{
public:
	extern (C) int function(SDL_RWops *contex, int offset, int whence) seek;
	extern (C) int function(SDL_RWops *context, void *ptr, int size, int maxnum) read;
	extern (C) int function(SDL_RWops *context, void *ptr, int size, int num) write;
	extern (C) int function(SDL_RWops *context) close;

	Uint32 type;
	union Hidden
	{
		struct Win32io
		{
			int    append;
			void*  h;
		}
		Win32io win32io;

		struct Stdio
		{
			int autoclose;
			FILE *fp;
	    }
		Stdio stdio;

	    struct Mem
		{
			Uint8 *base;
			Uint8 *here;
			Uint8 *stop;
		}
		Mem mem;

		struct Unknown
		{
			void *data1;
		}
		Unknown unknown;
	}
	Hidden hidden;
}

const RW_SEEK_SET = 0;
const RW_SEEK_CUR = 1;
const RW_SEEK_END = 2;

version (DynamicSDL)
{
extern (C):
SDL_RWops* function(char *file, char *mode) SDL_RWFromFile;
SDL_RWops* function(FILE *fp, int autoclose) SDL_RWFromFP;
SDL_RWops* function(void *mem, int size) SDL_RWFromMem;
SDL_RWops* function(void *mem, int size) SDL_RWFromConstMem;
SDL_RWops* function() SDL_AllocRW;
void function(SDL_RWops *area) SDL_FreeRW;
Uint16 function(SDL_RWops *src) SDL_ReadLE16;
Uint16 function(SDL_RWops *src) SDL_ReadBE16;
Uint32 function(SDL_RWops *src) SDL_ReadLE32;
Uint32 function(SDL_RWops *src) SDL_ReadBE32;
Uint64 function(SDL_RWops *src) SDL_ReadLE64;
Uint64 function(SDL_RWops *src) SDL_ReadBE64;
int function(SDL_RWops *dst, Uint16 value) SDL_WriteLE16;
int function(SDL_RWops *dst, Uint16 value) SDL_WriteBE16;
int function(SDL_RWops *dst, Uint32 value) SDL_WriteLE32;
int function(SDL_RWops *dst, Uint32 value) SDL_WriteBE32;
int function(SDL_RWops *dst, Uint64 value) SDL_WriteLE64;
int function(SDL_RWops *dst, Uint64 value) SDL_WriteBE64;
}
else
{
extern (C):
SDL_RWops* SDL_RWFromFile(char *file, char *mode);
SDL_RWops* SDL_RWFromFP(FILE *fp, int autoclose);
SDL_RWops* SDL_RWFromMem(void *mem, int size);
SDL_RWops* SDL_RWFromConstMem(void *mem, int size);
SDL_RWops* SDL_AllocRW();
void SDL_FreeRW(SDL_RWops *area);
Uint16 SDL_ReadLE16(SDL_RWops *src);
Uint16 SDL_ReadBE16(SDL_RWops *src);
Uint32 SDL_ReadLE32(SDL_RWops *src);
Uint32 SDL_ReadBE32(SDL_RWops *src);
Uint64 SDL_ReadLE64(SDL_RWops *src);
Uint64 SDL_ReadBE64(SDL_RWops *src);
int SDL_WriteLE16(SDL_RWops *dst, Uint16 value);
int SDL_WriteBE16(SDL_RWops *dst, Uint16 value);
int SDL_WriteLE32(SDL_RWops *dst, Uint32 value);
int SDL_WriteBE32(SDL_RWops *dst, Uint32 value);
int SDL_WriteLE64(SDL_RWops *dst, Uint64 value);
int SDL_WriteBE64(SDL_RWops *dst, Uint64 value);
}

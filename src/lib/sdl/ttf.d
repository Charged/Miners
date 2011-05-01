// This file is a hand mangled header file from SDL.
// See copyright in src/lib/sdl/sdl.d (LGPLv2+).
module lib.sdl.ttf;

import lib.loader;
import lib.sdl.sdl;

alias void TTF_Font;

const SDL_TTF_MAJOR_VERSION = 2;
const SDL_TTF_MINOR_VERSION = 0;
const SDL_TTF_PATCHLEVEL    = 9;

const UNICODE_BOM_NATIVE  = 0xFEFF;
const UNICODE_BOM_SWAPPED = 0xFFFE;

const TTF_STYLE_NORMAL    = 0x00;
const TTF_STYLE_BOLD      = 0x01;
const TTF_STYLE_ITALIC    = 0x02;
const TTF_STYLE_UNDERLINE = 0x04;

void loadSDLttf(Loader l)
{
	loadFunc!(TTF_Linked_Version)(l);
	loadFunc!(TTF_ByteSwappedUNICODE)(l);
	loadFunc!(TTF_Init)(l);
	loadFunc!(TTF_OpenFont)(l);
	loadFunc!(TTF_OpenFontIndex)(l);
	loadFunc!(TTF_OpenFontRW)(l);
	loadFunc!(TTF_OpenFontIndexRW)(l);
	loadFunc!(TTF_GetFontStyle)(l);
	loadFunc!(TTF_SetFontStyle)(l);
	loadFunc!(TTF_FontHeight)(l);
	loadFunc!(TTF_FontAscent)(l);
	loadFunc!(TTF_FontDescent)(l);
	loadFunc!(TTF_FontLineSkip)(l);
	loadFunc!(TTF_FontFaces)(l);
	loadFunc!(TTF_FontFaceIsFixedWidth)(l);
	loadFunc!(TTF_FontFaceFamilyName)(l);
	loadFunc!(TTF_FontFaceStyleName)(l);
	loadFunc!(TTF_GlyphMetrics)(l);
	loadFunc!(TTF_SizeText)(l);
	loadFunc!(TTF_SizeUTF8)(l);
	loadFunc!(TTF_SizeUNICODE)(l);
	loadFunc!(TTF_RenderText_Solid)(l);
	loadFunc!(TTF_RenderUTF8_Solid)(l);
	loadFunc!(TTF_RenderUNICODE_Solid)(l);
	loadFunc!(TTF_RenderGlyph_Solid)(l);
	loadFunc!(TTF_RenderText_Shaded)(l);
	loadFunc!(TTF_RenderUTF8_Shaded)(l);
	loadFunc!(TTF_RenderUNICODE_Shaded)(l);
	loadFunc!(TTF_RenderGlyph_Shaded)(l);
	loadFunc!(TTF_RenderText_Blended)(l);
	loadFunc!(TTF_RenderUTF8_Blended)(l);
	loadFunc!(TTF_RenderUNICODE_Blended)(l);
	loadFunc!(TTF_RenderGlyph_Blended)(l);
	loadFunc!(TTF_CloseFont)(l);
	loadFunc!(TTF_Quit)(l);
	loadFunc!(TTF_WasInit)(l);
}

extern(C):

int (*TTF_Init)();
TTF_Font* (*TTF_OpenFont)(char *file, int ptsize);
TTF_Font* (*TTF_OpenFontIndex)(char *file, int ptsize, long index);
TTF_Font* (*TTF_OpenFontRW)(SDL_RWops *src, int freesrc, int ptsize);
TTF_Font* (*TTF_OpenFontIndexRW)(SDL_RWops *src, int freesrc, int ptsize, long index);
void* (*TTF_Linked_Version)();
void (*TTF_ByteSwappedUNICODE)(int swapped);
int (*TTF_GetFontStyle)(TTF_Font *font);
void (*TTF_SetFontStyle)(TTF_Font *font, int style);
int (*TTF_FontHeight)(TTF_Font *font);
int (*TTF_FontAscent)(TTF_Font *font);
int (*TTF_FontDescent)(TTF_Font *font);
int (*TTF_FontLineSkip)(TTF_Font *font);
long (*TTF_FontFaces)(TTF_Font *font);
int (*TTF_FontFaceIsFixedWidth)(TTF_Font *font);
char* (*TTF_FontFaceFamilyName)(TTF_Font *font);
char* (*TTF_FontFaceStyleName)(TTF_Font *font);
int (*TTF_GlyphMetrics)(TTF_Font *font, Uint16 ch, int *minx, int *maxx, int *miny, int *maxy, int *advance);
int (*TTF_SizeText)(TTF_Font *font, char *text, int *w, int *h);
int (*TTF_SizeUTF8)(TTF_Font *font, char *text, int *w, int *h);
int (*TTF_SizeUNICODE)(TTF_Font *font, Uint16 *text, int *w, int *h);
SDL_Surface* (*TTF_RenderText_Solid)(TTF_Font *font, char *text, SDL_Color fg);
SDL_Surface* (*TTF_RenderUTF8_Solid)(TTF_Font *font, char *text, SDL_Color fg);
SDL_Surface* (*TTF_RenderUNICODE_Solid)(TTF_Font *font, Uint16 *text, SDL_Color fg);
SDL_Surface* (*TTF_RenderGlyph_Solid)(TTF_Font *font, Uint16 ch, SDL_Color fg);
SDL_Surface* (*TTF_RenderText_Shaded)(TTF_Font *font, char *text, SDL_Color fg, SDL_Color bg);
SDL_Surface* (*TTF_RenderUTF8_Shaded)(TTF_Font *font, char *text, SDL_Color fg, SDL_Color bg);
SDL_Surface* (*TTF_RenderUNICODE_Shaded)(TTF_Font *font, Uint16 *text, SDL_Color fg, SDL_Color bg);
SDL_Surface* (*TTF_RenderGlyph_Shaded)(TTF_Font *font, Uint16 ch, SDL_Color fg, SDL_Color bg);
SDL_Surface* (*TTF_RenderText_Blended)(TTF_Font *font, char *text, SDL_Color fg);
SDL_Surface* (*TTF_RenderUTF8_Blended)(TTF_Font *font, char *text, SDL_Color fg);
SDL_Surface* (*TTF_RenderUNICODE_Blended)(TTF_Font *font, Uint16 *text, SDL_Color fg);
SDL_Surface* (*TTF_RenderGlyph_Blended)(TTF_Font *font, Uint16 ch, SDL_Color fg);
void (*TTF_CloseFont)(TTF_Font *font);
void (*TTF_Quit)();
int (*TTF_WasInit)();

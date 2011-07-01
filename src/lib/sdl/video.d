// This file is a hand mangled header file from SDL.
// See copyright in src/lib/sdl/sdl.d (LGPLv2+).
module lib.sdl.video;

import lib.sdl.types;
import lib.sdl.rwops;

const SDL_ALPHA_OPAQUE      = 255;
const SDL_ALPHA_TRANSPARENT = 0;

struct SDL_Rect {
	Sint16 x, y;
	Uint16 w, h;
}

struct SDL_Color
{
	Uint8 r;
	Uint8 g;
	Uint8 b;
	Uint8 unused;
}
alias SDL_Color SDL_Colour;

struct SDL_Palette
{
	int       ncolors;
	SDL_Color *colors;
}

struct SDL_PixelFormat
{
	SDL_Palette *palette;
	Uint8  BitsPerPixel;
	Uint8  BytesPerPixel;
	Uint8  Rloss;
	Uint8  Gloss;
	Uint8  Bloss;
	Uint8  Aloss;
	Uint8  Rshift;
	Uint8  Gshift;
	Uint8  Bshift;
	Uint8  Ashift;
	Uint32 Rmask;
	Uint32 Gmask;
	Uint32 Bmask;
	Uint32 Amask;
	Uint32 colorkey;
	Uint8  alpha;
}

struct SDL_Surface
{
	Uint32 flags;
	SDL_PixelFormat *format;
	int w, h;
	Uint16 pitch;
	void *pixels;
	int offset;
	void *hwdata;
	SDL_Rect clip_rect;
	Uint32 unused1;
	Uint32 locked;
	void *map;
	uint format_version;
	int refcount;
}

const SDL_SWSURFACE   = 0x00000000;
const SDL_HWSURFACE   = 0x00000001;
const SDL_ASYNCBLIT   = 0x00000004;

const SDL_ANYFORMAT   = 0x10000000;
const SDL_HWPALETTE   = 0x20000000;
const SDL_DOUBLEBUF   = 0x40000000;
const SDL_FULLSCREEN  = 0x80000000;
const SDL_OPENGL      = 0x00000002;
const SDL_OPENGLBLIT  = 0x0000000A;
const SDL_RESIZABLE   = 0x00000010;
const SDL_NOFRAME     = 0x00000020;

const SDL_HWACCEL     = 0x00000100;
const SDL_SRCCOLORKEY = 0x00001000;
const SDL_RLEACCELOK  = 0x00002000;
const SDL_RLEACCEL    = 0x00004000;
const SDL_SRCALPHA    = 0x00010000;
const SDL_PREALLOC    = 0x01000000;

//SDL_MUSTLOCK(surface) (surface->offset || ((surface->flags & (SDL_HWSURFACE|SDL_ASYNCBLIT|SDL_RLEACCEL)) != 0))

struct SDL_VideoInfo
{
	Uint32 flags;
	Uint32 video_mem;
	SDL_PixelFormat *vfmt;
	int current_w;
	int current_h;
}

const SDL_YV12_OVERLAY = 0x32315659;
const SDL_IYUV_OVERLAY = 0x56555949;
const SDL_YUY2_OVERLAY = 0x32595559;
const SDL_UYVY_OVERLAY = 0x59565955;
const SDL_YVYU_OVERLAY = 0x55595659;

struct SDL_Overlay
{
	Uint32 format;
	int w, h;
	int planes;
	Uint16 *pitches;
	Uint8 **pixels;

	void *hwfuncs;
	void *hwdata;

	Uint32 flags;
}

enum
{
    SDL_GL_RED_SIZE,
    SDL_GL_GREEN_SIZE,
    SDL_GL_BLUE_SIZE,
    SDL_GL_ALPHA_SIZE,
    SDL_GL_BUFFER_SIZE,
    SDL_GL_DOUBLEBUFFER,
    SDL_GL_DEPTH_SIZE,
    SDL_GL_STENCIL_SIZE,
    SDL_GL_ACCUM_RED_SIZE,
    SDL_GL_ACCUM_GREEN_SIZE,
    SDL_GL_ACCUM_BLUE_SIZE,
    SDL_GL_ACCUM_ALPHA_SIZE,
    SDL_GL_STEREO,
    SDL_GL_MULTISAMPLEBUFFERS,
    SDL_GL_MULTISAMPLESAMPLES,
    SDL_GL_ACCELERATED_VISUAL,
    SDL_GL_SWAP_CONTROL
}

const SDL_LOGPAL = 0x01;
const SDL_PHYSPAL = 0x02;

enum SDL_GrabMode
{
	SDL_GRAB_QUERY = -1,
	SDL_GRAB_OFF = 0,
	SDL_GRAB_ON = 1,
	SDL_GRAB_FULLSCREEN
}

typedef extern(C) int function(SDL_Surface *src, SDL_Rect *srcrect, SDL_Surface *dst, SDL_Rect *dstrect) SDL_blit;

version (DynamicSDL)
{
import lib.loader;

package void loadSDL_Video(Loader l)
{
	loadFunc!(SDL_VideoInit)(l);
	loadFunc!(SDL_VideoQuit)(l);
	loadFunc!(SDL_VideoDriverName)(l);
	loadFunc!(SDL_GetVideoSurface)(l);
	loadFunc!(SDL_GetVideoInfo)(l);
	loadFunc!(SDL_VideoModeOK)(l);
	loadFunc!(SDL_ListModes)(l);
	loadFunc!(SDL_SetVideoMode)(l);
	loadFunc!(SDL_UpdateRects)(l);
	loadFunc!(SDL_UpdateRect)(l);
	loadFunc!(SDL_Flip)(l);
	loadFunc!(SDL_SetGamma)(l);
	loadFunc!(SDL_SetGammaRamp)(l);
	loadFunc!(SDL_GetGammaRamp)(l);
	loadFunc!(SDL_SetColors)(l);
	loadFunc!(SDL_SetPalette)(l);
	loadFunc!(SDL_MapRGB)(l);
	loadFunc!(SDL_MapRGBA)(l);
	loadFunc!(SDL_GetRGB)(l);
	loadFunc!(SDL_GetRGBA)(l);
	loadFunc!(SDL_CreateRGBSurface)(l);
	loadFunc!(SDL_CreateRGBSurfaceFrom)(l);
	loadFunc!(SDL_FreeSurface)(l);
	loadFunc!(SDL_LockSurface)(l);
	loadFunc!(SDL_UnlockSurface)(l);
	loadFunc!(SDL_SaveBMP_RW)(l);
	loadFunc!(SDL_SetColorKey)(l);
	loadFunc!(SDL_SetAlpha)(l);
	loadFunc!(SDL_SetClipRect)(l);
	loadFunc!(SDL_GetClipRect)(l);
	loadFunc!(SDL_ConvertSurface)(l);
	loadFunc!(SDL_UpperBlit)(l);
	loadFunc!(SDL_LowerBlit)(l);
	loadFunc!(SDL_FillRect)(l);
	loadFunc!(SDL_DisplayFormat)(l);
	loadFunc!(SDL_DisplayFormatAlpha)(l);
	loadFunc!(SDL_CreateYUVOverlay)(l);
	loadFunc!(SDL_LockYUVOverlay)(l);
	loadFunc!(SDL_UnlockYUVOverlay)(l);
	loadFunc!(SDL_DisplayYUVOverlay)(l);
	loadFunc!(SDL_FreeYUVOverlay)(l);
	loadFunc!(SDL_GL_LoadLibrary)(l);
	loadFunc!(SDL_GL_GetProcAddress)(l);
	loadFunc!(SDL_GL_SetAttribute)(l);
	loadFunc!(SDL_GL_GetAttribute)(l);
	loadFunc!(SDL_GL_SwapBuffers)(l);
	loadFunc!(SDL_GL_UpdateRects)(l);
	loadFunc!(SDL_GL_Lock)(l);
	loadFunc!(SDL_GL_Unlock)(l);
	loadFunc!(SDL_WM_SetCaption)(l);
	loadFunc!(SDL_WM_GetCaption)(l);
	loadFunc!(SDL_WM_SetIcon)(l);
	loadFunc!(SDL_WM_IconifyWindow)(l);
	loadFunc!(SDL_WM_ToggleFullScreen)(l);
	loadFunc!(SDL_WM_GrabInput)(l);
	loadFunc!(SDL_SoftStretch)(l);
}

extern(C):
int (*SDL_VideoInit)(char *driver_name, Uint32 flags);
void (*SDL_VideoQuit)();
char * (*SDL_VideoDriverName)(char *namebuf, int maxlen);
SDL_Surface * (*SDL_GetVideoSurface)();
SDL_VideoInfo * (*SDL_GetVideoInfo)();
int (*SDL_VideoModeOK)(int width, int height, int bpp, Uint32 flags);
SDL_Rect ** (*SDL_ListModes)(SDL_PixelFormat *format, Uint32 flags);
SDL_Surface * (*SDL_SetVideoMode)(int width, int height, int bpp, Uint32 flags);
void (*SDL_UpdateRects)(SDL_Surface *screen, int numrects, SDL_Rect *rects);
void (*SDL_UpdateRect)(SDL_Surface *screen, Sint32 x, Sint32 y, Uint32 w, Uint32 h);
int (*SDL_Flip)(SDL_Surface *screen);
int (*SDL_SetGamma)(float red, float green, float blue);
int (*SDL_SetGammaRamp)(Uint16 *red, Uint16 *green, Uint16 *blue);
int (*SDL_GetGammaRamp)(Uint16 *red, Uint16 *green, Uint16 *blue);
int (*SDL_SetColors)(SDL_Surface *surface, SDL_Color *colors, int firstcolor, int ncolors);
int (*SDL_SetPalette)(SDL_Surface *surface, int flags, SDL_Color *colors, int firstcolor, int ncolors);
Uint32 (*SDL_MapRGB)(SDL_PixelFormat *format, Uint8 r, Uint8 g, Uint8 b);
Uint32 (*SDL_MapRGBA)(SDL_PixelFormat *format, Uint8 r, Uint8 g, Uint8 b, Uint8 a);
void (*SDL_GetRGB)(Uint32 pixel, SDL_PixelFormat *fmt, Uint8 *r, Uint8 *g, Uint8 *b);
void (*SDL_GetRGBA)(Uint32 pixel, SDL_PixelFormat *fmt, Uint8 *r, Uint8 *g, Uint8 *b, Uint8 *a);
SDL_Surface * (*SDL_CreateRGBSurface)(Uint32 flags, int width, int height, int depth, Uint32 Rmask, Uint32 Gmask, Uint32 Bmask, Uint32 Amask);
SDL_Surface * (*SDL_CreateRGBSurfaceFrom)(void *pixels, int width, int height, int depth, int pitch, Uint32 Rmask, Uint32 Gmask, Uint32 Bmask, Uint32 Amask);
alias SDL_CreateRGBSurface SDL_AllocSurface;
void (*SDL_FreeSurface)(SDL_Surface *surface);
int (*SDL_LockSurface)(SDL_Surface *surface);
void (*SDL_UnlockSurface)(SDL_Surface *surface);
int (*SDL_SaveBMP_RW)(SDL_Surface* surface, SDL_RWops*   dst, int freedst);
int SDL_SaveBMP(SDL_Surface *surface, char *file) { return SDL_SaveBMP_RW(surface, SDL_RWFromFile(file, "wb"), 1); }
int (*SDL_SetColorKey)(SDL_Surface *surface, Uint32 flag, Uint32 key);
int (*SDL_SetAlpha)(SDL_Surface *surface, Uint32 flag, Uint8 alpha);
SDL_bool (*SDL_SetClipRect)(SDL_Surface *surface, SDL_Rect *rect);
void (*SDL_GetClipRect)(SDL_Surface *surface, SDL_Rect *rect);
SDL_Surface * (*SDL_ConvertSurface)(SDL_Surface *src, SDL_PixelFormat *fmt, Uint32 flags);
int (*SDL_UpperBlit)(SDL_Surface *src, SDL_Rect *srcrect, SDL_Surface *dst, SDL_Rect *dstrect);
alias SDL_UpperBlit SDL_BlitSurface;
int (*SDL_LowerBlit)(SDL_Surface *src, SDL_Rect *srcrect, SDL_Surface *dst, SDL_Rect *dstrect);
int (*SDL_FillRect)(SDL_Surface *dst, SDL_Rect *dstrect, Uint32 color);
SDL_Surface * (*SDL_DisplayFormat)(SDL_Surface *surface);
SDL_Surface * (*SDL_DisplayFormatAlpha)(SDL_Surface *surface);
SDL_Overlay * (*SDL_CreateYUVOverlay)(int width, int height, Uint32 format, SDL_Surface *display);
int (*SDL_LockYUVOverlay)(SDL_Overlay *overlay);
void (*SDL_UnlockYUVOverlay)(SDL_Overlay *overlay);
int (*SDL_DisplayYUVOverlay)(SDL_Overlay *overlay, SDL_Rect *dstrect);
void (*SDL_FreeYUVOverlay)(SDL_Overlay *overlay);
int (*SDL_GL_LoadLibrary)(char *path);
void * (*SDL_GL_GetProcAddress)(char* proc);
int (*SDL_GL_SetAttribute)(int attr, int value);
int (*SDL_GL_GetAttribute)(int attr, int* value);
void (*SDL_GL_SwapBuffers)();
void (*SDL_GL_UpdateRects)(int numrects, SDL_Rect* rects);
void (*SDL_GL_Lock)();
void (*SDL_GL_Unlock)();
void (*SDL_WM_SetCaption)(char *title, char *icon);
void (*SDL_WM_GetCaption)(char **title, char **icon);
void (*SDL_WM_SetIcon)(SDL_Surface *icon, Uint8 *mask);
int (*SDL_WM_IconifyWindow)();
int (*SDL_WM_ToggleFullScreen)(SDL_Surface *surface);
SDL_GrabMode (*SDL_WM_GrabInput)(SDL_GrabMode mode);
int (*SDL_SoftStretch)(SDL_Surface *src, SDL_Rect *srcrect, SDL_Surface *dst, SDL_Rect *dstrect);
}
else
{
extern (C):
int SDL_VideoInit(char *driver_name, Uint32 flags);
void SDL_VideoQuit();
char * SDL_VideoDriverName(char *namebuf, int maxlen);
SDL_Surface * SDL_GetVideoSurface();
SDL_VideoInfo * SDL_GetVideoInfo();
int SDL_VideoModeOK(int width, int height, int bpp, Uint32 flags);
SDL_Rect ** SDL_ListModes(SDL_PixelFormat *format, Uint32 flags);
SDL_Surface * SDL_SetVideoMode(int width, int height, int bpp, Uint32 flags);
void SDL_UpdateRects(SDL_Surface *screen, int numrects, SDL_Rect *rects);
void SDL_UpdateRect(SDL_Surface *screen, Sint32 x, Sint32 y, Uint32 w, Uint32 h);
int SDL_Flip(SDL_Surface *screen);
int SDL_SetGamma(float red, float green, float blue);
int SDL_SetGammaRamp(Uint16 *red, Uint16 *green, Uint16 *blue);
int SDL_GetGammaRamp(Uint16 *red, Uint16 *green, Uint16 *blue);
int SDL_SetColors(SDL_Surface *surface, SDL_Color *colors, int firstcolor, int ncolors);
int SDL_SetPalette(SDL_Surface *surface, int flags, SDL_Color *colors, int firstcolor, int ncolors);
Uint32 SDL_MapRGB(SDL_PixelFormat *format, Uint8 r, Uint8 g, Uint8 b);
Uint32 SDL_MapRGBA(SDL_PixelFormat *format, Uint8 r, Uint8 g, Uint8 b, Uint8 a);
void SDL_GetRGB(Uint32 pixel, SDL_PixelFormat *fmt, Uint8 *r, Uint8 *g, Uint8 *b);
void SDL_GetRGBA(Uint32 pixel, SDL_PixelFormat *fmt, Uint8 *r, Uint8 *g, Uint8 *b, Uint8 *a);
SDL_Surface * SDL_CreateRGBSurface(Uint32 flags, int width, int height, int depth, Uint32 Rmask, Uint32 Gmask, Uint32 Bmask, Uint32 Amask);
SDL_Surface * SDL_CreateRGBSurfaceFrom(void *pixels, int width, int height, int depth, int pitch, Uint32 Rmask, Uint32 Gmask, Uint32 Bmask, Uint32 Amask);
alias SDL_CreateRGBSurface SDL_AllocSurface;
void SDL_FreeSurface(SDL_Surface *surface);
int SDL_LockSurface(SDL_Surface *surface);
void SDL_UnlockSurface(SDL_Surface *surface);
int SDL_SaveBMP_RW(SDL_Surface* surface, SDL_RWops*   dst, int freedst);
int SDL_SaveBMP(SDL_Surface *surface, char *file) { return SDL_SaveBMP_RW(surface, SDL_RWFromFile(file, "wb"), 1); }
int SDL_SetColorKey(SDL_Surface *surface, Uint32 flag, Uint32 key);
int SDL_SetAlpha(SDL_Surface *surface, Uint32 flag, Uint8 alpha);
SDL_bool SDL_SetClipRect(SDL_Surface *surface, SDL_Rect *rect);
void SDL_GetClipRect(SDL_Surface *surface, SDL_Rect *rect);
SDL_Surface * SDL_ConvertSurface(SDL_Surface *src, SDL_PixelFormat *fmt, Uint32 flags);
int SDL_UpperBlit(SDL_Surface *src, SDL_Rect *srcrect, SDL_Surface *dst, SDL_Rect *dstrect);
alias SDL_UpperBlit SDL_BlitSurface;
int SDL_LowerBlit(SDL_Surface *src, SDL_Rect *srcrect, SDL_Surface *dst, SDL_Rect *dstrect);
int SDL_FillRect(SDL_Surface *dst, SDL_Rect *dstrect, Uint32 color);
SDL_Surface * SDL_DisplayFormat(SDL_Surface *surface);
SDL_Surface * SDL_DisplayFormatAlpha(SDL_Surface *surface);
SDL_Overlay * SDL_CreateYUVOverlay(int width, int height, Uint32 format, SDL_Surface *display);
int SDL_LockYUVOverlay(SDL_Overlay *overlay);
void SDL_UnlockYUVOverlay(SDL_Overlay *overlay);
int SDL_DisplayYUVOverlay(SDL_Overlay *overlay, SDL_Rect *dstrect);
void SDL_FreeYUVOverlay(SDL_Overlay *overlay);
int SDL_GL_LoadLibrary(char *path);
void * SDL_GL_GetProcAddress(char* proc);
int SDL_GL_SetAttribute(int attr, int value);
int SDL_GL_GetAttribute(int attr, int* value);
void SDL_GL_SwapBuffers();
void SDL_GL_UpdateRects(int numrects, SDL_Rect* rects);
void SDL_GL_Lock();
void SDL_GL_Unlock();
void SDL_WM_SetCaption(char *title, char *icon);
void SDL_WM_GetCaption(char **title, char **icon);
void SDL_WM_SetIcon(SDL_Surface *icon, Uint8 *mask);
int SDL_WM_IconifyWindow();
int SDL_WM_ToggleFullScreen(SDL_Surface *surface);
SDL_GrabMode SDL_WM_GrabInput(SDL_GrabMode mode);
int SDL_SoftStretch(SDL_Surface *src, SDL_Rect *srcrect, SDL_Surface *dst, SDL_Rect *dstrect);
}

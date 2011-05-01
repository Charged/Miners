// This file is a hand mangled header file from SDL.
// See copyright in src/lib/sdl/sdl.d (LGPLv2+).
module lib.sdl.image;

import lib.loader;
import lib.sdl.sdl;

const SDL_IMAGE_MAJOR_VERSION = 1;
const SDL_IMAGE_MINOR_VERSION = 2;
const SDL_IMAGE_PATCHLEVEL    = 6;

void loadSDLImage(Loader l)
{
//	loadFunc!(IMG_Linked_Version)(l);
	loadFunc!(IMG_LoadTyped_RW)(l);
	loadFunc!(IMG_Load)(l);
	loadFunc!(IMG_Load_RW)(l);
//	loadFunc!(IMG_InvertAlpha)(l); no longer supported
	loadFunc!(IMG_isBMP)(l);
	loadFunc!(IMG_isPNM)(l);
	loadFunc!(IMG_isXPM)(l);
	loadFunc!(IMG_isXCF)(l);
	loadFunc!(IMG_isPCX)(l);
	loadFunc!(IMG_isGIF)(l);
	loadFunc!(IMG_isJPG)(l);
	loadFunc!(IMG_isTIF)(l);
	loadFunc!(IMG_isPNG)(l);
	loadFunc!(IMG_isLBM)(l);
	loadFunc!(IMG_LoadBMP_RW)(l);
	loadFunc!(IMG_LoadPNM_RW)(l);
	loadFunc!(IMG_LoadXPM_RW)(l);
	loadFunc!(IMG_LoadXCF_RW)(l);
	loadFunc!(IMG_LoadPCX_RW)(l);
	loadFunc!(IMG_LoadGIF_RW)(l);
	loadFunc!(IMG_LoadJPG_RW)(l);
	loadFunc!(IMG_LoadTIF_RW)(l);
	loadFunc!(IMG_LoadPNG_RW)(l);
	loadFunc!(IMG_LoadLBM_RW)(l);
	loadFunc!(IMG_ReadXPMFromArray)(l);
}

extern(C):

//SDL_version* (*IMG_Linked_Version)(void);
SDL_Surface* (*IMG_LoadTyped_RW)(SDL_RWops *src, int freesrc, char *type);
SDL_Surface* (*IMG_Load)(char* file);
SDL_Surface* (*IMG_Load_RW)(SDL_RWops *src, int freesrc);
//int (*IMG_InvertAlpha)(int on);
int (*IMG_isBMP)(SDL_RWops *src);
int (*IMG_isGIF)(SDL_RWops *src);
int (*IMG_isJPG)(SDL_RWops *src);
int (*IMG_isLBM)(SDL_RWops *src);
int (*IMG_isPCX)(SDL_RWops *src);
int (*IMG_isPNG)(SDL_RWops *src);
int (*IMG_isPNM)(SDL_RWops *src);
int (*IMG_isTIF)(SDL_RWops *src);
int (*IMG_isXCF)(SDL_RWops *src);
int (*IMG_isXPM)(SDL_RWops *src);
int (*IMG_isXV)(SDL_RWops *src);
SDL_Surface* (*IMG_LoadBMP_RW)(SDL_RWops *src);
SDL_Surface* (*IMG_LoadGIF_RW)(SDL_RWops *src);
SDL_Surface* (*IMG_LoadJPG_RW)(SDL_RWops *src);
SDL_Surface* (*IMG_LoadLBM_RW)(SDL_RWops *src);
SDL_Surface* (*IMG_LoadPCX_RW)(SDL_RWops *src);
SDL_Surface* (*IMG_LoadPNG_RW)(SDL_RWops *src);
SDL_Surface* (*IMG_LoadPNM_RW)(SDL_RWops *src);
SDL_Surface* (*IMG_LoadTGA_RW)(SDL_RWops *src);
SDL_Surface* (*IMG_LoadTIF_RW)(SDL_RWops *src);
SDL_Surface* (*IMG_LoadXCF_RW)(SDL_RWops *src);
SDL_Surface* (*IMG_LoadXPM_RW)(SDL_RWops *src);
SDL_Surface* (*IMG_LoadXV_RW)(SDL_RWops *src);
SDL_Surface* (*IMG_ReadXPMFromArray)(char **xpm);

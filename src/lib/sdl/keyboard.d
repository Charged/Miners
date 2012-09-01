// This file is a hand mangled header file from SDL.
// See copyright in src/lib/sdl/sdl.d (LGPLv2+).
module lib.sdl.keyboard;

import lib.sdl.types;
import lib.sdl.keysym;


struct SDL_keysym
{
    Uint8 scancode;
    SDLKey sym;
    SDLMod mod;
    Uint16 unicode;
}

const SDL_ALL_HOTKEYS             = 0xFFFFFFFF;
const SDL_DEFAULT_REPEAT_DELAY    = 500;
const SDL_DEFAULT_REPEAT_INTERVAL = 30;

version (DynamicSDL)
{
extern (C):
int function(int) SDL_EnableUNICODE;
int function(int,int) SDL_EnableKeyRepeat;
void function(int*,int*) SDL_GetKeyRepeat;
Uint8* function(int*) SDL_GetKeyState;
SDLMod function() SDL_GetModState;
void function(SDLMod) SDL_SetModState;
char* function(SDLKey key) SDL_GetKeyName;
}
else
{
extern (C):
int SDL_EnableUNICODE(int);
int SDL_EnableKeyRepeat(int,int);
void SDL_GetKeyRepeat(int*,int*);
Uint8* SDL_GetKeyState(int*);
SDLMod SDL_GetModState();
void SDL_SetModState(SDLMod);
char* SDL_GetKeyName(SDLKey key);
}

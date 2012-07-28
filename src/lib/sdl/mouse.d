// This file is a hand mangled header file from SDL.
// See copyright in src/lib/sdl/sdl.d (LGPLv2+).
module lib.sdl.mouse;

import lib.sdl.types;


version (DynamicSDL)
{
extern (C):
int (*SDL_ShowCursor)(int toggle);
void (*SDL_WarpMouse)(Uint16 x, Uint16 y);
}
else
{
extern (C):
int SDL_ShowCursor(int toggle);
void SDL_WarpMouse(Uint16 x, Uint16 y);
}

// This file is a hand mangled header file from SDL.
// See copyright in src/lib/sdl/sdl.d (LGPLv2+).
module lib.sdl.mouse;

import lib.sdl.types;

version (DynamicSDL)
{
import lib.loader;

package void loadSDL_Mouse(Loader l)
{
	loadFunc!(SDL_ShowCursor)(l);
	loadFunc!(SDL_WarpMouse)(l);
}
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

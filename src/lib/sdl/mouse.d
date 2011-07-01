// This file is a hand mangled header file from SDL.
// See copyright in src/lib/sdl/sdl.d (LGPLv2+).
module lib.sdl.mouse;

version (DynamicSDL)
{
import lib.loader;

package void loadSDL_Mouse(Loader l)
{
	loadFunc!(SDL_ShowCursor)(l);
}
extern (C):

int (*SDL_ShowCursor)(int toggle);
}
else
{
extern (C):

int SDL_ShowCursor(int toggle);
}

// This file is a hand mangled header file from SDL.
// See copyright in src/lib/sdl/sdl.d (LGPLv2+).
module lib.sdl.timer;

import lib.sdl.types;

enum : Uint32
{
	SDL_TIMESLICE  = 10,
	SDL_RESOLUTION = 10,
}

alias void* SDL_TimerID;

typedef extern(C) Uint32 function(Uint32) SDL_TimerCallback;
typedef extern(C) Uint32 function(Uint32,void*) SDL_NewTimerCallback;

version (DynamicSDL)
{
import lib.loader;

package void loadSDL_Timer(Loader l)
{

	loadFunc!(SDL_GetTicks)(l);
	loadFunc!(SDL_Delay)(l);
	loadFunc!(SDL_SetTimer)(l);
	loadFunc!(SDL_AddTimer)(l);
	loadFunc!(SDL_RemoveTimer)(l);
}

extern(C):
Uint32 (*SDL_GetTicks)();
void (*SDL_Delay)(Uint32);
int (*SDL_SetTimer)(Uint32,SDL_TimerCallback);
SDL_TimerID (*SDL_AddTimer)(Uint32,SDL_NewTimerCallback,void*);
SDL_bool (*SDL_RemoveTimer)(SDL_TimerID);
}
else
{
extern(C):
Uint32 SDL_GetTicks();
void SDL_Delay(Uint32);
int SDL_SetTimer(Uint32,SDL_TimerCallback);
SDL_TimerID SDL_AddTimer(Uint32,SDL_NewTimerCallback,void*);
SDL_bool SDL_RemoveTimer(SDL_TimerID);
}

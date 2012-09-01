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

alias extern(C) Uint32 function(Uint32) SDL_TimerCallback;
alias extern(C) Uint32 function(Uint32,void*) SDL_NewTimerCallback;

version (DynamicSDL)
{
extern(C):
Uint32 function() SDL_GetTicks;
void function(Uint32) SDL_Delay;
int function(Uint32,SDL_TimerCallback) SDL_SetTimer;
SDL_TimerID function(Uint32,SDL_NewTimerCallback,void*) SDL_AddTimer;
SDL_bool function(SDL_TimerID) SDL_RemoveTimer;
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

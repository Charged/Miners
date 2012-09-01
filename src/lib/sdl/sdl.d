// This file is hand written.
// See copyright at the bottom of this file.
module lib.sdl.sdl;

public {
	import lib.sdl.types;
	import lib.sdl.rwops;
	import lib.sdl.audio;
	import lib.sdl.video;
	import lib.sdl.event;
	import lib.sdl.keyboard;
	import lib.sdl.keysym;
	import lib.sdl.timer;
	import lib.sdl.mouse;
	import lib.sdl.joystick;
}


const SDL_INIT_TIMER       = 0x00000001;
const SDL_INIT_AUDIO       = 0x00000010;
const SDL_INIT_VIDEO       = 0x00000020;
const SDL_INIT_CDROM       = 0x00000100;
const SDL_INIT_JOYSTICK    = 0x00000200;
const SDL_INIT_NOPARACHUTE = 0x00100000;
const SDL_INIT_EVENTTHREAD = 0x01000000;
const SDL_INIT_EVERYTHING  = 0x0000FFFF;

version (DynamicSDL)
{
extern (C):
int (*SDL_Init)(Uint32 flags);
int (*SDL_InitSubSystem)(Uint32 flags);
void (*SDL_QuitSubSystem)(Uint32 flags);
Uint32 (*SDL_WasInit)(Uint32 flags);
void (*SDL_Quit)();
}
else
{
extern (C):
int SDL_Init(Uint32 flags);
int SDL_InitSubSystem(Uint32 flags);
void SDL_QuitSubSystem(Uint32 flags);
Uint32 SDL_WasInit(Uint32 flags);
void SDL_Quit();
}


char[] licenseText = `
SDL - Simple DirectMedia Layer
Copyright (C) 1997-2009 Sam Lantinga

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

Sam Lantinga
slouken@libsdl.org
`;


import license;

static this()
{
	licenseArray ~= licenseText;
}

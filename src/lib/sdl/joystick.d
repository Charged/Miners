// This file is a hand mangled header file from SDL.
// See copyright in src/lib/sdl/sdl.d (LGPLv2+).
module lib.sdl.joystick;

import lib.sdl.types;


alias void* SDL_Joystick;

const SDL_HAT_CENTERED =	0x00;
const SDL_HAT_UP =		0x01;
const SDL_HAT_RIGHT =		0x02;
const SDL_HAT_DOWN =		0x04;
const SDL_HAT_LEFT =		0x08;
const SDL_HAT_RIGHTUP =		(SDL_HAT_RIGHT|SDL_HAT_UP);
const SDL_HAT_RIGHTDOWN =	(SDL_HAT_RIGHT|SDL_HAT_DOWN);
const SDL_HAT_LEFTUP =		(SDL_HAT_LEFT|SDL_HAT_UP);
const SDL_HAT_LEFTDOWN =	(SDL_HAT_LEFT|SDL_HAT_DOWN);

version (DynamicSDL)
{
extern(C):
int (*SDL_NumJoysticks)();
char* (*SDL_JoystickName)(int device_index);
SDL_Joystick* (*SDL_JoystickOpen)(int device_index);
int (*SDL_JoystickOpened)(int device_index);
int (*SDL_JoystickIndex)(SDL_Joystick *joystick);
int (*SDL_JoystickNumAxes)(SDL_Joystick *joystick);
int (*SDL_JoystickNumBalls)(SDL_Joystick *joystick);
int (*SDL_JoystickNumHats)(SDL_Joystick *joystick);
int (*SDL_JoystickNumButtons)(SDL_Joystick *joystick);
void (*SDL_JoystickUpdate)();
int (*SDL_JoystickEventState)(int state);
Sint16 (*SDL_JoystickGetAxis)(SDL_Joystick *joystick, int axis);
Uint8 (*SDL_JoystickGetHat)(SDL_Joystick *joystick, int hat);
int (*SDL_JoystickGetBall)(SDL_Joystick *joystick, int ball, int *dx, int *dy);
Uint8 (*SDL_JoystickGetButton)(SDL_Joystick *joystick, int button);
void (*SDL_JoystickClose)(SDL_Joystick *joystick);
}
else
{
extern(C):
int SDL_NumJoysticks();
char* SDL_JoystickName(int device_index);
SDL_Joystick * SDL_JoystickOpen(int device_index);
int SDL_JoystickOpened(int device_index);
int SDL_JoystickIndex(SDL_Joystick *joystick);
int SDL_JoystickNumAxes(SDL_Joystick *joystick);
int SDL_JoystickNumBalls(SDL_Joystick *joystick);
int SDL_JoystickNumHats(SDL_Joystick *joystick);
int SDL_JoystickNumButtons(SDL_Joystick *joystick);
void SDL_JoystickUpdate();
int SDL_JoystickEventState(int state);
Sint16 SDL_JoystickGetAxis(SDL_Joystick *joystick, int axis);
Uint8 SDL_JoystickGetHat(SDL_Joystick *joystick, int hat);
int SDL_JoystickGetBall(SDL_Joystick *joystick, int ball, int *dx, int *dy);
Uint8 SDL_JoystickGetButton(SDL_Joystick *joystick, int button);
void SDL_JoystickClose(SDL_Joystick *joystick);
}

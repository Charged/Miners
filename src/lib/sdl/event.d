// This file is a hand mangled header file from SDL.
// See copyright in src/lib/sdl/sdl.d (LGPLv2+).
module lib.sdl.event;

import lib.sdl.types;
import lib.sdl.keyboard;


const SDL_RELEASED = 0;
const SDL_PRESSED  = 1;

enum
{
	SDL_NOEVENT = 0,
	SDL_ACTIVEEVENT,
	SDL_KEYDOWN,
	SDL_KEYUP,
	SDL_MOUSEMOTION,
	SDL_MOUSEBUTTONDOWN,
	SDL_MOUSEBUTTONUP,
	SDL_JOYAXISMOTION,
	SDL_JOYBALLMOTION,
	SDL_JOYHATMOTION,
	SDL_JOYBUTTONDOWN,
	SDL_JOYBUTTONUP,
	SDL_QUIT,
	SDL_SYSWMEVENT,
	SDL_EVENT_RESERVEDA,
	SDL_EVENT_RESERVEDB,
	SDL_VIDEORESIZE,
	SDL_VIDEOEXPOSE,
	SDL_EVENT_RESERVED2,
	SDL_EVENT_RESERVED3,
	SDL_EVENT_RESERVED4,
	SDL_EVENT_RESERVED5,
	SDL_EVENT_RESERVED6,
	SDL_EVENT_RESERVED7,
	SDL_USEREVENT = 24,
	SDL_NUMEVENTS = 32
}

const SDL_ACTIVEEVENTMASK     = 1 << SDL_ACTIVEEVENT;
const SDL_KEYDOWNMASK         = 1 << SDL_KEYDOWN;
const SDL_KEYUPMASK           = 1 << SDL_KEYUP;
const SDL_KEYEVENTMASK        = (1 << SDL_KEYDOWN)|
                                (1 << SDL_KEYUP);
const SDL_MOUSEMOTIONMASK     = 1 << SDL_MOUSEMOTION;
const SDL_MOUSEBUTTONDOWNMASK = 1 << SDL_MOUSEBUTTONDOWN;
const SDL_MOUSEBUTTONUPMASK   = 1 << SDL_MOUSEBUTTONUP;
const SDL_MOUSEEVENTMASK      = (1 << SDL_MOUSEMOTION)|
                                (1 << SDL_MOUSEBUTTONDOWN)|
                                (1 << SDL_MOUSEBUTTONUP);
const SDL_JOYAXISMOTIONMASK   = 1 << SDL_JOYAXISMOTION;
const SDL_JOYBALLMOTIONMASK   = 1 << SDL_JOYBALLMOTION;
const SDL_JOYHATMOTIONMASK    = 1 << SDL_JOYHATMOTION;
const SDL_JOYBUTTONDOWNMASK   = 1 << SDL_JOYBUTTONDOWN;
const SDL_JOYBUTTONUPMASK     = 1 << SDL_JOYBUTTONUP;
const SDL_JOYEVENTMASK        = (1 << SDL_JOYAXISMOTION)|
                                (1 << SDL_JOYBALLMOTION)|
                                (1 << SDL_JOYHATMOTION)|
                                (1 << SDL_JOYBUTTONDOWN)|
                                (1 << SDL_JOYBUTTONUP);
const SDL_VIDEORESIZEMASK     = 1 << SDL_VIDEORESIZE;
const SDL_VIDEOEXPOSEMASK     = 1 << SDL_VIDEOEXPOSE;
const SDL_QUITMASK            = 1 << SDL_QUIT;
const SDL_SYSWMEVENTMASK      = 1 << SDL_SYSWMEVENT;
const SDL_ALLEVENTS           = 0xFFFFFFFF;

struct SDL_ActiveEvent
{
	Uint8 type;
	Uint8 gain;
	Uint8 state;
}

struct SDL_KeyboardEvent
{
	Uint8 type;
	Uint8 which;
	Uint8 state;
	SDL_keysym keysym;
}

struct SDL_MouseMotionEvent
{
	Uint8 type;
	Uint8 which;
	Uint8 state;
	Uint16 x, y;
	Sint16 xrel;
	Sint16 yrel;
}

struct SDL_MouseButtonEvent
{
	Uint8 type;
	Uint8 which;
	Uint8 button;
	Uint8 state;
	Uint16 x, y;
}

struct SDL_JoyAxisEvent
{
	Uint8 type;
	Uint8 which;
	Uint8 axis;
	Sint16 value;
}

struct SDL_JoyBallEvent
{
	Uint8 type;
	Uint8 which;
	Uint8 ball;
	Sint16 xrel;
	Sint16 yrel;
}

struct SDL_JoyHatEvent
{
	Uint8 type;
	Uint8 which;
	Uint8 hat;
	Uint8 value;
}

struct SDL_JoyButtonEvent
{
	Uint8 type;
	Uint8 which;
	Uint8 button;
	Uint8 state;
}

struct SDL_ResizeEvent
{
	Uint8 type;
	int w;
	int h;
}

struct SDL_ExposeEvent
{
	Uint8 type;
}

struct SDL_QuitEvent
{
	Uint8 type;
}

struct SDL_UserEvent
{
	Uint8 type;
	int code;
	void *data1;
	void *data2;
}

struct SDL_SysWMmsg
{

}

struct SDL_SysWMEvent {
	Uint8 type;
	SDL_SysWMmsg *msg;
}

union SDL_Event
{
	Uint8 type;
	SDL_ActiveEvent active;
	SDL_KeyboardEvent key;
	SDL_MouseMotionEvent motion;
	SDL_MouseButtonEvent button;
	SDL_JoyAxisEvent jaxis;
	SDL_JoyBallEvent jball;
	SDL_JoyHatEvent jhat;
	SDL_JoyButtonEvent jbutton;
	SDL_ResizeEvent resize;
	SDL_ExposeEvent expose;
	SDL_QuitEvent quit;
	SDL_UserEvent user;
	SDL_SysWMEvent syswm;
	Uint8 filler[64];
}

enum SDL_eventaction
{
	SDL_ADDEVENT,
	SDL_PEEKEVENT,
	SDL_GETEVENT
}

const SDL_QUERY   = -1;
const SDL_IGNORE  = 0;
const SDL_DISABLE = 0;
const SDL_ENABLE  = 1;

version (DynamicSDL)
{
extern (C):
void (*SDL_PumpEvents)();
int (*SDL_PeepEvents)(SDL_Event *events, int numevents, SDL_eventaction action, Uint32 mask);
int (*SDL_PollEvent)(SDL_Event *event);
int (*SDL_WaitEvent)(SDL_Event *event);
int (*SDL_PushEvent)(SDL_Event *event);
typedef int function(SDL_Event *event) SDL_EventFilter;
void (*SDL_SetEventFilter)(SDL_EventFilter filter);
SDL_EventFilter (*SDL_GetEventFilter)();
Uint8 (*SDL_EventState)(Uint8 type, int state);
}
else
{
extern (C):
void SDL_PumpEvents();
int SDL_PeepEvents(SDL_Event *events, int numevents, SDL_eventaction action, Uint32 mask);
int SDL_PollEvent(SDL_Event *event);
int SDL_WaitEvent(SDL_Event *event);
int SDL_PushEvent(SDL_Event *event);
typedef int function(SDL_Event *event) SDL_EventFilter;
void SDL_SetEventFilter(SDL_EventFilter filter);
SDL_EventFilter SDL_GetEventFilter();
Uint8 SDL_EventState(Uint8 type, int state);
}

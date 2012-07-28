// This file is a hand mangled header file from SDL.
// See copyright in src/lib/sdl/sdl.d (LGPLv2+).
module lib.sdl.loader;


version (DynamicSDL)
{
import lib.loader;
import lib.sdl.sdl;


void loadSDL(Loader l)
{
	loadSDL_Audio(l);
	loadSDL_Event(l);
	loadSDL_Joystick(l);
	loadSDL_Keyboard(l);
	loadSDL_Mouse(l);
	loadSDL_RWops(l);
	loadSDL_Timer(l);
	loadSDL_Video(l);

	loadFunc!(SDL_Init)(l);
	loadFunc!(SDL_InitSubSystem)(l);
	loadFunc!(SDL_QuitSubSystem)(l);
	loadFunc!(SDL_WasInit)(l);
	loadFunc!(SDL_Quit)(l);
}

private:
void loadSDL_Audio(Loader l)
{
	loadFunc!(SDL_LoadWAV_RW)(l);
	loadFunc!(SDL_FreeWAV)(l);
}

void loadSDL_Event(Loader l)
{
	loadFunc!(SDL_PumpEvents)(l);
	loadFunc!(SDL_PeepEvents)(l);
	loadFunc!(SDL_PollEvent)(l);
	loadFunc!(SDL_WaitEvent)(l);
	loadFunc!(SDL_PushEvent)(l);
	loadFunc!(SDL_SetEventFilter)(l);
	loadFunc!(SDL_GetEventFilter)(l);
	loadFunc!(SDL_EventState)(l);
}

void loadSDL_Joystick(Loader l)
{
	loadFunc!(SDL_NumJoysticks)(l);
	loadFunc!(SDL_JoystickName)(l);
	loadFunc!(SDL_JoystickOpen)(l);
	loadFunc!(SDL_JoystickOpened)(l);
	loadFunc!(SDL_JoystickIndex)(l);
	loadFunc!(SDL_JoystickNumAxes)(l);
	loadFunc!(SDL_JoystickNumBalls)(l);
	loadFunc!(SDL_JoystickNumHats)(l);
	loadFunc!(SDL_JoystickNumButtons)(l);
	loadFunc!(SDL_JoystickUpdate)(l);
	loadFunc!(SDL_JoystickEventState)(l);
	loadFunc!(SDL_JoystickGetAxis)(l);
	loadFunc!(SDL_JoystickGetHat)(l);
	loadFunc!(SDL_JoystickGetBall)(l);
	loadFunc!(SDL_JoystickGetButton)(l);
	loadFunc!(SDL_JoystickClose)(l);
}

void loadSDL_Keyboard(Loader l)
{
	loadFunc!(SDL_EnableUNICODE)(l);
	loadFunc!(SDL_EnableKeyRepeat)(l);
	loadFunc!(SDL_GetKeyRepeat)(l);
	loadFunc!(SDL_GetKeyState)(l);
	loadFunc!(SDL_GetModState)(l);
	loadFunc!(SDL_SetModState)(l);
	loadFunc!(SDL_GetKeyName)(l);
}

void loadSDL_Mouse(Loader l)
{
	loadFunc!(SDL_ShowCursor)(l);
	loadFunc!(SDL_WarpMouse)(l);
}

void loadSDL_RWops(Loader l)
{
	loadFunc!(SDL_RWFromFile)(l);
	loadFunc!(SDL_RWFromFP)(l);
	loadFunc!(SDL_RWFromMem)(l);
	loadFunc!(SDL_RWFromConstMem)(l);
	loadFunc!(SDL_AllocRW)(l);
	loadFunc!(SDL_FreeRW)(l);
	loadFunc!(SDL_ReadLE16)(l);
	loadFunc!(SDL_ReadBE16)(l);
	loadFunc!(SDL_ReadLE32)(l);
	loadFunc!(SDL_ReadBE32)(l);
	loadFunc!(SDL_ReadLE64)(l);
	loadFunc!(SDL_ReadBE64)(l);
	loadFunc!(SDL_WriteLE16)(l);
	loadFunc!(SDL_WriteBE16)(l);
	loadFunc!(SDL_WriteLE32)(l);
	loadFunc!(SDL_WriteBE32)(l);
	loadFunc!(SDL_WriteLE64)(l);
	loadFunc!(SDL_WriteBE64)(l);
}

void loadSDL_Timer(Loader l)
{

	loadFunc!(SDL_GetTicks)(l);
	loadFunc!(SDL_Delay)(l);
	loadFunc!(SDL_SetTimer)(l);
	loadFunc!(SDL_AddTimer)(l);
	loadFunc!(SDL_RemoveTimer)(l);
}

void loadSDL_Video(Loader l)
{
	loadFunc!(SDL_VideoInit)(l);
	loadFunc!(SDL_VideoQuit)(l);
	loadFunc!(SDL_VideoDriverName)(l);
	loadFunc!(SDL_GetVideoSurface)(l);
	loadFunc!(SDL_GetVideoInfo)(l);
	loadFunc!(SDL_VideoModeOK)(l);
	loadFunc!(SDL_ListModes)(l);
	loadFunc!(SDL_SetVideoMode)(l);
	loadFunc!(SDL_UpdateRects)(l);
	loadFunc!(SDL_UpdateRect)(l);
	loadFunc!(SDL_Flip)(l);
	loadFunc!(SDL_SetGamma)(l);
	loadFunc!(SDL_SetGammaRamp)(l);
	loadFunc!(SDL_GetGammaRamp)(l);
	loadFunc!(SDL_SetColors)(l);
	loadFunc!(SDL_SetPalette)(l);
	loadFunc!(SDL_MapRGB)(l);
	loadFunc!(SDL_MapRGBA)(l);
	loadFunc!(SDL_GetRGB)(l);
	loadFunc!(SDL_GetRGBA)(l);
	loadFunc!(SDL_CreateRGBSurface)(l);
	loadFunc!(SDL_CreateRGBSurfaceFrom)(l);
	loadFunc!(SDL_FreeSurface)(l);
	loadFunc!(SDL_LockSurface)(l);
	loadFunc!(SDL_UnlockSurface)(l);
	loadFunc!(SDL_SaveBMP_RW)(l);
	loadFunc!(SDL_SetColorKey)(l);
	loadFunc!(SDL_SetAlpha)(l);
	loadFunc!(SDL_SetClipRect)(l);
	loadFunc!(SDL_GetClipRect)(l);
	loadFunc!(SDL_ConvertSurface)(l);
	loadFunc!(SDL_UpperBlit)(l);
	loadFunc!(SDL_LowerBlit)(l);
	loadFunc!(SDL_FillRect)(l);
	loadFunc!(SDL_DisplayFormat)(l);
	loadFunc!(SDL_DisplayFormatAlpha)(l);
	loadFunc!(SDL_CreateYUVOverlay)(l);
	loadFunc!(SDL_LockYUVOverlay)(l);
	loadFunc!(SDL_UnlockYUVOverlay)(l);
	loadFunc!(SDL_DisplayYUVOverlay)(l);
	loadFunc!(SDL_FreeYUVOverlay)(l);
	loadFunc!(SDL_GL_LoadLibrary)(l);
	loadFunc!(SDL_GL_GetProcAddress)(l);
	loadFunc!(SDL_GL_SetAttribute)(l);
	loadFunc!(SDL_GL_GetAttribute)(l);
	loadFunc!(SDL_GL_SwapBuffers)(l);
	loadFunc!(SDL_GL_UpdateRects)(l);
	loadFunc!(SDL_GL_Lock)(l);
	loadFunc!(SDL_GL_Unlock)(l);
	loadFunc!(SDL_WM_SetCaption)(l);
	loadFunc!(SDL_WM_GetCaption)(l);
	loadFunc!(SDL_WM_SetIcon)(l);
	loadFunc!(SDL_WM_IconifyWindow)(l);
	loadFunc!(SDL_WM_ToggleFullScreen)(l);
	loadFunc!(SDL_WM_GrabInput)(l);
	loadFunc!(SDL_SoftStretch)(l);
}
}

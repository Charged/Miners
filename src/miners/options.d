// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.options;

import lib.sdl.keysym;

import charge.util.signal;
import charge.charge;

import miners.types;


/**
 * Holds settings and common resources that are shared between
 * multiple runners, worlds & actors.
 */
class Options
{
public:
	/*
	 *
	 * Global shared information.
	 *
	 */

	/**
	 * Arguments parsed.
	 *
	 * Do not share to mods, contains authentication information.
	 */
	/*@{*/
	bool shouldBuildAll;

	bool isClassicNetwork;
	bool isClassicResume;
	bool isClassicMcUrl;
	bool isClassicHttp;
	bool inhibitClassicListLoad;

	string playSessionCookie;
	string username;
	string password;

	ClassicServerInfo classicServerInfo;

	ClassicServerInfo[] classicServerList;

	string levelPath;
	string launcherPath;
	/*@}*/

	/**
	 * Last connected classic server name.
	 */
	Option!(string) lastClassicServer;
	const string lastClassicServerName = "mc.lastClassicServer";
	const string lastClassicServerDefault = "--";

	/**
	 * Last connected classic server name hash.
	 */
	Option!(string) lastClassicServerHash;
	const string lastClassicServerHashName = "mc.lastClassicServerHash";
	const string lastClassicServerHashDefault = "--";

	/**
	 * Used for resume option.
	 */
	Option!(string) lastMcUrl;
	const string lastMcUrlName = "mc.lastMcUrl";
	const string lastMcUrlDefault = "--";


	/*
	 *
	 * Options
	 *
	 */


	Option!(bool) aa; /**< should anti-aliasing be used */
	Option!(bool) fog; /**< should fog be drawn */
	Option!(int) fov; /**< which fov should be used */
	Option!(bool) hideUi; /**< hide the user interface */
	Option!(bool) noClip; /**< can the player move trough blocks */
	Option!(bool) flying; /**< gravity doesn't effect the player */
	Option!(bool) shadow; /**< should advanced shadowing be used */
	Option!(bool) showDebug; /**< should debug info be shown */
	Option!(bool) useCmdPrefix; /**< should we use the command prefix */
	Option!(double) viewDistance; /**< the view distance */

	const string aaName = "mc.aa";
	const string fogName = "mc.fog";
	const string fovName = "mc.fov";
	const string shadowName = "mc.shadow";
	const string useCmdPrefixName = "mc.useCmdPrefix";
	const string viewDistanceName = "mc.viewDistance";

	const bool aaDefault = true;
	const bool fogDefault = true;
	const int fovDefault = 45;
	const bool shadowDefault = true;
	const bool useCmdPrefixDefault = true;
	const double viewDistanceDefault = 256;


	/*
	 *
	 * Key bindings.
	 *
	 */


	const string[24] keyNames = [
		"mc.keyForward",
		"mc.keyBackward",
		"mc.keyLeft",
		"mc.keyRight",
		"mc.keyCameraUp",
		"mc.keyCameraDown",
		"mc.keyJump",
		"mc.keyCrouch",
		"mc.keyRun",
		"mc.keyFlightMode",
		"mc.keyNoClip",
		"mc.keyChat",
		"mc.keySelector",
		"mc.keyScreenshot",
		"mc.keyPlayerList",
		"mc.keySlot0",
		"mc.keySlot1",
		"mc.keySlot2",
		"mc.keySlot3",
		"mc.keySlot4",
		"mc.keySlot5",
		"mc.keySlot6",
		"mc.keySlot7",
		"mc.keySlot8",
	];

	const int[24] keyDefaults = [
		SDLK_w,
		SDLK_s,
		SDLK_a,
		SDLK_d,
		SDLK_q,
		SDLK_e,
		SDLK_SPACE,
		SDLK_LCTRL,
		SDLK_LSHIFT,
		SDLK_z,
		SDLK_x,
		SDLK_t,
		SDLK_b,
		SDLK_o,
		SDLK_TAB,
		SDLK_1, // mc.keySlot1
		SDLK_2,
		SDLK_3,
		SDLK_4,
		SDLK_5,
		SDLK_6,
		SDLK_7,
		SDLK_8,
		SDLK_9,
	];

	static assert(keyNames.length == keyDefaults.length);
	static assert(keyArray.length == keyDefaults.length);

	union {
		struct {
			int keyForward;
			int keyBackward;
			int keyLeft;
			int keyRight;
			int keyCameraUp;
			int keyCameraDown;
			int keyJump;
			int keyCrouch;
			int keyRun;
			int keyFlightMode;
			int keyNoClip;
			int keyChat;
			int keySelector;
			int keyScreenshot;
			int keyPlayerList;
			int keySlot0;
			int keySlot1;
			int keySlot2;
			int keySlot3;
			int keySlot4;
			int keySlot5;
			int keySlot6;
			int keySlot7;
			int keySlot8;
		};
		int[24] keyArray;
	}
	Signal!() keyBindings;


	/*
	 *
	 * Shared gfx resources.
	 *
	 */


	GfxTexture blackTexture;
	GfxTexture whiteTexture;

	Option!(GfxTexture) defaultSkin;

	GfxSimpleSkeleton.VBO playerSkeleton;
	alias PlayerModelData.bones playerBones;

	Option!(bool) backgroundTiled; /**< should the background be tiled */
	Option!(bool) backgroundDoubled; /**< should the background be doubled in size */

	Option!(Picture) modernTerrainPic;
	Option!(Picture) classicTerrainPic;
	Option!(Picture) borrowedTerrainPic;

	Option!(GfxTexture) background;
	Option!(GfxBitmapFont) classicFont;

	GfxTexture[50] classicSides;

	TerrainTextures modernTextures;
	TerrainTextures classicTextures;


	/*
	 *
	 * Renderer settings.
	 *
	 */


	bool failsafe; /**< use as little as possible gfx features */
	const string failsafeName = "mc.failsafe"; /**< config name */

	bool rendererBackground; /**< use the background scene */
	bool rendererBuildIndexed; /**< support array textures */
	string rendererString; /**< readable string for current renderer */
	TerrainBuildTypes rendererBuildType;
	Signal!(TerrainBuildTypes, string) renderer;


	/*
	 *
	 * Triggers.
	 *
	 */


	/**
	 * Change the terrain texture to this file.
	 */
	bool delegate(string file) changeTexture;


	/**
	 * Trigger a change of the renderer, return a human readable string.
	 */
	void delegate() changeRenderer;


	/**
	 * Not a trigger as such, but downloads a player skin.
	 */
	GfxTexture delegate(string name) getSkin;


public:
	~this()
	{
		sysReference(&playerSkeleton, null);
		sysReference(&blackTexture, null);
		sysReference(&whiteTexture, null);

		if (modernTextures !is null) {
			modernTextures.breakApart();
			modernTextures = null;
		}

		if (classicTextures !is null) {
			classicTextures.breakApart();
			classicTextures = null;
		}

		renderer.destruct();
		shadow.destruct();
		showDebug.destruct();
		viewDistance.destruct();
		useCmdPrefix.destruct();

		defaultSkin.destruct();

		backgroundTiled.destruct();
		backgroundDoubled.destruct();

		modernTerrainPic.destruct();
		classicTerrainPic.destruct();
		borrowedTerrainPic.destruct();

		background.destruct();
		classicFont.destruct();

		foreach (ref tex; classicSides) {
			sysReference(&tex, null);
		}
	}

	void allocateResources()
	{
		assert(playerSkeleton is null &&
		       blackTexture is null &&
		       whiteTexture is null);

		playerSkeleton = GfxSimpleSkeleton.VBO(PlayerModelData.verts);
		blackTexture = GfxColorTexture(SysPool(), Color4f.Black);
		whiteTexture = GfxColorTexture(SysPool(), Color4f.White);
	}

	void setRenderer(TerrainBuildTypes bt, string s)
	{
		rendererString = s;
		rendererBuildType = bt;
		renderer(bt, s);
	}
}


/**
 * Helper container for terrain textures.
 */
class TerrainTextures
{
public:
	GfxTexture t;
	GfxTextureArray ta;

public:
	~this()
	{
		assert(t is null);
		assert(ta is null);
	}

	void breakApart()
	{
		sysReference(&t, null);
		sysReference(&ta, null);
	}
}


/**
 * Single option.
 */
private struct Option(T)
{
	Signal!(T) signal;
	T value;

	T opCall()
	{
		return value;
	}

	bool opIn(T value)
	{
		return this.value is value;
	}

	void opAssign(T t)
	{
		static if (is(T : Picture) ||
		           is(T : GfxTexture) ||
		           is(T : GfxTextureArray) ||
		           is(T : GfxBitmapFont))
			sysReference(&value, t);
		else
			value = t;
		signal(t);
	}

	void opCatAssign(signal.Slot slot)
	{
		signal.opCatAssign(slot);
	}

	void opSubAssign(signal.Slot slot)
	{
		signal.opSubAssign(slot);
	}

	static if (is(T : bool)) {
		void toggle()
		{
			value = !value;
			signal(value);
		}
	}

	void destruct()
	{
		signal.destruct();

		static if (is(T : Picture) ||
		           is(T : GfxTexture) ||
		           is(T : GfxTextureArray) ||
		           is(T : GfxBitmapFont))
			sysReference(&value, null);
	}
}


class PlayerModelData
{
	const float sz = 0.215 / 2;
	const float s_2 = sz*2;
	const float s_3 = sz*3;
	const float s_4 = sz*4;
	const float s_5 = sz*5;
	const float s_6 = sz*6;
	const float offW = offH/2f;
	const float offH = 1f/4096f;

	const GfxSimpleSkeleton.Vertex verts[] = [
		// HEAD
		// X- Left
		{[-s_2,   0, -s_2], [   0.25f+offW,   0.5f-offH], [-1,  0,  0], 0},
		{[-s_2,   0,  s_2], [  0.375f-offW,   0.5f-offH], [-1,  0,  0], 0},
		{[-s_2, s_4,  s_2], [  0.375f-offW,  0.25f+offH], [-1,  0,  0], 0},
		{[-s_2, s_4, -s_2], [   0.25f+offW,  0.25f+offH], [-1,  0,  0], 0},
		// X+ Right
		{[ s_2,   0,  s_2], [    0.0f+offW,   0.5f-offH], [ 1,  0,  0], 0},
		{[ s_2,   0, -s_2], [  0.125f-offW,   0.5f-offH], [ 1,  0,  0], 0},
		{[ s_2, s_4, -s_2], [  0.125f-offW,  0.25f+offH], [ 1,  0,  0], 0},
		{[ s_2, s_4,  s_2], [    0.0f+offW,  0.25f+offH], [ 1,  0,  0], 0},
		// Y- Bottom
		{[ s_2,   0,  s_2], [  0.375f-offW,  0.25f-offH], [ 0, -1,  0], 0},
		{[-s_2,   0,  s_2], [   0.25f+offW,  0.25f-offH], [ 0, -1,  0], 0},
		{[-s_2,   0, -s_2], [   0.25f+offW,   0.0f+offH], [ 0, -1,  0], 0},
		{[ s_2,   0, -s_2], [  0.375f-offW,   0.0f+offH], [ 0, -1,  0], 0},
		// Y+ Top
		{[-s_2, s_4,  s_2], [   0.25f-offW,   0.0f+offH], [ 0,  1,  0], 0},
		{[ s_2, s_4,  s_2], [  0.125f+offW,   0.0f+offH], [ 0,  1,  0], 0},
		{[ s_2, s_4, -s_2], [  0.125f+offW,  0.25f-offH], [ 0,  1,  0], 0},
		{[-s_2, s_4, -s_2], [   0.25f-offW,  0.25f-offH], [ 0,  1,  0], 0},
		// Z- Front
		{[ s_2,   0, -s_2], [  0.125f+offW,   0.5f-offH], [ 0,  0, -1], 0},
		{[-s_2,   0, -s_2], [   0.25f-offW,   0.5f-offH], [ 0,  0, -1], 0},
		{[-s_2, s_4, -s_2], [   0.25f-offW,  0.25f+offH], [ 0,  0, -1], 0},
		{[ s_2, s_4, -s_2], [  0.125f+offW,  0.25f+offH], [ 0,  0, -1], 0},
		// Z+ Back
		{[-s_2,   0,  s_2], [  0.375f+offW,   0.5f-offH], [ 0,  0,  1], 0},
		{[ s_2,   0,  s_2], [    0.5f-offW,   0.5f-offH], [ 0,  0,  1], 0},
		{[ s_2, s_4,  s_2], [    0.5f-offW,  0.25f+offH], [ 0,  0,  1], 0},
		{[-s_2, s_4,  s_2], [  0.375f+offW,  0.25f+offH], [ 0,  0,  1], 0},

		// Body
		// X- Left
		{[-s_2, -s_3, -sz], [ 0.4375f+offW,   1.0f-offH], [-1,  0,  0], 1},
		{[-s_2, -s_3,  sz], [    0.5f-offW,   1.0f-offH], [-1,  0,  0], 1},
		{[-s_2,  s_3,  sz], [    0.5f-offW, 0.625f+offH], [-1,  0,  0], 1},
		{[-s_2,  s_3, -sz], [ 0.4375f+offW, 0.625f+offH], [-1,  0,  0], 1},
		// X+ Right
		{[ s_2, -s_3,  sz], [   0.25f+offW,   1.0f-offH], [ 1,  0,  0], 1},
		{[ s_2, -s_3, -sz], [ 0.3125f-offW,   1.0f-offH], [ 1,  0,  0], 1},
		{[ s_2,  s_3, -sz], [ 0.3125f-offW, 0.625f+offH], [ 1,  0,  0], 1},
		{[ s_2,  s_3,  sz], [   0.25f+offW, 0.625f+offH], [ 1,  0,  0], 1},
		// Y- Bottom
		{[ s_2, -s_3,  sz], [ 0.4375f+offW, 0.625f-offH], [ 0, -1,  0], 1},
		{[-s_2, -s_3,  sz], [ 0.5625f-offW, 0.625f-offH], [ 0, -1,  0], 1},
		{[-s_2, -s_3, -sz], [ 0.5625f-offW,   0.5f+offH], [ 0, -1,  0], 1},
		{[ s_2, -s_3, -sz], [ 0.4375f+offW,   0.5f+offH], [ 0, -1,  0], 1},
		// Y+ Top
		{[-s_2,  s_3,  sz], [ 0.4375f-offW,   0.5f+offH], [ 0,  1,  0], 1},
		{[ s_2,  s_3,  sz], [ 0.3125f+offW,   0.5f+offH], [ 0,  1,  0], 1},
		{[ s_2,  s_3, -sz], [ 0.3125f+offW, 0.625f-offH], [ 0,  1,  0], 1},
		{[-s_2,  s_3, -sz], [ 0.4375f-offW, 0.625f-offH], [ 0,  1,  0], 1},
		// Z- Front
		{[ s_2, -s_3, -sz], [ 0.3125f+offW,   1.0f-offH], [ 0,  0, -1], 1},
		{[-s_2, -s_3, -sz], [ 0.4375f-offW,   1.0f-offH], [ 0,  0, -1], 1},
		{[-s_2,  s_3, -sz], [ 0.4375f-offW, 0.625f+offH], [ 0,  0, -1], 1},
		{[ s_2,  s_3, -sz], [ 0.3125f+offW, 0.625f+offH], [ 0,  0, -1], 1},
		// Z+ Back
		{[-s_2, -s_3,  sz], [    0.5f+offW,   1.0f-offH], [ 0,  0,  1], 1},
		{[ s_2, -s_3,  sz], [  0.625f-offW,   1.0f-offH], [ 0,  0,  1], 1},
		{[ s_2,  s_3,  sz], [  0.625f-offW, 0.625f+offH], [ 0,  0,  1], 1},
		{[-s_2,  s_3,  sz], [    0.5f+offW, 0.625f+offH], [ 0,  0,  1], 1},

		// Arm 1
		// X- Left
		{[ -sz, -s_5, -sz], [ 0.6875f-offW,   1.0f-offH], [-1,  0,  0], 2},
		{[ -sz, -s_5,  sz], [  0.625f+offW,   1.0f-offH], [-1,  0,  0], 2},
		{[ -sz,   sz,  sz], [  0.625f+offW, 0.625f+offH], [-1,  0,  0], 2},
		{[ -sz,   sz, -sz], [ 0.6875f-offW, 0.625f+offH], [-1,  0,  0], 2},
		// X+ Right
		{[  sz, -s_5,  sz], [ 0.8125f-offW,   1.0f-offH], [ 1,  0,  0], 2},
		{[  sz, -s_5, -sz], [   0.75f+offW,   1.0f-offH], [ 1,  0,  0], 2},
		{[  sz,   sz, -sz], [   0.75f+offW, 0.625f+offH], [ 1,  0,  0], 2},
		{[  sz,   sz,  sz], [ 0.8125f-offW, 0.625f+offH], [ 1,  0,  0], 2},
		// Y- Bottom
		{[  sz, -s_5,  sz], [ 0.8125f-offW, 0.625f-offH], [ 0, -1,  0], 2},
		{[ -sz, -s_5,  sz], [   0.75f+offW, 0.625f-offH], [ 0, -1,  0], 2},
		{[ -sz, -s_5, -sz], [   0.75f+offW,   0.5f+offH], [ 0, -1,  0], 2},
		{[  sz, -s_5, -sz], [ 0.8125f-offW,   0.5f+offH], [ 0, -1,  0], 2},
		// Y+ Top
		{[ -sz,   sz,  sz], [ 0.6875f+offW, 0.625f-offH], [ 0,  1,  0], 2},
		{[  sz,   sz,  sz], [   0.75f-offW, 0.625f-offH], [ 0,  1,  0], 2},
		{[  sz,   sz, -sz], [   0.75f-offW,   0.5f+offH], [ 0,  1,  0], 2},
		{[ -sz,   sz, -sz], [ 0.6875f+offW,   0.5f+offH], [ 0,  1,  0], 2},
		// Z- Front
		{[  sz, -s_5, -sz], [   0.75f-offW,   1.0f-offH], [ 0,  0, -1], 2},
		{[ -sz, -s_5, -sz], [ 0.6875f+offW,   1.0f-offH], [ 0,  0, -1], 2},
		{[ -sz,   sz, -sz], [ 0.6875f+offW, 0.625f+offH], [ 0,  0, -1], 2},
		{[  sz,   sz, -sz], [   0.75f-offW, 0.625f+offH], [ 0,  0, -1], 2},
		// Z+ Back
		{[ -sz, -s_5,  sz], [  0.875f-offW,   1.0f-offH], [ 0,  0,  1], 2},
		{[  sz, -s_5,  sz], [ 0.8175f+offW,   1.0f-offH], [ 0,  0,  1], 2},
		{[  sz,   sz,  sz], [ 0.8175f+offW, 0.625f+offH], [ 0,  0,  1], 2},
		{[ -sz,   sz,  sz], [  0.875f-offW, 0.625f+offH], [ 0,  0,  1], 2},

		// Arm 2
		// X- Left
		{[ -sz, -s_5, -sz], [   0.75f+offW,   1.0f-offH], [-1,  0,  0], 3},
		{[ -sz, -s_5,  sz], [ 0.8125f-offW,   1.0f-offH], [-1,  0,  0], 3},
		{[ -sz,   sz,  sz], [ 0.8125f-offW, 0.625f+offH], [-1,  0,  0], 3},
		{[ -sz,   sz, -sz], [   0.75f+offW, 0.625f+offH], [-1,  0,  0], 3},
		// X+ Right
		{[  sz, -s_5,  sz], [  0.625f+offW,   1.0f-offH], [ 1,  0,  0], 3},
		{[  sz, -s_5, -sz], [ 0.6875f-offW,   1.0f-offH], [ 1,  0,  0], 3},
		{[  sz,   sz, -sz], [ 0.6875f-offW, 0.625f+offH], [ 1,  0,  0], 3},
		{[  sz,   sz,  sz], [  0.625f+offW, 0.625f+offH], [ 1,  0,  0], 3},
		// Y- Bottom
		{[  sz, -s_5,  sz], [   0.75f+offW, 0.625f-offH], [ 0, -1,  0], 3},
		{[ -sz, -s_5,  sz], [ 0.8125f-offW, 0.625f-offH], [ 0, -1,  0], 3},
		{[ -sz, -s_5, -sz], [ 0.8125f-offW,   0.5f+offH], [ 0, -1,  0], 3},
		{[  sz, -s_5, -sz], [   0.75f+offW,   0.5f+offH], [ 0, -1,  0], 3},
		// Y+ Top
		{[ -sz,   sz,  sz], [   0.75f-offW, 0.625f-offH], [ 0,  1,  0], 3},
		{[  sz,   sz,  sz], [ 0.6875f+offW, 0.625f-offH], [ 0,  1,  0], 3},
		{[  sz,   sz, -sz], [ 0.6875f+offW,   0.5f+offH], [ 0,  1,  0], 3},
		{[ -sz,   sz, -sz], [   0.75f-offW,   0.5f+offH], [ 0,  1,  0], 3},
		// Z- Front
		{[  sz, -s_5, -sz], [ 0.6875f+offW,   1.0f-offH], [ 0,  0, -1], 3},
		{[ -sz, -s_5, -sz], [   0.75f-offW,   1.0f-offH], [ 0,  0, -1], 3},
		{[ -sz,   sz, -sz], [   0.75f-offW, 0.625f+offH], [ 0,  0, -1], 3},
		{[  sz,   sz, -sz], [ 0.6875f+offW, 0.625f+offH], [ 0,  0, -1], 3},
		// Z+ Back
		{[ -sz, -s_5,  sz], [ 0.8125f+offW,   1.0f-offH], [ 0,  0,  1], 3},
		{[  sz, -s_5,  sz], [  0.875f-offW,   1.0f-offH], [ 0,  0,  1], 3},
		{[  sz,   sz,  sz], [  0.875f-offW, 0.625f+offH], [ 0,  0,  1], 3},
		{[ -sz,   sz,  sz], [ 0.8125f+offW, 0.625f+offH], [ 0,  0,  1], 3},

		// Leg 1
		// X- Left
		{[ -sz, -s_6, -sz], [ 0.0625f-offW,   1.0f-offH], [-1,  0,  0], 4},
		{[ -sz, -s_6,  sz], [    0.0f+offW,   1.0f-offH], [-1,  0,  0], 4},
		{[ -sz,    0,  sz], [    0.0f+offW, 0.625f+offH], [-1,  0,  0], 4},
		{[ -sz,    0, -sz], [ 0.0625f-offW, 0.625f+offH], [-1,  0,  0], 4},
		// X+ Right
		{[  sz, -s_6,  sz], [ 0.1875f-offW,   1.0f-offH], [ 1,  0,  0], 4},
		{[  sz, -s_6, -sz], [  0.125f+offW,   1.0f-offH], [ 1,  0,  0], 4},
		{[  sz,    0, -sz], [  0.125f+offW, 0.625f+offH], [ 1,  0,  0], 4},
		{[  sz,    0,  sz], [ 0.1875f-offW, 0.625f+offH], [ 1,  0,  0], 4},
		// Y- Bottom
		{[  sz, -s_6,  sz], [ 0.1875f-offW, 0.625f-offH], [ 0, -1,  0], 4},
		{[ -sz, -s_6,  sz], [  0.125f+offW, 0.625f-offH], [ 0, -1,  0], 4},
		{[ -sz, -s_6, -sz], [  0.125f+offW,   0.5f+offH], [ 0, -1,  0], 4},
		{[  sz, -s_6, -sz], [ 0.1875f-offW,   0.5f+offH], [ 0, -1,  0], 4},
		// Y+ Top
		{[ -sz,    0,  sz], [ 0.0625f+offW,   0.5f+offH], [ 0,  1,  0], 4},
		{[  sz,    0,  sz], [  0.125f-offW,   0.5f+offH], [ 0,  1,  0], 4},
		{[  sz,    0, -sz], [  0.125f-offW, 0.625f-offH], [ 0,  1,  0], 4},
		{[ -sz,    0, -sz], [ 0.0625f+offW, 0.625f-offH], [ 0,  1,  0], 4},
		// Z- Front
		{[  sz, -s_6, -sz], [  0.125f-offW,   1.0f-offH], [ 0,  0, -1], 4},
		{[ -sz, -s_6, -sz], [ 0.0625f+offW,   1.0f-offH], [ 0,  0, -1], 4},
		{[ -sz,    0, -sz], [ 0.0625f+offW, 0.625f+offH], [ 0,  0, -1], 4},
		{[  sz,    0, -sz], [  0.125f-offW, 0.625f+offH], [ 0,  0, -1], 4},
		// Z+ Back
		{[ -sz, -s_6,  sz], [   0.25f-offW,   1.0f-offH], [ 0,  0,  1], 4},
		{[  sz, -s_6,  sz], [ 0.1875f+offW,   1.0f-offH], [ 0,  0,  1], 4},
		{[  sz,    0,  sz], [ 0.1875f+offW, 0.625f+offH], [ 0,  0,  1], 4},
		{[ -sz,    0,  sz], [   0.25f-offW, 0.625f+offH], [ 0,  0,  1], 4},

		// Leg 2
		// X- Left
		{[ -sz, -s_6, -sz], [  0.125f+offW,   1.0f-offH], [-1,  0,  0], 5},
		{[ -sz, -s_6,  sz], [ 0.1875f-offW,   1.0f-offH], [-1,  0,  0], 5},
		{[ -sz,    0,  sz], [ 0.1875f-offW, 0.625f+offH], [-1,  0,  0], 5},
		{[ -sz,    0, -sz], [  0.125f+offW, 0.625f+offH], [-1,  0,  0], 5},
		// X+ Right
		{[  sz, -s_6,  sz], [    0.0f+offW,   1.0f-offH], [ 1,  0,  0], 5},
		{[  sz, -s_6, -sz], [ 0.0625f-offW,   1.0f-offH], [ 1,  0,  0], 5},
		{[  sz,    0, -sz], [ 0.0625f-offW, 0.625f+offH], [ 1,  0,  0], 5},
		{[  sz,    0,  sz], [    0.0f+offW, 0.625f+offH], [ 1,  0,  0], 5},
		// Y- Bottom
		{[  sz, -s_6,  sz], [  0.125f+offW, 0.625f-offH], [ 0, -1,  0], 5},
		{[ -sz, -s_6,  sz], [ 0.1875f-offW, 0.625f-offH], [ 0, -1,  0], 5},
		{[ -sz, -s_6, -sz], [ 0.1875f-offW,   0.5f+offH], [ 0, -1,  0], 5},
		{[  sz, -s_6, -sz], [  0.125f+offW,   0.5f+offH], [ 0, -1,  0], 5},
		// Y+ Top
		{[ -sz,    0,  sz], [  0.125f-offW,   0.5f+offH], [ 0,  1,  0], 5},
		{[  sz,    0,  sz], [ 0.0625f+offW,   0.5f+offH], [ 0,  1,  0], 5},
		{[  sz,    0, -sz], [ 0.0625f+offW, 0.625f-offH], [ 0,  1,  0], 5},
		{[ -sz,    0, -sz], [  0.125f-offW, 0.625f-offH], [ 0,  1,  0], 5},
		// Z- Front
		{[  sz, -s_6, -sz], [ 0.0625f+offW,   1.0f-offH], [ 0,  0, -1], 5},
		{[ -sz, -s_6, -sz], [  0.125f-offW,   1.0f-offH], [ 0,  0, -1], 5},
		{[ -sz,    0, -sz], [  0.125f-offW, 0.625f+offH], [ 0,  0, -1], 5},
		{[  sz,    0, -sz], [ 0.0625f+offW, 0.625f+offH], [ 0,  0, -1], 5},
		// Z+ Back
		{[ -sz, -s_6,  sz], [ 0.1875f+offW,   1.0f-offH], [ 0,  0,  1], 5},
		{[  sz, -s_6,  sz], [   0.25f-offW,   1.0f-offH], [ 0,  0,  1], 5},
		{[  sz,    0,  sz], [   0.25f-offW, 0.625f+offH], [ 0,  0,  1], 5},
		{[ -sz,    0,  sz], [ 0.1875f+offW, 0.625f+offH], [ 0,  0,  1], 5}
	];

	const charge.gfx.skeleton.Bone bones[] = [
		{Quatd(), Vector3d(   0,   s_6*2, 0), uint.max}, // Head
		{Quatd(), Vector3d(   0, s_6+s_3, 0), uint.max}, // Body
		{Quatd(), Vector3d(-s_3, s_6+s_5, 0), uint.max}, // Arm 1
		{Quatd(), Vector3d( s_3, s_6+s_5, 0), uint.max}, // Arm 2
		{Quatd(), Vector3d( -sz,     s_6, 0), uint.max}, // Leg 1
		{Quatd(), Vector3d(  sz,     s_6, 0), uint.max}, // Leg 2
	];
}

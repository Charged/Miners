// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.options;

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
	 * Options
	 *
	 */


	Option!(bool) aa; /**< should anti-aliasing be used */
	Option!(bool) fog; /**< should fog be drawn */
	Option!(bool) hideUi; /**< hide the user interface */
	Option!(bool) shadow; /**< should advanced shadowing be used */
	Option!(bool) showDebug; /**< should debug info be shown */
	Option!(bool) useCmdPrefix; /**< should we use the command prefix */
	Option!(double) viewDistance; /**< the view distance */

	const string aaName = "mc.aa";
	const string fogName = "mc.fog";
	const string shadowName = "mc.shadow";
	const string useCmdPrefixName = "mc.useCmdPrefix";
	const string viewDistanceName = "mc.viewDistance";

	const bool aaDefault = true;
	const bool fogDefault = true;
	const bool shadowDefault = true;
	const bool useCmdPrefixDefault = true;
	const double viewDistanceDefault = 256;


	/*
	 *
	 * Shared gfx resources.
	 *
	 */


	GfxTexture blackTexture;
	GfxTexture whiteTexture;

	GfxSimpleSkeleton.VBO playerSkeleton;
	alias PlayerModelData.bones playerBones;

	Option!(GfxTexture) dirt;
	Option!(GfxTexture) terrain;
	Option!(GfxTextureArray) terrainArray;
	Option!(GfxTexture) classicTerrain;
	Option!(GfxTextureArray) classicTerrainArray;


	/*
	 *
	 * Renderer settings.
	 *
	 */


	bool rendererBuildIndexed; /**< support array textures */
	char[] rendererString; /**< readable string for current renderer */
	TerrainBuildTypes rendererBuildType;
	Signal!(TerrainBuildTypes, char[]) renderer;


	/*
	 *
	 * Triggers.
	 *
	 */


	/**
	 * Change the terrain texture to this file.
	 */
	bool delegate(char[] file) changeTexture;


	/**
	 * Trigger a change of the renderer, return a human readable string.
	 */
	void delegate() changeRenderer;


public:
	this()
	{
		playerSkeleton = GfxSimpleSkeleton.VBO(PlayerModelData.verts);
		blackTexture = GfxColorTexture(Color4f.Black);
		whiteTexture = GfxColorTexture(Color4f.White);
	}

	~this()
	{
		sysReference(&playerSkeleton, null);
		sysReference(&blackTexture, null);
		sysReference(&whiteTexture, null);

		terrain.destruct();
		renderer.destruct();
		shadow.destruct();
		showDebug.destruct();
		viewDistance.destruct();
		useCmdPrefix.destruct();

		dirt.destruct();
		terrain.destruct();
		terrainArray.destruct();
		classicTerrain.destruct();
		classicTerrainArray.destruct();
	}

	void setRenderer(TerrainBuildTypes bt, char[] s)
	{
		rendererString = s;
		rendererBuildType = bt;
		renderer(bt, s);
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
		static if (is(T : GfxTexture) || is(T : GfxTextureArray))
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

		static if (is(T : GfxTexture) || is(T : GfxTextureArray))
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

	const GfxSimpleSkeleton.Vertex verts[] = [
		// HEAD
		// X-
		{[-s_2,   0, -s_2], [ 0,  1], [-1,  0,  0], 0},
		{[-s_2,   0,  s_2], [ 1,  1], [-1,  0,  0], 0},
		{[-s_2, s_4,  s_2], [ 1,  0], [-1,  0,  0], 0},
		{[-s_2, s_4, -s_2], [ 0,  0], [-1,  0,  0], 0},
		// X+
		{[ s_2,   0,  s_2], [ 0,  1], [ 1,  0,  0], 0},
		{[ s_2,   0, -s_2], [ 1,  1], [ 1,  0,  0], 0},
		{[ s_2, s_4, -s_2], [ 1,  0], [ 1,  0,  0], 0},
		{[ s_2, s_4,  s_2], [ 0,  0], [ 1,  0,  0], 0},
		// Y- Bottom
		{[ s_2,   0,  s_2], [ 0,  1], [ 0, -1,  0], 0},
		{[-s_2,   0,  s_2], [ 1,  1], [ 0, -1,  0], 0},
		{[-s_2,   0, -s_2], [ 1,  0], [ 0, -1,  0], 0},
		{[ s_2,   0, -s_2], [ 0,  0], [ 0, -1,  0], 0},
		// Y+ Top
		{[-s_2, s_4,  s_2], [ 0,  1], [ 0,  1,  0], 0},
		{[ s_2, s_4,  s_2], [ 1,  1], [ 0,  1,  0], 0},
		{[ s_2, s_4, -s_2], [ 1,  0], [ 0,  1,  0], 0},
		{[-s_2, s_4, -s_2], [ 0,  0], [ 0,  1,  0], 0},
		// Z- Front
		{[ s_2,   0, -s_2], [ 0,  1], [ 0,  0, -1], 0},
		{[-s_2,   0, -s_2], [ 1,  1], [ 0,  0, -1], 0},
		{[-s_2, s_4, -s_2], [ 1,  0], [ 0,  0, -1], 0},
		{[ s_2, s_4, -s_2], [ 0,  0], [ 0,  0, -1], 0},
		// Z+ Back
		{[-s_2,   0,  s_2], [ 0,  1], [ 0,  0,  1], 0},
		{[ s_2,   0,  s_2], [ 1,  1], [ 0,  0,  1], 0},
		{[ s_2, s_4,  s_2], [ 1,  0], [ 0,  0,  1], 0},
		{[-s_2, s_4,  s_2], [ 0,  0], [ 0,  0,  1], 0},

		// Body
		// X-
		{[-s_2, -s_3, -sz], [ 0,  1], [-1,  0,  0], 1},
		{[-s_2, -s_3,  sz], [ 1,  1], [-1,  0,  0], 1},
		{[-s_2,  s_3,  sz], [ 1,  0], [-1,  0,  0], 1},
		{[-s_2,  s_3, -sz], [ 0,  0], [-1,  0,  0], 1},
		// X+
		{[ s_2, -s_3,  sz], [ 0,  1], [ 1,  0,  0], 1},
		{[ s_2, -s_3, -sz], [ 1,  1], [ 1,  0,  0], 1},
		{[ s_2,  s_3, -sz], [ 1,  0], [ 1,  0,  0], 1},
		{[ s_2,  s_3,  sz], [ 0,  0], [ 1,  0,  0], 1},
		// Y- Bottom
		{[ s_2, -s_3,  sz], [ 0,  1], [ 0, -1,  0], 1},
		{[-s_2, -s_3,  sz], [ 1,  1], [ 0, -1,  0], 1},
		{[-s_2, -s_3, -sz], [ 1,  0], [ 0, -1,  0], 1},
		{[ s_2, -s_3, -sz], [ 0,  0], [ 0, -1,  0], 1},
		// Y+ Top
		{[-s_2,  s_3,  sz], [ 0,  1], [ 0,  1,  0], 1},
		{[ s_2,  s_3,  sz], [ 1,  1], [ 0,  1,  0], 1},
		{[ s_2,  s_3, -sz], [ 1,  0], [ 0,  1,  0], 1},
		{[-s_2,  s_3, -sz], [ 0,  0], [ 0,  1,  0], 1},
		// Z- Front
		{[ s_2, -s_3, -sz], [ 0,  1], [ 0,  0, -1], 1},
		{[-s_2, -s_3, -sz], [ 1,  1], [ 0,  0, -1], 1},
		{[-s_2,  s_3, -sz], [ 1,  0], [ 0,  0, -1], 1},
		{[ s_2,  s_3, -sz], [ 0,  0], [ 0,  0, -1], 1},
		// Z+ Back
		{[-s_2, -s_3,  sz], [ 0,  1], [ 0,  0,  1], 1},
		{[ s_2, -s_3,  sz], [ 1,  1], [ 0,  0,  1], 1},
		{[ s_2,  s_3,  sz], [ 1,  0], [ 0,  0,  1], 1},
		{[-s_2,  s_3,  sz], [ 0,  0], [ 0,  0,  1], 1},

		// Arm 1
		// X-
		{[-sz, -s_5, -sz], [ 0,  1], [-1,  0,  0], 2},
		{[-sz, -s_5,  sz], [ 1,  1], [-1,  0,  0], 2},
		{[-sz,   sz,  sz], [ 1,  0], [-1,  0,  0], 2},
		{[-sz,   sz, -sz], [ 0,  0], [-1,  0,  0], 2},
		// X+
		{[ sz, -s_5,  sz], [ 0,  1], [ 1,  0,  0], 2},
		{[ sz, -s_5, -sz], [ 1,  1], [ 1,  0,  0], 2},
		{[ sz,   sz, -sz], [ 1,  0], [ 1,  0,  0], 2},
		{[ sz,   sz,  sz], [ 0,  0], [ 1,  0,  0], 2},
		// Y- Bottom
		{[ sz, -s_5,  sz], [ 0,  1], [ 0, -1,  0], 2},
		{[-sz, -s_5,  sz], [ 1,  1], [ 0, -1,  0], 2},
		{[-sz, -s_5, -sz], [ 1,  0], [ 0, -1,  0], 2},
		{[ sz, -s_5, -sz], [ 0,  0], [ 0, -1,  0], 2},
		// Y+ Top
		{[-sz,   sz,  sz], [ 0,  1], [ 0,  1,  0], 2},
		{[ sz,   sz,  sz], [ 1,  1], [ 0,  1,  0], 2},
		{[ sz,   sz, -sz], [ 1,  0], [ 0,  1,  0], 2},
		{[-sz,   sz, -sz], [ 0,  0], [ 0,  1,  0], 2},
		// Z- Front
		{[ sz, -s_5, -sz], [ 0,  1], [ 0,  0, -1], 2},
		{[-sz, -s_5, -sz], [ 1,  1], [ 0,  0, -1], 2},
		{[-sz,   sz, -sz], [ 1,  0], [ 0,  0, -1], 2},
		{[ sz,   sz, -sz], [ 0,  0], [ 0,  0, -1], 2},
		// Z+ Back
		{[-sz, -s_5,  sz], [ 0,  1], [ 0,  0,  1], 2},
		{[ sz, -s_5,  sz], [ 1,  1], [ 0,  0,  1], 2},
		{[ sz,   sz,  sz], [ 1,  0], [ 0,  0,  1], 2},
		{[-sz,   sz,  sz], [ 0,  0], [ 0,  0,  1], 2},

		// Arm 2
		// X-
		{[-sz, -s_5, -sz], [ 0,  1], [-1,  0,  0], 3},
		{[-sz, -s_5,  sz], [ 1,  1], [-1,  0,  0], 3},
		{[-sz,   sz,  sz], [ 1,  0], [-1,  0,  0], 3},
		{[-sz,   sz, -sz], [ 0,  0], [-1,  0,  0], 3},
		// X+
		{[ sz, -s_5,  sz], [ 0,  1], [ 1,  0,  0], 3},
		{[ sz, -s_5, -sz], [ 1,  1], [ 1,  0,  0], 3},
		{[ sz,   sz, -sz], [ 1,  0], [ 1,  0,  0], 3},
		{[ sz,   sz,  sz], [ 0,  0], [ 1,  0,  0], 3},
		// Y- Bottom
		{[ sz, -s_5,  sz], [ 0,  1], [ 0, -1,  0], 3},
		{[-sz, -s_5,  sz], [ 1,  1], [ 0, -1,  0], 3},
		{[-sz, -s_5, -sz], [ 1,  0], [ 0, -1,  0], 3},
		{[ sz, -s_5, -sz], [ 0,  0], [ 0, -1,  0], 3},
		// Y+ Top
		{[-sz,   sz,  sz], [ 0,  1], [ 0,  1,  0], 3},
		{[ sz,   sz,  sz], [ 1,  1], [ 0,  1,  0], 3},
		{[ sz,   sz, -sz], [ 1,  0], [ 0,  1,  0], 3},
		{[-sz,   sz, -sz], [ 0,  0], [ 0,  1,  0], 3},
		// Z- Front
		{[ sz, -s_5, -sz], [ 0,  1], [ 0,  0, -1], 3},
		{[-sz, -s_5, -sz], [ 1,  1], [ 0,  0, -1], 3},
		{[-sz,   sz, -sz], [ 1,  0], [ 0,  0, -1], 3},
		{[ sz,   sz, -sz], [ 0,  0], [ 0,  0, -1], 3},
		// Z+ Back
		{[-sz, -s_5,  sz], [ 0,  1], [ 0,  0,  1], 3},
		{[ sz, -s_5,  sz], [ 1,  1], [ 0,  0,  1], 3},
		{[ sz,   sz,  sz], [ 1,  0], [ 0,  0,  1], 3},
		{[-sz,   sz,  sz], [ 0,  0], [ 0,  0,  1], 3},

		// Leg 1
		// X-
		{[-sz, -s_6, -sz], [ 0,  1], [-1,  0,  0], 4},
		{[-sz, -s_6,  sz], [ 1,  1], [-1,  0,  0], 4},
		{[-sz,    0,  sz], [ 1,  0], [-1,  0,  0], 4},
		{[-sz,    0, -sz], [ 0,  0], [-1,  0,  0], 4},
		// X+
		{[ sz, -s_6,  sz], [ 0,  1], [ 1,  0,  0], 4},
		{[ sz, -s_6, -sz], [ 1,  1], [ 1,  0,  0], 4},
		{[ sz,    0, -sz], [ 1,  0], [ 1,  0,  0], 4},
		{[ sz,    0,  sz], [ 0,  0], [ 1,  0,  0], 4},
		// Y- Bottom
		{[ sz, -s_6,  sz], [ 0,  1], [ 0, -1,  0], 4},
		{[-sz, -s_6,  sz], [ 1,  1], [ 0, -1,  0], 4},
		{[-sz, -s_6, -sz], [ 1,  0], [ 0, -1,  0], 4},
		{[ sz, -s_6, -sz], [ 0,  0], [ 0, -1,  0], 4},
		// Y+ Top
		{[-sz,    0,  sz], [ 0,  1], [ 0,  1,  0], 4},
		{[ sz,    0,  sz], [ 1,  1], [ 0,  1,  0], 4},
		{[ sz,    0, -sz], [ 1,  0], [ 0,  1,  0], 4},
		{[-sz,    0, -sz], [ 0,  0], [ 0,  1,  0], 4},
		// Z- Front
		{[ sz, -s_6, -sz], [ 0,  1], [ 0,  0, -1], 4},
		{[-sz, -s_6, -sz], [ 1,  1], [ 0,  0, -1], 4},
		{[-sz,    0, -sz], [ 1,  0], [ 0,  0, -1], 4},
		{[ sz,    0, -sz], [ 0,  0], [ 0,  0, -1], 4},
		// Z+ Back
		{[-sz, -s_6,  sz], [ 0,  1], [ 0,  0,  1], 4},
		{[ sz, -s_6,  sz], [ 1,  1], [ 0,  0,  1], 4},
		{[ sz,    0,  sz], [ 1,  0], [ 0,  0,  1], 4},
		{[-sz,    0,  sz], [ 0,  0], [ 0,  0,  1], 4},

		// Leg 2
		// X-
		{[-sz, -s_6, -sz], [ 0,  1], [-1,  0,  0], 5},
		{[-sz, -s_6,  sz], [ 1,  1], [-1,  0,  0], 5},
		{[-sz,    0,  sz], [ 1,  0], [-1,  0,  0], 5},
		{[-sz,    0, -sz], [ 0,  0], [-1,  0,  0], 5},
		// X5
		{[ sz, -s_6,  sz], [ 0,  1], [ 1,  0,  0], 5},
		{[ sz, -s_6, -sz], [ 1,  1], [ 1,  0,  0], 5},
		{[ sz,    0, -sz], [ 1,  0], [ 1,  0,  0], 5},
		{[ sz,    0,  sz], [ 0,  0], [ 1,  0,  0], 5},
		// Y- Bottom
		{[ sz, -s_6,  sz], [ 0,  1], [ 0, -1,  0], 5},
		{[-sz, -s_6,  sz], [ 1,  1], [ 0, -1,  0], 5},
		{[-sz, -s_6, -sz], [ 1,  0], [ 0, -1,  0], 5},
		{[ sz, -s_6, -sz], [ 0,  0], [ 0, -1,  0], 5},
		// Y+ Top
		{[-sz,    0,  sz], [ 0,  1], [ 0,  1,  0], 5},
		{[ sz,    0,  sz], [ 1,  1], [ 0,  1,  0], 5},
		{[ sz,    0, -sz], [ 1,  0], [ 0,  1,  0], 5},
		{[-sz,    0, -sz], [ 0,  0], [ 0,  1,  0], 5},
		// Z- Front
		{[ sz, -s_6, -sz], [ 0,  1], [ 0,  0, -1], 5},
		{[-sz, -s_6, -sz], [ 1,  1], [ 0,  0, -1], 5},
		{[-sz,    0, -sz], [ 1,  0], [ 0,  0, -1], 5},
		{[ sz,    0, -sz], [ 0,  0], [ 0,  0, -1], 5},
		// Z+ Back
		{[-sz, -s_6,  sz], [ 0,  1], [ 0,  0,  1], 5},
		{[ sz, -s_6,  sz], [ 1,  1], [ 0,  0,  1], 5},
		{[ sz,    0,  sz], [ 1,  0], [ 0,  0,  1], 5},
		{[-sz,    0,  sz], [ 0,  0], [ 0,  0,  1], 5}
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

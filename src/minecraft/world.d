// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.world;

import std.math;

import charge.charge;

import minecraft.terrain.chunk;
import minecraft.terrain.vol;

class World : public GameWorld
{
public:
	char[] level;

	RenderManager rm; /** Shared with other worlds */
	VolTerrain vt;

private:
	mixin SysLogging;

public:
	this(char[] level, RenderManager rm)
	{
		super();
		this.rm = rm;

		vt = new VolTerrain(this, level, rm.tex);
		vt.buildIndexed = MinecraftForwardRenderer.textureArraySupported;
		vt.setBuildType(rm.bt);
	}

	~this()
	{
		//delete vt;
	}

	void switchRenderer()
	{
		rm.switchRenderer();
		vt.setBuildType(rm.bt);
	}

protected:

}


import minecraft.gfx.renderer;

/**
 * Class for managing the different renderers.
 *
 * Also handles the textures use when rendering.
 */
class RenderManager
{
public:
	/*
	 * For managing the rendering.
	 */
	GfxTexture tex;
	GfxTextureArray ta;

	GfxRenderer r; // Current renderer
	GfxRenderer dr; // Inbuilt deferred or Fixed func
	MinecraftDeferredRenderer mdr; // Special deferred renderer
	MinecraftForwardRenderer mfr; // Special forward renderer
	GfxRenderer rs[4]; // Null terminated list of renderer
	VolTerrain.BuildTypes rsbt[4]; // A list of build types for the renderers
	VolTerrain.BuildTypes bt; // Current build type
	int num_renderers;
	int current_renderer;

	bool canDoForward;
	bool canDoDeferred;

	bool aa;

private:
	mixin SysLogging;

public:
	this()
	{
		canDoForward = MinecraftForwardRenderer.check();
		canDoDeferred = MinecraftDeferredRenderer.check();

		setupTextures();
		setupRenderers();
	}

	~this()
	{
		if (ta !is null) {
			ta.dereference();
			ta = null;
		}
		if (tex !is null) {
			tex.dereference();
			tex = null;
		}

		delete dr;
		delete mfr;
		delete mdr;
	}

	void switchRenderer()
	{
		current_renderer++;
		if (current_renderer >= num_renderers)
			current_renderer = 0;

		r = rs[current_renderer];
		bt = rsbt[current_renderer];
	}

protected:
	void setupTextures()
	{
		auto pic = Picture("mc/terrain", "res/terrain.png");

		// Doesn't support biomes right now fixup the texture before use.
		applyStaticBiome(pic);

		tex = GfxTexture("mc/terrain", pic);
		tex.filter = GfxTexture.Filter.Nearest; // Or we get errors near the block edges

		if (mfr.textureArraySupported && (canDoForward || canDoDeferred)) {
			ta = ta.fromTileMap("mc/terrain", pic, 16, 16);
			ta.filter = GfxTexture.Filter.NearestLinear;
		}

		pic.dereference();
		pic = null;
	}

	void setupRenderers()
	{
		GfxRenderer.init();
		r = new GfxFixedRenderer();
		rsbt[num_renderers] = VolTerrain.BuildTypes.RigidMesh;
		rs[num_renderers++] = r;

		if (canDoForward) {
			try {
				mfr = new MinecraftForwardRenderer(tex, ta);
				rsbt[num_renderers] = VolTerrain.BuildTypes.CompactMesh;
				rs[num_renderers++] = mfr;
			} catch (Exception e) {
				l.warn("No fancy renderer \"%s\"", e);
			}
		}

		if (canDoDeferred) {
			try {
				MinecraftDeferredRenderer.init();

				mdr = new MinecraftDeferredRenderer(ta);
				rsbt[num_renderers] = VolTerrain.BuildTypes.Array;
				rs[num_renderers++] = mdr;
			} catch (Exception e) {
				l.warn("No fancy renderer \"%s\"", e);
			}
		}

		// Pick the most advanced renderer
		current_renderer = num_renderers - 1;
		r = rs[current_renderer];
		bt = rsbt[current_renderer];
	}

	/*
	 * Functions for manipulating the terrain.png picture.
	 */

	void applyStaticBiome(Picture pic)
	{
		//auto grass = Color4b(88, 190, 55, 255);
		auto grass = Color4b(102, 180, 68, 255);
		auto leaves = Color4b(91, 139, 23, 255);

		modulateColor(pic, 0, 0, grass); // Top grass
		modulateColor(pic, 6, 2, grass); // Side grass blend
		modulateColor(pic, 4, 3, leaves); // Tree leaves

		// Blend the now colored side grass onto the used side
		blendTiles(pic, 3, 0, 6, 2);

		// When we are doing mipmaping, soften the edges.
		fillEmptyWithAverage(pic, 4, 3); // Leaves
		fillEmptyWithAverage(pic, 1, 3); // Glass
		fillEmptyWithAverage(pic, 1, 4); // Moster-spawn
	}

	void modulateColor(Picture pic, uint tile_x, uint tile_y, Color4b color)
	{
		uint tile_size = pic.width / 16;
		tile_x *= tile_size;
		tile_y *= tile_size;

		for (int x; x < tile_size; x++) {
			for (int y; y < tile_size; y++) {
				auto ptr = &pic.pixels[(x + tile_x) + (y + tile_y) * pic.width];
				ptr.modulate(color);
			}
		}
	}

	void blendTiles(Picture pic, uint dst_x, uint dst_y, uint src_x, uint src_y)
	{
		uint tile_size = pic.width / 16;
		dst_x *= tile_size;
		dst_y *= tile_size;
		src_x *= tile_size;
		src_y *= tile_size;

		for (int x; x < tile_size; x++) {
			for (int y; y < tile_size; y++) {
				auto dst = &pic.pixels[(x + dst_x) + (y + dst_y) * pic.width];
				auto src = &pic.pixels[(x + src_x) + (y + src_y) * pic.width];
				dst.blend(*src);
			}
		}
	}

	void fillEmptyWithAverage(Picture pic, uint dst_x, uint dst_y)
	{
		uint tile_size = pic.width / 16;
		dst_x *= tile_size;
		dst_y *= tile_size;

		uint num;
		double r = 0, g = 0, b = 0;

		for (int x; x < tile_size; x++) {
			for (int y; y < tile_size; y++) {
				auto dst = &pic.pixels[(x + dst_x) + (y + dst_y) * pic.width];
				if (dst.a == 0)
					continue;

				r += dst.r;
				g += dst.g;
				b += dst.b;
				num++;
			}
		}

		Color4b avrg;

		if (num == 0) {
			avrg = Color4b.Black;
			avrg.a = 0;
		} else {
			avrg.r = cast(ubyte)(r / num);
			avrg.g = cast(ubyte)(g / num);
			avrg.b = cast(ubyte)(b / num);
			avrg.a = 0;
		}

		for (int x; x < tile_size; x++) {
			for (int y; y < tile_size; y++) {
				auto dst = &pic.pixels[(x + dst_x) + (y + dst_y) * pic.width];
				if (dst.a != 0)
					continue;
				*dst = avrg;
			}
		}
	}
}

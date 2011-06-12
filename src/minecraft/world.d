// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.world;

import std.math;

import charge.charge;
import charge.platform.homefolder;

import minecraft.importer;
import minecraft.terrain.chunk;
import minecraft.terrain.data;
import minecraft.terrain.vol;
import minecraft.actors.helper;

class World : public GameWorld
{
public:
	char[] dir;

	RenderManager rm; /** Shared with other worlds */
	ResourceStore rs; /** Shared with other worlds */
	VolTerrain vt;
	Point3d spawn;

private:
	mixin SysLogging;

public:
	this(MinecraftLevelInfo *info, RenderManager rm, ResourceStore rs)
	{
		super();
		this.rm = rm;
		this.rs = rs;
		this.spawn = info ? info.spawn : Point3d(0, 64, 0);
		this.dir = info ? info.dir : null;

		vt = new VolTerrain(this, dir, rm.tex);
		vt.buildIndexed = MinecraftForwardRenderer.textureArraySupported;
		vt.setBuildType(rm.bt);

		// Find the actuall spawn height
		auto x = cast(int)spawn.x;
		auto y = cast(int)spawn.y;
		auto z = cast(int)spawn.z;
		auto xPos = x < 0 ? (x - 15) / 16 : x / 16;
		auto zPos = z < 0 ? (z - 15) / 16 : z / 16;

		vt.setCenter(xPos, zPos);
		vt.loadChunk(xPos, zPos);

		auto p = vt.getPointerY(x, z);
		for (int i = y; i < 128; i++) {
			if (tile[p[i]].filled)
				continue;
			if (tile[p[i+1]].filled)
				continue;

			spawn.y = i;
			break;
		}
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

	GfxDefaultTarget defaultTarget;
	GfxDoubleTarget dt;

	GfxRenderer r; // Current renderer
	GfxRenderer ifc; // Inbuilt fixed func
	GfxRenderer ifr; // Inbuilt forward renderer
	MinecraftDeferredRenderer mdr; // Special deferred renderer
	MinecraftForwardRenderer mfr; // Special forward renderer
	GfxRenderer rs[5]; // Null terminated list of renderer
	VolTerrain.BuildTypes rsbt[5]; // A list of build types for the renderers
	VolTerrain.BuildTypes bt; // Current build type
	int num_renderers;
	int current_renderer;

	bool canDoForward;
	bool canDoDeferred;

	bool aa;

private:
	mixin SysLogging;

public:
	this(Picture terrain)
	{
		canDoForward = MinecraftForwardRenderer.check();
		canDoDeferred = MinecraftDeferredRenderer.check();

		defaultTarget = GfxDefaultTarget();
		setupTextures(terrain);
		setupRenderers();

		aa = true;
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

		delete ifc;
		delete ifr;
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

	void render(GfxWorld w, GfxCamera c)
	{
		render(w, c, defaultTarget);
	}

	void render(GfxWorld w, GfxCamera c, GfxRenderTarget rt)
	{
		if (aa && (dt is null || rt.width != dt.width/2 || rt.height != dt.height/2))
			dt = new GfxDoubleTarget(rt.width, rt.height);

		r.target = aa ? cast(GfxRenderTarget)dt : cast(GfxRenderTarget)rt;

		r.render(c, w);

		if (aa)
			dt.resolve(rt);

	}

protected:
	void setupTextures(Picture pic)
	{
		// Doesn't support biomes right now fixup the texture before use.
		applyStaticBiome(pic);

		setupRedstoneWire(pic);

		tex = GfxTexture("mc/terrain", pic);
		tex.filter = GfxTexture.Filter.Nearest; // Or we get errors near the block edges

		if (mfr.textureArraySupported && (canDoForward || canDoDeferred)) {
			ta = ta.fromTileMap("mc/terrain", pic, 16, 16);
			ta.filter = GfxTexture.Filter.NearestLinear;
		}
	}

	void setupRenderers()
	{
		GfxRenderer.init();
		ifc = new GfxFixedRenderer();
		rsbt[num_renderers] = VolTerrain.BuildTypes.RigidMesh;
		rs[num_renderers++] = ifc;

		if (canDoForward) {
			ifr = new GfxForwardRenderer();
			rsbt[num_renderers] = VolTerrain.BuildTypes.RigidMesh;
			rs[num_renderers++] = ifr;
		}

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
				rsbt[num_renderers] = VolTerrain.BuildTypes.CompactMesh;
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

		// These colors are just a guess
		auto leavesRegular = Color4b(91, 139, 23, 255);
		auto leavesSpruce = Color4b(83, 107, 73, 255);
		auto leavesBirch = Color4b(125, 163, 83, 255);
		auto leavesOther = leavesRegular;

		// Copy to some currently unused texture tiles
		copyTile(pic, 4, 3, 9, 9); // Birch leaves
		copyTile(pic, 4, 3, 9, 10); // Other leaves

		modulateColor(pic, 0, 0, grass); // Top grass
		modulateColor(pic, 6, 2, grass); // Side grass blend
		modulateColor(pic, 7, 2, grass); // Tall grass
		modulateColor(pic, 8, 3, grass); // Fern
		modulateColor(pic, 4, 3, leavesRegular); // Tree leaves
		modulateColor(pic, 4, 8, leavesSpruce); // Spruce leaves
		modulateColor(pic, 9, 9, leavesBirch); // Birch leaves
		modulateColor(pic, 9, 10, leavesOther); // Other leaves

		// Blend the now colored side grass onto the used side
		blendTiles(pic, 3, 0, 6, 2);

		// When we are doing mipmaping, soften the edges.
		fillEmptyWithAverage(pic, 4, 3); // Leaves
		fillEmptyWithAverage(pic, 1, 3); // Glass
		fillEmptyWithAverage(pic, 1, 4); // Moster-spawn
	}

	void setupRedstoneWire(Picture pic) {
		auto active = Color4b(178, 0, 0, 155);
		auto inactive = Color4b(65, 0, 0, 155);

		// Clear tiles.
		auto tile = redstoneWireTile[0][RedstoneWireType.Corner];
		clearTile(pic, tile.xz.u, tile.xz.v);
		tile = redstoneWireTile[0][RedstoneWireType.Tjunction];
		clearTile(pic, tile.xz.u, tile.xz.v);

		foreach(BlockDescriptor dec; redstoneWireTile[1])
			clearTile(pic, dec.xz.u, dec.xz.v);

		// Create corner (2 connections) tile and T-form (3 connections) tile
		// from the crossover tile.
		auto src = redstoneWireTile[0][RedstoneWireType.Crossover];
		auto corner_dst = redstoneWireTile[0][RedstoneWireType.Corner];
		auto tjunction_dst = redstoneWireTile[0][RedstoneWireType.Tjunction];

		// AFAIK there are no non-square tile maps.
		uint tile_size = pic.width / 16;
		int h = tile_size / 2;
		int f = tile_size;
		copyTilePart(pic, src.xz.u*f, src.xz.v*f+h, f-h, f-h,
			     corner_dst.xz.u*f, corner_dst.xz.v*f+h);

		copyTilePart(pic, src.xz.u*f, src.xz.v*f, f-h, f,
				tjunction_dst.xz.u*f, tjunction_dst.xz.v*f);

		// Copy all four wire tiles.
		for (int i = 0; i < 4; i++) {
			src = redstoneWireTile[0][i];
			auto dst = redstoneWireTile[1][i];
			copyTile(pic, src.xz.u, src.xz.v, dst.xz.u, dst.xz.v);
		}

		// Color the wire tiles.
		foreach(BlockDescriptor dec; redstoneWireTile[0])
			modulateColor(pic, dec.xz.u, dec.xz.v, inactive);

		foreach(BlockDescriptor dec; redstoneWireTile[1])
			modulateColor(pic, dec.xz.u, dec.xz.v, active);
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

	void copyTile(Picture pic, uint tile_x, uint tile_y, uint newtile_x, uint newtile_y)
	{
		uint tile_size = pic.width / 16;
		tile_x *= tile_size;
		tile_y *= tile_size;
		newtile_x *= tile_size;
		newtile_y *= tile_size;

		for (int x; x < tile_size; x++) {
			for (int y; y < tile_size; y++) {
				auto ptr = &pic.pixels[(x + tile_x) + (y + tile_y) * pic.width];
				auto newptr = &pic.pixels[(x + newtile_x) + (y + newtile_y) * pic.width];
				*newptr = *ptr;
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

	void copyTilePart(Picture pic, uint src_x, uint src_y, uint src_w, uint src_h,
			  uint dst_x, uint dst_y) {
		for (int x; x < src_w; x++) {
			for (int y; y < src_h; y++) {
				auto dst = &pic.pixels[(x + dst_x) + (y + dst_y) * pic.width];
				auto src = &pic.pixels[(x + src_x) + (y + src_y) * pic.width];
				*dst = *src;
			}
		}
	}

	void clearTile(Picture pic, uint tile_x, uint tile_y)
	{
		modulateColor(pic, tile_x, tile_y, Color4b(0, 0, 0, 0));
	}
}

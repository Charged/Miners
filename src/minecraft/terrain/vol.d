// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.terrain.vol;

import std.math;

// For SDL get ticks
import lib.sdl.sdl;

import charge.charge;

import minecraft.gfx.vbo;
import minecraft.gfx.renderer;
import minecraft.importer;
import minecraft.terrain.chunk;

class VolTerrain : public GameActor
{
private:
	//mixin SysLogging;

public:
	enum BuildTypes {
		RigidMesh,
		CompactMesh,
		Array,
	}

	GfxTexture tex;
	const int width = 16;
	const int depth = 16;
	int view_radii;
	int save_build_i;
	int save_build_j;
	int save_build_k;
	int xCenter;
	int zCenter;
	int rxOff;
	int rzOff;
	Region[depth][width] region;
	ChunkVBOGroupArray cvga;
	ChunkVBOGroupRigidMesh cvgrm;
	ChunkVBOGroupCompactMesh cvgcm;
	BuildTypes currentBuildType;
	char[] dir;

	bool buildIndexed; // The renderer supports array textures.

	this(GameWorld w, char[] dir, GfxTexture tex)
	{
		super(w);

		view_radii = 250 / 16 + 1;

		this.rxOff = 0;
		this.rzOff = 0;
		this.dir = dir;
		this.tex = tex;

		// Make sure all state is setup correctly
		setCenter(0, 0);

		// Make the code not early out.
		currentBuildType = BuildTypes.Array;

		// Setup the groups
		setBuildType(BuildTypes.RigidMesh);
	}

	~this() {
		foreach(row; region)
			foreach(r; row)
				delete r;
		delete cvga;
		delete cvgrm;
		delete cvgcm;
	}

	void buildAll()
	{
		while(buildOne()) {}
	}

	void setRotation(ref Quatd rot)
	{
		super.setRotation(rot);
	}

	void setViewRadii(int radii)
	{
		if (radii < view_radii) {
			for (int x; x < width; x++) {
				for (int z; z < depth; z++) {
					auto r = region[x][z];
					if (r is null)
						continue;

					r.unbuildRadi(xCenter, zCenter, radii);
				}
			}
		}
		view_radii = radii;
	}

	void setBuildType(BuildTypes type)
	{
		if (type == currentBuildType)
			return;

		currentBuildType = type;

		// Unbuild all the meshes.
		for (int x; x < width; x++) {
			for (int z; z < depth; z++) {
				auto r = region[x][z];
				if (r is null)
					continue;
				r.unbuildAll();
			}
		}

		// Reset the saved position for the buildOne function
		save_build_i = 0;
		save_build_j = 0;
		save_build_k = 0;

		if (cvgrm !is null)
			delete cvgrm;
		if (cvgcm !is null)
			delete cvgcm;
		if (cvga !is null)
			delete cvga;

		cvgrm = null; cvgcm = null; cvga = null;

		switch(type) {
		case BuildTypes.RigidMesh:
			cvgrm = new ChunkVBOGroupRigidMesh(w.gfx);
			cvgrm.getMaterial().setTexture("tex", tex);
			cvgrm.getMaterial().setOption("fake", true);
			break;
		case BuildTypes.CompactMesh:
			cvgcm = new ChunkVBOGroupCompactMesh(w.gfx);
			// No need to setup material handled by the renderer
			break;
		case BuildTypes.Array:
			cvga = new ChunkVBOGroupArray(w.gfx);
			// No need to setup material handled by the renderer
			break;
		default:
			assert(false);
		}

		// Build at least one chunk
		buildOne();
	}

	final Chunk getChunk(int x, int z)
	{
		auto r = getRegion(x, z);
		if (r is null)
			return null;

		return r.getChunk(x, z);
	}

	ubyte get(int xPos, int zPos, int x, int y, int z)
	{
		xPos += x < 0 ? (x - 15) / 16 : x / 16;
		zPos += z < 0 ? (z - 15) / 16 : z / 16;
		x = cast(uint)x % 16;
		z = cast(uint)z % 16;

		auto c = getChunk(xPos, zPos);
		if (c)
			return c.get(x, y, z);
		return 0;
	}

	ubyte* getDataPointerY(int xPos, int zPos, int x, int z)
	{
		xPos += x < 0 ? (x - 15) / 16 : x / 16;
		zPos += z < 0 ? (z - 15) / 16 : z / 16;
		x = cast(uint)x % 16;
		z = cast(uint)z % 16;

		auto c = getChunk(xPos, zPos);
		if (c)
			return c.getDataPointerY(x, z);
		return null;
	}

	ubyte* getPointerY(int xPos, int zPos, int x, int z)
	{
		xPos += x < 0 ? (x - 15) / 16 : x / 16;
		zPos += z < 0 ? (z - 15) / 16 : z / 16;
		x = cast(uint)x % 16;
		z = cast(uint)z % 16;

		auto c = getChunk(xPos, zPos);
		if (c)
			return c.getPointerY(x, z);
		return null;
	}

	void setCenter(int xNew, int zNew)
	{
		setCenterRegions(xNew, zNew);

		xCenter = xNew;
		zCenter = zNew;
		for (int x; x < width; x++) {
			for (int z; z < depth; z++) {
				auto r = region[x][z];
				if (r is null)
					continue;

				r.unbuildRadi(xCenter, zCenter, view_radii);
			}
		}

		// Reset the saved position for the buildOne function
		save_build_i = 0;
		save_build_j = 0;
		save_build_k = 0;

		charge.sys.resource.Pool().collect();
	}

	bool buildOne()
	{
		bool dob(int x, int z) {
			x += xCenter;
			z += zCenter;

			auto c = getChunk(x, z);
			if (c !is null && c.gfx)
				return false;

			for (int i = x-1; i < x+2; i++) {
				for (int j = z-1; j < z+2; j++) {
					loadChunk(i, j);
				}
			}

			getRegion(x, z).buildUnsafe(x, z);
			return true;
		}

		int offset(int i) { i++; return i & 1 ? -(i >> 1) : (i >> 1); }
		int num(int i) { i++; return i | 1; }

		// Restart from save position
		int i = save_build_i;
		int j = save_build_j;
		int k = save_build_k;
		for (; i < view_radii * 2 - 1; i++) {
			for (; j < num(i); j++) {
				for (; k < num(i); k++) {
					if (dob(offset(j), offset(k))) {
						save_build_i = i;
						save_build_j = j;
						save_build_k = k;
						return true;
					}
				}
				k = 0;
			}
			j = 0;
		}
		// This make all buildOne calls just skip the loops
		save_build_i = i;
		save_build_j = j;
		save_build_k = k;
		return false;
	}

protected:
	void setCenterRegions(int xNew, int zNew)
	{
		auto rxNew = cast(int)floor(cast(float)xNew / Region.width);
		auto rzNew = cast(int)floor(cast(float)zNew / Region.depth);

		int rxNewOff = rxNew - (width / 2);
		int rzNewOff = rzNew - (depth / 2);

		if (rxNewOff == rxOff && rzNewOff == rzOff)
			return;

		Region[depth][width] copy;

		for (int x; x < width; x++) {
			for (int z; z < depth; z++) {
				auto r = region[x][z];
				if (r is null)
					continue;
				int rxPos = r.xPos - rxNewOff;
				int rzPos = r.zPos - rzNewOff;
				if (rxPos < 0 || rzPos < 0 || rxPos >= width || rzPos >= depth) {
					delete r;
				} else {
					copy[rxPos][rzPos] = r;
				}
			}
		}

		rxOff = rxNewOff;
		rzOff = rzNewOff;
		for (int x; x < width; x++)
			for (int z; z < depth; z++)
				region[x][z] = copy[x][z];
	}

	final Region getRegion(int x, int z)
	{
		auto rx = cast(int)floor(x/32.0) - rxOff;
		auto rz = cast(uint)floor(z/32.0) - rzOff;

		if (rx < 0 || rz < 0)
			return null;
		else if (rx >= width || rz >= depth)
			return null;

		return region[rx][rz];
	}

	/**
	 * Creates and if a level was specified loads data.
	 */
	Chunk loadChunk(int x, int z)
	{
		auto rx = cast(int)floor(x/32.0) - rxOff;
		auto rz = cast(uint)floor(z/32.0) - rzOff;

		if (rx < 0 || rz < 0)
			assert(null is "tried to load chunk outside of regions");
		else if (rx >= width || rz >= depth)
			assert(null is "tried to load chunk outside of regions");

		auto r = region[rx][rz];
		if (r is null)
			region[rx][rz] = r = new Region(this, rx+rxOff, rz+rzOff);

		auto c = r.createChunkUnsafe(x, z);

		// Don't load chunk data if no level was specified.
		if (dir is null)
			return c;

		ubyte *blocks;
		ubyte *data;
		if (getBlocksForChunk(dir, x, z, blocks, data))
			c.giveBlocksAndData(blocks, data);

		return c;
	}
}

final class Region
{
public:
	const int width = 32;
	const int depth = 32;
	Chunk[width][depth] chunk;

	VolTerrain vt;

	int numBuilt;

	/*
	 * The same used as as in the filename.
	 */
	int xPos;
	int zPos;

	/*
	 * Used to go from a global chunk position to a local one.
	 */
	int xOff;
	int zOff;
private:

public:
	this(VolTerrain vt, int xPos, int zPos)
	{
		this.vt = vt;
		this.xPos = xPos;
		this.zPos = zPos;

		xOff = xPos * 32;
		zOff = zPos * 32;
	}

	~this()
	{
		foreach(row; chunk)
			foreach(c; row)
				delete c;
	}

	final void buildUnsafe(int x, int z)
	{
		auto c = getChunkUnsafe(x, z);
		if (c is null || c.gfx)
			return;

		c.build();
		numBuilt++;
	}

	final void unbuild(int x, int z)
	{
		if (numBuilt <= 0)
			return;

		auto c = getChunk(x, z);
		if (c is null || !c.gfx)
			return;

		c.build();
		numBuilt--;
	}

	final void unbuildAll()
	{
		if (numBuilt <= 0)
			return;

		for (int x; x < width; x++) {
			for (int z; z < depth; z++) {
				auto c = chunk[x][z];
				if (c is null)
					continue;
				c.unbuild();
			}
		}

		numBuilt = 0;
	}

	final void unbuildRadi(int xCenter, int zCenter, int view_radi)
	{
		if (numBuilt <= 0)
			return;

		int r = view_radi - 1;
		for (int x; x < width; x++) {
			for (int z; z < depth; z++) {
				auto xp = x + xOff;
				auto zp = z + zOff;

				auto c = chunk[x][z];
				if (c is null || !c.gfx)
					continue;

				if (xp < xCenter - r || xp > xCenter + r ||
				    zp < zCenter - r || zp > zCenter + r) {
					c.unbuild();
					numBuilt--;
				}
			}
		}
	}

	final Chunk createChunkUnsafe(int x, int z)
	{
		x -= xOff;
		z -= zOff;

		if (chunk[x][z] !is null)
			return chunk[x][z];

		return chunk[x][z] = new Chunk(vt, vt.w, x+xOff, z+zOff);
	}

	final Chunk getChunkUnsafe(int x, int z)
	{
		x -= xOff;
		z -= zOff;

		if (x < 0 || z < 0)
			return null;
		else if (x >= width || z >= depth)
			return null;

		return chunk[x][z];
	}

	final Chunk getChunk(int x, int z)
	{
		x -= xOff;
		z -= zOff;

		if (x < 0 || z < 0)
			return null;
		else if (x >= width || z >= depth)
			return null;

		return chunk[x][z];
	}
}

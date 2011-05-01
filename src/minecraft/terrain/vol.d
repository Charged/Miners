// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.terrain.vol;

// For SDL get ticks
import lib.sdl.sdl;

import charge.charge;

import minecraft.gfx.vbo;
import minecraft.gfx.renderer;
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
	const int width = 64;
	const int depth = 64;
	const int view_radi = 16;
	int save_build_i;
	int save_build_j;
	int save_build_k;
	int xOff;
	int zOff;
	Chunk[depth][width] chunk;
	ChunkVBOGroupArray cvga;
	ChunkVBOGroupRigidMesh cvgrm;
	ChunkVBOGroupCompactMesh cvgcm;
	BuildTypes currentBuildType;
	char[] dir;

	bool buildIndexed; // The renderer supports array textures.


	this(GameWorld w, char[] dir, GfxTexture tex)
	{
		super(w);

		this.xOff = 0;
		this.zOff = 0;
		this.dir = dir;
		this.tex = tex;

		// Make the code not early out.
		currentBuildType = BuildTypes.Array;

		// Setup the groups
		setBuildType(BuildTypes.RigidMesh);

		// Make sure all state is setup correctly
		setCenter(0, 0);
	}

	~this() {
		foreach(row; chunk)
			foreach(c; row)
				delete c;
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

	void setBuildType(BuildTypes type)
	{
		if (type == currentBuildType)
			return;

		currentBuildType = type;

		// Unbuild all the meshes.
		for (int x; x < width; x++) {
			for (int z; z < depth; z++) {
				auto c = chunk[x][z];
				if (c is null)
					continue;
				c.unbuild();
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
		x -= xOff;
		z -= zOff;

		if (x < 0 || z < 0)
			return null;
		else if (x >= width || z >= depth)
			return null;
		else
			return chunk[x][z];
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
		Chunk[depth][width] copy;
		int xNewOff = xNew - (width / 2);
		int zNewOff = zNew - (depth / 2);

		for (int x; x < width; x++) {
			for (int z; z < depth; z++) {
				auto c = chunk[x][z];
				if (c is null)
					continue;
				int xPos = c.xPos - xNewOff;
				int zPos = c.zPos - zNewOff;
				if (xPos < 0 || zPos < 0 || xPos >= width || zPos >= depth) {
					delete c;
				} else {
					copy[xPos][zPos] = c;
				}
			}
		}

		xOff = xNewOff;
		zOff = zNewOff;
		for (int x; x < width; x++) {
			for (int z; z < depth; z++) {
				auto c = copy[x][z];
				if (c is null)
					chunk[x][z] = null;
				else
					chunk[x][z] = c;
			}
		}

		const hW = width/2;
		const hD = depth/2;
		for (int x; x < width; x++) {
			for (int z; z < depth; z++) {
				const int r = view_radi - 1;
				auto c = chunk[x][z];
				if (c is null)
					continue;
				if (x < hW - r || x > hW + r ||
				    z < hD - r || z > hD + r)
					c.unbuild();
			}
		}

		charge.sys.resource.Pool().collect();

		// Reset the saved position for the buildOne function
		save_build_i = 0;
		save_build_j = 0;
		save_build_k = 0;
	}

	bool buildOne()
	{
		const hW = width/2;
		const hD = depth/2;

		bool dob(int x, int z) {
			x += hW;
			z += hD;

			auto c = chunk[x][z];
			if (c !is null && c.gfx/* !is null*/)
				return false;

			for (int i = x-1; i < x+2; i++) {
				for (int j = z-1; j < z+2; j++) {
					if (chunk[i][j] is null)
						chunk[i][j] = new Chunk(this, w, i+xOff, j+zOff);
				}
			}

			chunk[x][z].build();
			return true;
		}

		int offset(int i) { i++; return i & 1 ? -(i >> 1) : (i >> 1); }
		int num(int i) { i++; return i | 1; }

		// Restart from save position
		int i = save_build_i;
		int j = save_build_j;
		int k = save_build_k;
		for (; i < view_radi * 2 - 1; i++) {
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


}

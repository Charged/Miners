// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.terrain.common;

import std.math;

import charge.charge;

import miners.types;
import miners.options;
import miners.gfx.vbo;

class Terrain : public GameActor
{
private:
	mixin SysLogging;

protected:
	Options opts;
	int view_radii;
	TerrainBuildTypes currentBuildType;

public:
	ChunkVBOGroupRigidMesh cvgrm;
	ChunkVBOGroupCompactMesh cvgcm;
	bool buildIndexed; // The renderer supports array textures.

public:
	this(GameWorld w, Options opts)
	{
		super(w);
		this.opts = opts;

		view_radii = 250 / 16 + 1;

		// Setup the groups
		buildIndexed = opts.rendererBuildIndexed;
		doBuildTypeChange(opts.rendererBuildType);

		opts.renderer ~= &setBuildType;
	}

	~this() {
		delete cvgrm;
		delete cvgcm;
	}

	abstract void setCenter(int xNew, int zNew);
	abstract void setViewRadii(int radii);
	abstract void setBuildType(TerrainBuildTypes type, char[] name);
	abstract bool buildOne();

	abstract void resetBuild();
	abstract void markVolumeDirty(int x, int y, int z, uint w, uint h, uint d);

	abstract Block opIndex(int x, int y, int z);
	abstract Block opIndexAssign(Block b, int x, int y, int z);

	abstract ubyte getType(int x, int y, int z);
	abstract ubyte setType(ubyte type, int x, int y, int z);

protected:
	void doBuildTypeChange(TerrainBuildTypes type)
	{
		this.currentBuildType = type;
		delete cvgrm;
		delete cvgcm;

		cvgrm = null; cvgcm = null;

		switch(type) {
		case TerrainBuildTypes.RigidMesh:
			cvgrm = new ChunkVBOGroupRigidMesh(w.gfx);
			cvgrm.getMaterial()["tex"] = opts.terrainTexture;
			cvgrm.getMaterial()["fake"] = true;
			break;
		case TerrainBuildTypes.CompactMesh:
			cvgcm = new ChunkVBOGroupCompactMesh(w.gfx);
			cvgcm.getMaterial()["tex"] =
				buildIndexed ? opts.terrainTextureArray : opts.terrainTexture;
			cvgcm.getMaterial()["fake"] = true;
			// No need to setup material handled by the renderer
			break;
		default:
			assert(false);
		}
	}
}

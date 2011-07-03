// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.terrain.common;

import std.math;

import charge.charge;

import minecraft.types;
import minecraft.gfx.vbo;
import minecraft.gfx.renderer;
import minecraft.actors.helper;

class Terrain : public GameActor
{
private:
	mixin SysLogging;

protected:
	ResourceStore rs;
	int view_radii;
	TerrainBuildTypes currentBuildType;

public:
	ChunkVBOGroupRigidMesh cvgrm;
	ChunkVBOGroupCompactMesh cvgcm;
	bool buildIndexed; // The renderer supports array textures.

public:
	this(GameWorld w, ResourceStore rs)
	{
		super(w);
		this.rs = rs;

		view_radii = 250 / 16 + 1;

		// Setup the groups
		doBuildTypeChange(TerrainBuildTypes.RigidMesh);
	}

	~this() {
		delete cvgrm;
		delete cvgcm;
	}

	abstract void setCenter(int xNew, int zNew);
	abstract void setViewRadii(int radii);
	abstract void setBuildType(TerrainBuildTypes type);
	abstract bool buildOne();

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
			cvgrm.getMaterial()["tex"] = rs.terrainTexture;
			cvgrm.getMaterial()["fake"] = true;
			break;
		case TerrainBuildTypes.CompactMesh:
			cvgcm = new ChunkVBOGroupCompactMesh(w.gfx);
			cvgcm.getMaterial()["tex"] =
				buildIndexed ? rs.terrainTextureArray : rs.terrainTexture;
			cvgcm.getMaterial()["fake"] = true;
			// No need to setup material handled by the renderer
			break;
		default:
			assert(false);
		}
	}
}

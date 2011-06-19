// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.terrain.common;

import std.math;

import charge.charge;

import minecraft.gfx.vbo;
import minecraft.gfx.renderer;

class Terrain : public GameActor
{
private:
	mixin SysLogging;

protected:
	enum BuildTypes {
		RigidMesh,
		CompactMesh,
	}

	GfxTexture tex;
	int view_radii;
	BuildTypes currentBuildType;

public:
	ChunkVBOGroupRigidMesh cvgrm;
	ChunkVBOGroupCompactMesh cvgcm;
	bool buildIndexed; // The renderer supports array textures.

public:
	this(GameWorld w, GfxTexture tex)
	{
		super(w);
		this.tex = tex;

		view_radii = 250 / 16 + 1;

		// Setup the groups
		doBuildTypeChange(BuildTypes.RigidMesh);
	}

	~this() {
		delete cvgrm;
		delete cvgcm;
	}

	abstract void setCenter(int xNew, int zNew);
	abstract void setViewRadii(int radii);
	abstract void setBuildType(BuildTypes type);
	abstract bool buildOne();

protected:
	void doBuildTypeChange(BuildTypes type)
	{
		this.currentBuildType = type;
		delete cvgrm;
		delete cvgcm;

		cvgrm = null; cvgcm = null;

		switch(type) {
		case BuildTypes.RigidMesh:
			cvgrm = new ChunkVBOGroupRigidMesh(w.gfx);
			cvgrm.getMaterial()["tex"] = tex;
			cvgrm.getMaterial()["fake"] = true;
			break;
		case BuildTypes.CompactMesh:
			cvgcm = new ChunkVBOGroupCompactMesh(w.gfx);
			// No need to setup material handled by the renderer
			break;
		default:
			assert(false);
		}
	}
}

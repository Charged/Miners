// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.terrain.common;

import std.math;

import charge.charge;

import miners.types;
import miners.options;
import miners.gfx.vbo;
import miners.builder.interfaces;


class Terrain : public GameActor
{
public:
	ChunkVBOGroupRigidMesh cvgrm;
	ChunkVBOGroupCompactMesh cvgcm;
	bool buildIndexed; // The renderer supports array textures.
	MeshBuilder builder;
	bool useClassicTexture;

protected:
	Options opts;
	int view_radii;
	TerrainBuildTypes currentBuildType;

private:
	mixin SysLogging;

public:
	this(GameWorld w, Options opts, MeshBuilder builder, bool useClassicTexture)
	{
		super(w);
		this.opts = opts;
		this.builder = builder;
		this.useClassicTexture = useClassicTexture;

		// Setup the groups
		buildIndexed = opts.rendererBuildIndexed;
		doBuildTypeChange(opts.rendererBuildType);

		setViewDistance(opts.viewDistance());

		opts.renderer ~= &setBuildType;
		opts.viewDistance ~= &setViewDistance;
	}

	~this()
	{
		delete cvgrm;
		delete cvgcm;
		delete builder;
	}

	abstract void setCenter(int xNew, int zNew);
	abstract void setBuildType(TerrainBuildTypes type, char[] name);
	abstract bool buildOne();
	abstract void unbuildAll();

	abstract void resetBuild();
	abstract void markVolumeDirty(int x, int y, int z, uint w, uint h, uint d);

	abstract Block opIndex(int x, int y, int z);
	abstract Block opIndexAssign(Block b, int x, int y, int z);

	abstract ubyte getType(int x, int y, int z);
	abstract ubyte setType(ubyte type, int x, int y, int z);

protected:
	abstract void setViewRadii(int radii);

	void doBuildTypeChange(TerrainBuildTypes type)
	{
		this.currentBuildType = type;
		delete cvgrm;
		delete cvgcm;

		cvgrm = null; cvgcm = null;
		GfxTexture t = opts.terrain();
		GfxTextureArray ta = opts.terrainArray();

		if (useClassicTexture) {
			t = opts.classicTerrain();
			ta = opts.classicTerrainArray();
		}

		switch(type) {
		case TerrainBuildTypes.RigidMesh:
			cvgrm = new ChunkVBOGroupRigidMesh(w.gfx);
			auto m = cvgrm.getMaterial();
			m["tex"] = t;
			m["fake"] = true;
			break;
		case TerrainBuildTypes.CompactMesh:
			cvgcm = new ChunkVBOGroupCompactMesh(w.gfx);
			auto m = cvgcm.getMaterial();
			m["tex"] = buildIndexed ? ta : t;
			m["fake"] = true;
			break;
		default:
			assert(false);
		}
	}

private:
	void setViewDistance(double dist)
	{
		view_radii = cast(int)(dist / 16 + 2);
		setViewRadii(view_radii);
	}
}

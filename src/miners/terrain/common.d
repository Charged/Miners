// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.terrain.common;

import charge.charge;

import miners.types;
import miners.defines;
import miners.options;
import miners.gfx.vbo;
import miners.builder.workspace;
import miners.builder.interfaces;


class Terrain : GameActor
{
public:
	ChunkVBOGroupCompactMesh[BuildMeshes] cvgcm;
	bool buildIndexed; // The renderer supports array textures.
	MeshBuilder builder;
	TerrainTextures texs;

protected:
	Options opts;
	int view_radii;
	TerrainBuildTypes currentBuildType;

private:
	mixin SysLogging;

public:
	this(GameWorld w, Options opts, MeshBuilder builder, TerrainTextures texs)
	{
		super(w);
		this.opts = opts;
		this.texs = texs;
		this.builder = builder;

		// Setup the groups
		buildIndexed = opts.rendererBuildIndexed;
		doBuildTypeChange(opts.rendererBuildType);

		setViewDistance(opts.viewDistance());

		opts.renderer ~= &setBuildType;
		opts.viewDistance ~= &setViewDistance;
	}

	~this()
	{
		foreach(g; cvgcm)
			delete g;
		delete builder;
	}

	abstract void setCenter(int xNew, int yNew, int zNew);
	abstract void setBuildType(TerrainBuildTypes type, string name);
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
		foreach(g; cvgcm)
			delete g;

		switch(type) {
		case TerrainBuildTypes.RigidMesh:
			// XXX Disabled for now
			break;
		case TerrainBuildTypes.CompactMesh:
			foreach(int i, ref g; cvgcm) {
				g = new ChunkVBOGroupCompactMesh(w.gfx);
				auto m = g.getMaterial();
				m["tex"] = buildIndexed ? texs.ta : texs.t;
				m["fake"] = true;
				if (i == 1)
					m["stipple"] = true;
			}
			break;
		default:
			assert(false);
		}
	}

package:
	void doUpdates(GfxVBO[] vbos, WorkspaceData *ws, int x, int y, int z)
	{
		if (currentBuildType != TerrainBuildTypes.CompactMesh)
			return;

		GfxVBO[BuildMeshes] old = vbos;

		builder.updateCompactMesh(vbos, buildIndexed, ws, x, y, z);

		foreach(int i, v; vbos) {
			auto o = old[i];
			auto g = cvgcm[i];

			if (o !is v) {
				if (o !is null)
					g.remove(o);
				if (v !is null)
					g.add(v, x, y, z);
			}
		}
	}

	void doUnbuild(GfxVBO[] vbos, int x, int y, int z)
	{
		if (currentBuildType != TerrainBuildTypes.CompactMesh)
			return;

		foreach(int i, vbo; vbos)
			if (vbo !is null)
				cvgcm[i].remove(vbo);

		foreach(ref v; vbos)
			v = null;
	}

private:
	void setViewDistance(double dist)
	{
		view_radii = cast(int)(dist / 16 + 2);
		setViewRadii(view_radii);
	}
}

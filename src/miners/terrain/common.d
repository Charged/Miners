// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.terrain.common;

import std.math;

import charge.charge;

import miners.types;
import miners.options;
import miners.gfx.vbo;
import miners.builder.workspace;
import miners.builder.interfaces;


class Terrain : public GameActor
{
public:
	ChunkVBOGroupCompactMesh[2] cvgcm;
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
		foreach(g; cvgcm)
			delete g;
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
		foreach(g; cvgcm)
			delete g;

		GfxTexture t = opts.terrain();
		GfxTextureArray ta = opts.terrainArray();

		if (useClassicTexture) {
			t = opts.classicTerrain();
			ta = opts.classicTerrainArray();
		}

		switch(type) {
		case TerrainBuildTypes.RigidMesh:
			// XXX Disabled for now
			break;
		case TerrainBuildTypes.CompactMesh:
			foreach(int i, ref g; cvgcm) {
				g = new ChunkVBOGroupCompactMesh(w.gfx);
				auto m = g.getMaterial();
				m["tex"] = buildIndexed ? ta : t;
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
	void doUpdates(GfxVBO[] vbosIn, WorkspaceData *ws, int x, int y, int z)
	{
		if (currentBuildType != TerrainBuildTypes.CompactMesh)
			return;

		ChunkVBOCompactMesh[8] old;
		auto vbos = cast(ChunkVBOCompactMesh[])vbosIn;
		old[0 .. vbos.length] = vbos;

		builder.update(vbos, buildIndexed, ws, x, y, z);

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

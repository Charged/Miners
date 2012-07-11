// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.builder.builder;

import miners.defines;
import miners.gfx.vbo;

import miners.builder.types;
import miners.builder.packers;
import miners.builder.workspace;
import miners.builder.interfaces;


/**
 * Main implementor of the MeshBuilder interface.
 *
 * Classic and Beta both subclass this class to
 * make it build classic or beta terrains.
 */
abstract class MeshBuilderBuildArray : public MeshBuilder
{
public:
	BuildFunction *buildArray;
	BuildBlockDescriptor *tile;
	WorkspaceData *ws;
	PackerCompact*[2] packers;

public:
	this(BuildFunction *buildArray, BuildBlockDescriptor *tile)
	{
		this.buildArray = buildArray;
		this.tile = tile;
		this.packers[0] = PackerCompact.cAlloc(128 * 1024);
		this.packers[1] = PackerCompact.cAlloc(128 * 1024);
		foreach(int i, p; packers[0 .. $-1])
			p.base.next = &packers[i+1].base;
	}

	~this()
	{
		freeMemory();
	}


	/*
	 *
	 * MeshBuilder interface function.
	 *
	 */


	WorkspaceData* getWorkspace()
	{
		if (ws is null)
			return WorkspaceData.malloc(tile);

		auto tmp = ws;
		ws = null;
		return tmp;
	}

	void putWorkspace(WorkspaceData *ws)
	{
		if (this.ws is null)
			this.ws = ws;
		else
			ws.free();
	}

	void update(ChunkVBOCompactMesh vbos[], bool indexed,
	            WorkspaceData *data,
	            int xPos, int yPos, int zPos)
	{
		int xOff = xPos * BuildWidth;
		int yOff = yPos * BuildHeight;
		int zOff = zPos * BuildDepth;

		return update(vbos, indexed, data, xPos, yPos, zPos, xOff, yOff, zOff);
	}


	/*
	 *
	 * Internal functions.
	 *
	 */


	void freeMemory()
	{
		if (ws !is null) {
			ws.free();
			ws = null;
		}

		foreach(ref p; packers) {
			if (p is null)
				continue;
			p.cFree();
			p = null;
		}
	}

	/**
	 * Update a RigidMesh from a WorkspaceData.
	 */
	ChunkVBORigidMesh update(ChunkVBORigidMesh vbo,
			WorkspaceData *data,
			int xPos, int yPos, int zPos,
			int xOffArg, int yOffArg, int zOffArg)
	{
		// XXX Disabled for now.
		return null;
	}

	/**
	 * Build and update a CompactMesh from a WorkspaceData.
	 */
	ChunkVBOCompactMesh update(ChunkVBOCompactMesh vbo, bool indexed,
	                           WorkspaceData *data,
	                           int xPos, int yPos, int zPos,
	                           int xOffArg, int yOffArg, int zOffArg)
	{
		packers[0].ctor(xOffArg, yOffArg, zOffArg, indexed);
		packers[1].ctor(xOffArg, yOffArg, zOffArg, indexed);

		auto packer = packers[0];
		doBuildMesh(&packer.base, buildArray, data);

		auto verts = packer.getVerts();
		if (verts.length == 0)
			return null;

		if (vbo is null)
			return ChunkVBOCompactMesh(verts, xPos, yPos, zPos);

		vbo.update(verts);
		return vbo;
	}

	void update(ChunkVBOCompactMesh[] vbos, bool indexed,
	            WorkspaceData *data,
	            int xPos, int yPos, int zPos,
	            int xOffArg, int yOffArg, int zOffArg)
	{
		packers[0].ctor(xOffArg, yOffArg, zOffArg, indexed);
		packers[1].ctor(xOffArg, yOffArg, zOffArg, indexed);

		auto packer = packers[0];
		doBuildMesh(&packer.base, buildArray, data);

		assert(vbos.length <= packers.length);
		foreach(int i, ref v; vbos) {
			auto verts = packers[i].getVerts();
			if (verts.length == 0) {
				v = null;
				continue;
			}

			if (v is null)
				v = ChunkVBOCompactMesh(verts, xPos, yPos, zPos);

			v.update(verts);
		}
	}

	/**
	 * Builds a mesh packed with p from data in data.
	 */
	static void doBuildMesh(Packer *p, BuildFunction *buildArray, WorkspaceData *data)
	{
		for (int x; x < BuildWidth; x++) {
			for (int y; y < BuildHeight; y++) {
				for (int z; z < BuildDepth; z++) {
					ubyte type = data.get(x, y, z);
					buildArray[type](p, x, y, z, type, data);
				}
			}
		}
	}
}

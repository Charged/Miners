// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.terrain.finite;

import charge.charge;

import minecraft.types;
import minecraft.options;
import minecraft.gfx.vbo;
import minecraft.gfx.imports;
import minecraft.terrain.common;
import minecraft.terrain.builder;
import minecraft.terrain.workspace;

/**
 * Finite terrain that doesn't doesn't handle growing as good
 * as infinite terrain (like alpha/beta). Used for classic levels.
 *
 * Has a minimum size of 16x128x16.
 */
class FiniteTerrain : public Terrain
{
private:
	mixin SysLogging;

public:
	int xSize;
	int ySize;
	int zSize;

	/** Height of meta data in bytes */
	int yMetaSize;

	/**
	 * Chunks here refere to VBO's.
	 */
	uint xNumChunks;
	uint yNumChunks;
	uint zNumChunks;

	uint xStride;
	uint yStride;
	uint zStride;

	size_t sizeBlocks;
	size_t sizeData;

protected:
	ubyte *blocks;
	ubyte *data;

	cMemoryArray!(ubyte) store;

	GfxVBO vbos[];

	int xSaved;
	int ySaved;
	int zSaved;

public:
	this(GameWorld w, Options opts, int x, int y, int z)
	{
		l.info("Created (%sx%sx%s)", x, y, z);

		if (x < 1 || y < 1 || z < 1 )
			throw new Exception("Size must be at least 1x1x1 for FiniteTerrain");

		xSize = x;
		ySize = y;
		zSize = z;

		yMetaSize = ySize / 2 + (ySize % 2);

		xNumChunks = xSize / 16;
		yNumChunks = ySize / 128;
		zNumChunks = zSize / 16;

		// Add a extra chunk if nSize % 16 != 0
		// y axis is aligned to 128 instead due to vbo size.
		if (xNumChunks * 16 < xSize)
			xNumChunks++;
		if (yNumChunks * 128 < ySize)
			yNumChunks++;
		if (zNumChunks * 16 < zSize)
			zNumChunks++;

		vbos.length = xNumChunks * yNumChunks * zNumChunks;

		xStride = ySize;
		yStride = 1;
		zStride = ySize * xSize;

		sizeBlocks = xSize * ySize * zSize;
		sizeData = xSize * yMetaSize * zSize;;

		store.length = sizeBlocks + sizeData;

		blocks = store.ptr;
		data = store.ptr + sizeBlocks;

		super(w, opts);
	}

	~this()
	{
		unbuildAll();
		store.free();
	}


	/*
	 *
	 * Block and metadata accessors.
	 *
	 */


	final void setBlocksAndMeta(ubyte* blocks, ubyte *meta)
	{
		if (blocks)
			this.blocks[0 .. sizeBlocks] = blocks[0 .. sizeBlocks];
		if (meta)
			this.data[0 .. sizeData] = meta[0 .. sizeData];
	}

	final void setMeta(int x, int y, int z, ubyte meta)
	{
		auto mPtr = getMetaPointer(x, y, z);
		auto d = *mPtr;

		if (meta == 1)
			assert((this)[x, y, z] == 35);

		if (y % 2 == 0)
			*mPtr = (d & 0xf0) | (0x0f & meta);
		else
			*mPtr = (d & 0x0f) | (cast(ubyte)(meta << 4) & 0xf0);
	}

	final ubyte opIndexAssign(ubyte data, int x, int y, int z)
	{
		blocks[(xSize * z + x) * ySize + y] = data;
		return data;
	}

	final ubyte opIndex(int x, int y, int z)
	{
		return blocks[(xSize * z + x) * ySize + y];
	}

	/**
	 * Get a pointer to the block at location.
	 */
	final ubyte *getBlockPointer(int x, int y, int z)
	{
		return &blocks[(xSize * z + x) * ySize + y];
	}

	/**
	 * Get a pointer to the metadata at location,
	 *
	 * Will return the byte that the metadata is located in.
	 * So yPos = (y / 2).
	 */
	final ubyte *getMetaPointer(int x, int y, int z)
	{
		return &data[(xSize * z + x) * yMetaSize + (y / 2)];
	}

	/**
	 * Get a WorkspaceData copy of blocks and metadata at the given
	 * location in "chunk" coords.
	 *
	 * Only handles nPos >= 0.
	 */
	WorkspaceData* extractWorkspace(int xPos, int yPos, int zPos)
	{
		auto ws = WorkspaceData.malloc();

		assert(xPos >= 0 && yPos >= 0 && zPos >= 0);

		int xEnd = ws.ws_width;
		int yEnd = ws.ws_height;
		int zEnd = ws.ws_depth;

		int xOff = xPos * 16 - 1;
		int yOff = yPos * 128 - 1;
		int yOffMeta = yPos * 128;
		int zOffStart = zPos * 16 - 1;

		int startX, y, yMeta, startZ;

		// Handle underflow
		if (xOff < 0) {
			startX++;
			xOff++;
		}
		if (yOff < 0) {
			y = 1;
			yMeta = 1;
			yEnd--;
			yOff++;
		}
		if (zOffStart < 0) {
			startZ++;
			zOffStart++;
		}

		// Handle overflow
		if (xOff + xEnd >= xSize)
			xEnd = xSize - xOff;
		if (yOff + yEnd >= ySize)
			yEnd = ySize - yOff;
		if (zOffStart + zEnd >= zSize)
			zEnd = zSize - zOffStart;

		// Need to include the whole last byte
		int yMetaEnd = yEnd / 2 + (yEnd % 2);

		// Could be smarter about this
		ws.zero();

		for (int x = startX; x < xEnd; x++, xOff++) {
			int zOff = zOffStart;
			for (int z = startZ; z < zEnd; z++, zOff++) {
				assert(xPos >= 0 && yPos >= 0 && zPos >= 0);

				auto ptr = getBlockPointer(xOff, yOff, zOff);
				ws.blocks[x][z][y .. y + yEnd] = ptr[0 .. yEnd];
				ptr = getMetaPointer(xOff, yOff, zOff);
				ws.data[x][z][yMeta .. yMeta + yMetaEnd] = ptr[0 .. yMetaEnd];
			}
		}

		return ws;
	}


	/*
	 *
	 * Inhereted terrain methods.
	 *
	 */


	/**
	 * Set the center of the view circle.
	 *
	 * XXX: Currently not implemented.
	 */
	void setCenter(int xNew, int zNew)
	{

	}

	/**
	 * Set the number of chunks around the center to be built.
	 *
	 * XXX: Currently not implemented.
	 */
	void setViewRadii(int radii)
	{

	}

	void setBuildType(TerrainBuildTypes type, char[] name)
	{
		if (currentBuildType == type)
			return;

		unbuildAll();

		doBuildTypeChange(type);

		buildReset();
	}

	/**
	 * Start over from the begining when building "chunk" meshes.
	 */
	void buildReset()
	{
		xSaved = ySaved = zSaved = 0;
	}

	/**
	 * Build a single "chunk" mesh.
	 */
	bool buildOne()
	{
		int x = xSaved;
		int y = ySaved;
		int z = zSaved;

		for (; x < xNumChunks; x++) {
			for (; z < zNumChunks; z++) {
				for (; y < yNumChunks; y++) {
					if (!build(x, y, z))
						continue;
					xSaved = x;
					ySaved = y++;
					zSaved = z;
					return true;
				}
				y = 0;
			}
			z = 0;
		}

		xSaved = x;
		ySaved = y;
		zSaved = z;

		return false;
	}

	void unbuildAll()
	{
		for (int x; x < xNumChunks; x++)
			for (int z; z < zNumChunks; z++)
				for (int y; y < yNumChunks; y++)
					unbuild(x, y, z);
	}


protected:
	/*
	 *
	 * Internal functions.
	 *
	 */


	bool build(int x, int y, int z)
	{
		auto ws = extractWorkspace(x, y, z);
		GfxVBO v;

		if (getVBO(x, y, z) !is null)
			return false;

		if (cvgrm !is null) {
			v = buildRigidMeshFromChunk(ws, x, y, z);

			setVBO(v, x, y, z);
			if (v !is null)
				cvgrm.add(v, x, y, z);
		}

		if (cvgcm !is null) {
			if (buildIndexed)
				v = buildCompactMeshIndexedFromChunk(ws, x, y, z);
			else
				v = buildCompactMeshFromChunk(ws, x, y, z);

			setVBO(v, x, y, z);
			if (v !is null)
				cvgcm.add(v, x, y, z);
		}

		return true;
	}

	void unbuild(int x, int y, int z)
	{
		auto v = getVBO(x, y, z);

		if (v is null)
			return;

		setVBO(null, x, y, z);

		if (cvgrm !is null)
			cvgrm.remove(v);
		if (cvgcm !is null)
			cvgcm.remove(v);
	}

	final void setVBO(GfxVBO vbo, int x, int y, int z)
	{
		vbos[(xNumChunks * z + x) * yNumChunks + y] = vbo;
	}

	final GfxVBO getVBO(int x, int y, int z)
	{
		return vbos[(xNumChunks * z + x) * yNumChunks + y];
	}
}

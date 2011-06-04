// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.terrain.chunk;

import std.math;

import charge.charge;
import charge.math.ints;

import minecraft.importer;
import minecraft.gfx.vbo;
import minecraft.gfx.imports;
import minecraft.gfx.renderer;
import minecraft.terrain.vol;
import minecraft.terrain.data;
import minecraft.terrain.builder;

class Chunk
{
public:
	int xPos;
	int zPos;

	int xOff;
	int yOff;
	int zOff;

	// Tracking block and gfx status
	bool empty; /**< The chunk is full of air and the memory is shared */
	bool valid; /**< The chunk has valid data (okay to build mesh) */
	bool dirty; /**< The data in the chunk has changed */
	bool gfx; /**< The chunk has been built */
	bool loaded; /**< The chunk has been loaded of disk (can still be empty) */

	const int width = 16;
	const int height = 128;
	const int depth = 16;

	const int blocks_size = width * height * depth;
	const int data_size = blocks_size;

protected:
	GameWorld w;
	VolTerrain vt;

	// VBO's.
	ChunkVBOArray cva;
	ChunkVBORigidMesh cvrm;
	ChunkVBOCompactMesh cvcm;

	// Blocks and Data.
	static ubyte *empty_blocks; /**< so we don't need to allocate data for empty chunks */
	ubyte *blocks;
	ubyte *data;

	static int used_mem;

	GfxPointLight lights[];

public:
	this(VolTerrain vt, GameWorld w, int xPos, int zPos)
	{
		this.w = w;
		this.vt = vt;
		this.xPos = xPos;
		this.zPos = zPos;
		this.xOff = xPos * 16;
		this.yOff = 0;
		this.zOff = zPos * 16;

		this.dirty = true;

		// Setup pointers
		this.empty = true;
		emptyChunk();
	}

	~this()
	{
		unbuild();
		freeBlocksAndData();
	}

private:
	static this()
	{
		empty_blocks = cast(ubyte*)std.c.stdlib.malloc(blocks_size);
		std.c.string.memset(empty_blocks, 0, blocks_size);
		used_mem += blocks_size;
	}

	static ~this()
	{
		std.c.stdlib.free(empty_blocks);
		used_mem -= blocks_size;
	}

	/**
	 * If the chunk is not empty free the blocks and data
	 * arrays that where given to us.
	 */
	void freeBlocksAndData()
	{
		if (!empty) {
			std.c.stdlib.free(blocks);
			std.c.stdlib.free(data);
			used_mem -= (blocks_size + data_size);
		}
	}

public:
	/**
	 * Give a block and data array to this chunk.
	 *
	 * The two arrays must be allocted via C lib *alloc function.
	 * It is now the chunks responsibility to free the data.
	 */
	void giveBlocksAndData(ubyte *blocks, ubyte *data)
	{
		freeBlocksAndData();

		this.empty = false;
		this.blocks = blocks;
		this.data = data;
		used_mem += blocks_size + data_size;
	}

	/**
	 * Allocate blocks and data arrays and set empty to false if empty.
	 *
	 * The allocated arrays will be zero (air). Nothing will be done if
	 * already non-empty. While just being filled with air could count as
	 * empty, empty in this case means that blocks and data are shared
	 * between chunks and is read-only.
	 */
	void allocBlocksAndData()
	{
		if (!empty)
			return;

		empty = false;
		blocks = cast(ubyte*)std.c.stdlib.malloc(blocks_size);
		data = cast(ubyte*)std.c.stdlib.malloc(data_size);
		std.c.string.memset(blocks, 0, blocks_size);
		std.c.string.memset(data, 0, data_size);
		used_mem += blocks_size + data_size;
	}

	/**
	 * Free any data allocated and mark the chunk as empty.
	 *
	 * Read access is still possible but will only return 0 (air)
	 * and for pointer access pointers to a shared array empty array.
	 *
	 * So make sure to not write to a emptied chunk. Newly allocated
	 * chunks are empty, call allocBlocksAndData to alloc writable data.
	 */
	void emptyChunk()
	{
		freeBlocksAndData();

		blocks = empty_blocks;
		data = empty_blocks;
		empty = true;
	}

	/**
	 * Should this chunk be built;
	 */
	final bool shouldBuild()
	{
		return !gfx || dirty;
	}

	/**
	 * Mark this chunk as dirty.
	 */
	final void markDirty()
	{
		dirty = true;
	}

	/**
	 * Mark this chunk and all neighbours as dirty.
	 */
	void markNeighborsDirty()
	{
		Chunk c;

		void mark(int x, int z) {
			c = vt.getChunk(x, z);
			if (c !is null)
				c.markDirty();
		}

		mark(xPos-1, zPos-1);
		mark(xPos-1, zPos  );
		mark(xPos-1, zPos+1);

		mark(xPos,   zPos-1);
		mark(xPos,   zPos+1);

		mark(xPos+1, zPos-1);
		mark(xPos+1, zPos  );
		mark(xPos+1, zPos+1);

		markDirty();
	}

	void build()
	{
		gfx = true;

		if (empty)
			return;

		if (vt.cvgrm !is null) {
			cvrm = buildRigidMeshFromChunk(this);
			if (cvrm !is null)
				vt.cvgrm.add(cvrm, xPos, zPos);
		}

		if (vt.cvgcm !is null) {
			if (vt.buildIndexed)
				cvcm = buildCompactMeshIndexedFromChunk(this);
			else
				cvcm = buildCompactMeshFromChunk(this);

			if (cvcm !is null)
				vt.cvgcm.add(cvcm, xPos, zPos);
		}

		if (vt.cvga !is null) {
			// TODO: Disabled for now
			cva = null;//buildArrayFromChunk(this);
			if (cva !is null)
				vt.cvga.add(cva, xPos, zPos);
		}
	}

	void unbuild()
	{
		foreach(l; lights) {
			w.gfx.remove(l);
			delete l;
		}
		lights = null;
		if (gfx) {

			if (cvrm) {
				vt.cvgrm.remove(cvrm);
				cvrm = null;
			}
			if (cvcm !is null) {
				vt.cvgcm.remove(cvcm);
				cvcm = null;
			}
			if (cva !is null) {
				vt.cvga.remove(cva);
				cva = null;
			}
			gfx = false;
		}
	}


	/*
	 * Accessors to blocks.
	 */


	final ubyte get(int x, int y, int z)
	{
		if (y < 0)
			y = 0;
		else if (y >= height)
			return 0;

		if (x < 0 || z < 0)
			return vt.get(xPos, zPos, x, y, z);
		else if (x >= width || z >= depth)
			return vt.get(xPos, zPos, x, y, z);
		else
			return getUnsafe(x, y, z);
	}

	final ubyte getUnsafe(int x, int y, int z)
	{
		return blocks[x * depth * height + z * height + y];
	}

	final ubyte* getPointerY(int x, int z)
	{
		if (x < 0 || z < 0)
			return vt.getPointerY(xPos, zPos, x, z);
		else if (x >= width || z >= depth)
			return vt.getPointerY(xPos, zPos, x, z);
		else
			return getUnsafePointerY(x, z);
	}

	final ubyte* getUnsafePointerY(int x, int z)
	{
		return &blocks[x * depth * height + z * height];
	}


	/*
	 * Accessors to data.
	 */


	final ubyte getDataUnsafe(int x, int y, int z)
	{
		ubyte d = data[x * depth * height / 2 + z * height / 2  + y / 2];
		if (y % 2 == 0)
			return d & 0xf;
		return cast(ubyte)(d >> 4);
	}

	final ubyte* getDataPointerY(int x, int z)
	{
		if (x < 0 || z < 0)
			return vt.getDataPointerY(xPos, zPos, x, z);
		else if (x >= width || z >= depth)
			return vt.getDataPointerY(xPos, zPos, x, z);
		else
			return getDataUnsafePointerY(x, z);
	}

	final ubyte* getDataUnsafePointerY(int x, int z)
	{
		return &data[x * depth * height/2 + z * height/2];
	}

}

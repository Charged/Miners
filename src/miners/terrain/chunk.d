// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.terrain.chunk;

import std.math;

import charge.charge;
import charge.math.ints;

import miners.defines;
import miners.gfx.vbo;
import miners.gfx.imports;
import miners.gfx.renderer;
import miners.terrain.beta;
import miners.builder.data;
import miners.builder.builder;
import miners.builder.workspace;

class Chunk
{
public:
	int xPos;
	int yPos;
	int zPos;

	// Tracking block and gfx status
	bool empty; /**< The chunk is full of air and the memory is shared */
	bool valid; /**< The chunk has valid data (okay to build mesh) */
	bool dirty; /**< The data in the chunk has changed */
	bool gfx; /**< The chunk has been built */
	bool loaded; /**< The chunk has been loaded of disk (can still be empty) */

	// This chunk size, seperate from BuildX sizes.
	const int width = 16;
	const int height = 128;
	const int depth = 16;

	const int blocks_size = width * height * depth;
	const int data_size = blocks_size;

protected:
	GameWorld w;
	BetaTerrain bt;

	// VBO's.
	GfxVBO vbos[height / BuildHeight];

	// Blocks and Data.
	static ubyte *empty_blocks; /**< so we don't need to allocate data for empty chunks */
	ubyte *blocks;
	ubyte *data;

	static int used_mem;

	GfxPointLight lights[];

public:
	this(BetaTerrain bt, GameWorld w, int xPos, int zPos)
	{
		this.w = w;
		this.bt = bt;
		this.xPos = xPos;
		this.yPos = 0;
		this.zPos = zPos;
		this.dirty = true;

		static assert(width == BuildWidth);
		static assert(depth == BuildDepth);
		static assert(height % BuildHeight == 0);
		static assert(height >= BuildHeight);

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
	 * Mark the given block as dirty, chunk local coords.
	 */
	final void markDirty(int y, int sy)
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
			c = bt.getChunk(x, z);
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

		auto ws = WorkspaceData.malloc();
		scope(exit)
			ws.free();

		foreach(int i, v; vbos) {
			copyToWorkspace(ws, i);

			if (bt.cvgrm !is null) {
				v = buildRigidMeshFromChunk(ws, xPos, yPos+i, zPos);
				if (v !is null)
					bt.cvgrm.add(v, xPos, yPos+i, zPos);
			}

			if (bt.cvgcm !is null) {
				if (bt.buildIndexed)
					v = buildCompactMeshIndexedFromChunk(ws, xPos, yPos+i, zPos);
				else
					v = buildCompactMeshFromChunk(ws, xPos, yPos+i, zPos);

				if (v !is null)
					bt.cvgcm.add(v, xPos, yPos+i, zPos);
			}

			vbos[i] = v;
		}
	}

	void unbuild()
	{
		foreach(l; lights) {
			w.gfx.remove(l);
			delete l;
		}
		lights = null;

		if (!gfx) {
			gfx = false;
			return;
		}

		foreach(int i, v; vbos) {
			vbos[i] = null;

			if (v is null)
				continue;

			if (bt.cvgrm !is null)
				bt.cvgrm.remove(v);
			if (bt.cvgcm !is null)
				bt.cvgcm.remove(v);
		}

		gfx = false;
	}


	/*
	 * Accessors to blocks.
	 */


	final ubyte getTypeUnsafe(int x, int y, int z)
	{
		return *(getTypePointerUnsafe(x, z) + y);
	}

	final ubyte* getTypePointerUnsafe(int x, int z)
	{
		return &blocks[x * depth * height + z * height];
	}

	/**
	 * Returns a pointer to this or another chunks block type.
	 * Coords are relative to this chunk.
	 */
	final ubyte* getTypePointer(int x, int z)
	{
		if (x < 0 || z < 0)
			return bt.getTypePointer(xPos, zPos, x, z);
		else if (x >= width || z >= depth)
			return bt.getTypePointer(xPos, zPos, x, z);
		else
			return getTypePointerUnsafe(x, z);
	}


	/*
	 * Accessors to meta data.
	 */


	final ubyte getMetaUnsafe(int x, int y, int z)
	{
		ubyte d = *(getMetaPointerUnsafe(x, z) + y/2);
		if (y % 2 == 0)
			return d & 0xf;
		return cast(ubyte)(d >> 4);
	}

	final ubyte* getMetaPointerUnsafe(int x, int z)
	{
		return &data[x * depth * height/2 + z * height/2];
	}

	/**
	 * Returns a pointer to this or another chunks meta data.
	 * Coords are relative to this chunk.
	 */
	final ubyte* getMetaPointer(int x, int z)
	{
		if (x < 0 || z < 0)
			return bt.getMetaPointer(xPos, zPos, x, z);
		else if (x >= width || z >= depth)
			return bt.getMetaPointer(xPos, zPos, x, z);
		else
			return getMetaPointerUnsafe(x, z);
	}


	/*
	 * Mesh building related.
	 */


	void copyToWorkspace(WorkspaceData *d, int off)
	{
		bool first = off == 0;
		bool last = off == (vbos.length - 1);
		int dstStart = 1;
		int srcStart = 0;
		int len = d.ws_height-2;

		if (!first) {
			dstStart = 0;
			srcStart = BuildHeight * off - 1;
			len++;
		}

		if (!last) {
			len++;
		}

		if (!last && !first) {
			for (int x; x < d.ws_width; x++) {
				for (int z; z < d.ws_depth; z++) {
					auto tPtr = getTypePointer(x-1, z-1);
					auto dPtr = getMetaPointer(x-1, z-1);
					d.blocks[x][z][0 .. $] =
						tPtr[srcStart .. srcStart + d.ws_height];

					d.data[x][z][0 .. $] =
						dPtr[srcStart/2 .. srcStart/2 + d.ws_data_height];
				}
			}

			return;
		}

		d.zero;

		for (int x; x < d.ws_width; x++) {
			for (int z; z < d.ws_depth; z++) {
				auto tPtr = getTypePointer(x-1, z-1);
				auto dPtr = getMetaPointer(x-1, z-1);


				d.blocks[x][z][dstStart .. dstStart + len] =
					tPtr[srcStart .. srcStart + len];

				d.data[x][z][dstStart .. dstStart + len/2+1] =
					dPtr[srcStart/2 .. srcStart/2 + len/2+1];

				if (first) {
					d.blocks[x][z][0] = tPtr[0];
					d.data[x][z][0] = cast(ubyte)(dPtr[0] << 4);
				}
				if (last) {
					d.blocks[x][z][$-1] = 0;
					d.data[x][z][$-1] = 0;
				}
			}
		}
	}
}

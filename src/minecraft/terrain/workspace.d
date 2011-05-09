// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.terrain.workspace;

static import std.c.stdlib;

import minecraft.terrain.data;
import minecraft.terrain.chunk;

/**
 * Since the mesh depends on data outside of the chunk array accessing it
 * any access needs to be checked if touching data outside of it. By copying
 * all the data needed and placing that in a linear array we remove the need
 * for the checks. This turns out to be faster.
 */
struct WorkspaceData
{
	/**
	 * Allocate a workspace from the C heap.
	 */
	static WorkspaceData* malloc()
	{
		return cast(WorkspaceData*)
			std.c.stdlib.malloc(WorkspaceData.sizeof);
	}

	/**
	 * Free a workspace that was allocted from the C heap.
	 */
	void free()
	{
		std.c.stdlib.free(cast(void*)this);
	}

	/*
	 * We copy the data so we can use unsafe accessor functionswhen building
	 * mesh geometry data.
	 */
	const int ws_width = 16+2;
	const int ws_height = 128+2;
	const int ws_depth = 16+2;

	const int ws_data_width = 16+2;
	const int ws_data_height = 128/2+2;
	const int ws_data_depth = 16+2;

	ubyte blocks[ws_width][ws_depth][ws_height];
	ubyte data[ws_data_width][ws_data_depth][ws_data_height];

	ubyte opIndex(int x, int y, int z)
	{
		return blocks[x+1][z+1][y+1];
	}

	ubyte opIndexAssign(ubyte value, int x, int y, int z)
	{
		return blocks[x+1][z+1][y+1] = value;
	}

	ubyte get(int x, int y, int z)
	{
		return (*this)[x, y, z];
	}

	ubyte getDataUnsafe(int x, int y, int z)
	{
		ubyte d = data[x+1][z+1][y/2+1];
		if (y % 2 == 0)
			return d & 0xf;
		return cast(ubyte)(d >> 4);
	}
	
	bool filled(int x, int y, int z)
	{
		auto t = (*this)[x, y, z];
		return tile[t].filled != 0;
	}

	bool filledOrType(ubyte type, int x, int y, int z)
	{
		auto t = (*this)[x, y, z];
		return tile[t].filled != 0 || t == type;
	}

	int getSolidSet(int x, int y, int z)
	{
		auto xmc = !filled(x-1,   y,   z);
		auto xpc = !filled(x+1,   y,   z);
		auto ymc = !filled(  x, y-1,   z);
		auto ypc = !filled(  x, y+1,   z);
		auto zmc = !filled(  x,   y, z-1);
		auto zpc = !filled(  x,   y, z+1);
		return xmc << 0 | xpc << 1 | ymc << 2 | ypc << 3 | zmc << 4 | zpc << 5;
	}

	int getSolidOrTypeSet(ubyte type, int x, int y, int z)
	{
		auto xmc = !filledOrType(type, x-1,   y,   z);
		auto xpc = !filledOrType(type, x+1,   y,   z);
		auto ymc = !filledOrType(type,   x, y-1,   z);
		auto ypc = !filledOrType(type,   x, y+1,   z);
		auto zmc = !filledOrType(type,   x,   y, z-1);
		auto zpc = !filledOrType(type,   x,   y, z+1);
		return xmc << 0 | xpc << 1 | ymc << 2 | ypc << 3 | zmc << 4 | zpc << 5;
	}

	void copyFromChunk(Chunk chunk)
	{
		for (int x; x < ws_width; x++) {
			for (int z; z < ws_depth; z++) {
				ubyte *ptr = chunk.getPointerY(x-1, z-1);
				blocks[x][z][0] = ptr[0];
				blocks[x][z][1 .. ws_height+1-2] = ptr[0 .. ws_height-2];
				blocks[x][z][length-1] = 0;

				ptr = chunk.getDataPointerY(x-1, z-1);
				data[x][z][0] = cast(ubyte)(ptr[0] << 4);
				data[x][z][1 .. ws_data_height+1-2] = ptr[0 .. ws_data_height-2];
				data[x][z][length-1] = 0;
			}
		}
	}
}

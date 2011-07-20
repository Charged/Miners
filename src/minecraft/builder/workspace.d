// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.builder.workspace;

static import std.c.stdlib;
static import std.c.string;

import minecraft.builder.data;


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

	void zero()
	{
		std.c.string.memset(this, 0, (*this).sizeof);
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

	const int ws_x_stride = ws_depth * ws_height;
	const int ws_y_stride = 1;
	const int ws_z_stride = ws_height;

	ubyte blocks[ws_width][ws_depth][ws_height];
	ubyte data[ws_data_width][ws_data_depth][ws_data_height];

	ubyte opIndex(int x, int y, int z)
	{
		auto ptr = &blocks[0][0][0];
		ptr += (++y) + ws_height * ((++x) * ws_depth + (++z));
		return *ptr;
	}

	alias opIndex get;

	ubyte opIndexAssign(ubyte value, int x, int y, int z)
	{
		return blocks[x+1][z+1][y+1] = value;
	}

	ubyte* getPointer(int x, int y, int z)
	{
		return &blocks[x+1][z+1][y+1];
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

	bool filledOrTypes(ubyte t1, ubyte t2, int x, int y, int z)
	{
		auto t = (*this)[x, y, z];
		return t == t1 || t == t2 || tile[t].filled != 0;
	}

	int getSolidSet(int x, int y, int z)
	{
		auto ptr = getPointer(x, y, z);
		auto xmc = tile[*(ptr - ws_x_stride)].filled;
		auto xpc = tile[*(ptr + ws_x_stride)].filled;
		auto ymc = tile[*(ptr - ws_y_stride)].filled;
		auto ypc = tile[*(ptr + ws_y_stride)].filled;
		auto zmc = tile[*(ptr - ws_z_stride)].filled;
		auto zpc = tile[*(ptr + ws_z_stride)].filled;
		auto ret = xmc << 0 | xpc << 1 | ymc << 2 | ypc << 3 | zmc << 4 | zpc << 5;
		return 0x3f & ~ret;
	}

	int getSolidOrTypeSet(ubyte type, int x, int y, int z)
	{
		ubyte t;
		bool b;
		auto ptr = getPointer(x, y, z);

		t = *(ptr - ws_x_stride);
		auto xmc = tile[t].filled || t == type;
		t = *(ptr + ws_x_stride);
		auto xpc = tile[t].filled || t == type;
		t = *(ptr - ws_y_stride);
		auto ymc = tile[t].filled || t == type;
		t = *(ptr + ws_y_stride);
		auto ypc = tile[t].filled || t == type;
		t = *(ptr - ws_z_stride);
		auto zmc = tile[t].filled || t == type;
		t = *(ptr + ws_z_stride);
		auto zpc = tile[t].filled || t == type;

		auto ret =  xmc << 0 | xpc << 1 | ymc << 2 | ypc << 3 | zmc << 4 | zpc << 5;
		return 0x3f & ~ret;
	}

	int getSolidOrTypesSet(ubyte t1, ubyte t2, int x, int y, int z)
	{
		ubyte t;
		bool b;
		auto ptr = getPointer(x, y, z);

		t = *(ptr - ws_x_stride);
		auto xmc = tile[t].filled || t == t1 || t == t2;
		t = *(ptr + ws_x_stride);
		auto xpc = tile[t].filled || t == t1 || t == t2;
		t = *(ptr - ws_y_stride);
		auto ymc = tile[t].filled || t == t1 || t == t2;
		t = *(ptr + ws_y_stride);
		auto ypc = tile[t].filled || t == t1 || t == t2;
		t = *(ptr - ws_z_stride);
		auto zmc = tile[t].filled || t == t1 || t == t2;
		t = *(ptr + ws_z_stride);
		auto zpc = tile[t].filled || t == t1 || t == t2;

		auto ret =  xmc << 0 | xpc << 1 | ymc << 2 | ypc << 3 | zmc << 4 | zpc << 5;
		return 0x3f & ~ret;
	}
}

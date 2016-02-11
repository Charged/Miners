// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for c memory helpers.
 */
module charge.sys.memory;

static import std.c.stdlib;
import core.exception : onOutOfMemoryError;

version(MemDump) {
	import std.stdio : writefln;
	import std.string : toString;
}


private struct MemHeader
{
private:
	size_t size;
	const(char)* file;
	uint line;
	uint magic;

	static size_t memory;

public:
	static size_t getMemory()
	{
		return memory;
	}

	static MemHeader* fromData(void *ptr)
	{
		if (ptr is null)
			return null;
		return &(cast(MemHeader*)ptr)[-1];
	}

	void* getData()
	{
		return &(&this)[1];
	}

	static void* cAlloc(size_t size)
	{
		MemHeader *ret;
		ret = cast(typeof(ret))std.c.stdlib.malloc(size + MemHeader.sizeof);
		if (ret is null)
			onOutOfMemoryError();

		ret.size = size;
		memory += size;

		return ret.getData();
	}

	static void* cRealloc(void *ptr, size_t newSize)
	{
		if (ptr is null)
			return cAlloc(newSize);

		if (newSize == 0) {
			cFree(ptr);
			return null;
		}

		auto mem = fromData(ptr);

		memory -= mem.size;
		memory += newSize;

		mem.size = newSize;

		mem = cast(MemHeader*)std.c.stdlib.realloc(mem, newSize + MemHeader.sizeof);
		if (mem is null)
			onOutOfMemoryError();

		return mem.getData();
	}

	static void cFree(void *ptr)
	{
		if (ptr is null)
			return;

		auto mem = fromData(ptr);
		memory -= mem.size;
		mem.size = 0;
		std.c.stdlib.free(mem);
	}
}

static extern(C) void* charge_malloc_dbg(size_t size, const(char)* file, uint line)
{
	auto ret = MemHeader.cAlloc(size);
	auto mem = MemHeader.fromData(ret);
	mem.file = file;
	mem.line = line;

	version(MemDump) {
		writefln(" malloc %s:%s %s (%s)", toString(file), line, ret, size);
	}

	return ret;
}

static extern(C) void* charge_realloc_dbg(void *ptr, size_t size, const(char)* file, uint line)
{
	auto ret = MemHeader.cRealloc(ptr, size);
	auto mem = MemHeader.fromData(ret);
	mem.file = file;
	mem.line = line;

	version(MemDump) {
		writefln("realloc %s:%s %s (%s)", toString(file), line, ret, size);
	}

	return ret;
}

static extern(C) void charge_free_dbg(void *ptr)
{
	auto mem = MemHeader.fromData(ptr);

	version(MemDump) {
		if (ptr != null)
			writefln("   free %s:%s %s (%s)", toString(mem.file), mem.line, ptr, mem.size);
		else
			writefln("   free %s:%s %s (%s)", "<int>", 0, ptr, 0);
	}

	MemHeader.cFree(ptr);
}

static extern(C) void* charge_malloc(size_t size)
{
	return charge_malloc_dbg(size, "<D>", 0);
}

static extern(C) void* charge_realloc(void *ptr, size_t size)
{
	return charge_realloc_dbg(ptr, size, "<D>", 0);
}

static extern(C) void charge_free(void *ptr)
{
	return charge_free_dbg(ptr);
}

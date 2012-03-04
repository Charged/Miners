// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.sys.memory;

static import std.c.stdlib;


private struct MemHeader
{
private:
	size_t size;
	char *file;
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
		return &this[1];
	}

	static void* cAlloc(size_t size)
	{
		MemHeader *ret;
		ret = cast(typeof(ret))std.c.stdlib.malloc(size + MemHeader.sizeof);

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

static extern(C) void* charge_malloc_dbg(size_t size, char* file, uint line)
{
	debug {
		auto ret = MemHeader.cAlloc(size);
		auto mem = MemHeader.fromData(ret);
		mem.file = file;
		mem.line = line;
		return ret;
	} else {
		return std.c.stdlib.malloc(size);
	}
}

static extern(C) void* charge_realloc_dbg(void *ptr, size_t size, char* file, uint line)
{
	auto ret = MemHeader.cRealloc(ptr, size);
	auto mem = MemHeader.fromData(ret);
	mem.file = file;
	mem.line = line;
	return ret;
}

static extern(C) void charge_free_dbg(void *ptr)
{
	MemHeader.cFree(ptr);
}

static extern(C) void* charge_malloc(size_t size)
{
	return MemHeader.cAlloc(size);
}

static extern(C) void* charge_realloc(void *ptr, size_t size)
{
	return MemHeader.cRealloc(ptr, size);
}

static extern(C) void charge_free(void *ptr)
{
	MemHeader.cFree(ptr);
}

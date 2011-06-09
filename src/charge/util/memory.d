// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.util.memory;

static import std.outofmemory;
static import std.c.stdlib;

/*
 * A simple c memory allocator.
 *
 * XXX Freeing the memory is manual, does not track ownership of memory.
 */
struct cMemoryArray(T)
{
	T *mem;
	size_t len;

	/**
	 * Allocate at least the same amount as the given array and copy.
	 */
	void allocCopy(T[] array)
	{
		if (len) {
			if (!ensure(array.length))
				throw new std.outofmemory.OutOfMemoryException();
		} else {
			length = array.length;
		}

		mem[0 .. array.length] = array[0 .. $];
	}

	T* realloc(size_t newLen)
	{
		auto ret = std.c.stdlib.realloc(mem, newLen * T.sizeof);

		// Failed to alloc new memory don't change anything and return null.
		if (ret == null && newLen != 0)
			return null;

		mem = cast(T*)ret;
		len = newLen;
		return mem;
	}

	void free()
	{
		std.c.stdlib.free(mem);
		mem = null;
		len = 0;
	}

	bool ensure(size_t number)
	{
		if (number <= len)
			return true;
		auto newLen = len;

		do {
			newLen = newLen * 2 + 3;
		} while(number > newLen);

		return realloc(newLen) != null;
	}

	size_t length()
	{
		return len;
	}

	size_t length(size_t newLen)
	{
		if (realloc(newLen) == null && newLen != 0)
			throw new std.outofmemory.OutOfMemoryException();
		return len;
	}

	T* ptr()
	{
		return mem;
	}
}

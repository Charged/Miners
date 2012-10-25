// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for File and ZipFile.
 */
module charge.sys.file;

import std.file : read;
import std.mmfile : MmFile;

import lib.sdl.rwops;

import charge.sys.resource;
import charge.util.zip;
import charge.util.vector;
import charge.util.memory;


/**
 * A loaded file.
 */
abstract class File
{
	/**
	 * Return a SDL_RWops to look at the contents of this file.
	 *
	 * Read only, and only valid as long as this file is valid.
	 */
	SDL_RWops* peekSDL() { return null; }

	/**
	 * Return a array to the entire file.
	 *
	 * Read only, and only valid as long as this file is valid.
	 */
	void[] peekMem() { return null; }
}

/**
 * Base class for all memory based files.
 */
abstract class BaseMemFile : File
{
	void[] mem;

	this(void[] mem)
	{
		this.mem = mem;
	}

	SDL_RWops* peekSDL()
	{
		return SDL_RWFromConstMem(mem.ptr, cast(int)mem.length);
	}

	void[] peekMem()
	{
		return mem;
	}
}

/**
 * A builtin file pointing to data in memory.
 */
class BuiltinFile : BaseMemFile
{
	this(void[] mem)
	{
		super(mem);
	}
}

/**
 * A file backed by D memory.
 */
class DMemFile : BaseMemFile
{
	this(void[] mem)
	{
		super(mem);
	}
}

/**
 * A file backed by C memory.
 */
class CMemFile : BaseMemFile
{
	this(void[] mem)
	{
		super(mem);
	}

	~this()
	{
		cFree(mem.ptr);
	}
}

/**
 * ZipFile for loading files out of a ZipFile.
 */
class ZipFile
{
private:
	MmFile mmap;

public:
	static ZipFile opCall(string filename)
	{
		MmFile mmap;

		try {
			mmap = new MmFile(filename);
		} catch (Exception e) {
			return null;
		}

		auto f = new ZipFile(mmap);
		return f;
	}

	File load(string filename)
	{
		void[] data;

		try {
			// XXX Use preparesed header.
			data = cUncompressFromFile(mmap[], filename);
		} catch (Exception e) {
			return null;
		}

		return new CMemFile(data);
	}

private:
	this(MmFile mmap)
	{
		// XXX Preparse header.
		this.mmap = mmap;
	}
}

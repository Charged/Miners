// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.sys.file;

import std.file;
import std.zip;

import lib.sdl.rwops;

import charge.sys.logger;
import charge.util.vector;
import charge.util.memory;

alias File delegate(char[] filename) FileLoader;

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

class FileManager
{
protected:
	static FileManager instance;
	Vector!(FileLoader) loaders;
	void[][char[]] builtins;
	mixin Logging;

public:
	this()
	{
		loaders ~= &this.loadBuiltin;
	}

	static FileManager opCall()
	{
		if (instance is null)
			instance = new FileManager();
		return instance;
	}

	static File opCall(char[] filename)
	{
		return FileManager().get(filename);
	}

	void add(FileLoader dg)
	{
		loaders ~= dg; 
	}

	void rem(FileLoader dg)
	{
		loaders.remove(dg); 
	}

	void addBuiltin(char[] filename, void[] data)
	{
		assert(null is (filename in builtins));

		builtins[filename] = data;
	}

	void remBuiltin(char[] filename)
	{
		assert(null !is (filename in builtins));

		builtins.remove(filename);
	}

private:
	File get(char[] file)
	{
		// Always check if file is on disk
		auto f = loadDisk(file);

		int len = cast(int)loaders.length - 1;
		for(int i = len; i >= 0 && f is null; --i)
			f = loaders[i](file);

		return f;
	}

	static File loadDisk(char[] file)
	{
		void[] data;

		try {
			data = std.file.read(file);
		} catch (Exception e) {
			return null;
		}

		auto df = new DMemFile(data);

		return df;
	}

	File loadBuiltin(char[] file)
	{
		auto data = file in builtins;
		if (data is null)
			return null;

		return new BuiltinFile(*data);
	}
}


/*
 * Implementation of different file types.
 */


/**
 * Base class for all memory based files.
 */
abstract class BaseMemFile : public File
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
class BuiltinFile : public BaseMemFile
{
	this(void[] mem)
	{
		super(mem);
	}
}

/**
 * A file backed by D memory.
 */
class DMemFile : public BaseMemFile
{
	this(void[] mem)
	{
		super(mem);
	}

	~this()
	{
		delete mem;
	}
}

/**
 * A file backed by C memory.
 */
class CMemFile : public BaseMemFile
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

class ZipFile
{
private:
	mixin Logging;

	File load(char[] filename)
	{
		//l.trace("tried to load file ", filename);
		return null;
	}

public
	static ZipFile opCall(char[] filename)
	{
		auto f = new ZipFile();
		FileManager().add(&f.load);
		return f;
	}

	~this()
	{
		FileManager().rem(&this.load);
	}
}

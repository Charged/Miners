// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.sys.file;

import std.file;
import std.zip;

import lib.sdl.rwops;

import charge.util.vector;
import charge.sys.logger;

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
	mixin Logging;

public:
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

private:
	File get(char[] filename)
	{
		auto f = load(filename);

		int len = cast(int)loaders.length - 1;
		for(int i = len; i >= 0 && f is null; --i) {
			f = loaders[i](filename);
		}

		return f;
	}

	File load(char[] file)
	{
		auto m = std.file.read(file);
		if (!m)
			return null;

		auto df = new DefaultFile();
		df.mem = m;

		return df;
	}
}


/*
 * Implementation of different file types.
 */


class DefaultFile : public File
{
	void[] mem;

	~this()
	{
		delete mem;
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

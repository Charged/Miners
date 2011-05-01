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
	SDL_RWops* getSDL() { return null; }
	void[] getMem() { return null; }
	void[] takeMem() { return null; }
}


class FileManager
{
protected:
	static FileManager instance;
	Vector!(FileLoader) loaders;
	mixin Logging;

public:
	this()
	{
		loaders ~= &(new DefaultFile).load;
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

	File get(char[] filename)
	{
		for(int i = cast(int)loaders.length - 1; i >= 0; --i) {
			auto f = loaders[i](filename);
			if (f is null)
				continue;
			return f;
		}
		return null;
	}

	static class DefaultFile : public File
	{
		void[] mem;

		~this()
		{
			delete mem;
		}

		SDL_RWops* getSDL()
		{
			return SDL_RWFromConstMem(mem.ptr, cast(int)mem.length);
		}

		void[] getMem()
		{
			return mem.dup;
		}

		void[] takeMem()
		{
			auto ret = mem;
			this.mem = null;
			delete this;
			return ret;
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

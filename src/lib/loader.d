// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module lib.loader;

import std.stdio : writefln;
import std.string;


alias void* delegate(string) Loader;

struct loadFunc(alias T)
{
	static void opCall(Loader l) {
		try {
			T = cast(typeof(T))l(T.stringof);
		} catch (Exception e) {
			T = null;
		}
		if (T is null)
			writefln("Error loading function ", T.stringof);
	}

	static void opCall(string c, Loader l) {
		try {
			T = cast(typeof(T))l(c);
		} catch (Exception e) {
			T = null;
		}
		if (T is null)
			writefln("Error loading function ", c, " to ", T.stringof);
	}
}

version(Windows)
{
	import std.c.windows.windows;
}
else version(linux)
{
	import std.c.linux.linux;
}
else
{
	// XXX Figure out the proper way to import this on Mac.
	extern(C)
	{
		void *dlopen(char* file, int mode);
		int dlclose(void* handle);
		void *dlsym(void* handle, char* name);
		char* dlerror();
	}

	// Can't be extern(C) or we conflict with phobos.
	const RTLD_NOW = 2;
}

class Library
{
public:
	static Library loads(string[] files)
	{
		foreach(filename; files) {
			auto l = load(filename);
			if (l)
				return l;
		}

		return null;
	}

	version (Windows) {

		static Library load(string filename)
		{
			void *ptr = LoadLibraryA(toStringz(filename));

			if (!ptr)
				return null;

			return new Library(ptr);
		}

		void* symbol(string symbol)
		{
			return GetProcAddress(cast(HANDLE)ptr, toStringz(symbol));
		}

		~this()
		{
			if (ptr)
				FreeLibrary(cast(HANDLE)ptr);
		}

	} else version (linux) {

		static Library load(string filename)
		{
			const RTLD_GLOBAL = 0x00100;
			void *ptr = dlopen(toStringz(filename), RTLD_NOW | RTLD_GLOBAL);

			if (!ptr)
				return null;

			return new Library(ptr);
		}

		void* symbol(string symbol)
		{
			return dlsym(ptr, toStringz(symbol));
		}

		~this()
		{
			if (ptr)
				dlclose(ptr);
		}

	} else version (darwin) {

		static Library load(string filename)
		{
			const RTLD_GLOBAL = 0x00100;
			void *ptr = dlopen(toStringz(filename), RTLD_NOW | RTLD_GLOBAL);

			if (!ptr)
				return null;

			return new Library(ptr);
		}

		void* symbol(string symbol)
		{
			return dlsym(ptr, toStringz(symbol));
		}

		~this()
		{
			if (ptr)
				dlclose(ptr);
		}

	} else {

		static Library load(string filename)
		{
			writefln("Huh oh! no impementation");
			return null;
		}

		void* symbol(string symbol)
		{
			return null;
		}

	}

private:
	this(void *ptr) { this.ptr = ptr; }
	void *ptr;

}

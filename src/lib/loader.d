// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module lib.loader;

import std.stdio;
import std.string;

alias void* delegate(char[]) Loader;

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

	static void opCall(char[] c, Loader l) {
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
	extern(C)
	{
		const int RTLD_NOW = 2;
		void *dlopen(char* file, int mode);
		int dlclose(void* handle);
		void *dlsym(void* handle, char* name);
		char* dlerror();
	}
}

class Library
{
public:
	static Library loads(char[][] files)
	{
		foreach(filename; files) {
			auto l = load(filename);
			if (l)
				return l;
		}

		return null;
	}

	version (Windows) {

		static Library load(char[] filename)
		{
			void *ptr = LoadLibraryA(toStringz(filename));

			if (!ptr)
				return null;

			return new Library(ptr);
		}

		void* symbol(char[] symbol)
		{
			return GetProcAddress(cast(HANDLE)ptr, toStringz(symbol));
		}

		~this()
		{
			if (ptr)
				FreeLibrary(cast(HANDLE)ptr);
		}

	} else version (linux) {

		static Library load(char[] filename)
		{
			const RTLD_GLOBAL = 0x00100;
			void *ptr = dlopen(toStringz(filename), RTLD_NOW | RTLD_GLOBAL);

			if (!ptr)
				return null;

			return new Library(ptr);
		}

		void* symbol(char[] symbol)
		{
			return dlsym(ptr, toStringz(symbol));
		}

		~this()
		{
			if (ptr)
				dlclose(ptr);
		}

	} else version (darwin) {

		static Library load(char[] filename)
		{
			const RTLD_GLOBAL = 0x00100;
			void *ptr = dlopen(toStringz(filename), RTLD_NOW | RTLD_GLOBAL);

			if (!ptr)
				return null;

			return new Library(ptr);
		}

		void* symbol(char[] symbol)
		{
			return dlsym(ptr, toStringz(symbol));
		}

		~this()
		{
			if (ptr)
				dlclose(ptr);
		}

	} else {

		static Library load(char[] filename)
		{
			writefln("Huh oh! no impementation");
			return null;
		}

		void* symbol(char[] symbol)
		{
			return null;
		}

	}

private:
	this(void *ptr) { this.ptr = ptr; }
	void *ptr;

}

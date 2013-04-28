// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file for getting certain folder locations.
 */
module charge.platform.homefolder;

import std.c.stdlib : getenv, free;
import std.utf : toUTF8;
import std.file : exists, mkdir, chdir;
import std.stdio : writefln;
import std.string : toString;


string tempFolder;
string homeFolder;
string applicationConfigFolder;
string chargeConfigFolder;
string privateFrameworksPath;

static this()
{
	version(linux) {
		homeFolder = toString(getenv("HOME"));
		tempFolder = toString(getenv("TEMP"));
		applicationConfigFolder = homeFolder ~ "/.config";
		chargeConfigFolder = applicationConfigFolder ~ "/charge";
	} else version(darwin) {
		homeFolder = toString(getenv("HOME"));
		tempFolder = toString(getenv("TEMP"));
		applicationConfigFolder = homeFolder ~ "/Library/Application Support";
		chargeConfigFolder = applicationConfigFolder ~ "/charge";
	} else version(Windows) {
		tempFolder = wgetenv("TEMP");
		homeFolder = wgetenv("USERPROFILE"w);
		applicationConfigFolder = wgetenv("APPDATA"w);
		chargeConfigFolder = applicationConfigFolder ~ "\\charge";
	} else {
		static assert(false);
	}

	version(darwin) {
		auto s = macGetPrivateFrameworksPath();
		privateFrameworksPath = toString(s);
	}

	// Ensure that the config folder exists.
	try {
		if (!exists(chargeConfigFolder))
			mkdir(chargeConfigFolder);

		// Change working directory to the config folder.
		chdir(chargeConfigFolder);
	} catch (Exception e) {
		// Can't do any logging since the logging module looks for the homeFolder.
		writefln("Could not create config folder (%s)", chargeConfigFolder);
	}
}

static ~this()
{
	// This should be stdlib free
	free(privateFrameworksPath.ptr);
	privateFrameworksPath = null;
}

version(Windows) {

	extern(C) wchar* _wgetenv(wchar*);

	char[] wgetenv(wchar[] str)
	{
		auto ptr = _wgetenv(str.ptr);
		if (!ptr)
			return null;

		for(int i;; i++)
			if (!ptr[i])
				return toUTF8(ptr[0 .. i]);
	}

} else version(darwin) {

	extern(C) char* macGetPrivateFrameworksPath();

}

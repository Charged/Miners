// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.platform.homefolder;

import std.c.stdlib : getenv, free;
import std.file : exists, mkdir, chdir;
import std.stdio : writefln;
import std.string : toString;


string homeFolder;
string applicationConfigFolder;
string chargeConfigFolder;
string privateFrameworksPath;

extern(C) char* macGetPrivateFrameworksPath();

static this()
{
	version(linux) {
		homeFolder = toString(getenv("HOME"));
		applicationConfigFolder = homeFolder ~ "/.config";
		chargeConfigFolder = applicationConfigFolder ~ "/charge";
	} else version(darwin) {
		homeFolder = toString(getenv("HOME"));
		applicationConfigFolder = homeFolder ~ "/Library/Application Support";
		chargeConfigFolder = applicationConfigFolder ~ "/charge";
	} else version(Windows) {
		homeFolder = toString(getenv("USERPROFILE"));
		applicationConfigFolder = toString(getenv("APPDATA"));
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

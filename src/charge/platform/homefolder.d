// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.platform.homefolder;

import std.c.stdlib;
import std.file;
import std.stdio;
import std.string;

char[] homeFolder;
char[] applicationConfigFolder;
char[] chargeConfigFolder;
char[] privateFrameworksPath;

extern(C) char* macGetPrivateFrameworksPath();

static this()
{
	version(linux) {
		homeFolder = toString(getenv("HOME"));
		applicationConfigFolder = homeFolder ~ "/.config";
	} else version(darwin) {
		// TODO Not tested
		homeFolder = toString(getenv("HOME"));
		applicationConfigFolder = homeFolder ~ "/Library/Application Support";
	} else version(Windows) {
		// TODO Not tested
		homeFolder = toString(getenv("USERPROFILE"));
		applicationConfigFolder = toString(getenv("APPDATA"));
	} else {
		static assert(false);
	}

	chargeConfigFolder = applicationConfigFolder ~ "/charge";

	version(darwin) {
		auto s = macGetPrivateFrameworksPath();
		privateFrameworksPath = toString(s);
	}

	// Ensure that the config folder exists.
	try {
		if (!exists(chargeConfigFolder))
			mkdir(chargeConfigFolder);
	} catch (Exception e) {
		// Can't do any logging since the logging module looks for the homeFolder.
		writefln("Could not create config folder (%s)", chargeConfigFolder);
	}
}

static ~this()
{
	std.c.stdlib.free(privateFrameworksPath.ptr);
}

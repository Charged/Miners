/* See Copyright Notice in src/charge/charge.d */
module main;

import std.stdio;
import charge.core;

static import test.lua;
static import test.game;
static import test.terrain;

static import robbers.game;
static import minecraft.game;

import license;

bool printLicense()
{
	foreach(license; licenseArray)
		writefln(license);
	return false;
}

bool filterArgs(inout char[][] args)
{
	char[][] ret;
	int i;
	ret.length = args.length;

	foreach(arg; args) {
		if (arg == "-license" || arg == "--license")
			return printLicense();

		// Ignore the -psn_ argument we get on Mac when launched by Finder.
		version(darwin) {
			if (arg.length > 4 && arg[0 .. 4] == "-psn")
				continue;
		}

		ret[i++] = arg;
	}

	ret.length = i;
	args = ret;
	return true;
}

int main(char[][] args)
{
	if (!filterArgs(args))
		return 0;

//	auto g = new test.lua.Game(args);
//	auto g = new test.bill.Game(args);
//	auto g = new test.game.Game(args);
//	auto g = new test.terrain.Game(args);
//	auto g = new robbers.game.Game(args);
	auto g = new minecraft.game.Game(args);

	g.loop();

	delete g;

	return 0;
}

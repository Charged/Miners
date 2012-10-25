/* See Copyright Notice in src/charge/charge.d */
module main;

import std.stdio : writefln;
import charge.core;

static import test.lua;
static import test.game;
static import test.frustum;
static import test.terrain;

static import miners.game;

// For memory tracking
static import lib.lua.state;
static import charge.sys.memory;

import license;


bool printLicense()
{
	foreach(license; licenseArray)
		writefln(license);
	return false;
}

bool filterArgs(inout string[] args)
{
	string[] ret;
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

int main(string[] args)
{
	if (!filterArgs(args))
		return 0;

//	auto g = new test.lua.Game(args);
//	auto g = new test.game.Game(args);
//	auto g = new test.frustum.Game(args);
//	auto g = new test.terrain.Game(args);
	auto g = new miners.game.Game(args);

	g.loop();

	delete g;

	accountMemory();

	return 0;
}

void accountMemory()
{
	auto lua = lib.lua.state.State.getMemory();
	if (lua != 0)
		writefln("lua leaked %s bytes", cast(long)lua);

	auto c = charge.sys.memory.MemHeader.getMemory();
	if (c != 0)
		writefln("c leaked %s bytes", cast(long)c);
}

/* See Copyright Notice in src/charge/charge.d */
module main;

import std.stdio : writefln;
import charge.core;

static import box.game;
static import miners.game;
static import examples.game;

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

	try {
//		auto g = new box.game.Game(args);
		auto g = new miners.game.Game(args);
//		auto g = new examples.game.Game(args);

		g.loop();

		delete g;

		accountMemory();
	} catch (Exception e) {
		Core().panic(e.toString());
	}

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

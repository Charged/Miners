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

bool printLicense(char[][] args)
{
	foreach(arg; args) {
		if (arg == "-license" || arg == "--license") {
			foreach(license; licenseArray)
				writefln(license);
			return true;
		}
	}

	return false;
}

int main(char[][] args)
{
	if (printLicense(args))
		return 0;

	auto c = Core();
	c.init();

//	auto g = new test.lua.Game(args);
//	auto g = new test.bill.Game(args);
//	auto g = new test.game.Game(args);
//	auto g = new test.terrain.Game(args);
//	auto g = new robbers.game.Game(args);
	auto g = new minecraft.game.Game(args);

	g.loop();

	delete g;

	c.close();
	return 0;
}

version(darwin)
{
	/*
	 * This only works on GDC, DMD has diffrent _d_run_main prototype
	 * but thats okay, since there is no DMD for MacOSX.
	 */
	extern (C) int _d_run_main(int argc, char **argv, void * p);
	extern(C) int SDL_main(int argc, char** argv)
	{
		return _d_run_main(argc, argv, &main);
	}
}

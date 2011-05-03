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

int chargeMain(char[][] args)
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
	extern(C) int _SDL_run_main(int argc, char** argv);

	version(DigitalMars)
	{
		char[][] saved_args;

		int main(char[][] args)
		{
			saved_args = args;
			scope(exit) saved_args = null;

			char *ptr = args[0].ptr;
			return _SDL_run_main(1, &ptr);
		}

		extern(C) int SDL_main(int argc, char** argv)
		{
			return chargeMain(saved_args);
		}
	}
	else
	{
		/*
		 * This only works on GDC, DMD has diffrent _d_run_main prototype.
		 */
		extern (C) int _d_run_main(int argc, char **argv, void * p);
		extern(C) int SDL_main(int argc, char** argv)
		{
			return _d_run_main(argc, argv, &chargeMain);
		}

		extern(C) int main(int argc, char **argv)
		{
			return _SDL_run_main(argc, argv);
		}
	}
}
else
{
	int main(char[][] args)
	{
		return chargeMain(args);
	}
}

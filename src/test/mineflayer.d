// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module test.mineflayer;

import std.thread;

import lib.loader;
import lib.mineflayer.mineflayer;

import charge.charge;


class Game : GameSimpleApp
{
private:
	mineflayer_Callbacks cbs;
	mineflayer_GamePtr game;
	char[] user;
	char[] pass;
	char[] server;
	uint port;

	char[][] libName;

	char[] library;
	char[] libpath;

	Library lib;

public:
	this(char[][] args)
	{
		super(args);

		server = "localhost";
		port = 25565;

		parseArgs(args);

		if (running && user is null) {
			std.stdio.writefln("no user provided");
			parseArgs(["", "-h"]);
		}

		if (!running)
			return;

		char[] libName = "libmineflayer-core.so";
		char[][] libNames;

		if (library)
			libNames ~= [library];

		if (libpath)
			libNames ~= [libpath ~ "/" ~ libName];

		libNames ~= [libName];

		lib = Library.loads(libNames);

		if (lib is null) {
			std.stdio.writefln("Could not find mineflayer looked for: ", libNames);
			running = false;
			return;
		}

		loadMineflayer(&lib.symbol);

		if (mineflayer_createGamePullCallbacks is null || mineflayer_doCallbacks is null) {
			std.stdio.writefln("Mineflayer doesn't have the new needed functions");
			std.stdio.writefln("\tmineflayer_createGamePullCallbacks");
			std.stdio.writefln("\tmineflayer_doCallbacks");
			running = false;
			return;
		}

		std.stdio.writefln("################################");
		std.stdio.writefln("#");
		std.stdio.writefln("# connecting to %s@%s:%s", user, server, port);
		std.stdio.writefln("#");
		std.stdio.writefln("################################");

		cbs.playerPositionUpdated = &playerPositionUpdated;
		cbs.chunkUpdated = &chunkUpdated;

		mineflayer_Url url;
		url.username = mineflayer_Utf8(user);
		url.password = mineflayer_Utf8(pass);
		url.hostname = mineflayer_Utf8(server);
		url.port = port;

		game = mineflayer_createGamePullCallbacks(url, cbs, cast(void*)this);
	}

	void logic()
	{
		mineflayer_doCallbacks(game);
	}

	void render() {}
	void network() {}

	void close()
	{
		if (game !is null)
			mineflayer_destroyGame(game);
	}

protected:
	void parseArgs(char[][] args)
	{
		for(int i = 1; i < args.length; i++) {
			switch(args[i]) {
			case "-L":
				if (++i < args.length) {
					libpath = args[i];
					break;
				}
				std.stdio.writefln("Expected argument to libpath switch");
				throw new Exception("");
			case "-l":
				if (++i < args.length) {
					library = args[i];
					break;
				}
				std.stdio.writefln("Expected argument to library switch");
				throw new Exception("");
			case "-host":
			case "--host":
			case "-a":
			case "-address":
			case "--address":
				if (++i < args.length) {
					server = args[i];
					break;
				}
				std.stdio.writefln("Expected argument to host switch");
				throw new Exception("");
			case "-u":
			case "-user":
			case "--user":
				if (++i < args.length) {
					user = args[i];
					break;
				}
				std.stdio.writefln("Expected argument to user switch");
				throw new Exception("");
			case "-p":
			case "-pass":
			case "--pass":
				if (++i < args.length) {
					pass = args[i];
					break;
				}
				std.stdio.writefln("Expected argument to pass switch");
				throw new Exception("");
			case "-port":
			case "--port":
				if (++i < args.length) {
					port = std.conv.toUint(args[i]);
					break;
				}
				std.stdio.writefln("Expected argument to port switch");
				throw new Exception("");
			default:
				std.stdio.writefln("Unknown argument %s", args[i]);
			case "-h":
			case "-help":
			case "--help":
				std.stdio.writefln("[-a address] [-port port] [-u user] [-p pass] [-L path_to_lib] [-l library]");
				running = false;
				break;
			}
		}
	}

	extern(C) static void playerPositionUpdated(void *ctx)
	{
		//std.stdio.writefln("playerPositionUpdated");
	}

	extern(C) static void chunkUpdated(void *ctx, mineflayer_Int3D s, mineflayer_Int3D sz)
	{
		std.stdio.writefln("chunkUpdated (%s, %s, %s) (%sx%sx%s)", s.x, s.y, s.z, sz.x, sz.y, sz.z);
	}
}

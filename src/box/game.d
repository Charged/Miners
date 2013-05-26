// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module box.game;

import charge.charge;

import box.client;
import box.server;


/**
 * Main hub of the box game.
 */
class Game : GameSceneManagerApp
{
private:
	mixin SysLogging;

	bool server;
	string address = "localhost";
	ushort port = 21337;

public:
	this(string[] args)
	{
		parseArgs(args);

		/* This will initalize Core and other important things */
		auto opts = new CoreOptions();
		opts.title = "Box";
		opts.flags = server ? coreFlag.PHY : coreFlag.AUTO;
		super(opts);

		if (!phyLoaded)
			throw new Exception("Failed to load ODE");

		if (!server)
			push(new ClientScene(this, address, port));
		else
			push(new ServerScene(this, port));
	}

	override void close()
	{
		super.close();
	}

	void parseArgs(string[] args)
	{
		foreach(a; args) {
			if (a == "-server")
				server = true;
		}
	}
}

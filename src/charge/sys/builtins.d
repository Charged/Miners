// Copyright © 2012, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
/**
 * Source file that includes all builtin files.
 */
module charge.sys.builtins;


/**
 * Build the AA at startup.
 */
static this()
{
	// From Miners
	builtins["script/main-level.lua"] = import("main-level.lua");
	builtins["script/defaults.lua"] = import("defaults.lua");
	builtins["script/exported.lua"] = import("exported.lua");
	builtins["script/physics.lua"] = import("physics.lua");
	builtins["script/player.lua"] = import("player.lua");
	builtins["script/blocks.lua"] = import("blocks.lua");
	builtins["script/input.lua"] = import("input.lua");

	// Common
	builtins["res/spotlight.png"] = import("spotlight.png");
	builtins["res/default.png"] = import("default.png");
	builtins["res/font.png"] = import("font.png");
}

void[][string] builtins;

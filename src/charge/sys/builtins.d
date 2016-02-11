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
	builtins["script/main-level.lua"] = cast(void[])import("main-level.lua");
	builtins["script/defaults.lua"] = cast(void[])import("defaults.lua");
	builtins["script/exported.lua"] = cast(void[])import("exported.lua");
	builtins["script/physics.lua"] = cast(void[])import("physics.lua");
	builtins["script/player.lua"] = cast(void[])import("player.lua");
	builtins["script/blocks.lua"] = cast(void[])import("blocks.lua");
	builtins["script/input.lua"] = cast(void[])import("input.lua");

	// Common
	builtins["res/spotlight.png"] = cast(void[])import("spotlight.png");
	builtins["res/default.png"] = cast(void[])import("default.png");
	builtins["res/font.png"] = cast(void[])import("font.png");
}

void[][string] builtins;

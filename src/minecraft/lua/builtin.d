// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module minecraft.lua.builtin;

import charge.sys.file;

void initLuaBuiltins()
{
	auto fm = FileManager();

	fm.addBuiltin("script/main-level.lua", import("main-level.lua"));
	fm.addBuiltin("script/defaults.lua", import("defaults.lua"));
	fm.addBuiltin("script/exported.lua", import("exported.lua"));
	fm.addBuiltin("script/physics.lua", import("physics.lua"));
	fm.addBuiltin("script/input.lua", import("input.lua"));
}

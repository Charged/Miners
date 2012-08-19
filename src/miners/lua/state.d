// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.lua.state;

import charge.charge;

public import lib.lua.lua;
public import lib.lua.lauxlib;

static import lib.lua.state;
static import charge.game.lua;

alias lib.lua.state.ObjectWrapper ObjectWrapper;
alias charge.game.lua.StructWrapper StructWrapper;

import miners.types;
import miners.lua.wrappers.types;


class LuaState : public charge.game.lua.LuaState
{
	static LuaState opCall(lua_State *l)
	{
		auto s = lib.lua.state.State(l);
		return cast(LuaState)s;
	}

	mixin (StructWrapper("Block"));

private:

}

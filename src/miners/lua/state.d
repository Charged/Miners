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
import miners.lua.functions;
import miners.lua.wrappers.isle;
import miners.lua.wrappers.beta;
import miners.lua.wrappers.types;
import miners.lua.wrappers.actors;
import miners.lua.wrappers.terrain;
import miners.lua.wrappers.classic;


class LuaState : public charge.game.lua.LuaState
{
	static LuaState opCall(lua_State *l)
	{
		auto s = lib.lua.state.State(l);
		return cast(LuaState)s;
	}

	void openMiners()
	{
		pushCFunction(&openlib);
		pushStringz("miners");
		call(1);
	}

	mixin (StructWrapper("Block"));

private:
	const luaL_Reg minerslib[] = [
		{ "Block", &BlockWrapper.newBlock },
		{ "OtherPlayer", &OtherPlayerWrapper.newOtherPlayer },
		{ "getRayPoints", &getRayPoints },
		{ null, null },
	];

	extern (C) static int openlib(lua_State *l)
	{
		auto s = LuaState(l);

		luaL_register(l, "miners", minerslib.ptr);

		// Register structs
		BlockWrapper.register(s);

		// Register actors
		CameraWrapper.register(s);
		OptionsWrapper.register(s);
		SunLightWrapper.register(s);
		OtherPlayerWrapper.register(s);

		// Register world and terrain
		IsleWorldWrapper.register(s);
		BetaWorldWrapper.register(s);
		BetaTerrainWrapper.register(s);
		ClassicWorldWrapper.register(s);
		FiniteTerrainWrapper.register(s);

		return 1;
	}
}

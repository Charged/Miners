// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.lua.wrappers.types;

import std.string : format;

import miners.types;

import miners.lua.state;

import lib.lua.lua;
import lib.lua.state;
import lib.lua.lauxlib;


struct BlockWrapper
{
	const static char *namez = "d_struct_miners_types_Block";
	const static string name = "d_struct_miners_types_Block";

	extern (C) static int toString(lua_State *l)
	{
		auto s = LuaState(l);
		auto b = check(s, 1);
		s.pushString(format("(%s, %s)", b.type, b.meta));
		return 1;
	}

	extern (C) static int index(lua_State *l)
	{
		auto s = LuaState(l);
		auto b = check(s, 1);
		auto key = s.checkString(2);
		
		switch(key) {
		case "type":
			s.pushNumber(b.type);
			return 1;
		case "meta":
			s.pushNumber(b.meta);
			return 1;
		default:
			s.getMetaTable(1);
			s.pushValue(2);
			s.getTable(-2);
			return 1;
		}
	}

	extern (C) static int newIndex(lua_State *l)
	{
		auto s = LuaState(l);
		auto b = check(s, 1);
		auto key = s.checkString(2);
		auto v = s.checkNumber(3);

		switch(key) {
		case "type":
			b.type = cast(ubyte)v;
			return 1;
		case "meta":
			b.meta = cast(ubyte)v;
			return 1;
		default:
		}
		return s.error("No such member");
	}

	extern (C) static int newBlock(lua_State *l)
	{
		auto s = LuaState(l);

		if (s.isNumber(1) && s.isNumber(2)) {
			auto t = cast(ubyte)s.toNumber(1);
			auto m = cast(ubyte)s.toNumber(2);
			push(s, Block(t, m));
		} else {
			push(s, Block());
		}
		return 1;
	}

	static void register(State s)
	{
		s.registerStructz!(Block)(namez);

		s.pushCFunction(&index);
		s.setFieldz(-2, "__index");
		s.pushCFunction(&newIndex);
		s.setFieldz(-2, "__newIndex");
		s.pushCFunction(&toString);
		s.setFieldz(-2, "__tostring");
		s.pop();
	}

	static Block* push(State s)
	{
		return s.pushStructPtrz!(Block)(namez);
	}

	static Block* push(State s, Block q)
	{
		return cast(Block*)s.pushStructRefz(q, namez);
	}

	static Block* check(State s, int index)
	{
		return s.checkStructz!(Block)(index, namez);
	}

	static Block* to(State s, int index)
	{
		return cast(Block*)s.toUserData(index);
	}

	static bool isAt(State s, int index)
	{
		return s.isUserDataz(index, namez);
	}
}

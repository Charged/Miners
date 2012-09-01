// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module miners.lua.wrappers.isle;

import miners.lua.state;
import miners.isle.world;


struct IsleWorldWrapper
{
	const static char *namez = "d_class_minecraft_world_World";
	const static string name = "d_class_minecraft_world_World";

	extern (C) static int index(lua_State *l)
	{
		auto s = LuaState(l);
		string key;
		auto w = s.checkClass!(IsleWorld)(1, false);
		s.checkString(2);

		key = s.toString(2);
		switch(key) {
		case "spawn":
			s.pushPoint3d(w.spawn);
			break;
		default:
			s.getMetaTable(1);
			s.pushValue(2);
			s.getTable(-2);
			break;
		}

		return 1;
	}

	static void register(LuaState s)
	{
		s.registerClass!(IsleWorld);
		s.pushCFunction(&ObjectWrapper.toString);
		s.setFieldz(-2, "__tostring");
		s.pushCFunction(&index);
		s.setFieldz(-2, "__index");
		s.pop();
	}
}

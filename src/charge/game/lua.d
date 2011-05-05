// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).
module charge.game.lua;

import std.stdio;
import std.string;

import lib.lua.state;

import charge.math.point3d;
import charge.math.vector3d;
import charge.math.movable;
import charge.math.quatd;

private static char[] StructWrapperPush(char[] type)
{
	return `
	final ` ~ type ~ `* push` ~ type ~ `()
	{
		return ` ~ type ~ `Wrapper.push(this);
	}

	final ` ~ type ~ `* push` ~ type ~ `(ref ` ~ type ~ ` s)
	{
		return ` ~ type ~ `Wrapper.push(this, s);
	}`;
}

private static char[] StructWrapperRest(char[] type)
{
	return `
	final ` ~ type ~ `* check` ~ type ~`(int index = -1)
	{
		return ` ~ type ~ `Wrapper.check(this, index);
	}

	final ` ~ type ~ `* to` ~ type ~`(int index = -1)
	{
		return ` ~ type ~ `Wrapper.to(this, index);
	}

	final bool is` ~ type ~ `(int index = -1)
	{
		return ` ~ type ~ `Wrapper.isAt(this, index);
	}
	`;
}

alias lib.lua.lua.lua_State lua_State;
alias lib.lua.state.ObjectWrapper ObjectWrapper;

private static char[] StructWrapper(char[] type)
{
	return StructWrapperPush(type) ~ StructWrapperRest(type);
}

class LuaState : public State
{
	static LuaState opCall(lua_State *l)
	{
		auto s = State(l);
		return cast(LuaState)s;
	}

	mixin (StructWrapper("Vector3d"));
	mixin (StructWrapper("Point3d"));
	mixin (StructWrapper("Quatd"));
}

struct MovableWrapper
{
	const static char *namez = "d_class_charge_math_movable_Movable";
	const static char[] name = "d_class_charge_math_movable_Movable";

	extern (C) static int index(lua_State *l)
	{
		auto s = LuaState(l);
		char[] key;
		auto obj = s.checkClassName!(Movable)(1, false, name);

		s.checkString(2);

		key = s.toString(2);
		try {
			switch(key) {
			case "position":
				obj.getPosition(*Point3dWrapper.push(s));
				return 1;
			case "rotation":
				obj.getRotation(*QuatdWrapper.push(s));
				return 1;
			default:
				s.getMetaTable(1);
				s.pushValue(2);
				s.getTable(-2);
				return 1;
			}
		} catch (Exception e) {
			return s.error(e);
		}
	}

	extern (C) static int newIndex(lua_State *l)
	{
		auto s = LuaState(l);
		char[] key;
		auto obj = s.checkClassName!(Movable)(1, false, name);
		s.checkString(2);

		key = s.toString(2);
		switch(key) {
		case "position":
			auto p = Point3dWrapper.check(s, 3);
			try {
				obj.setPosition(*p);
				return 1;
			} catch (Exception e) {
				return s.error(e);
			}
		case "rotation":
			auto q = QuatdWrapper.check(s, 3);
			try {
				obj.setRotation(*q);
				return 1;
			} catch (Exception e) {
				return s.error(e);
			}
		default:
		}
		return s.error("No such member");
	}

}

struct QuatdWrapper
{
	const static char *namez = "d_struct_charge_math_quatd_Quatd";
	const static char[] name = "d_struct_charge_math_quatd_Quatd";

	extern (C) static int toString(lua_State *l)
	{
		auto s = LuaState(l);
		s.pushString(check(s, 1).toString);
		return 1;
	}

	extern (C) static int index(lua_State *l)
	{
		auto s = LuaState(l);
		char[] key;
		auto ud = check(s, 1);
		s.checkString(2);

		key = s.toString(2);
		switch(key)	{
		case "x":
			s.pushNumber(ud.x);
			break;
		case "y":
			s.pushNumber(ud.y);
			break;
		case "z":
			s.pushNumber(ud.z);
			break;
		case "w":
			s.pushNumber(ud.w);
			break;
		default:
			s.getMetaTable(1);
			s.pushValue(2);
			s.getTable(-2);
			break;
		}

		return 1;
	}

	extern (C) static int mul(lua_State *l)
	{
		auto s = LuaState(l);
		auto q1 = check(s, 1);

		if (isAt(s, 2)) {
			auto q2 = to(s, 2);
			push(s, *q1 * *q2);
			return 1;
		} else if (Vector3dWrapper.isAt(s, 2)) {
			auto v = Vector3dWrapper.to(s, 2);
			Vector3dWrapper.push(s, *q1 * *v);
			return 1;
		}
		s.error("Expected either Vector3d or Quatd");
		return 1;
	}

	extern (C) static int newQuatd(lua_State *l)
	{
		auto s = LuaState(l);

		if (s.isNumber(1) && s.isNumber(2) && s.isNumber(3))
			push(s, Quatd(s.toNumber(1), s.toNumber(2), s.toNumber(3)));
		else
			push(s, Quatd());
		return 1;
	}

	static void register(State s)
	{
		s.registerStructz!(Quatd)(namez);

		s.pushCFunction(&index);
		s.setFieldz(-2, "__index");
		s.pushCFunction(&mul);
		s.setFieldz(-2, "__mul");
		s.pushCFunction(&toString);
		s.setFieldz(-2, "__tostring");
		s.pop();

		s.pushString("Quatd");
		s.pushCFunction(&newQuatd);
		s.setTable(lib.lua.lua.LUA_GLOBALSINDEX);
	}

	static Quatd* push(State s)
	{
		return s.pushStructPtrz!(Quatd)(namez);
	}

	static Quatd* push(State s, Quatd q)
	{
		return cast(Quatd*)s.pushStructRefz(q, namez);
	}

	static Quatd* check(State s, int index)
	{
		return s.checkStructz!(Quatd)(index, namez);
	}

	static Quatd* to(State s, int index)
	{
		return cast(Quatd*)s.toUserData(index);
	}

	static bool isAt(State s, int index)
	{
		return s.isUserDataz(index, namez);
	}

}

struct Vector3dWrapper
{
	const static char *namez = "d_struct_charge_math_vector3d_Vector3d";
	const static char[] name = "d_struct_charge_math_vector3d_Vector3d";

	extern (C) static int toString(lua_State *l)
	{
		auto s = LuaState(l);
		s.pushString(check(s, 1).toString);
		return 1;
	}

	extern (C) static int index(lua_State *l)
	{
		auto s = LuaState(l);
		char[] key;
		auto ud = check(s, 1);
		s.checkString(2);

		key = s.toString(2);
		switch(key)	{
		case "x":
			s.pushNumber(ud.x);
			break;
		case "y":
			s.pushNumber(ud.y);
			break;
		case "z":
			s.pushNumber(ud.z);
			break;
		default:
			s.getMetaTable(1);
			s.pushValue(2);
			s.getTable(-2);
			break;
		}

		return 1;
	}

	extern (C) static int newIndex(lua_State *l)
	{
		auto s = LuaState(l);
		char[] key;
		auto ud = check(s, 1);
		auto v = s.checkNumber(3);
		s.checkString(2);

		key = s.toString(2);
		switch(key)	{
		case "x":
			ud.x = v;
			break;
		case "y":
			ud.y = v;
			break;
		case "z":
			ud.z = v;
			break;
		default:
			s.error("No memeber of that that name");
			break;
		}

		return 0;
	}

	extern (C) static int add(lua_State *l)
	{
		auto s = LuaState(l);
		auto v1 = check(s, 1);
		auto v2 = check(s, 2);
		push(s, *v1 + *v2);
		return 1;
	}

	extern (C) static int newVector3d(lua_State *l)
	{
		auto s = LuaState(l);

		if (s.isNumber(1) && s.isNumber(2) && s.isNumber(3))
			push(s, Vector3d(s.toNumber(1), s.toNumber(2), s.toNumber(3)));
		else
			push(s, Vector3d());
		return 1;
	}

	extern (C) static int scale(lua_State *l)
	{
		auto s = LuaState(l);
		auto v = check(s, 1);
		s.checkNumber(2);

		v.scale(s.toNumber(2));
		s.pop();

		return 1;
	}

	extern (C) static int lengthSqrd(lua_State *l)
	{
		auto s = LuaState(l);
		auto v = check(s, 1);

		s.pushNumber(v.lengthSqrd());

		return 1;
	}

	extern (C) static int normalize(lua_State *l)
	{
		auto s = LuaState(l);
		auto v = check(s, 1);

		v.normalize();

		return 1;
	}

	static void register(State s)
	{
		s.registerStructz!(Vector3d)(namez);

		s.pushCFunction(&index);
		s.setFieldz(-2, "__index");
		s.pushCFunction(&newIndex);
		s.setFieldz(-2, "__newindex");
		s.pushCFunction(&add);
		s.setFieldz(-2, "__add");
		s.pushCFunction(&toString);
		s.setFieldz(-2, "__tostring");
		s.pushCFunction(&lengthSqrd);
		s.setFieldz(-2, "lengthSqrd");
		s.pushCFunction(&scale);
		s.setFieldz(-2, "scale");
		s.pushCFunction(&normalize);
		s.setFieldz(-2, "normalize");
		s.pop();

		s.pushString("Vector3d");
		s.pushCFunction(&newVector3d);
		s.setTable(lib.lua.lua.LUA_GLOBALSINDEX);
	}

	static Vector3d* push(State s)
	{
		return s.pushStructPtrz!(Vector3d)(namez);
	}

	static Vector3d* push(State s, Vector3d p)
	{
		return cast(Vector3d*)s.pushStructRefz(p, namez);
	}

	static Vector3d* check(State s, int index)
	{
		return s.checkStructz!(Vector3d)(index, namez);
	}

	static Vector3d* to(State s, int index)
	{
		return cast(Vector3d*)s.toUserData(index);
	}

	static bool isAt(State s, int index)
	{
		return s.isUserDataz(index, namez);
	}

}

struct Point3dWrapper
{
	const static char *namez = "d_struct_charge_math_point3d_Point3d";
	const static char[] name = "d_struct_charge_math_point3d_Point3d";

	extern (C) static int toString(lua_State *l)
	{
		auto s = LuaState(l);
		s.pushString(check(s, 1).toString);
		return 1;
	}

	extern (C) static int index(lua_State *l)
	{
		auto s = LuaState(l);
		char[] key;
		auto ud = check(s, 1);
		s.checkString(2);

		key = s.toString(2);
		switch(key)	{
		case "x":
			s.pushNumber(ud.x);
			break;
		case "y":
			s.pushNumber(ud.y);
			break;
		case "z":
			s.pushNumber(ud.z);
			break;
		default:
			s.getMetaTable(1);
			s.pushValue(2);
			s.getTable(-2);
			break;
		}

		return 1;
	}

	extern (C) static int newIndex(lua_State *l)
	{
		auto s = LuaState(l);
		char[] key;
		auto ud = check(s, 1);
		auto v = s.checkNumber(3);
		s.checkString(2);

		key = s.toString(2);
		switch(key)	{
		case "x":
			ud.x = v;
			break;
		case "y":
			ud.y = v;
			break;
		case "z":
			ud.z = v;
			break;
		default:
			s.error("No memeber of that that name");
			break;
		}

		return 0;
	}

	extern (C) static int add(lua_State *l)
	{
		auto s = LuaState(l);
		auto p = check(s, 1);
		auto v = Vector3dWrapper.check(s, 2);
		push(s, *p + *v);
		return 1;
	}

	extern (C) static int newPoint3d(lua_State *l)
	{
		auto s = LuaState(l);

		if (s.isNumber(1) && s.isNumber(2) && s.isNumber(3))
			push(s, Point3d(s.toNumber(1), s.toNumber(2), s.toNumber(3)));
		else if (s.isVector3d(1))
			push(s, Point3d(*s.toVector3d(1)));
		else
			push(s, Point3d());
		return 1;
	}

	static void register(State s)
	{
		s.registerStructz!(Point3d)(namez);

		s.pushCFunction(&index);
		s.setFieldz(-2, "__index");
		s.pushCFunction(&newIndex);
		s.setFieldz(-2, "__newindex");
		s.pushCFunction(&add);
		s.setFieldz(-2, "__add");
		s.pushCFunction(&toString);
		s.setFieldz(-2, "__tostring");
		s.pop();

		s.pushString("Point3d");
		s.pushCFunction(&newPoint3d);
		s.setTable(lib.lua.lua.LUA_GLOBALSINDEX);
	}

	static Point3d* push(State s)
	{
		return s.pushStructPtrz!(Point3d)(namez);
	}

	static Point3d* push(State s, Point3d p)
	{
		return cast(Point3d*)s.pushStructRefz(p, namez);
	}

	static Point3d* check(State s, int index)
	{
		return s.checkStructz!(Point3d)(index, namez);
	}

	static Point3d* to(State s, int index)
	{
		return cast(Point3d*)s.toUserData(index);
	}

	static bool isAt(State s, int index)
	{
		return s.isUserDataz(index, namez);
	}

}

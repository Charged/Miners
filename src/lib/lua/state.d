module lib.lua.state;

import std.stdio;
import std.string;

import lib.lua.all;

class ObjectWrapper
{
	const static char* namez = "d_class_object_Object";
	const static char[] name = "d_class_object_Object";

	extern (C) static int toString(lua_State *l)
	{
		auto s = State(l);
		auto obj = s.checkClassName!(Object)(1, false, name);

		try {
			auto str = obj.toString();
			s.pushString(str);
			return 1;
		} catch (Exception e) {
			return s.error(e);
		}
	}

	static void registerObject(State s)
	{
		s.registerClass!(Object);

		s.pushCFunction(&toString);
		s.setFieldz(-2, "__tostring");
		s.pop();
	}

}

class State
{
protected:
	lua_State *l;

public:
	this()
	{
		this.l = luaL_newstate();
		if (!l)
			throw new Exception("Could not create lua state");

		/* Use the userdata for the alloc function to hold the state */
		auto af = lua_getallocf(l, null);
		lua_setallocf(l, af, cast(void*)this);
	}

	~this()
	{
		lua_close(l);
	}

	static State opCall(lua_State *l)
	{
		State state;
		auto af = lua_getallocf(l, cast(void**)&state);
		/* XXX if state == NULL wrap it */
		return state;
	}


	/*
	 * Struct support.
	 */


	State registerStruct(T)()
	{
		TypeInfo ti = typeid(T);
		auto namez = getMangledNamez("d_struct_" ~ ti.toString);
		if (!luaL_newmetatable(l, namez))
			throw new Exception("Struct " ~ ti.toString ~ " allready registered");

		return this;
	}

	State registerStructz(T)(char *namez)
	{
		TypeInfo ti = typeid(T);
		char *checkz = getMangledNamez("d_struct_" ~ ti.toString);
		/* picks the wrong toString */
		alias std.string.toString tSz;

		if (cmp(tSz(namez), tSz(checkz)))
			throw new Exception("Failed to register Struct " ~ tSz(namez) ~ " is invalid");

		if (!luaL_newmetatable(l, namez))
			throw new Exception("Struct " ~ ti.toString ~ " allready registered");

		return this;
	}

	T* pushStructRef(T)(ref T s)
	{
		TypeInfo ti = typeid(T);
		auto namez = getMangledNamez("d_struct_" ~ ti.toString);
		return pushStructRefz!(T)(s, namez);
	} 

	T* pushStructRefz(T)(ref T s, char *namez)
	{
		auto ptr = lua_newuserdata(l, T.sizeof);

		if (luaL_newmetatable(l, namez)) {
			throw new Exception("Struct not " ~ typeid(T).toString ~ " registered");
		}

		*cast(T*)ptr = s;

		lua_setmetatable(l, -2);

		return cast(T*)ptr;
	} 

	T* pushStructPtr(T)()
	{
		TypeInfo ti = typeid(T);
		auto namez = getMangledNamez("d_struct_" ~ ti.toString);
		return pushStructPtrz!(T)(namez);
	}

	T* pushStructPtrz(T)(char *namez)
	{
		auto ptr = lua_newuserdata(l, T.sizeof);

		if (luaL_newmetatable(l, namez)) {
			throw new Exception("Struct not " ~ typeid(T).toString ~ " registered");
		}

		lua_setmetatable(l, -2);

		return cast(T*)ptr;
	} 

	T* checkStruct(T)(int index)
	{
		TypeInfo ti = typeid(T);
		return checkStructz!(T)(index, getMangledNamez("d_struct_" ~ ti.toString));
	}

	T* checkStructz(T)(int index, char *namez)
	{
		return cast(T*)luaL_checkudata(l, index, namez);
	}


	/*
	 * Object support.
	 */


	/**
	 * Struct that contains a class instance.
	 */
	static struct Instance
	{
		Object obj;

		void ctor(Object obj)
		{
			if (obj !is null)
				obj.notifyRegister(&notify);
			this.obj = obj;
		}

		void dtor()
		{
			if (obj !is null)
				obj.notifyUnRegister(&notify);
		}

		void notify(Object obj)
		{
			assert(this.obj is obj);
			this.obj = null;
		}

	};

	void registerClass(T)()
	{
		ClassInfo ci = T.classinfo;

		if (!luaL_newmetatable(l, getClassNamez(ci)))
			throw new Exception("Class already registered");

		/* set the collector function */
		lua_pushcfunction(l, &gc);
		lua_setfield(l, -2, "__gc");

		/* by defualt set the index table to the meta table */
		lua_pushvalue(l, -1);
		lua_setfield(l, -2, "__index");

		/* say which classes the class can be cast to */
		for(; ci; ci = ci.base) {
			pushString(getClassName(ci));
			pushBool(true);
			setTable(-3);
		}
	}

	void pushClass(Object obj)
	{
		Instance *ptr = cast(Instance*)lua_newuserdata(l, (Object*).sizeof);

		if (luaL_newmetatable(l, getClassNamez(obj.classinfo))) {
			throw new Exception("Class " ~ obj.classinfo.name ~ " not registered");
		}

		ptr.ctor(obj);

		lua_setmetatable(l, -2);
	}

	T checkClass(T)(int index, bool nullz)
	{
		return checkClassName!(T)(index, nullz, getClassName(T.classinfo));
	}

	T checkClassName(T)(int index, bool nullz, char[] name)
	{
		Instance *p;
		char[] cnz = T.classinfo.name;
		T obj;

		if (!lua_isuserdata(l, index))
			luaL_typerror(l, index, cnz.ptr);

		p = cast(Instance*)lua_touserdata(l, index);
		if (lua_getmetatable(l, index)) {
			lua_pushlstring(l, name.ptr, name.length);
			lua_rawget(l, -2);
			if (!lua_isnil(l, -1)) {
				lua_pop(l, 2);
				if (p.obj is null && !nullz)
					luaL_error(l, "Instance is null");
				return cast(T)p.obj;
			}
		}
		luaL_typerror(l, index, cnz.ptr);
		return null;
	}

	static char[] getClassName(ClassInfo ci)
	{
		return getMangledName("d_class_" ~ ci.name);
	}

	static char* getClassNamez(ClassInfo ci)
	{
		return std.string.toStringz(getClassName(ci));
	}


	/*
	 * Misc helpers
	 */


	static char[] getMangledName(char[] str)
	{
		foreach (i, c; str) {
			if (c == '.')
				str[i] = '_';
		}
		return str;
	}

	static char* getMangledNamez(char[] str)
	{
		return std.string.toStringz(getMangledName(str));
	}


	bool isUserDataz(int index, char* namez)
	{
		bool ret = false;
		if (!lua_isuserdata(l, index))
			return false;

		if (!lua_getmetatable(l, index))
			return false;

		lua_getfield(l, LUA_REGISTRYINDEX, namez);
		if (lua_rawequal(l, -1, -2))
			ret = true;

		lua_pop(l, 2);
		return ret;
	}

	lua_State * state() { return l; }

	/*
	 * Lua function wrappers.
	 */


	int doFile(char[] name)
	{
		return luaL_dofile(l, std.string.toStringz("res/test.lua"));
	}

	int loadFile(char[] name)
	{
		return luaL_loadfile(l, std.string.toStringz("res/test.lua"));
	}

	int call(int nargs = 0, int nresults = LUA_MULTRET)
	{
		return lua_pcall(l, nargs, nresults, 0);
	}

	State openLibs() { luaL_openlibs(l); return this; }

	State setTable(int index) { lua_settable(l, index); return this; }
	State setField(int index, char[] string) { return setFieldz(index, std.string.toStringz(string)); }
	State setFieldz(int index, char* stringz) { lua_setfield(l, index, stringz); return this; }

	State getTable(int index) { lua_gettable(l, index); return this; }
	State getField(int index, char[] string) { return getFieldz(index, std.string.toStringz(string)); }
	State getFieldz(int index, char* stringz) { lua_getfield(l, index, stringz); return this; }
	State getGlobal(char[] string) { return getGlobalz(std.string.toStringz(string)); }
	State getGlobalz(char* stringz) { lua_getfield(l, lib.lua.lua.LUA_GLOBALSINDEX, stringz); return this; }

	State getMetaTable(int index = -1) { lua_getmetatable(l, index); return this; }

	int error(char[] error)
	{
		luaL_where(l, 1);
		pushString(error);
		lua_concat(l, 2);
		return lua_error(l);
	}

	int error(Exception e)
	{
		luaL_where(l, 1);
		pushString(e.toString);
		lua_concat(l, 2);
		return lua_error(l);
	}

	State top(int index) { lua_settop(l, index); return this; }
	int top() { return lua_gettop(l); }
	size_t objectLength(int index = -1) { return lua_objlen(l, index); }
	State pop(uint amount = 1) { lua_pop(l, amount); return this; }

	void* newUserData(size_t size) { return lua_newuserdata(l, size); }

	State pushValue(int index = -1) { lua_pushvalue (l, index); return this; }
	State pushUpValue(int number) { lua_pushvalue(l, lua_upvalueindex(1)); return this; }
	State pushNil() { lua_pushnil(l); return this; }
	State pushBool(bool v) { lua_pushboolean(l, v); return this; }
	State pushNumber(double value) { lua_pushnumber(l, value); return this; }
	State pushString(char[] string) { lua_pushlstring(l, string.ptr, string.length); return this; }
	State pushStringz(char* stringz) { lua_pushstring(l, stringz); return this; }
	State pushTable() { lua_newtable(l); return this; }
	State pushCFunction(lua_CFunction f) { lua_pushcfunction(l, f); return this; }

	bool toBool(int index = -1) { return lua_toboolean(l, index) != 0; }
	char[] toString(int index = -1) { size_t e; auto p = lua_tolstring(l, index, &e); return p[0 .. e]; }
	char* toStringz(int index = -1, size_t *e = null) { return lua_tolstring(l, index, e); }
	double toNumber(int index = -1) { return lua_tonumber(l, index); }
	lua_CFunction toCFunction(int index = -1) { return lua_tocfunction(l, index); }
	void* toUserData(int index = -1) { return lua_touserdata(l, index); }

	char* checkString(int index = -1) { return luaL_checkstring(l, index); }
	double checkNumber(int index = -1) { return luaL_checknumber(l, index); }
	void* checkUserData(int index, char[] name) { return checkUserDataz(index, std.string.toStringz(name)); }
	void* checkUserDataz(int index, char* namez) { return luaL_checkudata(l, index, namez); }

	bool isNoneOrNil(int index = -1) { return lua_isnoneornil(l, index) != 0; }
	bool isNil(int index = -1) { return lua_isnil(l, index) != 0; }
	bool isBool(int index = -1) { return lua_isboolean(l, index) != 0; }
	bool isNumber(int index = -1) { return lua_isnumber(l, index) != 0; }
	bool isString(int index = -1) { return lua_isstring(l, index) != 0; }
	bool isTable(int index = -1) { return lua_istable(l, index) != 0; }
	bool isFunction(int index = -1) { return lua_isfunction(l, index) != 0; }
	bool isCFunction(int index = -1) { return lua_iscfunction(l, index) != 0; }
	bool isUserData(int index = -1) { return lua_isuserdata(l, index) != 0; }

protected:
	extern (C) static int gc(lua_State *l)
	{
		alias ObjectWrapper.namez namez;
		alias ObjectWrapper.name name;
		Instance *p;

		if (!lua_isuserdata(l, 1))
			luaL_typerror(l, 1, namez);

		p = cast(Instance*)lua_touserdata(l, 1);
		if (lua_getmetatable(l, 1)) {
			lua_pushlstring(l, name.ptr, name.length);
			lua_rawget(l, -2);
			if (!lua_isnil(l, -1)) {
				p.dtor();
				return 0;
			}
		}
		return luaL_typerror(l, 1, namez);
	}

}

module lib.lua.state;

import std.string : cmp, sformat, toStringz;
import std.c.stdlib : realloc;
import stdx.string : toString;

import lib.lua.all;


class ObjectWrapper
{
	const static char* namez = "d_class_object_Object";
	const static string name = "d_class_object_Object";

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
public:
	const size_t tmpSize = 256;

protected:
	lua_State *l;

	static size_t memory;


public:
	this()
	{
		/* Use the userdata for the alloc function to hold the state */
		this.l = lua_newstate(&alloc, cast(void*)this);
		if (!l)
			throw new Exception("Could not create lua state");
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

	/**
	 * Replace the loaders from package with the function given.
	 *
	 * Doesn't replace the preload one.
	 */
	void replacePackageLoaders(lua_CFunction f)
	{
		getGlobalz("package");
		pushStringz("loaders");
		lua_rawget(l, -2);
		pushCFunction(f);
		lua_rawseti(l, -2, 2);
		lua_pushnil(l);
		lua_rawseti(l, -2, 3);
		lua_pushnil(l);
		lua_rawseti(l, -2, 4);

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

	State registerStructz(T)(const(char)* namez)
	{
		TypeInfo ti = typeid(T);
		char[tmpSize] tmp;
		char[] check = mangleName(sformat(tmp, "d_struct_", ti.toString));
		/* picks the wrong toString */
		alias .toString tSz;

		if (cmp(tSz(namez), check))
			throw new Exception("Failed to register Struct " ~ tSz(namez) ~ " is invalid");

		if (!luaL_newmetatable(l, namez))
			throw new Exception("Struct " ~ ti.toString ~ " allready registered");

		return this;
	}

	T* pushStructRef(T)(ref T s)
	{
		TypeInfo ti = typeid(T);
		char[tmpSize] tmp;
		char* namez = mangledName(sformat("d_struct_", ti.toString, "\0")).ptr;
		return pushStructRefz!(T)(s, namez);
	} 

	T* pushStructRefz(T)(ref T s, const(char)* namez)
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

	T* pushStructPtrz(T)(const(char)* namez)
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

	T* checkStructz(T)(int index, const(char)* namez)
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
	public:
		Object obj;

		alias void delegate() GC;
		GC gc;

	public:
		/**
		 * Main Constructor, need to always call this
		 * as lua doesn't memset memory.
		 */
		void ctor(Object obj, GC gc)
		{
			if (obj !is null)
				rt_attachDisposeEvent(obj, &notify);

			this.obj = obj;
			this.gc = gc;
		}

		void ctor(Object obj)
		{
			ctor(obj, null);
		}

		void ctor(Object obj, bool autoDelete)
		{
			ctor(obj, autoDelete ? &this.deleteObj : null);
		}

		void dtor()
		{
			if (obj !is null)
				rt_detachDisposeEvent(obj, &notify);

			if (gc !is null)
				gc();
		}

		/**
		 * Notify callback for when objects are deleted.
		 */
		void notify(Object obj)
		{
			assert(this.obj is obj);
			this.obj = null;
		}

		/**
		 * Helper function to delete the object on gc.
		 */
		void deleteObj()
		{
			delete obj;
			obj = null;
		}
	};

	void registerClass(T)()
	{
		ClassInfo ci = T.classinfo;
		char[tmpSize] tmp;

		if (!luaL_newmetatable(l, getClassNamez(ci, tmp)))
			throw new Exception("Class already registered");

		/* set the collector function */
		lua_pushcfunction(l, &gc);
		lua_setfield(l, -2, "__gc");

		/* by defualt set the index table to the meta table */
		lua_pushvalue(l, -1);
		lua_setfield(l, -2, "__index");

		/* say which classes the class can be cast to */
		for(; ci; ci = ci.base) {
			pushString(getClassName(ci, tmp));
			pushBool(true);
			setTable(-3);
		}
	}

	final Instance* pushInstance(Object obj)
	{
		Instance *ptr = cast(Instance*)lua_newuserdata(l, Instance.sizeof);
		char[tmpSize] tmp;

		int ret = luaL_newmetatable(l, getClassNamez(obj.classinfo, tmp));
		assert(!ret);

		lua_setmetatable(l, -2);

		return ptr;
	}

	Instance* pushClass(Object obj)
	{
		auto ptr = pushInstance(obj);
		ptr.ctor(obj);
		assert(ptr.obj is obj);
		return ptr;
	}

	Instance* pushClass(Object obj, bool autoDelete)
	{
		auto ptr = pushInstance(obj);
		ptr.ctor(obj, autoDelete);
		assert(ptr.obj is obj);
		return ptr;
	}

	Instance* pushClass(Object obj, Instance.GC gc)
	{
		auto ptr = pushInstance(obj);
		ptr.ctor(obj, gc);
		assert(ptr.obj is obj);
		return ptr;
	}

	Instance* checkInstance(T)(int index)
	{
		return checkInstanceName!(T)(index, nullz, getClassName(T.classinfo));
	}

	Instance* checkInstanceName(T)(int index, const(char)[] name)
	{
		Instance *p;
		string cnz = T.classinfo.name;

		if (!lua_isuserdata(l, index))
			luaL_typerror(l, index, cnz.ptr);

		p = cast(Instance*)lua_touserdata(l, index);
		if (lua_getmetatable(l, index)) {
			lua_pushlstring(l, name.ptr, name.length);
			lua_rawget(l, -2);
			if (!lua_isnil(l, -1)) {
				lua_pop(l, 2);
				return p;
			}
		}
		luaL_typerror(l, index, cnz.ptr);
		return null;
	}

	T checkClass(T)(int index, bool nullz)
	{
		char[tmpSize] tmp;
		auto name = getClassName(T.classinfo, tmp);
		return checkClassName!(T)(index, nullz, name);
	}

	T checkClassName(T)(int index, bool nullz, const(char)[] name)
	{
		auto p = checkInstanceName!(T)(index, name);
		if (p.obj is null && !nullz)
			luaL_error(l, "Instance is null");
		return cast(T)p.obj;
	}

	static char[] getClassName(ClassInfo ci, char[] tmp)
	{
		auto name = sformat(tmp, "d_class_", ci.name);
		return mangleName(name);
	}

	static char* getClassNamez(ClassInfo ci, char[] tmp)
	{
		auto namez = sformat(tmp, "d_class_", ci.name, "\0");
		return mangleName(namez).ptr;
	}


	/*
	 * Misc helpers
	 */


	static char[] mangleName(char[] str)
	{
		foreach (i, c; str) {
			if (c == '.')
				str[i] = '_';
		}
		return str;
	}

	bool isUserDataz(int index, const(char)* namez)
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


	int doFile(string name)
	{
		return luaL_dofile(l, .toStringz(name));
	}

	/**
	 * Load a string but pretend it is a file.
	 */
	int loadStringAsFile(const(char)[] str, string filename)
	{
		// Make lua think this is a file.
		auto strLua = "@" ~ filename;

		// Do the actual loading into lua
		return loadString(str, strLua);
	}

	int loadString(const(char)[] str, string name)
	{
		return luaL_loadbuffer(l, str.ptr, str.length, name.ptr);
	}

	int loadFile(string name)
	{
		return luaL_loadfile(l, .toStringz(name));
	}

	int call(int nargs = 0, int nresults = LUA_MULTRET)
	{
		return lua_pcall(l, nargs, nresults, 0);
	}

	State openLibs() { luaL_openlibs(l); return this; }

	State setTable(int index) { lua_settable(l, index); return this; }
	State setField(int index, string str) { return setFieldz(index, .toStringz(str)); }
	State setFieldz(int index, const(char)* stringz) { lua_setfield(l, index, stringz); return this; }

	State getTable(int index) { lua_gettable(l, index); return this; }
	State getField(int index, string str) { return getFieldz(index, .toStringz(str)); }
	State getFieldz(int index, const(char)* stringz) { lua_getfield(l, index, stringz); return this; }
	State getGlobal(string str) { return getGlobalz(.toStringz(str)); }
	State getGlobalz(const(char)* stringz) { lua_getfield(l, lib.lua.lua.LUA_GLOBALSINDEX, stringz); return this; }

	State getMetaTable(int index = -1) { lua_getmetatable(l, index); return this; }

	int error(string error)
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
	State pushString(const(char)[] str) { lua_pushlstring(l, str.ptr, str.length); return this; }
	State pushStringz(const(char)* stringz) { lua_pushstring(l, stringz); return this; }
	State pushTable() { lua_newtable(l); return this; }
	State pushCFunction(lua_CFunction f) { lua_pushcfunction(l, f); return this; }

	bool toBool(int index = -1) { return lua_toboolean(l, index) != 0; }
	string toString(int index = -1) { size_t e; auto p = lua_tolstring(l, index, &e); return cast(string)p[0 .. e]; }
	const(char)* toStringz(int index = -1, size_t *e = null) { return lua_tolstring(l, index, e); }
	double toNumber(int index = -1) { return lua_tonumber(l, index); }
	lua_CFunction toCFunction(int index = -1) { return lua_tocfunction(l, index); }
	void* toUserData(int index = -1) { return lua_touserdata(l, index); }

	string checkString(int index = -1) { size_t e; auto p = luaL_checklstring(l, index, &e); return cast(string)p[0 .. e]; }
	double checkNumber(int index = -1) { return luaL_checknumber(l, index); }
	void* checkUserData(int index, string name) { return checkUserDataz(index, .toStringz(name)); }
	void* checkUserDataz(int index, const(char)* namez) { return luaL_checkudata(l, index, namez); }

	bool isNoneOrNil(int index = -1) { return lua_isnoneornil(l, index) != 0; }
	bool isNil(int index = -1) { return lua_isnil(l, index) != 0; }
	bool isBool(int index = -1) { return lua_isboolean(l, index) != 0; }
	bool isNumber(int index = -1) { return lua_isnumber(l, index) != 0; }
	bool isString(int index = -1) { return lua_isstring(l, index) != 0; }
	bool isTable(int index = -1) { return lua_istable(l, index) != 0; }
	bool isFunction(int index = -1) { return lua_isfunction(l, index) != 0; }
	bool isCFunction(int index = -1) { return lua_iscfunction(l, index) != 0; }
	bool isUserData(int index = -1) { return lua_isuserdata(l, index) != 0; }
	static size_t getMemory() { return memory; }

	override string toString() { return super.toString(); }

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

	static extern(C) void* alloc(void *ud, void *data, size_t oldSize, size_t newSize)
	{
		/* XXX atomic ops */
		memory -= oldSize;
		memory += newSize;

		return realloc(data, newSize);
	}
}

private:
alias void delegate(Object) DisposeEvt;
extern(C) void rt_attachDisposeEvent(Object obj, DisposeEvt evt);
extern(C) void rt_detachDisposeEvent(Object obj, DisposeEvt evt);

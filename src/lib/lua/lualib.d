/*
** Lua standard libraries
** See Copyright Notice in lua.d
*/
module lib.lua.lualib;

import lib.lua.lua;


void luaL_openlibs(lua_State *L)
{
	struct Reg {
		string name;
		extern(C) int function(lua_State *L) func;
	}

	const Reg lualibs[] = [
		{"", &luaopen_base},
		{LUA_LOADLIBNAME, &luaopen_package},
		{LUA_TABLIBNAME, &luaopen_table},
//		{LUA_IOLIBNAME, &luaopen_io},
//		{LUA_OSLIBNAME, &luaopen_os},
		{LUA_STRLIBNAME, &luaopen_string},
		{LUA_MATHLIBNAME, &luaopen_math},
//		{LUA_DBLIBNAME, &luaopen_debug},
	];

	foreach (lib; lualibs) {
		lua_pushcfunction(L, lib.func);
		lua_pushlstring(L, lib.name.ptr, lib.name.length);
		lua_call(L, 1, 0);
	}
}

extern (C):

const LUA_COLIBNAME = "coroutine";
int luaopen_base(lua_State *L);

const LUA_TABLIBNAME = "table";
int luaopen_table(lua_State *L);

/+
const LUA_IOLIBNAME = "io";
int luaopen_io(lua_State *L);
+/

/+
const LUA_OSLIBNAME = "os";
int luaopen_os(lua_State *L);
+/

const LUA_STRLIBNAME = "string";
int luaopen_string(lua_State *L);

const LUA_MATHLIBNAME = "math";
int luaopen_math(lua_State *L);

/+
const LUA_DBLIBNAME = "debug";
int luaopen_debug(lua_State *L);
+/

const LUA_LOADLIBNAME = "package";
int luaopen_package(lua_State *L);

/+
/* open all previous libraries */
void luaL_openlibs(lua_State *L); 
+/

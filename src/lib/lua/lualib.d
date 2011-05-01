/*
** Lua standard libraries
** See Copyright Notice in lua.d
*/
module lib.lua.lualib;

import lib.lua.lua;

void luaL_openlibs(lua_State *L)
{
	luaopen_base(L);
	luaopen_table(L);
	luaopen_string(L);
	luaopen_math(L);
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

/+
const LUA_LOADLIBNAME = "package";
int luaopen_package(lua_State *L);
+/

/+
/* open all previous libraries */
void luaL_openlibs(lua_State *L); 
+/

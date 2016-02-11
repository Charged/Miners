module lib.lua.lauxlib;

import lib.lua.lua;
import lib.lua.luaconf;


extern (C):

/* extra error code for `luaL_load' */
const LUA_ERRFILE = (LUA_ERRERR+1);


struct luaL_Reg {
  const(char)* name;
  lua_CFunction func;
}



void luaI_openlib(lua_State *L, const(char)* libname, const(luaL_Reg)* l, int nup);
void luaL_register(lua_State *L, const(char)* libname, const(luaL_Reg)* l);
int luaL_getmetafield(lua_State *L, int obj, const(char)* e);
int luaL_callmeta(lua_State *L, int obj, const(char)* e);
int luaL_typerror(lua_State *L, int narg, const(char)* tname);
int luaL_argerror(lua_State *L, int numarg, const(char)* extramsg);
const(char)* luaL_checklstring(lua_State *L, int numArg, size_t *l);
const(char)* luaL_optlstring(lua_State *L, int numArg, const(char)* def, size_t *l);
lua_Number luaL_checknumber(lua_State *L, int numArg);
lua_Number luaL_optnumber(lua_State *L, int nArg, lua_Number def);

lua_Integer luaL_checkinteger(lua_State *L, int numArg);
lua_Integer luaL_optinteger(lua_State *L, int nArg, lua_Integer def);

void luaL_checkstack(lua_State *L, int sz, const(char)* msg);
void luaL_checktype(lua_State *L, int narg, int t);
void luaL_checkany(lua_State *L, int narg);

int   luaL_newmetatable (lua_State *L, const(char)* tname);
void *luaL_checkudata (lua_State *L, int ud, const(char)* tname);

void luaL_where (lua_State *L, int lvl);
int luaL_error (lua_State *L, const(char)* fmt, ...);

int luaL_checkoption(lua_State *L, int narg, const(char)* def, const(char)* * lst);

int luaL_ref(lua_State *L, int t);
void luaL_unref(lua_State *L, int t, int reff);

int luaL_loadfile(lua_State *L, const(char)* filename);
int luaL_loadbuffer(lua_State *L, const(char)* buff, size_t sz, const(char)* name);
int luaL_loadstring(lua_State *L, const(char)* s);

lua_State *luaL_newstate();


const(char)* luaL_gsub(lua_State *L, const(char)* s, const(char)* p, const(char)* r);

const(char)* luaL_findtable(lua_State *L, int idx, const(char)* fname, int szhint);




/*
** ===============================================================
** some useful macros
** ===============================================================
*/

void luaL_argcheck(lua_State* L, int cond, int numarg, const(char)* extramsg) { if (!cond) luaL_argerror(L, numarg, extramsg); }
const(char)* luaL_checkstring(lua_State* L, int n) { return luaL_checklstring(L, n, null); }
const(char)* luaL_optstring(lua_State* L, int n, const(char)* d) { return luaL_optlstring(L, n, d, null); }
lua_Integer luaL_checkint(lua_State* L, int n) { return luaL_checkinteger(L, n); }
lua_Integer luaL_optint (lua_State* L, int n, lua_Integer d) { return luaL_optinteger(L, n, d); }
long luaL_checklong(lua_State* L, int n) { return luaL_checkinteger(L, n); }
lua_Integer luaL_optlong(lua_State* L, int n, lua_Integer d) { return luaL_optinteger(L, n, d); }

char* luaL_typename(lua_State* L, int i) { return lua_typename(L, lua_type(L, i)); }

int luaL_dofile(lua_State* L, const(char)* fn) { return luaL_loadfile(L, fn) || lua_pcall(L, 0, LUA_MULTRET, 0); }

int luaL_dostring(lua_State*L, const(char)* s) { return luaL_loadstring(L, s) || lua_pcall(L, 0, LUA_MULTRET, 0); }

void luaL_getmetatable(lua_State* L, const(char)* s) { lua_getfield(L, LUA_REGISTRYINDEX, s); }

bool luaL_opt(lua_State* L, int function(lua_State*, int) f, int n, int d) { return luaL_opt(L, f, n, d); }


/*
** {======================================================
** Generic Buffer manipulation
** =======================================================
*/



struct luaL_Buffer {
  char* p;			/* current position in buffer */
  int lvl;  /* number of strings in the stack (level) */
  lua_State *L;
  char[LUAL_BUFFERSIZE] buffer;
};

void luaL_addchar(luaL_Buffer* B, char c)
{
	if (B.p < B.buffer.ptr + LUAL_BUFFERSIZE || (luaL_prepbuffer(B)))
	{
		*B.p = c;
		B.p++;
	}
}

void luaL_buffinit(lua_State *L, luaL_Buffer *B);
const(char)* luaL_prepbuffer(luaL_Buffer *B);
void luaL_addlstring(luaL_Buffer *B, const(char)* s, size_t l);
void luaL_addstring(luaL_Buffer *B, const(char)* s);
void luaL_addvalue(luaL_Buffer *B);
void luaL_pushresult(luaL_Buffer *B);


/* }====================================================== */

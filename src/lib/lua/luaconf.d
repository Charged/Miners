module lib.lua.luaconf;

alias ptrdiff_t LUA_INTEGER;
alias size_t LUAI_UMEM;
alias ptrdiff_t LUAI_MEM;
alias int LUAI_INT32;
alias double LUA_NUMBER;
alias double LUAI_UACNUMBER;
alias long LUA_INTFRM_T;

const LUAI_MAXCALLS      = 20000;
const LUA_IDSIZE         = 60;
const LUAI_GCPAUSE       = 200;
const LUAI_GCMUL         = 200;
const LUA_COMPAT_LSTR    = 1;
const LUAI_MAXCSTACK     = 8000;
const LUAI_BITSINT       = 32;
const LUA_MAXCAPTURES    = 32;
const LUAI_MAXCCALLS     = 200;
const LUAI_MAXVARS       = 200;
const LUAI_MAXUPVALUES   = 60;
const LUAL_BUFFERSIZE    = 16384;
const LUAI_EXTRASPACE    = 0;
const LUAI_MAXNUMBER2STR = 32;

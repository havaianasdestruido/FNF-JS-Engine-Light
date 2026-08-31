package headers;

#if LUA_ALLOWED
typedef LuaUtils = psychlua.LuaUtils;
#else
typedef LuaUtils = Dynamic;
#end
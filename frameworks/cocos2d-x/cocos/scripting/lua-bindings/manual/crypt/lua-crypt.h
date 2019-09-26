#ifndef LUA_CRYPT_H_
#define LUA_CRYPT_H_

#ifdef __cplusplus
extern "C" {
#endif
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
extern "C" {
#endif
	int luaopen_crypt(lua_State *L);
#ifdef __cplusplus
}
#endif

#endif
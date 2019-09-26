#ifndef LSHA1_H_
#define LSHA1_H_

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
	int lsha1(lua_State *L);
	int lhmac_sha1(lua_State *L);
#ifdef __cplusplus
}
#endif

#endif
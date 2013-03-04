/*
** Load and dump code.
** Copyright (C) 2013 Francois Perrad.
**
** Major portions taken verbatim or adapted from the LuaJIT.
** Copyright (C) 2005-2013 Mike Pall.
*/

#include <errno.h>
#include <stdio.h>

#define lj_load_c
#define LUA_CORE

#include "lua.h"
#include "lauxlib.h"

#include "lj_str.h"

/* -- Load Lua source code and bytecode ----------------------------------- */

LUALIB_API int luaL_loadfilex(lua_State *L, const char *filename,
			      const char *mode)
{
  const char *chunkname;
  const char *buf;
  size_t size;
  if (filename) {
    chunkname = lua_pushfstring(L, "@%s", filename);
    lua_getglobal(L, "io");
    lua_getfield(L, -1, "open");
    lua_pushstring(L, filename);
    lua_pushstring(L, "rb");
    lua_call(L, 2, 2); /* f, msg = io.open(filename, "rb") */
    if (lua_isnil(L, -2)) {
      lua_pushfstring(L, "cannot open %s", lua_tostring(L, -1));
      return LUA_ERRFILE;
    }
    lua_pop(L, 1); /* msg */
  }
  else {
    chunkname = "=stdin";
    lua_getglobal(L, "io");
    lua_getfield(L, -1, "stdin"); /* f = io.stdin */
  }
  lua_getfield(L, -1, "read");
  lua_pushvalue(L, -2);
  lua_pushstring(L, "*a");
  lua_call(L, 2, 1); /* buf = f.read(f, "*a") */
  buf = lua_tolstring(L, -1, &size);
  lua_getfield(L, -2, "close");
  lua_pushvalue(L, -3);
  lua_call(L, 1, 0); /* f.close(f) */
  return luaL_loadbufferx(L, buf, size, chunkname, mode);
}

LUALIB_API int luaL_loadfile(lua_State *L, const char *filename)
{
  return luaL_loadfilex(L, filename, NULL);
}

LUALIB_API int luaL_loadbufferx(lua_State *L, const char *buf, size_t size,
				const char *name, const char *mode)
{
  int bc = buf[0] == '\x1b';
  if (mode && !strchr(mode, bc ? 'b' : 't')) {
      lua_pushliteral(L, "attempt to load chunk with wrong mode");
      return LUA_ERRSYNTAX;
  }
  if (bc)
    return tvm_loadbufferx(L, buf, size, name, mode);
  else {
    lua_getglobal(L, "_COMPILER");
    lua_assert(!lua_isnil(L, -1));
    lua_pushlstring(L, buf, size);
    lua_pushstring(L, name);
    lua_call(L, 2, 1); /* buf = _G._COMPILER(buf, name) */
    buf = lua_tolstring(L, -1, &size);
    return tvm_loadbufferx(L, buf, size, name, NULL);
  }
}

LUALIB_API int luaL_loadbuffer(lua_State *L, const char *buf, size_t size,
			       const char *name)
{
  return luaL_loadbufferx(L, buf, size, name, NULL);
}

LUALIB_API int luaL_loadstring(lua_State *L, const char *s)
{
  return luaL_loadbuffer(L, s, strlen(s), s);
}


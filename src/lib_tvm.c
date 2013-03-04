/*
** Tvm library.
** Copyright (C) 2013 Francois Perrad.
**
** Major parts taken verbatim from the LuaJIT.
** Copyright (C) 2005-2013 Mike Pall.
*/

#include <stdio.h>

#define lib_tvm_c
#define LUA_LIB

#include "tvmjit.h"
#include "lauxlib.h"
#include "lualib.h"

#include "lj_obj.h"
#include "lj_gc.h"
#include "lj_err.h"
#include "lj_str.h"
#include "lj_char.h"
#include "lj_lib.h"

/* ------------------------------------------------------------------------ */

#define LJLIB_MODULE_tvm

/* macro to `unsign' a character */
#define uchar(c)        ((unsigned char)(c))

LJLIB_CF(tvm_escape)
{
  GCstr *str = lj_lib_checkstr(L, 1);
  int32_t len = (int32_t)str->len;
  const char *s = strdata(str);
  luaL_Buffer b;
  luaL_buffinit(L, &b);
  while (len--) {
    uint32_t c = uchar(*s);
    if (c == '(' || c == ')' || c == ':' || lj_char_isspace(c)) {
      luaL_addchar(&b, '\\');
    }
    luaL_addchar(&b, c);
    s++;
  }
  luaL_pushresult(&b);
  return 1;
}

LJLIB_CF(tvm_quote)
{
  GCstr *str = lj_lib_checkstr(L, 1);
  int32_t len = (int32_t)str->len;
  const char *s = strdata(str);
  const char *e = s + len;
  luaL_Buffer b;
  luaL_buffinit(L, &b);
  luaL_addchar(&b, '"');
  while (s < e) {
    uint32_t c = uchar(*s);
    if (c == '"' || c == '\\' || (c == '\n' && len > 32)) {
      luaL_addchar(&b, '\\');
      luaL_addchar(&b, c);
    } else if (c < ' ') {
      uint32_t h = c >> 4;
      uint32_t l = c & 0x0F;
      luaL_addchar(&b, '\\');
      luaL_addchar(&b, 'x');
      luaL_addchar(&b, (h >= 0x0A) ? 'A'-10+h: '0'+h);
      luaL_addchar(&b, (l >= 0x0A) ? 'A'-10+l: '0'+l);
    } else {
      luaL_addchar(&b, c);
    }
    s++;
  }
  luaL_addchar(&b, '"');
  luaL_pushresult(&b);
  return 1;
}

LJLIB_CF(tvm_wchar)
{
  int i, nargs = (int)(L->top - L->base);
  luaL_Buffer b;
  luaL_buffinit(L, &b);
  for (i = 1; i <= nargs; i++) {
    int32_t k = lj_lib_checkint(L, i);
    if ((k < 0) || (k > 0xffff))
      lj_err_arg(L, i, LJ_ERR_BADVAL);
    if (k >= 0x0800) {
      luaL_addchar(&b, 0xE0 | (k >> 12));
      luaL_addchar(&b, 0x80 | ((k >> 6) & 0x3f));
      luaL_addchar(&b, 0x80 | (k & 0x3f));
    }
    else if (k >= 0x0080) {
      luaL_addchar(&b, 0xC0 | (k >> 6));
      luaL_addchar(&b, 0x80 | (k & 0x3f));
    }
    else
      luaL_addchar(&b, k);
  }
  luaL_pushresult(&b);
  return 1;
}

/* -- load Tvm code ------------------------------------------------------- */

static int tvm_load_aux(lua_State *L, int status, int envarg)
{
  if (status == 0) {
    if (tvistab(L->base+envarg-1)) {
      GCfunc *fn = funcV(L->top-1);
      GCtab *t = tabV(L->base+envarg-1);
      setgcref(fn->c.env, obj2gco(t));
      lj_gc_objbarrier(L, fn, t);
    }
    return 1;
  } else {
    setnilV(L->top-2);
    return 2;
  }
}

LJLIB_CF(tvm_loadfile)
{
  GCstr *fname = lj_lib_optstr(L, 1);
  GCstr *mode = lj_lib_optstr(L, 2);
  int status;
  lua_settop(L, 3);  /* Ensure env arg exists. */
  status = tvm_loadfilex(L, fname ? strdata(fname) : NULL,
			 mode ? strdata(mode) : NULL);
  return tvm_load_aux(L, status, 3);
}

static const char *tvm_reader_func(lua_State *L, void *ud, size_t *size)
{
  UNUSED(ud);
  luaL_checkstack(L, 2, "too many nested functions");
  copyTV(L, L->top++, L->base);
  lua_call(L, 0, 1);  /* Call user-supplied function. */
  L->top--;
  if (tvisnil(L->top)) {
    *size = 0;
    return NULL;
  } else if (tvisstr(L->top) || tvisnumber(L->top)) {
    copyTV(L, L->base+4, L->top);  /* Anchor string in reserved stack slot. */
    return lua_tolstring(L, 5, size);
  } else {
    lj_err_caller(L, LJ_ERR_RDRSTR);
    return NULL;
  }
}

LJLIB_CF(tvm_load)
{
  GCstr *name = lj_lib_optstr(L, 2);
  GCstr *mode = lj_lib_optstr(L, 3);
  int status;
  if (L->base < L->top && (tvisstr(L->base) || tvisnumber(L->base))) {
    GCstr *s = lj_lib_checkstr(L, 1);
    lua_settop(L, 4);  /* Ensure env arg exists. */
    status = tvm_loadbufferx(L, strdata(s), s->len, strdata(name ? name : s),
			     mode ? strdata(mode) : NULL);
  } else {
    lj_lib_checkfunc(L, 1);
    lua_settop(L, 5);  /* Reserve a slot for the string from the reader. */
    status = tvm_loadx(L, tvm_reader_func, NULL, name ? strdata(name) : "=(load)",
		       mode ? strdata(mode) : NULL);
  }
  return tvm_load_aux(L, status, 4);
}

LJLIB_CF(tvm_dofile)
{
  GCstr *fname = lj_lib_optstr(L, 1);
  setnilV(L->top);
  L->top = L->base+1;
  if (tvm_loadfile(L, fname ? strdata(fname) : NULL) != 0)
    lua_error(L);
  lua_call(L, 0, LUA_MULTRET);
  return (int)(L->top - L->base) - 1;
}

/* ------------------------------------------------------------------------ */

#include "lj_libdef.h"

LUALIB_API int luaopen_tvm(lua_State *L)
{
  LJ_LIB_REG(L, LUA_TVMLIBNAME, tvm);
  lua_pushliteral(L, TVMJIT_VERSION);
  lua_setfield(L, -2, "_VERSION");
  return 1;
}


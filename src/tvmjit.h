/*
** TvmJIT
** Copyright (C) 2013 Francois Perrad.
**
** Major parts taken verbatim from the LuaJIT.
** Copyright (C) 2005-2012 Mike Pall.
*/

#ifndef _TVMJIT_H
#define _TVMJIT_H

#include "tvmconf.h"
#include "lua.h"

#define TVMJIT_VERSION		"TvmJIT 0.0.1"
#define TVMJIT_VERSION_NUM	000001  /* Version 0.0.1 = 00_00_01 */
#define LUAJIT_VERSION_SYM	luaJIT_version_2_0_0
#define TVMJIT_COPYRIGHT	"Copyright (C) 2012 Francois Perrad"
#define LUAJIT_URL		"http://luajit.org/"

/* Modes for luaJIT_setmode. */
#define LUAJIT_MODE_MASK	0x00ff

enum {
  LUAJIT_MODE_ENGINE,		/* Set mode for whole JIT engine. */
  LUAJIT_MODE_DEBUG,		/* Set debug mode (idx = level). */

  LUAJIT_MODE_FUNC,		/* Change mode for a function. */
  LUAJIT_MODE_ALLFUNC,		/* Recurse into subroutine protos. */
  LUAJIT_MODE_ALLSUBFUNC,	/* Change only the subroutines. */

  LUAJIT_MODE_TRACE,		/* Flush a compiled trace. */

  LUAJIT_MODE_WRAPCFUNC = 0x10,	/* Set wrapper mode for C function calls. */

  LUAJIT_MODE_MAX
};

/* Flags or'ed in to the mode. */
#define LUAJIT_MODE_OFF		0x0000	/* Turn feature off. */
#define LUAJIT_MODE_ON		0x0100	/* Turn feature on. */
#define LUAJIT_MODE_FLUSH	0x0200	/* Flush JIT-compiled code. */

/* LuaJIT public C API. */

/* Control the JIT engine. */
LUA_API int luaJIT_setmode(lua_State *L, int idx, int mode);

/* Enforce (dynamic) linker error for version mismatches. Call from main. */
LUA_API void LUAJIT_VERSION_SYM(void);

#endif

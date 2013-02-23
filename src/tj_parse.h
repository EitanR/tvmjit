/*
** tVM parser (source code -> bytecode).
** Copyright (C) 2013 Francois Perrad.
**
** Major parts taken verbatim from the LuaJIT.
** Copyright (C) 2005-2013 Mike Pall.
*/

#ifndef _TJ_PARSE_H
#define _TJ_PARSE_H

#include "lj_obj.h"
#include "tj_lex.h"

LJ_FUNC GCproto *lj_parse(LexState *ls);
LJ_FUNC GCstr *lj_parse_keepstr(LexState *ls, const char *str, size_t l);
#if LJ_HASFFI
LJ_FUNC void lj_parse_keepcdata(LexState *ls, TValue *tv, GCcdata *cd);
#endif
LJ_FUNC void lj_parse_init(lua_State *L);

#endif

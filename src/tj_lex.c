/*
** Lexical analyzer.
** Copyright (C) 2013 Francois Perrad.
**
** Major portions taken verbatim or adapted from the LuaJIT.
** Copyright (C) 2005-2013 Mike Pall.
** Major portions taken verbatim or adapted from the Lua interpreter.
** Copyright (C) 1994-2008 Lua.org, PUC-Rio.
*/

#define tj_lex_c
#define LUA_CORE

#include "lj_obj.h"
#include "lj_gc.h"
#include "lj_err.h"
#include "lj_str.h"
#if LJ_HASFFI
#include "lj_tab.h"
#include "lj_ctype.h"
#include "lj_cdata.h"
#include "lualib.h"
#endif
#include "lj_state.h"
#include "tj_lex.h"
#include "tj_parse.h"
#include "lj_char.h"
#include "lj_strscan.h"

/* tVM lexer token names. */
static const char *const tokennames[] = {
#define TKSTR(name, sym)	#sym,
TKDEF(TKSTR)
#undef TKSTR
  NULL
};

/* -- Buffer handling ----------------------------------------------------- */

#define char2int(c)		((int)(uint8_t)(c))
#define next(ls) \
  (ls->current = (ls->n--) > 0 ? char2int(*ls->p++) : fillbuf(ls))
#define save_and_next(ls)	(save(ls, ls->current), next(ls))
#define currIsNewline(ls)	(ls->current == '\n' || ls->current == '\r')
#define END_OF_STREAM		(-1)

static int fillbuf(LexState *ls)
{
  size_t sz;
  const char *buf = ls->rfunc(ls->L, ls->rdata, &sz);
  if (buf == NULL || sz == 0) return END_OF_STREAM;
  ls->n = (MSize)sz - 1;
  ls->p = buf;
  return char2int(*(ls->p++));
}

static LJ_NOINLINE void save_grow(LexState *ls, int c)
{
  MSize newsize;
  if (ls->sb.sz >= LJ_MAX_STR/2)
    lj_lex_error(ls, 0, LJ_ERR_XELEM);
  newsize = ls->sb.sz * 2;
  lj_str_resizebuf(ls->L, &ls->sb, newsize);
  ls->sb.buf[ls->sb.n++] = (char)c;
}

static LJ_AINLINE void save(LexState *ls, int c)
{
  if (LJ_UNLIKELY(ls->sb.n + 1 > ls->sb.sz))
    save_grow(ls, c);
  else
    ls->sb.buf[ls->sb.n++] = (char)c;
}

static void inclinenumber(LexState *ls)
{
  int old = ls->current;
  lua_assert(currIsNewline(ls));
  next(ls);  /* skip `\n' or `\r' */
  if (currIsNewline(ls) && ls->current != old)
    next(ls);  /* skip `\n\r' or `\r\n' */
  if (++ls->linenumber >= LJ_MAX_LINE)
    lj_lex_error(ls, ls->token, LJ_ERR_XLINES);
}

/* -- Scanner for terminals ----------------------------------------------- */

/* Parse a number literal. */
static void lex_number(LexState *ls)
{
  StrScanFmt fmt;
  TValue *tv = &ls->tokenval;
  int c, xp = 'e';
  if (ls->current == '-' || ls->current == '+') {
    save_and_next(ls);
  }
  if ((c = ls->current) == '0') {
    save_and_next(ls);
    if ((ls->current | 0x20) == 'x') xp = 'p';
  }
  while (lj_char_isident(ls->current) || ls->current == '.' ||
	 ((ls->current == '-' || ls->current == '+') && (c | 0x20) == xp)) {
    c = ls->current;
    save_and_next(ls);
  }
  save(ls, '\0');
  fmt = lj_strscan_scan((const uint8_t *)ls->sb.buf, tv,
	  (LJ_DUALNUM ? STRSCAN_OPT_TOINT : STRSCAN_OPT_TONUM) |
	  (LJ_HASFFI ? (STRSCAN_OPT_LL|STRSCAN_OPT_IMAG) : 0));
  ls->token = TK_number;
  if (LJ_DUALNUM && fmt == STRSCAN_INT) {
    setitype(tv, LJ_TISNUM);
  } else if (fmt == STRSCAN_NUM) {
    /* Already in correct format. */
#if LJ_HASFFI
  } else if (fmt != STRSCAN_ERROR) {
    lua_State *L = ls->L;
    GCcdata *cd;
    lua_assert(fmt == STRSCAN_I64 || fmt == STRSCAN_U64 || fmt == STRSCAN_IMAG);
    if (!ctype_ctsG(G(L))) {
      ptrdiff_t oldtop = savestack(L, L->top);
      luaopen_ffi(L);  /* Load FFI library on-demand. */
      L->top = restorestack(L, oldtop);
    }
    if (fmt == STRSCAN_IMAG) {
      cd = lj_cdata_new_(L, CTID_COMPLEX_DOUBLE, 2*sizeof(double));
      ((double *)cdataptr(cd))[0] = 0;
      ((double *)cdataptr(cd))[1] = numV(tv);
    } else {
      cd = lj_cdata_new_(L, fmt==STRSCAN_I64 ? CTID_INT64 : CTID_UINT64, 8);
      *(uint64_t *)cdataptr(cd) = tv->u64;
    }
    lj_parse_keepcdata(ls, tv, cd);
#endif
  } else {
    lua_assert(fmt == STRSCAN_ERROR);
    lj_lex_error(ls, TK_number, LJ_ERR_XNUMBER);
  }
}

static void read_string(LexState *ls)
{
  save_and_next(ls);
  while (ls->current != '"') {
    switch (ls->current) {
    case END_OF_STREAM:
      lj_lex_error(ls, TK_eof, LJ_ERR_XSTR);
      continue;
    case '\n':
    case '\r':
      lj_lex_error(ls, TK_string, LJ_ERR_XSTR);
      continue;
    case '\\': {
      int c = next(ls);  /* Skip the '\\'. */
      switch (c) {
      case 'a': c = '\a'; break;
      case 'b': c = '\b'; break;
      case 'f': c = '\f'; break;
      case 'n': c = '\n'; break;
      case 'r': c = '\r'; break;
      case 't': c = '\t'; break;
      case 'v': c = '\v'; break;
      case 'x':  /* Hexadecimal escape '\xXX'. */
	c = (next(ls) & 15u) << 4;
	if (!lj_char_isdigit(ls->current)) {
	  if (!lj_char_isxdigit(ls->current)) goto err_xesc;
	  c += 9 << 4;
	}
	c += (next(ls) & 15u);
	if (!lj_char_isdigit(ls->current)) {
	  if (!lj_char_isxdigit(ls->current)) goto err_xesc;
	  c += 9;
	}
	break;
      case 'u':  /* Unicode escape '\uXXXX'. */
	c = (next(ls) & 15u) << 12;
	if (!lj_char_isdigit(ls->current)) {
	  if (!lj_char_isxdigit(ls->current)) goto err_xesc;
	  c += 9 << 12;
	}
	c += (next(ls) & 15u) << 8;
	if (!lj_char_isdigit(ls->current)) {
	  if (!lj_char_isxdigit(ls->current)) goto err_xesc;
	  c += 9 << 8;
	}
	c += (next(ls) & 15u) << 4;
	if (!lj_char_isdigit(ls->current)) {
	  if (!lj_char_isxdigit(ls->current)) goto err_xesc;
	  c += 9 << 4;
	}
	c += (next(ls) & 15u);
	if (!lj_char_isdigit(ls->current)) {
	  if (!lj_char_isxdigit(ls->current)) goto err_xesc;
	  c += 9;
	}
	if (c >= 0x0800) {
	  save(ls, 0xE0 | (c >> 12));
	  save(ls, 0x80 | ((c >> 6) & 0x3f));
	  c = 0x80 | (c & 0x3f);
	}
	else if (c >= 0x0080) {
	  save(ls, 0xC0 | (c >> 6));
	  c = 0x80 | (c & 0x3f);
	}
	break;
      case 'z':  /* Skip whitespace. */
	next(ls);
	while (lj_char_isspace(ls->current))
	  if (currIsNewline(ls)) inclinenumber(ls); else next(ls);
	continue;
      case '\n': case '\r': save(ls, '\n'); inclinenumber(ls); continue;
      case '\\': case '\"': case '\'': break;
      case END_OF_STREAM: continue;
      default:
      err_xesc:
	lj_lex_error(ls, TK_string, LJ_ERR_XESC);
      }
      save(ls, c);
      next(ls);
      continue;
      }
    default:
      save_and_next(ls);
      break;
    }
  }
  save_and_next(ls);  /* skip delimiter */
  setstrV(ls->L, &ls->tokenval, lj_parse_keepstr(ls, ls->sb.buf + 1, ls->sb.n - 2));
  ls->token = TK_string;
}

static void lex_name(LexState *ls)
{
  GCstr *s;
  for (;;) {
    switch (ls->current) {
      case '\n':
      case '\r':  /* line breaks */
      case ' ':
      case '\f':
      case '\t':
      case '\v':  /* spaces */
      case '(':
      case ')':
      case ':':
        goto end;
      case '\\':
        next(ls);
      default:
        save_and_next(ls);
    }
  }
end:
  s = lj_parse_keepstr(ls, ls->sb.buf, ls->sb.n);
  setstrV(ls->L, &ls->tokenval, s);
  ls->token = TK_name;
}

/* -- Main lexical scanner ------------------------------------------------ */

void lj_lex_next(LexState *ls)
{
  ls->lastline = ls->linenumber;
  lj_str_resetbuf(&ls->sb);
  for (;;) {
    switch (ls->current) {
    case '\n':
    case '\r':
      inclinenumber(ls);
      continue;
    case ' ':
    case '\t':
    case '\v':
    case '\f':
      next(ls);
      continue;
    case ';':
      next(ls);
      while (!currIsNewline(ls) && ls->current != END_OF_STREAM)
	next(ls);
      continue;
    case '(':
    case ')':
    case ':': {
      ls->token = ls->current;
      next(ls);
      return;
    }
    case '"':
      read_string(ls);
      return;
    case '-':
    case '+':
    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
      lex_number(ls);
      return;
    case END_OF_STREAM:
      ls->token = TK_eof;
      return;
    default: {
      lex_name(ls);
      return;
    }
    }
  }
}

/* -- Lexer API ----------------------------------------------------------- */

/* Setup lexer state. */
int lj_lex_setup(lua_State *L, LexState *ls)
{
  int header = 0;
  ls->L = L;
  ls->fs = NULL;
  ls->n = 0;
  ls->p = NULL;
  ls->vstack = NULL;
  ls->sizevstack = 0;
  ls->vtop = 0;
  ls->bcstack = NULL;
  ls->sizebcstack = 0;
  ls->linenumber = 1;
  ls->lastline = 1;
  lj_str_resizebuf(ls->L, &ls->sb, LJ_MIN_SBUF);
  next(ls);  /* Read-ahead first char. */
  if (ls->current == 0xef && ls->n >= 2 && char2int(ls->p[0]) == 0xbb &&
      char2int(ls->p[1]) == 0xbf) {  /* Skip UTF-8 BOM (if buffered). */
    ls->n -= 2;
    ls->p += 2;
    next(ls);
    header = 1;
  }
  if (ls->current == '#') {  /* Skip POSIX #! header line. */
    do {
      next(ls);
      if (ls->current == END_OF_STREAM) return 0;
    } while (!currIsNewline(ls));
    inclinenumber(ls);
    header = 1;
  }
  if (ls->current == LUA_SIGNATURE[0]) {  /* Bytecode dump. */
    if (header) {
      /*
      ** Loading bytecode with an extra header is disabled for security
      ** reasons. This may circumvent the usual check for bytecode vs.
      ** Lua code by looking at the first char. Since this is a potential
      ** security violation no attempt is made to echo the chunkname either.
      */
      setstrV(L, L->top++, lj_err_str(L, LJ_ERR_BCBAD));
      lj_err_throw(L, LUA_ERRSYNTAX);
    }
    return 1;
  }
  return 0;
}

/* Cleanup lexer state. */
void lj_lex_cleanup(lua_State *L, LexState *ls)
{
  global_State *g = G(L);
  lj_mem_freevec(g, ls->bcstack, ls->sizebcstack, BCInsLine);
  lj_mem_freevec(g, ls->vstack, ls->sizevstack, VarInfo);
  lj_str_freebuf(g, &ls->sb);
}

const char *lj_lex_token2str(LexState *ls, LexToken token)
{
  if (token > TK_OFS)
    return tokennames[token-TK_OFS-1];
  else if (!lj_char_iscntrl(token))
    return lj_str_pushf(ls->L, "%c", token);
  else
    return lj_str_pushf(ls->L, "char(%d)", token);
}

void lj_lex_error(LexState *ls, LexToken token, ErrMsg em, ...)
{
  const char *tok;
  va_list argp;
  if (token == 0) {
    tok = NULL;
  } else if (token == TK_name || token == TK_string || token == TK_number) {
    save(ls, '\0');
    tok = ls->sb.buf;
  } else {
    tok = lj_lex_token2str(ls, token);
  }
  va_start(argp, em);
  lj_err_lex(ls->L, ls->chunkname, tok, ls->linenumber, em, argp);
  va_end(argp);
}


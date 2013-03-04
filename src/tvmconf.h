/*
** Configuration header.
** Copyright (C) 2013 Francois Perrad.
*/

#ifndef tvmconf_h
#define tvmconf_h

#include "luaconf.h"

/* Default path for loading Lua and C modules with require(). */
#if defined(_WIN32)
/*
** In Windows, any exclamation mark ('!') in the path is replaced by the
** path of the directory of the executable file of the current process.
*/
#define TVM_LDIR	"!\\tvm\\"
#define TVM_CDIR	"!\\"
#define TVM_PATH_DEFAULT \
  ".\\?.lua;" LUA_LDIR"?.lua;" LUA_LDIR"?\\init.lua;"
#define LUA_CPATH_DEFAULT \
  ".\\?.dll;" LUA_CDIR"?.dll;" LUA_CDIR"loadall.dll"
#else
/*
** Note to distribution maintainers: do NOT patch the following line!
** Please read ../doc/install.html#distro and pass PREFIX=/usr instead.
*/
#define LUA_ROOT	"/usr/local/"
#define LUA_LDIR	LUA_ROOT "share/lua/5.1/"
#define LUA_CDIR	LUA_ROOT "lib/lua/5.1/"
#ifdef TVM_XROOT
#define TVM_JDIR	TVM_XROOT "share/tvmjit-0.0.1/"
#define TVM_XPATH
#define TVM_XCPATH	TVM_XROOT "lib/tvmjit/5.1/?.so;"
#else
#define TVM_JDIR	LUA_ROOT "share/tvmjit-0.0.1/"
#define TVM_XPATH
#define TVM_XCPATH	LUA_ROOT "lib/tvmjit/5.1/?.so;"
#endif
#define TVM_PATH_DEFAULT \
  "./?.lua;" TVM_JDIR"?.lua;" TVM_XPATH
#define TVM_CPATH_DEFAULT \
  "./?.so;" TVM_XCPATH LUA_CDIR"?.so;"
#endif

/* Environment variable names for path overrides and initialization code. */
#define TVM_PATH	"TVM_PATH"
#define TVM_CPATH	"TVM_CPATH"
#define TVM_INIT	"TVM_INIT"

#endif

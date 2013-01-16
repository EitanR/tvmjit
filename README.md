README for TvmJIT
=================

TvmJIT is a hack around [LuaJIT](http://luajit.org/).

The goal is a more generic VM which could be used for various dynamic languages.
tVM stands for Table Virtual Machine, table is the main structure type in Lua.

Main differences with LuaJIT :

- the TP (Table Processing) language uses the S-expression syntax (but the semantic still Lua)
- array and string start at 0
- TvmJIT includes a port of LPeg, the Parsing Expression Grammars for Lua
- an almost comprehensive test suite (using TAP format)


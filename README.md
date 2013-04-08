README for TvmJIT
=================

[![Build Status](https://travis-ci.org/fperrad/tvmjit.png)](https://travis-ci.org/fperrad/tvmjit)

TvmJIT is a hack around [LuaJIT](http://luajit.org/).

The goal is a more generic VM which could be used for various dynamic languages.
tVM stands for Table Virtual Machine, table is the main structure type in Lua.

Main differences with LuaJIT :

- the TP (Table Processing) language uses the S-expression syntax (but the semantic still Lua)
- an almost comprehensive test suite (using TAP format)

A Lua interpreter is built over TvmJIT, and it could use libraries like LPeg and lua-linenoise.

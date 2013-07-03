#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call (!index tvm "dofile") "TAP.tp")

(!let plan plan)
(!let ok ok)
(!let type_ok type_ok)

(!call plan 23)

(!call ok (!index (!index package "loaded") "_G") "table package.loaded")
(!call ok (!index (!index package "loaded") "coroutine"))
(!call ok (!index (!index package "loaded") "io"))
(!call ok (!index (!index package "loaded") "math"))
(!call ok (!index (!index package "loaded") "os"))
(!call ok (!index (!index package "loaded") "package"))
(!call ok (!index (!index package "loaded") "string"))
(!call ok (!index (!index package "loaded") "table"))
(!call ok (!index (!index package "loaded") "bit"))
(!call ok (!index (!index package "loaded") "jit"))

(!call type_ok (!index package "path") "string")

(!call type_ok (!index package "preload") "table" "table package.preload")
(!call is (!len (!index package "preload")) 0)

(!call type_ok (!index package "loaders") "table" "table package.loaders")

(!let m (!call require "linenoise"))
(!call (!index m "historyadd") "line")
(!call is m (!index (!index package "loaded") "linenoise"))

(!let p (!call (!index package "searchpath") "linenoise" (!index package "cpath")))
(!call type_ok p "string" "searchpath")
(!let p (!call (!index package "searchpath") "linenoise" "bad path"))
(!call is p !nil)

(!let f (!call (!index io "open") "complex.lua" "w"))
(!callmeth f write "
complex = {}

function complex.new (r, i) return {r=r, i=i} end

--defines a constant 'i'
complex.i = complex.new(0, 1)

function complex.add (c1, c2)
    return complex.new(c1.r + c2.r, c1.i + c2.i)
end

function complex.sub (c1, c2)
    return complex.new(c1.r - c2.r, c1.i - c2.i)
end

function complex.mul (c1, c2)
    return complex.new(c1.r*c2.r - c1.i*c2.i,
                       c1.r*c2.i + c1.i*c2.r)
end

local function inv (c)
    local n = c.r^2 + c.i^2
    return complex.new(c.r/n, -c.i/n)
end

function complex.div (c1, c2)
    return complex.mul(c1, inv(c2))
end

return complex
")
(!callmeth f close)
(!let m (!call require "complex"))
(!call is m complex "function require")
(!call is (!index (!index complex "i") "r") 0)
(!call is (!index (!index complex "i") "i") 1)
(!call (!index os "remove") "complex.lua")      ; clean up

(!call error_contains (!lambda () (!call require "no_module"))
                      ": module 'no_module' not found:"
                      "function require (no module)")

(!assign foo ())
(!assign (!index foo "bar") 1234)
(!assign foo_loader (!lambda () (!return foo)))
(!assign (!index (!index package "preload") "foo") foo_loader)
(!let m (!call require "foo"))
(!call assert (!eq m foo))
(!call is (!index m "bar") 1234 "function require & package.preload")

(!let f (!call (!index io "open") "bar.lua" "w"))
(!callmeth f write "
    print('    in bar.lua', ...)
    a = ...
")
(!callmeth f close)
(!assign a !nil)
(!call require "bar")
(!call is a "bar" "function require (arg)")
(!call (!index os "remove") "bar.lua")   ; clean up


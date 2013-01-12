#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call require "TAP")

(!let plan plan)
(!let ok ok)
(!let type_ok type_ok)

(!call plan 24)

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

(!let m (!call require "TAP"))
(!call (!index m "ok") !true "function require")
(!call is m (!index (!index package "loaded") "TAP"))

(!let p (!call (!index package "searchpath") "TAP" (!index package "path")))
(!call type_ok p "string" "searchpath")
(!let p (!call (!index package "searchpath") "TAP" "bad path"))
(!call is p !nil)

(!let f (!call (!index io "open") "complex.tp" "w"))
(!callmeth f write "\
(!assign complex ())\
\
(!assign (!index complex \"new\") (!lambda (r i)\
                (!return (\"r\":r \"i\":i))))\
\
; defines a constant 'i'\
(!assign (!index complex \"i\") (!call (!index complex \"new\") 0 1))\
\
(!assign (!index complex \"add\") (!lambda (c1 c2)\
                (!return (!call (!index complex \"new\") (!add (!index c1 \"r\") (!index c2 \"r\"))\
                                                         (!add (!index c1 \"i\") (!index c2 \"i\"))))))\
\
(!assign (!index complex \"sub\") (!lambda (c1 c2)\
                (!return (!call (!index complex \"new\") (!sub (!index c1 \"r\") (!index c2 \"r\"))\
                                                         (!sub (!index c1 \"i\") (!index c2 \"i\"))))))\
\
(!return complex)\
")
(!callmeth f close)
(!let m (!call require "complex"))
(!call is m complex "function require")
(!call is (!index (!index complex "i") "r") 0)
(!call is (!index (!index complex "i") "i") 1)
(!call (!index os "remove") "complex.tp")      ; clean up

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

(!let f (!call (!index io "open") "bar.tp" "w"))
(!callmeth f write "\
    (!call print \"    in bar.tp\" !vararg)\
    (!assign a !vararg)\
")
(!callmeth f close)
(!assign a !nil)
(!call require "bar")
(!call is a "bar" "function require (arg)")
(!call (!index os "remove") "bar.tp")   ; clean up


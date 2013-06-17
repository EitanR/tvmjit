#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call (!index tvm "dofile") "TAP.tp")

(!let load (!index tvm "load"))
(!let plan plan)
(!let type_ok type_ok)
(!let contains contains)
(!let lives_ok lives_ok)

(!call plan 8)

;   orphan break
(!define (f msg) ((!call load "
(!let f (!lambda ()
    (!call println \"before\")
    (!do
        (!call println \"inner\")
        (!break))
    (!call println \"after\")))
")))
(!call contains msg ": no loop to break" "orphan break")

;   break anywhere
(!call lives_ok (!call load "
(!let f (!lambda ()
    (!call println \"before\")
    (!while !true
        (!call println \"inner\")
        (!break)
        (!call println \"break\"))
    (!call println \"after\")))
") "break anywhere")

;   goto
(!define (f msg) ((!call load "
(!label L)
(!goto unknown)
")))
(!call contains msg ": undefined label 'unknown'" "unknown goto")

(!define (f msg) ((!call load "
(!label L)
(!goto L)
(!label L)
")))
(!call contains msg ": duplicate label 'L'" "repeated label")

(!define (f msg) ((!call load "
(!label e)
(!goto f)
(!define x)
(!label f)
(!goto e)
")))
(!call contains msg ": <goto f> jumps into the scope of local 'x'" "bad goto")

;   final / !let
(!define (f msg) ((!call load "
(!define a)
(!let b)
")))
(!call contains msg ": 'expr' expected near" "let alone")

(!define (f msg) ((!call load "
(!let b 1)
(!assign b 2)
")))
(!call contains msg ": assign a final variable near '2'" "assign let")

(!define (f msg) ((!call load "
(!let b 1)
(!let f (!lambda ()
    (!assign b 2)))
")))
(!call contains msg ": assign a final upvar near '2'" "assign let")


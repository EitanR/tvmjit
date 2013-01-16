#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-CodeGen library.
;   Copyright (c) 2010-2011 Francois Perrad
;

(!call require "TAP")

(!let CodeGen (!call require "CodeGen"))

(!call plan 2)

(!assign tmpl1 (!call CodeGen ("_a": " ${a} ${_b()} "
                               "_b": " (${b}) "
                               "a": "print"
                               "b": 1)))

(!call is (!call tmpl1 "_a") " print  (1)  ")

(!assign tmpl2 (!call CodeGen ("_b": " [${c}] "
                               "a": "call") tmpl1 ("c": 2)))

(!call is (!call tmpl2 "_a") " call  [2]  ")


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

(!call plan 1)

(!assign tmpl (!call dofile "../t/CodeGen/tmpl.tp"))
(!assign (!index tmpl "data") (("name": "key1" "value": 1)
                               ("name": "key2" "value": 2)
                               ("name": "key3" "value": 3)))
(!call is (!call tmpl "top") "\
begin\
        print(\"key1 = 1\");\
        print(\"key2 = 2\");\
        print(\"key3 = 3\");\
end\
" "external")


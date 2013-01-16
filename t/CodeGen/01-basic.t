#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-CodeGen library.
;   Copyright (c) 2010-2011 Francois Perrad
;

(!call require "TAP")

(!let tostring tostring)
(!let CodeGen (!call require "CodeGen"))

(!call plan 8)

(!assign tmpl (!call CodeGen))
(!call type_ok tmpl "table" "new CodeGen")
(!assign (!index tmpl "a") "some text")
(!call is (!call tmpl "a") "some text" "eval \"a\"")

(!assign tmpl (!call CodeGen ("pi": 3.14159
                              "str": "some text")))
(!call type_ok tmpl "table" "new CodeGen")
(!assign (!index tmpl "pi") 3.14)
(!call is (!call tmpl "str") "some text" "eval \"str\"")
(!call is (!call tmpl "pi") "3.14" "eval \"pi\"")
(!call isnt (!call tmpl "pi") 3.14)
(!call is (!call tmpl "unk") "" "unknown gives an empty string" )

(!call is (!call tostring tmpl) "CodeGen" "__tostring")

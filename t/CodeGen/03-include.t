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

(!call plan 5)

(!assign tmpl (!call CodeGen ("outer": "\
begin\
    ${inner()}\
end\
"
                              "inner": "print(\"${hello}\");"
                              "hello": "Hello, world!")))
(!call is (!call tmpl "outer") "\
begin\
    print(\"Hello, world!\");\
end\
" "")

(!assign (!index tmpl "inner") 3.14)
(!massign (res msg) ((!call tmpl "outer")))
(!call is res "\
begin\
    ${inner()}\
end\
" "not a template")
(!call is msg "outer:3: inner is not a template" )

(!assign tmpl (!call CodeGen ("top": "\
${outer()}\
"
                              "outer": "\
begin\
    ${inner()}\
end\
"
                              "inner": "print(\"${outer()}\");")))
(!massign (res msg) ((!call tmpl "top")))
(!call is res "\
\
begin\
    print(\"${outer()}\");\
end\
" "cyclic call")
(!call is msg "inner:1: cyclic call of outer")


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

(!call plan 10)

(!assign tmpl (!call CodeGen ("outer": "\
begin\
${data/inner()}\
end\
"
                              "inner": "\
    print(\"${name()} = ${value}\");\
")))
(!call is (!call tmpl "outer") "\
begin\
end\
" "empty")

(!assign tmpl (!call CodeGen ("outer": "\
begin\
    ${data/inner()}\
end\
"
                              "inner": "    print(\"${name()} = ${value}\");\
")))
(!assign (!index tmpl "data") (("name": "key1" "value": 1)
                               ("name": "key2" "value": 2)
                               ("name": "key3" "value": 3)))
(!call is (!call tmpl "outer") "\
begin\
        print(\"key1 = 1\");\
        print(\"key2 = 2\");\
        print(\"key3 = 3\");\
end\
" "with array")

(!assign (!index tmpl "inner") 3.14)
(!massign (res msg) ((!call tmpl "outer")))
(!call is res "\
begin\
    ${data/inner()}\
end\
" "not a template")
(!call is msg "outer:3: inner is not a template")

(!assign (!index tmpl "data") 3.14)
(!massign (res msg) ((!call tmpl "outer")))
(!call is res "\
begin\
    ${data/inner()}\
end\
" "not a table")
(!call is msg "outer:3: data is not a table")

(!assign tmpl (!call CodeGen ("outer": "\
begin\
${data/inner()}\
end\
"
                              "inner": "    print(${it});\
")))
(!assign (!index tmpl "data") (1 2 3))
(!call is (!call tmpl "outer") "\
begin\
    print(1);\
    print(2);\
    print(3);\
end\
" "it")

(!assign (!index tmpl "data") ())
(!call is (!call tmpl "outer") "\
begin\
end\
" "it")

(!assign tmpl (!call CodeGen ("outer": "\
begin\
    call(${data/inner(); separator=', '});\
end\
"
                              "inner": "${it}")))
(!assign (!index tmpl "data") (1 2 3))
(!call is (!call tmpl "outer") "\
begin\
    call(1, 2, 3);\
end\
" "with sep")

(!assign tmpl (!call CodeGen ("outer": "\
begin\
    list(\
        ${data/inner(); separator=\",\\n\"}\
    );\
end\
"
                              "inner": "${it}")))
(!assign (!index tmpl "data") (1 2 3))
(!call is (!call tmpl "outer") "\
begin\
    list(\
        1,\
        2,\
        3\
    );\
end\
" "sep with escape seq")


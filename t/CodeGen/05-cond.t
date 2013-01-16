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

(!call plan 4)

(!assign tmpl (!call CodeGen ("outer": "\
begin\
    ${data.locale?inner_fr()!inner_en()}\
end\
"
                             "inner_en": "print(\"Hello, ${data.guy}\");"
                             "inner_fr": "print(\"Bonjour, ${data.guy}\");")))

(!assign (!index tmpl "data") ())
(!assign (!index (!index tmpl "data") "locale") !true)
(!assign (!index (!index tmpl "data") "guy") "toi")
(!call is (!call tmpl "outer") "\
begin\
    print(\"Bonjour, toi\");\
end\
")

(!assign (!index (!index tmpl "data") "locale") !false)
(!assign (!index (!index tmpl "data") "guy") "you")
(!call is (!call tmpl "outer") "\
begin\
    print(\"Hello, you\");\
end\
")

(!assign tmpl (!call CodeGen ("outer": "\
begin\
${data.guy?inner()}\
end\
"
                              "inner": "print(\"Hello, ${data.guy}\");")))
(!assign (!index tmpl "data") ())
(!assign (!index (!index tmpl "data") "guy") "you")
(!call is (!call tmpl "outer") "\
begin\
print(\"Hello, you\");\
end\
")

(!assign (!index (!index tmpl "data") "guy")  !nil)
(!call is (!call tmpl "outer") "\
begin\
end\
")


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

(!call plan 21)

(!assign tmpl (!call CodeGen ("code": "print(\"${hello}, ${_guy1; format=upper}\");"
                              "upper": (!index string "upper")
                              "hello": "Hello"
                              "_guy1": "you")))

(!call is (!call tmpl "code") "print(\"Hello, YOU\");" "scalar attributes")
(!assign (!index tmpl "hello") "Hi")
(!massign (res msg) ((!call tmpl "code")))
(!call is res "print(\"Hi, YOU\");")
(!call is msg !nil "no error" )

(!assign tmpl (!call CodeGen))
(!assign (!index tmpl "a") ("abc" "def" "hij"))
(!assign (!index tmpl "upper1") (!index string "upper"))
(!assign (!index tmpl "upper2") (!lambda (str) (!return (!call (!index string "upper") str))))
(!assign (!index tmpl "upper3") (!index tmpl "upper2"))
(!assign (!index tmpl "code") "print(${a})")
(!call is (!call tmpl "code") "print(abcdefhij)" "array")
(!assign (!index tmpl "code") "print(${a; separator=', '})")
(!call is (!call tmpl "code") "print(abc, def, hij)" "array with sep")
(!assign (!index tmpl "code") "print(${a; separator = \"\\44\\32\" })")
(!call is (!call tmpl "code") "print(abc, def, hij)" "array with sep")
(!assign (!index tmpl "code") "print(${a; format=upper1 })")
(!call is (!call tmpl "code") "print(ABCDEFHIJ)" "array")
(!assign (!index tmpl "code") "print(${a; separator='\\044\\032'; format=upper2})")
(!call is (!call tmpl "code") "print(ABC, DEF, HIJ)" "array with sep & format")
(!call eq_array (!index tmpl "a") ("abc" "def" "hij") "don't alter the original table")
(!assign (!index tmpl "code") "print(${a; separator = \", \" ; format = upper3 })")
(!call is (!call tmpl "code") "print(ABC, DEF, HIJ)" "array with sep & format")
(!call eq_array (!index tmpl "a") ("abc" "def" "hij") "don't alter the original table")

(!assign tmpl (!call CodeGen ("code": "print(\"${data.hello}, ${data.people.guy}\");"
                              "data": ("hello": "Hello"
                                       "people": ("guy": "you")))))
(!call is (!call tmpl "code") "print(\"Hello, you\");" "complex attr")
(!assign (!index (!index tmpl "data") "hello") "Hi")
(!call is (!call tmpl "code") "print(\"Hi, you\");")

(!assign (!index tmpl "code") "print(\"${hello}, ${people.guy}\");")
(!massign (res msg) ((!call tmpl "code")))
(!call is res "print(\", \");" "missing attr")
(!call is msg "code:1: people.guy is invalid" )

(!assign (!index tmpl "code") "print(\"${hello-people}\");")
(!massign (res msg) ((!call tmpl "code")))
(!call is res "print(\"${hello-people}\");" "no match")
(!call is msg "code:1: ${hello-people} does not match")

(!assign (!index tmpl "code") "print(\"${ hello }\");")
(!massign (res msg) ((!call tmpl "code")))
(!call is res "print(\"${ hello }\");" "no match")
(!call is msg "code:1: ${ hello } does not match")

(!assign (!index tmpl "code") "print(\"${hello; format=lower }\");")
(!massign (res msg) ((!call tmpl "code")))
(!call is res "print(\"${hello; format=lower }\");" "no formatter")
(!call is msg "code:1: lower is not a formatter")


#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call dofile "TAP.tp")

(!let print print)
(!let type type)
(!let plan plan)
(!let error_contains error_contains)
(!let is is)
(!let ok ok)

(!call plan 51)

(!define f (!lambda () (!return 1)))

(!call error_contains (!lambda () (!return (!neg f)))
                      ": attempt to perform arithmetic on"
                      "!neg f")

(!call error_contains (!lambda () (!assign f print)(!return (!neg f)))
                       ": attempt to perform arithmetic on")

(!call error_contains (!lambda () (!return (!len f)))
                      ": attempt to get length of"
                      "!len f")

(!call error_contains (!lambda () (!assign f print)(!return (!len f)))
                      ": attempt to get length of")

(!call is (!not f) !false "!not f")

(!call is (!not print) !false)

(!call error_contains (!lambda () (!return (!add f 10)))
                      ": attempt to perform arithmetic on"
                      "!add f 10")

(!call error_contains (!lambda () (!assign f print)(!return (!add f 10)))
                      ": attempt to perform arithmetic on")

(!call error_contains (!lambda () (!return (!sub f 2)))
                      ": attempt to perform arithmetic on"
                      "!sub f 2")

(!call error_contains (!lambda () (!assign f print)(!return (!sub f 2)))
                      ": attempt to perform arithmetic on")

(!call error_contains (!lambda () (!return (!mul f 3.14)))
                      ": attempt to perform arithmetic on"
                      "!mul f 3.14")

(!call error_contains (!lambda () (!assign f print)(!return (!mul f 3.14)))
                      ": attempt to perform arithmetic on")

(!call error_contains (!lambda () (!return (!div f -7)))
                      ": attempt to perform arithmetic on"
                      "!div f -7")

(!call error_contains (!lambda () (!assign f print)(!return (!div f -7)))
                      ": attempt to perform arithmetic on")

(!call error_contains (!lambda () (!return (!mod f 4)))
                      ": attempt to perform arithmetic on"
                      "!mod f 4")

(!call error_contains (!lambda () (!assign f print)(!return (!mod f 4)))
                      ": attempt to perform arithmetic on")

(!call error_contains (!lambda () (!return (!pow f 3)))
                      ": attempt to perform arithmetic on"
                      "!pow f 3")

(!call error_contains (!lambda () (!assign f print)(!return (!pow f 3)))
                      ": attempt to perform arithmetic on")

(!call error_contains (!lambda () (!return (!concat f "end")))
                      ": attempt to concatenate"
                      "!concat f \"end\"")

(!call error_contains (!lambda () (!assign f print)(!return (!concat f "end")))
                      ": attempt to concatenate")

(!define g f)
(!call is (!eq f g) !true "!eq f f")

(!assign g print)
(!call is (!eq g print) !true)

(!assign g (!lambda () (!return 2)))
(!call is (!ne f g) !true "!ne f g")
(!define h type)
(!call is (!ne f h) !true)

(!call is (!ne print g) !true)
(!call is (!ne print h) !true)

(!call is (!eq f 1) !false "!ne f 1")

(!call is (!eq print 1) !false)

(!call is (!ne f 1) !true "!ne f 1")

(!call is (!ne print 1) !true)

(!call error_contains (!lambda () (!return (!lt f g)))
                      ": attempt to compare two function values"
                      "!lt f g")

(!call error_contains (!lambda () (!assign f print)(!assign g type)(!return (!lt f g)))
                      ": attempt to compare two function values")

(!call error_contains (!lambda () (!return (!le f g)))
                      ": attempt to compare two function values"
                      "!le f g")

(!call error_contains (!lambda () (!assign f print)(!assign g type)(!return (!le f g)))
                      ": attempt to compare two function values")

(!call error_contains (!lambda () (!return (!gt f g)))
                      ": attempt to compare two function values"
                      "!gt f g")

(!call error_contains (!lambda () (!assign f print)(!assign g type)(!return (!gt f g)))
                      ": attempt to compare two function values")

(!call error_contains (!lambda () (!return (!ge f g)))
                      ": attempt to compare two function values"
                      "!ge f g")

(!call error_contains (!lambda () (!assign f print)(!assign g type)(!return (!ge f g)))
                      ": attempt to compare two function values")

(!call error_contains (!lambda () (!return (!lt f 0)))
                      ": attempt to compare function with number"
                      "!lt f 0")

(!call error_contains (!lambda () (!assign f print)(!return (!lt f 0)))
                      ": attempt to compare function with number")

(!call error_contains (!lambda () (!return (!le f 0)))
                      ": attempt to compare number with function"
                      "!le f 0")

(!call error_contains (!lambda () (!assign f print)(!return (!le f 0)))
                      ": attempt to compare number with function")

(!call error_contains (!lambda () (!return (!gt f 0)))
                      ": attempt to compare number with function"
                      "!gt f 0")

(!call error_contains (!lambda () (!assign f print)(!return (!gt f 0)))
                      ": attempt to compare number with function")

(!call error_contains (!lambda () (!return (!ge f 0)))
                      ": attempt to compare function with number"
                      "!ge f 0")

(!call error_contains (!lambda () (!assign f print)(!return (!ge f 0)))
                      ": attempt to compare function with number")

(!call error_contains (!lambda () (!define a f)(!define b (!index a 1)))
                      ": attempt to index"
                      "index")

(!call error_contains (!lambda () (!define a print)(!define b (!index a 1)))
                      ": attempt to index")

(!call error_contains (!lambda () (!define a f)(!assign (!index a 1) 1))
                      ": attempt to index"
                      "index")

(!call error_contains (!lambda () (!define a print)(!assign (!index a 1) 1))
                      ": attempt to index")

(!let t ())
(!assign (!index t "print") !true)
(!call ok (!index t "print"))


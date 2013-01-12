#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call dofile "TAP.tp")

(!let plan plan)
(!let error_contains error_contains)
(!let is is)

(!call plan 24)

(!call error_contains (!lambda () (!return (!neg !true)))
                       ": attempt to perform arithmetic on a boolean value"
                       "!neg !true")

(!call error_contains (!lambda () (!return (!len !true)))
                      ": attempt to get length of a boolean value"
                      "!len !true")

(!call is (!not !false) !true "!not !false")

(!call error_contains (!lambda () (!return (!add !true 10)))
                      ": attempt to perform arithmetic on a boolean value"
                      "!add !true 10")

(!call error_contains (!lambda () (!return (!sub !true 2)))
                      ": attempt to perform arithmetic on a boolean value"
                      "!sub !true 2")

(!call error_contains (!lambda () (!return (!mul !true 3.14)))
                      ": attempt to perform arithmetic on a boolean value"
                      "!mul !true 3.14")

(!call error_contains (!lambda () (!return (!div !true -7)))
                      ": attempt to perform arithmetic on a boolean value"
                      "!div !true -7")

(!call error_contains (!lambda () (!return (!mod !true 4)))
                      ": attempt to perform arithmetic on a boolean value"
                      "!mod !true 4")

(!call error_contains (!lambda () (!return (!pow !true 3)))
                      ": attempt to perform arithmetic on a boolean value"
                      "!pow !true 3")

(!call error_contains (!lambda () (!return (!concat !true "end")))
                      ": attempt to concatenate a boolean value"
                      "!concat !true \"end\"")

(!call is (!eq !true !true) !true "!eq !true !true")

(!call is (!ne !true !false) !true "!ne !true !false")

(!call is (!eq !true 1) !false "!eq !true 1")

(!call is (!ne !true 1) !true "!ne !true 1")

(!call error_contains (!lambda () (!return (!lt !true !false)))
                      ": attempt to compare two boolean values"
                      "!lt !true !false")

(!call error_contains (!lambda () (!return (!le !true !false)))
                      ": attempt to compare two boolean values"
                      "!le !true !false")

(!call error_contains (!lambda () (!return (!gt !true !false)))
                      ": attempt to compare two boolean values"
                      "!gt !true !false")

(!call error_contains (!lambda () (!return (!ge !true !false)))
                      ": attempt to compare two boolean values"
                      "!ge !true !false")

(!call error_contains (!lambda () (!return (!lt !true 0)))
                      ": attempt to compare boolean with number"
                       "!lt !true 0")

(!call error_contains (!lambda () (!return (!le !true 0)))
                      ": attempt to compare number with boolean"
                      "!le !true 0")

(!call error_contains (!lambda () (!return (!gt !true 0)))
                      ": attempt to compare number with boolean"
                      "!gt !true 0")

(!call error_contains (!lambda () (!return (!ge !true 0)))
                      ": attempt to compare boolean with number"
                      "!ge !true 0")

(!call error_contains (!lambda () (!define a !true)(!define b (!index a 1)))
                      ": attempt to index"
                      "index")

(!call error_contains (!lambda () (!define a !true)(!assign (!index a 1) 1))
                      ": attempt to index"
                      "index")


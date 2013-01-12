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
(!let ok ok)
(!let coroutine coroutine)

(!call plan 25)

(!let co (!call (!index coroutine "create") (!lambda () (!return 1))))

(!call error_contains (!lambda () (!return (!neg co)))
                      ": attempt to perform arithmetic on"
                      "!neg co")

(!call error_contains (!lambda () (!return (!len co)))
                      ": attempt to get length of"
                      "!len co")

(!call is (!not co) !false "!not co")

(!call error_contains (!lambda () (!return (!add co 10)))
                      ": attempt to perform arithmetic on"
                      "!add co 10")

(!call error_contains (!lambda () (!return (!sub co 2)))
                      ": attempt to perform arithmetic on"
                      "!sub co 2")

(!call error_contains (!lambda () (!return (!mul co 3.14)))
                      ": attempt to perform arithmetic on"
                      "!mul co 3.14")

(!call error_contains (!lambda () (!return (!div co 7)))
                      ": attempt to perform arithmetic on"
                      "!div co 7")

(!call error_contains (!lambda () (!return (!mod co 4)))
                      ": attempt to perform arithmetic on"
                      "!mod co 4")

(!call error_contains (!lambda () (!return (!pow co 3)))
                      ": attempt to perform arithmetic on"
                      "!pow co 3")

(!call error_contains (!lambda () (!return (!concat co "end")))
                      ": attempt to concatenate"
                      "!concat co \"end\"")

(!call is (!eq co co) !true "!eq co co")

(!let co1 (!call (!index coroutine "create") (!lambda () (!return 1))))
(!let co2 (!call (!index coroutine "create") (!lambda () (!return 2))))
(!call is (!ne co1 co2)  !true "!ne co1 co2")

(!call is (!eq co 1) !false "!eq co 1")

(!call is (!ne co 1) !true "!ne co 1")

(!call error_contains (!lambda () (!return (!lt co1 co2)))
                      ": attempt to compare two thread values"
                      "!lt co1 co2")

(!call error_contains (!lambda () (!return (!le co1 co2)))
                      ": attempt to compare two thread values"
                      "!le co1 co2")

(!call error_contains (!lambda () (!return (!gt co1 co2)))
                      ": attempt to compare two thread values"
                      "!gt co1 co2")

(!call error_contains (!lambda () (!return (!ge co1 co2)))
                      ": attempt to compare two thread values"
                      "!ge co1 co2")

(!call error_contains (!lambda () (!return (!lt co 0)))
                      ": attempt to compare thread with number"
                      "!lt co 0")

(!call error_contains (!lambda () (!return (!le co 0)))
                      ": attempt to compare number with thread"
                      "!le co 0")

(!call error_contains (!lambda () (!return (!gt co 0)))
                      ": attempt to compare number with thread"
                      "!gt co 0")

(!call error_contains (!lambda () (!return (!ge co 0)))
                      ": attempt to compare thread with number"
                      "!ge co 0")

(!call error_contains (!lambda () (!assign a (!index co 1)))
                      ": attempt to index"
                      "index")

(!call error_contains (!lambda () (!assign (!index co 1) 1))
                      ": attempt to index"
                      "index")

(!let t ())
(!assign (!index t co) !true)
(!call ok (!index t co))


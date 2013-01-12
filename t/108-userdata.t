#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call dofile "TAP.tp")

(!let peg peg)
(!let plan plan)
(!let error_contains error_contains)
(!let is is)
(!let ok ok)

(!call plan 25)

(!let u (!call (!index peg "literal") "u"))

(!call error_contains (!lambda () (!return (!neg u)))
                      ": attempt to perform arithmetic on"
                      "!neg u")

(!call error_contains (!lambda () (!return (!len u)))
                      ": attempt to get length of"
                      "!len u")

(!call is (!not u) !false "!not u")

(!call error_contains (!lambda () (!return (!add u 10)))
                      ": attempt to perform arithmetic on"
                      "!add u 10")

(!call error_contains (!lambda () (!return (!sub u 2)))
                      ": attempt to perform arithmetic on"
                      "!sub u 2")

(!call error_contains (!lambda () (!return (!mul u 3.14)))
                      ": attempt to perform arithmetic on"
                      "!mul u 3.14")

(!call error_contains (!lambda () (!return (!div u 7)))
                      ": attempt to perform arithmetic on"
                      "!div u 7")

(!call error_contains (!lambda () (!return (!mod u 4)))
                      ": attempt to perform arithmetic on"
                      "!mod u 4")

(!call error_contains (!lambda () (!return (!pow u 3)))
                      ": attempt to perform arithmetic on"
                      "!pow u 3")

(!call error_contains (!lambda () (!return (!concat u "end")))
                      ": attempt to concatenate"
                      "!concat u \"end\"")

(!call is (!eq u u) !true "!eq u u")

(!let v (!call (!index peg "literal") "v"))
(!call is (!ne u v) !true "!ne u v")

(!call is (!eq u 1) !false "!eq u 1")

(!call is (!ne u 1) !true "!ne u 1")

(!call error_contains (!lambda () (!return (!lt u v)))
                      ": attempt to compare two userdata values"
                      "!lt u v")

(!call error_contains (!lambda () (!return (!le u v)))
                      ": attempt to compare two userdata values"
                      "!le u v")

(!call error_contains (!lambda () (!return (!gt u v)))
                      ": attempt to compare two userdata values"
                      "!gt u v")

(!call error_contains (!lambda () (!return (!ge u v)))
                      ": attempt to compare two userdata values"
                      "!ge u v")

(!call error_contains (!lambda () (!return (!lt u 0)))
                      ": attempt to compare userdata with number"
                      "!lt u 0")

(!call error_contains (!lambda () (!return (!le u 0)))
                      ": attempt to compare number with userdata"
                      "!lt u 0")

(!call error_contains (!lambda () (!return (!gt u 0)))
                      ": attempt to compare number with userdata"
                      "!gt u 0")

(!call error_contains (!lambda () (!return (!ge u 0)))
                      ": attempt to compare userdata with number"
                      "!ge u 0")

(!call is (!index u 1) !nil "index")

(!call error_contains (!lambda () (!assign (!index u 1) 1))
                      ": attempt to index"
                      "index")

(!let t ())
(!assign (!index t u) !true)
(!call ok (!index t u))


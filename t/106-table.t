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

(!call plan 28)

(!call error_contains (!lambda () (!return (!neg ())))
                      ": attempt to perform arithmetic on"
                      "!neg ()")

(!call is (!len ()) 0 "!len ()")
(!call is (!len (4 5 6)) 3)

(!call is (!not ()) !false "!not ()")

(!call error_contains (!lambda() (!return (!add () 10)))
                      ": attempt to perform arithmetic on"
                      "!add () 10")

(!call error_contains (!lambda() (!return (!sub () 2)))
                      ": attempt to perform arithmetic on"
                      "!sub () 2")

(!call error_contains (!lambda() (!return (!mul () 3.14)))
                      ": attempt to perform arithmetic on"
                      "!mul () 3.14")

(!call error_contains (!lambda() (!return (!div () 7)))
                      ": attempt to perform arithmetic on"
                      "!div () 7")

(!call error_contains (!lambda() (!return (!mod () 4)))
                      ": attempt to perform arithmetic on"
                      "!mod () 4")

(!call error_contains (!lambda() (!return (!pow () 3)))
                      ": attempt to perform arithmetic on"
                      "!pow () 3")

(!call error_contains (!lambda () (!return (!concat () "end")))
                      ": attempt to concatenate"
                      "!concat () \"end\"")

(!call is (!eq () ()) !false "!eq () ()")

(!let t1 ())
(!let t2 ())
(!call is (!eq t1 t1) !true "!eq t1 t1")
(!call is (!eq t1 t2) !false "!eq t1 t2")
(!call is (!ne t1 t2) !true "!ne t1 t2")

(!call is (!eq () 1) !false "!eq () 1")

(!call is (!ne () 1) !true "!ne () 1")

(!call error_contains (!lambda () (!return (!lt t1 t2)))
                      ": attempt to compare two table values"
                      "!lt t1 t2")

(!call error_contains (!lambda () (!return (!le t1 t2)))
                      ": attempt to compare two table values"
                      "!le t1 t2")

(!call error_contains (!lambda () (!return (!gt t1 t2)))
                      ": attempt to compare two table values"
                      "!gt t1 t2")

(!call error_contains (!lambda () (!return (!ge t1 t2)))
                      ": attempt to compare two table values"
                      "!ge t1 t2")

(!call error_contains (!lambda () (!return (!lt () 0)))
                      ": attempt to compare table with number"
                      "!lt () 0")

(!call error_contains (!lambda () (!return (!le () 0)))
                      ": attempt to compare number with table"
                      "!le () 0")

(!call error_contains (!lambda () (!return (!gt () 0)))
                      ": attempt to compare number with table"
                      "!gt () 0")

(!call error_contains (!lambda () (!return (!ge () 0)))
                      ": attempt to compare table with number"
                      "!ge () 0")

(!let t ())
(!call is (!index t 1) !nil "index")
(!assign (!index t 1) 42)
(!call is (!index t 1) 42 "index")

(!call error_contains (!lambda () (!define t ())(!assign (!index t !nil) 42))
                      ": table index is nil"
                      "table index is nil")


#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call dofile "TAP.tp")

(!let tostring tostring)
(!let plan plan)
(!let error_contains error_contains)
(!let is is)

(!call plan 39)

(!define x 3.14159)
(!call is (!sub x (!mod x 0.01)) 3.14 "modulo")

(!define a ())
(!assign (!index a "x") 1)
(!assign (!index a "y") 0)
(!define b ())
(!assign (!index b "x") 1)
(!assign (!index b "y") 0)
(!define c a)
(!call is (!eq a c) !true "relational op (by reference)")
(!call is (!ne a b) !true)

(!call is (!eq "0" 0) !false "relational op")
(!call is (!lt 2 15) !true)
(!call is (!lt "2" "15") !false)

(!call error_contains (!lambda () (!return (!lt 2 "15")))
                      "compare"
                      "relational op")

(!call error_contains (!lambda () (!return (!lt "2" 15)))
                      "compare"
                      "relational op")

(!call is (!and 4 5) 5 "logical op")
(!call is (!and !nil 13) !nil)
(!call is (!and !false 13) !false)
(!call is (!or 4 5) 4)
(!call is (!or !false 5) 5)
(!call is (!or !false "text") "text")

(!call is (!or 10 20) 10 "logical op")
(!call is (!or 10 (!call error)) 10)
(!call is (!or !nil "a") "a")
(!call is (!and !nil 10) !nil)
(!call is (!and !false (!call error)) !false)
(!call is (!and !false !nil) !false)
(!call is (!or !false !nil) !nil)
(!call is (!and 10 20) 20)

(!call is (!not !nil) !true "logical not")
(!call is (!not !false) !true)
(!call is (!not 0) !false)
(!call is (!not (!not !nil)) !false)
(!call is (!not "text") !false)
(!define a ())
(!call is (!not a) !false)

(!call is (!concat "Hello " "World") "Hello World" "concatenation")
(!call is (!concat 0 1) "01")
(!define a "Hello")
(!call is (!concat a " World") "Hello World")
(!call is a "Hello")

(!call is (!add "10" 1) 11 "coercion")
(!call is (!mul "-5.3" "2") -10.6)
(!call is (!concat 10 20) "1020")
(!call is (!call tostring 10) "10")
(!call is (!concat 10 "") "10")

(!call error_contains (!lambda () (!return (!add "hello" 1)))
                      "perform arithmetic"
                      "no coercion")

(!call error_contains (!lambda ()
                (!define first (!lambda () (!return 1)))
                (!define limit (!lambda () (!return)))
                (!define step (!lambda () (!return 2)))
                (!loop i (!call first) (!call limit) (!call step)
                        (!call println i)))
                      ": 'for' limit must be a number"
                      "loop tonumber")


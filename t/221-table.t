#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call (!index tvm "dofile") "TAP.tp")

(!let tconcat (!index table "concat"))
(!let tonumber tonumber)
(!let plan plan)
(!let is is)
(!let error_contains error_contains)

(!call plan 25)

;
(!define a ())
(!define k "x")
(!assign (!index a k) 10)
(!assign (!index a 20) "great")
(!call is (!index a "x") 10)
(!assign k 20)
(!call is (!index a k) "great")
(!assign (!index a "x") (!add (!index a "x") 1))
(!call is (!index a "x") 11)

;
(!assign a ())
(!assign (!index a "x") 10)
(!define b a)
(!call is (!index b "x") 10)
(!assign (!index b "x") 20)
(!call is (!index a "x") 20)
(!assign a !nil)
(!assign b !nil)

;
(!assign a ())
(!loop i 1 1000 1 (!assign (!index a i) (!mul i 2)))
(!call is (!index a 9) 18)
(!assign (!index a "x") 10)
(!call is (!index a "x") 10)
(!call is (!index a "y") !nil)

;
(!assign a ())
(!define x "y")
(!assign (!index a x) 10)
(!call is (!index a x) 10)
(!call is (!index a "x") !nil)
(!call is (!index a "y") 10)

;
(!define i 10)(!define j "10")(!define k "+10")
(!assign a ())
(!assign (!index a i) "one value")
(!assign (!index a j) "another value")
(!assign (!index a k) "yet another value")
(!call is (!index a j) "another value")
(!call is (!index a k) "yet another value")
(!call is (!index a (!call tonumber j)) "one value")
(!call is (!index a (!call tonumber k)) "one value")

(!define t ((!nil "a" "b" "c") 10))
(!call is (!index t 1) 10)
(!call is (!index (!index t 0) 3) "c")
(!assign (!index (!index t 0) 1) "A")
(!call is (!call tconcat (!index t 0) ",") "A,b,c")

;
(!define tt)
(!assign tt ((!nil "a" "b" "c") 10))
(!call is (!index tt 1) 10)
(!call is (!index (!index tt 0) 3) "c")
(!assign (!index (!index tt 0) 1) "A")
(!call is (!call tconcat (!index tt 0) ",") "A,b,c")

;
(!assign a ())
(!call error_contains (!lambda () (!call a))
                      ": attempt to call")

;
(!define tt)
(!assign tt ((!nil "a" "b" "c") 10))
(!call is (!index tt 1) 10)
(!call is (!index (!index tt 0) 3) "c")
(!assign (!index (!index tt 0) 2) "B")
(!assign (!index (!index tt 0) 3) "C")
(!call is (!call tconcat (!index tt 0) ",") "a,B,C")


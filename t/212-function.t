#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call (!index tvm "dofile") "TAP.tp")

(!let load (!index tvm "load"))
(!let tconcat (!index table "concat"))
(!let plan plan)
(!let is is)
(!let contains contains)
(!let eq_array eq_array)

(!call plan 66)

;   add
(!let add (!lambda (a)
                (!define sum 0)
                (!loop i 0 (!sub (!len a) 1) 1
                      (!let v (!index a i))
                      (!assign sum (!add sum v)))
                (!return sum)))

(!define t (10 20 30 40))
(!call is (!call add t) 100 "add")

;   f
(!let f (!lambda (a b) (!return (!or a b))))

(!call is (!call f 3) 3 "f")
(!call is (!call f 3 4) 3)
(!call is (!call f 3 4 5) 3)

;   incCount
(!define count 0)

(!let incCount (!lambda (n)
                (!assign n (!or n 1))
                (!assign count (!add count n))))

(!call is count 0 "inCount")
(!call incCount)
(!call is count 1)
(!call incCount 2)
(!call is count 3)
(!call incCount 1)
(!call is count 4)

;   maximum
(!let maximum (!lambda (a)
                (!define mi 0)                  ; maximum index
                (!define m (!index a mi))       ; maximum value
                (!loop i 0 (!sub (!len a) 1) 1
                      (!let val (!index a i))
                      (!if (!gt val m)
                           (!do (!assign mi i)
                                (!assign m val))))
                (!return m mi)))

(!define (m mi) ((!call maximum (8 10 23 12 5))))
(!call is m 23 "maximum")
(!call is mi 2)

;   call by value
(!let f (!lambda (n)
                (!assign n (!sub n 1))
                (!return n)))

(!define a 12)
(!call is a 12 "call by value")
(!define b (!call f a))
(!call is b 11)
(!call is a 12)
(!define c (!call f 12))
(!call is c 11)
(!call is a 12)

;   call by ref
(!let f (!lambda (t)
                (!assign (!index t (!len t)) "end")
                (!return t)))

(!define a (!nil "a" "b" "c"))
(!call is (!call tconcat a ",") "a,b,c" "call by ref")
(!define b (!call f a))
(!call is (!call tconcat b ",") "a,b,c,end")
(!call is (!call tconcat a ",") "a,b,c,end")

;   var args
(!let g (!lambda (a b !vararg)
                (!define arg (!vararg))
                (!call is a 3 "vararg")
                (!call is b !nil)
                (!call is (!len arg) 0)
                (!call is (!index arg 0) !nil)))
(!call g 3)

(!let g (!lambda (a b !vararg)
                (!define arg (!vararg))
                (!call is a 3)
                (!call is b 4)
                (!call is (!len arg) 0)
                (!call is (!index arg 0) !nil)))
(!call g 3 4)

(!let g (!lambda (a b !vararg)
                (!define arg (!vararg))
                (!call is a 3)
                (!call is b 4)
                (!call is (!len arg) 2)
                (!call is (!index arg 0) 5)
                (!call is (!index arg 1) 8)))
(!call g 3 4 5 8)

;   var args
(!let g (!lambda (a b !vararg)
                (!define (c d e) (!vararg))
                (!call is a 3 "var args")
                (!call is b !nil)
                (!call is c !nil)
                (!call is d !nil)
                (!call is e !nil)))
(!call g 3)

(!let g (!lambda (a b !vararg)
                (!define (c d e) (!vararg))
                (!call is a 3)
                (!call is b 4)
                (!call is c !nil)
                (!call is d !nil)
                (!call is e !nil)))
(!call g 3 4)

(!let g (!lambda (a b !vararg)
                (!define (c d e) (!vararg))
                (!call is a 3)
                (!call is b 4)
                (!call is c 5)
                (!call is d 8)
                (!call is e !nil)))
(!call g 3 4 5 8)

;   var args
(!let g (!lambda (a b !vararg)
                (!call is (!len (a b !vararg)) 1 "varargs")))
(!call g 3)

(!let g (!lambda (a b !vararg)
                (!call is (!len (a b !vararg)) 2)))
(!call g 3 4)

(!let g (!lambda (a b !vararg)
                (!call is (!len (a b !vararg)) 4)))
(!call g 3 4 5 8)

;   var args
(!let f (!lambda () (!return 1 2)))
(!let g (!lambda () (!return "a" (!call f))))
(!let h (!lambda () (!return (!call f) "b")))
(!let k (!lambda () (!return "c" (!call1 f))))

(!define (x y) ((!call f)))
(!call is x 1 "var args")
(!call is y 2)
(!define (x y z) ((!call g)))
(!call is x "a")
(!call is y 1)
(!call is z 2)
(!define (x y) ((!call h)))
(!call is x 1)
(!call is y "b")
(!define (x y z) ((!call k)))
(!call is x "c")
(!call is y 1)
(!call is z !nil)


;   invalid var args
(!define (f msg) ((!call load "(!let f (!lambda () (!call println !vararg)))")))
(!call contains msg ": cannot use '!vararg' outside a vararg function" "invalid var args")

;   tail call
(!define output ())
(!letrec foo (!lambda (n)
                (!assign (!index output (!len output)) n)
                (!if (!gt n 0)
                     (!return (!call foo (!sub n 1))))
                (!return "end" 0)))

(!call eq_array ((!call foo 3)) ("end" 0) "tail call")
(!call eq_array output (3 2 1 0))

;   no tail call
(!define output ())
(!letrec foo (!lambda (n)
                (!assign (!index output (!len output)) n)
                (!if (!gt n 0)
                     (!return (!call1 foo (!sub n 1))))
                (!return "end" 0)))

(!call is (!call foo 3) "end" "no tail call")
(!call eq_array output (3 2 1 0))

;   no tail call
(!define output ())
(!letrec foo (!lambda (n)
                (!assign (!index output (!len output)) n)
                (!if (!gt n 0)
                     (!call foo (!sub n 1)))))

(!call is (!call foo 3) !nil "no tail call")
(!call eq_array output (3 2 1 0))


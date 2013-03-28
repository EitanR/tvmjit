#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call (!index tvm "dofile") "TAP.tp")

(!let load load)
(!let print print)

(!call plan 35)

(!call is b !nil "global variable")
(!assign b 10)
(!call is b 10)
(!assign b !nil)
(!call is b !nil)

(!assign a ())
(!assign i 3)
(!massign (i (!index a i)) ((!add i 1) 20))
(!call is i 4 "check eval")
(!call is (!index a 3) 20)


(!assign x 1.)
(!assign y 2.)
(!massign (x y) (y x))  ; swap
(!call is x 2 "check swap")
(!call is y 1)

(!massign (a b c) (0 1))
(!call is a 0 "check padding")
(!call is b 1)
(!call is c !nil)
(!massign (a b) ((!add a 1) (!add b  1) (!add a b)))
(!call is a 1)
(!call is b 2)
(!massign (a b c) (0))
(!call is a 0)
(!call is b !nil)
(!call is c !nil)

(!assign f (!lambda ()
                (!return 1 2)))
(!massign (a b c d) ((!call f)))
(!call is a 1 "adjust with function")
(!call is b 2)
(!call is c !nil)
(!call is d !nil)

(!assign f (!lambda ()
                (!call print "# f")))
(!assign a 2)
(!massign (a b c) ((!call f) 3))
(!call is a !nil "padding with function")
(!call is b 3)
(!call is c !nil)

(!define my_i 1)
(!call is my_i 1 "local variable")
(!define my_i 2)
(!call is my_i 2)

(!define i 1)
(!define (j) (1))
(!call is i 1 "local variable")
(!call is j 1)
(!assign j 2)
(!call is i 1)
(!call is j 2)

(!let f (!lambda (x)
                (!return (!mul 2 x))))
(!call is (!call f 2) 4 "param & result of function")
(!assign a 2)
(!assign a (!call f a))
(!call is a 4)
(!define b 2)
(!assign b (!call f b))
(!call is b 4)

(!define n1 1)
(!define (n2 n3 n4) (2 3 4))
(!massign (n1 n2 n3 n4) (n4 n3 n2 n1))
(!call is n1 4 "assignment list swap values")
(!call is n2 3)
(!call is n3 2)
(!call is n4 1)


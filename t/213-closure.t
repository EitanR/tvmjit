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
(!let is is)
(!let type_ok type_ok)

(!call plan 15)

;   inc
(!define counter 0)

(!let inc (!lambda (x)
                (!assign counter (!add counter x))
                (!return counter)))

(!call is (!call inc 1) 1 "inc")
(!call is (!call inc 2) 3)

;   newCounter
(!let newCounter (!lambda ()
                (!define i 0)
                (!return (!lambda ()
                                (!assign i (!add i 1))
                                (!return i)))))

(!let c1 (!call newCounter))
(!call is (!call c1) 1 "newCounter")
(!call is (!call c1) 2)

(!let c2 (!call newCounter))
(!call is (!call c2) 1)
(!call is (!call c1) 3)
(!call is (!call c2) 2)

;
;   The loop creates ten closures (that is, ten instances of the anonymous
;   function). Each of these closures uses a different y variable, while all
;   of them share the same x.
;
(!define a ())
(!define x 20)
(!loop i 1 10 1
        (!define y 0)
        (!assign (!index a i) (!lambda ()
                        (!assign y (!add y 1))
                        (!return (!add x y)))))

(!call is (!call (!index a 1)) 21 "ten closures")
(!call is (!call (!index a 1)) 22)
(!call is (!call (!index a 2)) 21)


;   add
(!let add (!lambda (x)
                (!return (!lambda (y)
                                (!return (!add x y))))))

(!let f (!call add 2))
(!call type_ok f "function" "add")
(!call is (!call f 10) 12)
(!let g (!call add 5))
(!call is (!call g 1) 6)
(!call is (!call g 10) 15)
(!call is (!call f 1) 3)


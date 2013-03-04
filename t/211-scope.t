#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call (!index tvm "dofile") "TAP.tp")

(!call plan 10)

(!assign x 10)
(!do (!define x x)
     (!call is x 10 "scope")
     (!assign x (!add x 1))
     (!do (!define x (!add x 1))
          (!call is x 12))
     (!call is x 11))
(!call is x 10)

; scope
(!assign x 10)
(!define i 1)

(!while (!le i x)
        (!define x (!mul i 2))
;        (!call println x)
        (!assign i (!add i 1)))

(!if (!gt i 20)
     (!do (!define x)
          (!assign x 20)
          (!call nok "scope"))
     (!call is x 10 "scope"))

(!call is x 10)

; scope
(!define (a b) (1 10))
(!if (!lt a b)
     (!do (!call is a 1 "scope")
          (!define a)
          (!call is a !nil)))
(!call is a 1)
(!call is b 10)


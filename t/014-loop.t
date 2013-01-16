#!/usr/bin/tvmjit
;
;   Copyright (C) 2013 Francois Perrad.
;

(!let print print)

(!call print "1..36")

(!loop i 1 10 2
        (!call print (!mconcat "ok " (!div (!add i 1) 2) " - loop 1, 10, 2")))

(!loop i 1 10 2
        (!assign f (!lambda ()
                        (!call print (!mconcat "ok " (!div (!add i 11) 2) " - loop 1, 10, 2 lex"))))
        (!call f))

(!assign f (!lambda (i)
                (!call print (!mconcat "ok " (!div (!add i 21) 2) " - loop 1, 10, 2 !lex"))))
(!loop i 1 10 2
        (!call f i))

(!loop i 3 5 1
        (!call print (!mconcat "ok " (!add 13 i) " - loop 3, 5, 1"))
        (!define i (!add i 1)))

(!loop i 5 1 -1
        (!call print (!mconcat "ok " (!sub 24 i) " - loop 5, 1, -1")))

(!loop i 5 5 1
        (!call print (!mconcat "ok " (!add 19 i) " - loop 5, 5, 1")))

(!loop i 5 5 -1
        (!call print (!mconcat "ok " (!add 20 i) " - loop 5, 5, -1")))

(!assign v !false)
(!loop i 5 3 1
        (!assign v !true))
(!if v
     (!call print "not ok 26 - loop 5, 3, 1")
     (!call print "ok 26 - loop 5, 3, 1"))

(!assign v !false)
(!loop i 5 7 -1
        (!assign v !true))
(!if v
     (!call print "not ok 27 - loop 5, 7, -1")
     (!call print "ok 27 - loop 5, 7, -1"))

(!assign v !false)
(!loop i 7 5 0
        (!assign v !true)
        (!break))
(!if v
     (!call print "not ok 28 - loop 7, 5, 0")
     (!call print "ok 28 - loop 7, 5, 0"))

(!assign v !nil)
(!loop i 1 10 2
        (!if (!gt i 4) (!break))
        (!call print (!mconcat "ok " (!div (!add i 57) 2) " - loop break"))
        (!assign v i))
(!if (!eq v 3)
     (!call print "ok 31 - break")
     (!call print (!concat "not ok 31 - " v)))

(!let first (!lambda () (!return 1)))
(!let limit (!lambda () (!return 8)))
(!let step (!lambda () (!return 2)))
(!loop i (!call first) (!call limit) (!call step)
        (!call print (!mconcat "ok " (!div (!add i 63) 2) " - with functions")))

(!define a ())
(!loop i 1 10 1
        (!assign (!index a i) (!lambda () (!return i))))
(!define v (!call (!index a 5)))
(!if (!eq v 5)
     (!call print "ok 36 - loop & upval")
     (!do (!call print "not ok 36 - loop & upval")
          (!call print "#" v)))


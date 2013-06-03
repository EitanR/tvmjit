#!/usr/bin/tvmjit
;
;   Copyright (C) 2013 Francois Perrad.
;

(!let print print)

(!call print "1..11")

(!define a ())
(!define i 1)
(!while (!index a i)
        (!assign i (!add i 1)))
(!if (!eq i 1)
     (!call print "ok 1 - while empty")
     (!call print (!concat "not ok 1 - " i)))

(!define a ("ok 2 - while " "ok 3" "ok 4"))
(!define i 1)
(!while (!index a i)
        (!call print (!index a i))
        (!assign i (!add i 1)))

(!define a ("ok 5 - with break" "ok 6" "stop" "more"))
(!define i 1)
(!while (!index a i)
        (!if (!eq (!index a i) "stop")
             (!break))
        (!call print (!index a i))
        (!assign i (!add i 1)))
(!if (!eq i 3)
     (!call print "ok 7 - break")
     (!call print (!concat "not ok 7 - " i)))

(!define x 2)
(!define i 0)
(!while (!le i x)
        (!call print (!concat "ok " (!add 8 i)))
        (!assign i (!add i 1)))
(!if (!eq i 3)
     (!call print "ok 11")
     (!call print (!concat "not ok 11 - " i)))


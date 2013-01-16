#!/usr/bin/tvmjit
;
;   Copyright (C) 2013 Francois Perrad.
;

(!let print print)

(!call print "1..8")

(!define a ("ok 1 - repeat" "ok 2" "ok 3"))
(!define i -1)
(!repeat (!assign i (!add i 1))
         (!if (!index a i)
              (!call print (!index a i)))
         (!not (!index a i)))
(!if (!eq i 3)
     (!call print "ok 4")
     (!call print (!concat "not ok 4 - " i)))


(!assign a ("ok 5 - with break" "ok 6" "stop" "more"))
(!define i -1)
(!repeat (!assign i (!add i 1))
         (!if (!eq (!index a i) "stop") (!break))
         (!call print (!index a i))
         (!not (!index a i)))
(!if (!eq (!index a i) "stop")
     (!call print "ok 7 - break")
     (!call print (!concat "not ok 7 - " (!index a i))))

(!let f (!lambda () (!return !true)))

(!define i 1)
(!repeat
        (!define v (!call1 f))
        (!if (!eq i 1)
             (!call print "ok 8 - scope")
             (!do (!call print "not ok")
                  (!break)))
        (!assign i (!add i 1))
        v)


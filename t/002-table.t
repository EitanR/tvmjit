#!/usr/bin/tvmjit
;
;   Copyright (C) 2013 Francois Perrad.
;

(!let print print)

(!call print "1..8")

(!define a ("ok 1" "ok 2" "ok 3"))
(!call print (!index a 1))
(!define i 2)
(!call print (!index a i))
(!call print (!index a (!add i 1)))
(!if (!eq (!len a) 3)
     (!call print "ok 4 - len")
     (!call print "not ok 4 - len " (!len a)))
(!if (!eq (!index a 7) !nil)
     (!call print "ok 5")
     (!call print "not ok 5"))

(!define t ("a": 10 "b": 100))
(!if (!eq (!index t "a") 10)
     (!call print "ok 6")
     (!call print "not ok 6"))

(!if (!eq (!index t "b") 100)
     (!call print "ok 7")
     (!call print "not ok 7"))
(!if (!eq (!index t "z") !nil)
     (!call print "ok 8")
     (!call print "not ok 8"))


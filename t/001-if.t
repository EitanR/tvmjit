#!/usr/bin/tvmjit
;
;   Copyright (C) 2013 Francois Perrad.
;

(!let print print)

(!call print "1..6")

(!if !true
     (!call print "ok 1")
     (!call print "not ok 1"))

(!if (!not !true)
     (!call print "not ok 2")
     (!call print "ok 2"))

(!define a 12)
(!define b 34)
(!if (!lt a b)
     (!call print "ok 3")
     (!call print "not ok 3"))

(!assign a 0)
(!assign b 4)
(!cond ((!lt a b) (!call print "ok 4"))
       ((!eq a b) (!call print "not ok 4"))
       (!true     (!call print "not ok 4")))

(!assign a 5)
(!assign b 5)
(!cond ((!lt a b) (!call print "not ok 5"))
       ((!eq a b) (!call print "ok 5"))
       (!true     (!call print "not ok 5")))

(!assign a 10)
(!assign b 6)
(!cond ((!lt a b) (!call print "not ok 6"))
       ((!eq a b) (!call print "not ok 6"))
       (!true     (!call print "ok 6")))


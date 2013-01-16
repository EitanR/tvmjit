#!/usr/bin/tvmjit
;
;   Copyright (C) 2013 Francois Perrad.
;

(!let print print)

;   emul ipairs
(!let iter (!lambda (a i)
                (!assign i (!add i 1))
                (!let v (!index a i))
                (!if v
                     (!return i v))))

(!let ipairs (!lambda (a)
                (!return iter a -1)))

(!call print "1..18")

(!define a ("ok 1 - for ipairs" "ok 2 - for ipairs" "ok 3 - for ipairs"))
(!for (_ v) ((!call ipairs a))
      (!call print v))
(!for (i v) ((!call ipairs a))
      (!call print (!mconcat "ok " (!add 4 i) " - for ipairs")))

(!define r !false)
(!define t ("a": 10 "b": 100))
(!for (i v) ((!call ipairs t))
      (!call print i v)
      (!assign r !true))
(!if r
     (!call print "not ok 7 - for ipairs (hash)")
     (!call print "ok 7 - for ipairs (hash)"))

(!for (k) ((!call pairs a))
      (!call print (!mconcat "ok " (!add 8 k) " - for pairs")))

(!define i 1)
(!for (k) ((!call pairs t))
      (!if (!or (!eq k "a") (!eq k "b"))
           (!call print (!mconcat "ok " (!add 10 i) " - for pairs (hash)"))
           (!call print (!mconcat "not ok " (!add 10 i) " - " k)))
      (!assign i (!add i 1)))

(!assign a ("ok 13 - for break" "ok 14 - for break" "stop" "more"))
(!define i !nil)
(!for (_ v) ((!call ipairs a))
      (!if (!eq v "stop") (!break))
      (!call print v)
      (!assign i _))
(!if (!eq i 1)
     (!call print "ok 15 - break")
     (!call print (!concat "not ok 15 - " i)))

(!define a ("ok 16 - for & upval" "ok 17 - for & upval" "ok 18 - for & upval"))
(!define b ())
(!for (i v) ((!call ipairs a))
      (!assign (!index b i) (!lambda () (!return v))))
(!for (i v) ((!call ipairs a))
      (!define r (!call (!index b i)))
      (!if (!eq r (!index a i))
           (!call print r)
           (!do (!call print (!concat "not " (!index a i)))
                (!call print "#" r))))


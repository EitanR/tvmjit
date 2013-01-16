#!/usr/bin/tvmjit
;
;   Copyright (C) 2013 Francois Perrad.
;

(!let print print)

(!define f (!lambda (n)
                (!return (!add n 1))))

(!define g (!lambda (m p)
                (!return (!add m p))))

(!call print "1..9")
(!call print "ok 1 -")
(!call print "ok " 2 " - list")
(!call print (!mconcat "ok " 3 " - concatenation"))
(!assign i 4)
(!call print (!mconcat "ok " i " - var"))
(!assign i (!add i 1))
(!call print (!mconcat "ok " i " - var incr"))
(!call print (!mconcat "ok " (!add i 1) " - expr"))
(!assign j (!call f (!add i 1)))
(!call print (!mconcat "ok " j " - call f"))
(!assign k (!call g i 3))
(!call print (!mconcat "ok " k " - call g"))
(!let my_print print)
(!call my_print "ok 9 - let")


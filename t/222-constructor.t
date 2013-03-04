#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call (!index tvm "dofile") "TAP.tp")

(!let plan plan)
(!let is is)
(!let eq_array eq_array)

(!call plan 14)

;   list-style init
(!define days ("Sunday" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday"))
(!call is (!index days 3) "Wednesday" "list-style init")
(!call is (!len days) 7)

;   record-style init
(!define a ("x": 0 "y": 0))
(!call is (!index a "x") 0 "record-style init")
(!call is (!index a "y") 0)

;
(!define w ("x": 0 "y": 0 "label": "console"))
(!define x (0 1 2))
(!assign (!index w 1) "another field")
(!assign (!index x "f") w)
(!call is (!index w "x") 0 "ctor")
(!call is (!index w 1) "another field")
(!call is (!index (!index x "f") 1) "another field")
(!assign (!index w "x") !nil)

;   mix record-style and list-style init
(!define polyline ("color": "blue" "thickness": 2 "npoints": 4
                   ("x": 0   "y": 0)
                   ("x": -10 "y": 0)
                   ("x": -10 "y": 1)
                   ("x": 0   "y": 1)))
(!call is (!index (!index polyline 2) "x") -10 "mix record-style and list-style init")

;
(!define opnames ("+": "add" "-": "sub" "*": "mul" "/": "div"))
(!define i 20)(!define s "-")
(!define a ((!add i 0): s (!add i 1): (!concat s s) (!add i 2): (!mconcat s s s)))
(!call is (!index opnames s) "sub" "ctor")
(!call is (!index a 22) "---")

;
(!define f (!lambda () (!return 10 20)))

(!call eq_array ((!call f)) (10 20) "ctor")
(!call eq_array ("a" (!call f)) ("a" 10 20))
(!call eq_array ((!call1 f) "b") (10 "b"))
(!call eq_array ("c" (!call1 f)) ("c" 10))


#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;

(!call (!index tvm "dofile") "TAP.tp")

(!let dump (!call (!index tvm "dofile") "dump/graph.tp"))

(!let assert assert)
(!let tostring tostring)
(!let load (!index tvm "load"))
(!let plan plan)
(!let diag diag)
(!let is is)
(!let is_deeply is_deeply)
(!let eq_array eq_array)
(!let type_ok type_ok)
(!let error_contains error_contains)

(!call plan 18)

(!call type_ok dump "function" "dump")

(!let eval (!lambda (s)
;                (!call diag s)
                (!return (!call (!call assert (!call load s))))))

(!call is (!call eval (!call dump 3.14)) 3.14 "basic number" )
(!call is (!call eval (!call dump (!div 1 0))) (!div 1 0) "inf" )
(!call is (!call eval (!call dump (!div -1 0))) (!div -1 0) "inf" )
(!call is (!call dump (!div 0 0)) "(!return (!div 0 0))" "nan" )
(!call is (!call eval (!call dump "some text")) "some text" "basic string" )
(!call is (!call eval (!call dump !nil)) !nil "!nil" )
(!call is (!call eval (!call dump !true)) !true "boolean !true" )
(!call is (!call eval (!call dump !false)) !false "boolean !false" )

(!call eq_array (!call eval (!call dump ())) () "empty array")
(!call eq_array (!call eval (!call dump ("a" "b" "c"))) ("a" "b" "c") "array of string")
(!call eq_array (!call eval (!call dump (0 1 2 3))) (0 1 2 3) "array of integer")
(!call is_deeply (!call eval (!call dump ("a":97 "b":98 "c":99))) ("a":97 "b":98 "c":99) "hash")
(!call is_deeply (!call eval (!call dump ("a" !nil "c" !nil "e"))) ("a" !nil "c" !nil "e") "array with few holes" )

(!call error_contains (!lambda () (!call dump plan))
                      ": dump 'function' is unimplemented"
                      "function unimplemented" )

(!let a ())
(!assign (!index a "foo") a)
(!call is_deeply (!call eval (!call dump a)) a "direct cycle")

(!let a ())
(!let b ())
(!assign (!index a "foo") b)
(!assign (!index b "foo") a)
(!call is_deeply (!call eval (!call dump a)) a "indirect cycle")

(!let a ("x":1 "y":2 (3 4 5)))
(!assign (!index a 2) a)                ; cycle
(!assign (!index a "z") (!index a 0))   ; shared subtable
(!call is_deeply (!call eval (!call dump a)) a "cycle & shared subtable")


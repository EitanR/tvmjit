#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call (!index tvm "dofile") "TAP.tp")

(!let concat (!index table "concat"))
(!let insert (!index table "insert"))
(!let pack (!index table "pack"))
(!let remove (!index table "remove"))
(!let sort (!index table "sort"))
(!let unpack (!index table "unpack"))
(!let pairs pairs)

(!let plan plan)
(!let is is)
(!let eq_array eq_array)
(!let error_contains error_contains)

(!call plan 39)

(!define t ("a" "b" "c" "d" "e"))
(!call is (!call concat t) "abcde" "function concat")
(!call is (!call concat t ",") "a,b,c,d,e")
(!call is (!call concat t "," 2) "b,c,d,e")
(!call is (!call concat t "," 2 4) "b,c,d")
(!call is (!call concat t "," 4 2) "")

(!define t ("a" "b" 3 "d" "e"))
(!call is (!call concat t ",") "a,b,3,d,e" "function concat (number)")

(!define t ("a" "b" "c" "d" "e"))
(!call error_contains (!lambda () (!call concat t "," 2 7))
                      ": invalid value (nil) at index 6 in table for 'concat'"
                      "function concat (out of range)")

(!define t ("a" "b" !true "d" "e"))
(!call error_contains (!lambda () (!call concat t ","))
                      ": invalid value (boolean) at index 3 in table for 'concat'"
                      "function concat (non-string)")

(!define a (10 20 30))
(!call insert a 1 15)
(!call is (!call concat a ",") "15,10,20,30" "function insert")
(!define t ())
(!call insert t "a")
(!call is (!call concat t ",") "a")
(!call insert t "b")
(!call is (!call concat t ",") "a,b")
(!call insert t 1 "c")
(!call is (!call concat t ",") "c,a,b")
(!call insert t 2 "d")
(!call is (!call concat t ",") "c,d,a,b")
(!call insert t 7 "e")
(!call is (!index t 7) "e")
(!call insert t -9 "f")
(!call is (!index t -9) "f")

(!call error_contains (!lambda () (!call insert t 2 "g" "h"))
                      ": wrong number of arguments to 'insert'"
                      "function insert (too many arg)")

(!define t (!call pack "abc" "def" "ghi"))
(!call eq_array t ("abc" "def" "ghi") "function pack")
(!call is (!index t "n") 3)

(!define t (!call pack))
(!call eq_array t () "function pack (no element)")
(!call is (!index t "n") 0)

(!define t ())
(!define a (!call remove t))
(!call is a !nil "function remove (no element)")
(!define t ("a" "b" "c" "d" "e"))
(!define a (!call remove t))
(!call is a "e" "function remove")
(!call is (!call concat t ",") "a,b,c,d")
(!define a (!call remove t 3))
(!call is a "c")
(!call is (!call concat t ",") "a,b,d")
(!define a (!call remove t 1))
(!call is a "a")
(!call is (!call concat t ",") "b,d")
(!define a (!call remove t 7))
(!call is a !nil)
(!call is (!call concat t ",") "b,d")

(!define lines ("luaH_set": 10
                "luaH_get": 24
                "luaH_present": 48))
(!define a ())
(!for (k) ((!call pairs lines)) (!assign (!index a (!add (!len a) 1)) k))
(!call sort a)
(!define output ())
(!loop i 1 (!len a) 1
      (!call insert output (!index a i)))
(!call eq_array output ("luaH_get" "luaH_present" "luaH_set") "function sort")

(!define pairsByKeys (!lambda (t f)
                (!define a ())
                (!for (n) ((!call pairs t))
                      (!assign (!index a (!add (!len a) 1)) n))
                (!call sort a f)
                (!define i 0)          ; iterator variable
                (!return (!lambda ()    ; iterator function
                                (!assign i (!add i 1))
                                (!return (!index a i) (!index t (!index a i)))))))

(!define output ())
(!for (name line) ((!call pairsByKeys lines))
      (!call insert output name)
      (!call insert output line))
(!call eq_array output ("luaH_get" 24 "luaH_present" 48 "luaH_set" 10) "function sort")

(!define output ())
(!for (name line) ((!call pairsByKeys lines (!lambda (a b) (!return (!lt a b)))))
      (!call insert output name)
      (!call insert output line))
(!call eq_array output ("luaH_get" 24 "luaH_present" 48 "luaH_set" 10) "function sort")

(!call error_contains (!lambda ()
                (!define t (1))
                (!call sort (t t t t) (!lambda (a b) (!return (!eq (!index a 1)(!index b 1))))))
                      ": invalid order function for sorting"
                      "function sort (bad func)")

(!call eq_array ((!call unpack ())) () "function unpack")
(!call eq_array ((!call unpack ("a"))) ("a"))
(!call eq_array ((!call unpack ("a" "b" "c"))) ("a" "b" "c"))
(!call eq_array ((!call1 unpack ("a" "b" "c"))) ("a"))
(!call eq_array ((!call unpack ("a" "b" "c" "d" "e") 2 4)) ("b" "c" "d"))
(!call eq_array ((!call unpack ("a" "b" "c") 2 4)) ("b" "c"))


#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call (!index tvm "dofile") "TAP.tp")

(!let error error)
(!let getmetatable getmetatable)
(!let next next)
(!let pairs pairs)
(!let print print)
(!let rawget rawget)
(!let rawset rawset)
(!let setmetatable setmetatable)
(!let tconcat (!index table "concat"))
(!let tonumber tonumber)
(!let tostring tostring)
(!let tsort (!index table "sort"))
(!let type type)

(!call plan 94)

(!define t ())
(!call is (!call getmetatable t) !nil "metatable")
(!define t1 ())
(!call is (!call setmetatable t t1) t)
(!call is (!call getmetatable t) t1)
(!call is (!call setmetatable t !nil) t)
(!call error_contains (!lambda () (!call setmetatable t !true))
                      ": bad argument #2 to 'setmetatable' (nil or table expected)")

(!define mt ())
(!assign (!index mt "__metatable") "not your business")
(!call setmetatable t mt)
(!call is (!call getmetatable t) "not your business" "protected metatable")
(!call error_contains (!lambda () (!call setmetatable t ()))
                      ": cannot change a protected metatable")

(!call is (!call getmetatable !nil) !nil "metatable for nil")
(!call is (!call getmetatable !false) !nil "metatable for boolean")
(!call is (!call getmetatable 2) !nil "metatable for number")
(!call is (!call getmetatable print) !nil "metatable for function")

(!define t ())
(!define mt ("__tostring": (!lambda () (!return "__TABLE__"))))
(!call setmetatable t mt)
(!call is (!call tostring t) "__TABLE__" "__tostring")

(!define mt ())
(!define a !nil)
(!assign (!index mt "__tostring") (!lambda () (!assign a "return nothing")))
(!call setmetatable t mt)
(!call is (!call tostring t) !nil "__tostring no-output")
(!call is a "return nothing")
(!call error_contains (!lambda () (!call print t))
                      ": 'tostring' must return a string to 'print'")

(!assign (!index mt "__tostring") (!lambda () (!return "__FIRST__" 2)))
(!call setmetatable t mt)
(!call is (!call tostring t) "__FIRST__" "__tostring too-many-output")

(!define t ())
(!assign (!index t "mt") ())
(!call setmetatable t (!index t "mt"))
(!assign (!index (!index t "mt") "__tostring") "not a function")
(!call error_contains (!lambda () (!call tostring t))
                      "attempt to call"
                      "__tostring invalid")

(!define t ())
(!define mt ("__len": (!lambda () (!return 42))))
(!call setmetatable t mt)
(!call is (!len t) 42 "__len")

(!define t ())
(!define mt ("__len": (!lambda () (!return !nil))))
(!call setmetatable t mt)
(!call todo "LuaJIT TODO. __len." 1)
(!call error_contains (!lambda () (!call print (!call tconcat t)))
                      "object length is not a number"
                      "__len invalid")

(!define t ())
(!define mt ("__tostring": (!lambda () (!return "t"))
             "__concat":   (!lambda (op1 op2)
                                    (!return (!mconcat (!call tostring op1) "|" (!call tostring op2))))))
(!call setmetatable t mt)
(!call is (!mconcat t t t 4 "end") "t|t|t|4end" "__concat")


;   Cplx
(!define Cplx ())
(!assign (!index Cplx "mt") ())

(!assign (!index Cplx "new") (!lambda (re im)
                (!let c ())
                (!call setmetatable c (!index Cplx "mt"))
                (!assign (!index c "re") (!call tonumber re))
                (!if (!eq im !nil)
                     (!assign (!index c "im") 0.0)
                     (!assign (!index c "im") (!call tonumber im)))
                (!return c)))

(!assign (!index (!index Cplx "mt") "__tostring") (!lambda (c)
                (!return (!mconcat "(" (!index c "re") "," (!index c "im") ")"))))

(!assign (!index (!index Cplx "mt") "__add") (!lambda (a b)
                (!if (!ne (!call type a) "table")
                     (!assign a (!call (!index Cplx "new") a 0)))
                (!if (!ne (!call type b) "table")
                     (!assign b (!call (!index Cplx "new") b 0)))
                (!let r (!call (!index Cplx "new") (!add (!index a "re") (!index b "re"))
                                                   (!add (!index a "im") (!index b "im"))))
                (!return r)))

(!define c1 (!call (!index Cplx "new") 1 3))
(!define c2 (!call (!index Cplx "new") 2 -1))

(!call is (!call tostring (!add c1 c2)) "(3,2)" "cplx __add")
(!call is (!call tostring (!add c1 3)) "(4,3)")
(!call is (!call tostring (!add -2 c1)) "(-1,3)")
(!call is (!call tostring (!add c1 "3")) "(4,3)")
(!call is (!call tostring (!add "-2" c1)) "(-1,3)")

(!assign (!index (!index Cplx "mt") "__sub") (!lambda (a b)
                (!if (!ne (!call type a) "table")
                     (!assign a (!call (!index Cplx "new") a 0)))
                (!if (!ne (!call type b) "table")
                     (!assign b (!call (!index Cplx "new") b 0)))
                (!let r (!call (!index Cplx "new") (!sub (!index a "re") (!index b "re"))
                                                   (!sub (!index a "im") (!index b "im"))))
                (!return r)))

(!call is (!call tostring (!sub c1 c2)) "(-1,4)" "cplx __sub")
(!call is (!call tostring (!sub c1 3)) "(-2,3)")
(!call is (!call tostring (!sub -2 c1)) "(-3,-3)")
(!call is (!call tostring (!sub c1 "3")) "(-2,3)")
(!call is (!call tostring (!sub "-2" c1)) "(-3,-3)")

(!assign (!index (!index Cplx "mt") "__mul") (!lambda (a b)
                (!if (!ne (!call type a) "table")
                     (!assign a (!call (!index Cplx "new") a 0)))
                (!if (!ne (!call type b) "table")
                     (!assign b (!call (!index Cplx "new") b 0)))
                (!let r (!call (!index Cplx "new") (!sub (!mul (!index a "re") (!index b "re")) (!mul (!index a "im") (!index b "im")))
                                                   (!add (!mul (!index a "re") (!index b "im")) (!mul (!index a "im") (!index b "re")))))
                (!return r)))

(!call is (!call tostring (!mul c1 c2)) "(5,5)" "cplx __mul")
(!call is (!call tostring (!mul c1 3)) "(3,9)")
(!call is (!call tostring (!mul -2 c1)) "(-2,-6)")
(!call is (!call tostring (!mul c1 "3")) "(3,9)")
(!call is (!call tostring (!mul "-2" c1)) "(-2,-6)")

(!assign (!index (!index Cplx "mt") "__div") (!lambda (a b)
                (!if (!ne (!call type a) "table")
                     (!assign a (!call (!index Cplx "new") a 0)))
                (!if (!ne (!call type b) "table")
                     (!assign b (!call (!index Cplx "new") b 0)))
                (!let n (!add (!mul (!index b "re") (!index b "re")) (!mul (!index b "im") (!index b "im"))))
                (!let inv (!call (!index Cplx "new") (!div (!index b "re") n) (!div (!index b "im") n)))
                (!let r (!call (!index Cplx "new") (!sub (!mul (!index a "re") (!index inv "re")) (!mul (!index a "im") (!index inv "im")))
                                                   (!add (!mul (!index a "re") (!index inv "im")) (!mul (!index a "im") (!index inv "re")))))
                (!return r)))

(!define c1 (!call (!index Cplx "new") 2 6))
(!define c2 (!call (!index Cplx "new") 2 0))

(!call is (!call tostring (!div c1 c2)) "(1,3)" "cplx __div")
(!call is (!call tostring (!div c1 2)) "(1,3)")
(!call is (!call tostring (!div -4 c2)) "(-2,0)")
(!call is (!call tostring (!div c1 "2")) "(1,3)")
(!call is (!call tostring (!div "-4" c2)) "(-2,0)")

(!assign (!index (!index Cplx "mt") "__unm") (!lambda  (a)
                (!if (!ne (!call type a) "table")
                     (!assign a (!call (!index Cplx "new") a 0)))
                (!let r (!call (!index Cplx "new") (!neg (!index a "re")) (!neg (!index a "im"))))
                (!return r)))

(!define c1 (!call (!index Cplx "new") 1 3))
(!call is (!call tostring (!neg c1)) "(-1,-3)" "cplx __unm")

(!assign (!index (!index Cplx "mt") "__len") (!lambda (a)
                (!return (!pow (!add (!mul (!index a "re") (!index a "re")) (!mul (!index a "im") (!index a "im"))) 0.5))))

(!define c1 (!call (!index Cplx "new") 3 4))
(!call is (!len c1) 5 "cplx __len")

(!assign (!index (!index Cplx "mt") "__eq") (!lambda (a b)
                (!if (!ne (!call type a) "table")
                     (!assign a (!call (!index Cplx "new") a 0)))
                (!if (!ne (!call type b) "table")
                     (!assign b (!call (!index Cplx "new") b 0)))
                (!return (!and (!eq (!index a "re") (!index b "re")) (!eq (!index a "im") (!index b "im"))))))


(!define c1 (!call (!index Cplx "new") 2 0))
(!define c2 (!call (!index Cplx "new") 1 3))
(!define c3 (!call (!index Cplx "new") 2 0))

(!call is (!ne c1 c2) !true "cplx __eq")
(!call is (!eq c1 c3) !true)
(!call is (!eq c1 2) !false)
(!call is (!call (!index (!index Cplx "mt") "__eq") c1 2) !true)

(!assign (!index (!index Cplx "mt") "__lt") (!lambda (a b)
                (!if (!ne (!call type a) "table")
                     (!assign a (!call (!index Cplx "new") a 0)))
                (!if (!ne (!call type b) "table")
                     (!assign b (!call (!index Cplx "new") b 0)))
                (!let ra (!add (!mul (!index a "re") (!index a "re")) (!mul (!index a "im") (!index a "im"))))
                (!let rb (!add (!mul (!index b "re") (!index b "re")) (!mul (!index b "im") (!index b "im"))))
                (!return (!lt ra rb))))

(!call is (!lt c1 c2) !true "cplx __lt")
(!call is (!lt c1 c3) !false)
(!call is (!le c1 c3) !true)
(!call is (!lt c1 1) !false)
(!call is (!lt c1 4) !true)

(!assign (!index (!index Cplx "mt") "__le") (!lambda (a b)
                (!if (!ne (!call type a) "table")
                     (!assign a (!call (!index Cplx "new") a 0)))
                (!if (!ne (!call type b) "table")
                     (!assign b (!call (!index Cplx "new") b 0)))
                (!let ra (!add (!mul (!index a "re") (!index a "re")) (!mul (!index a "im") (!index a "im"))))
                (!let rb (!add (!mul (!index b "re") (!index b "re")) (!mul (!index b "im") (!index b "im"))))
                (!return (!le ra rb))))

(!call is (!lt c1 c2) !true "cplx __lt __le")
(!call is (!lt c1 c3) !false)
(!call is (!le c1 c3) !true)

(!define a)
(!assign (!index (!index Cplx "mt") "__call") (!lambda (obj)
                (!assign a (!concat "Cplx.__call " (!call tostring obj)))
                (!return !true)))

(!define c1 (!call (!index Cplx "new") 2 0))
(!assign a !nil)
(!define r (!call c1))
(!call is r !true "cplx __call (without args)")
(!call is a "Cplx.__call (2,0)")

(!assign (!index (!index Cplx "mt") "__call") (!lambda (obj !vararg)
                (!assign a (!mconcat "Cplx.__call " (!call tostring obj) ", " (!call tconcat (!vararg) ", ")))
                (!return !true)))

(!call is (!call c1) !true "cplx __call (with args)")
(!call is a "Cplx.__call (2,0), ")
(!call is (!call c1 "a") !true)
(!call is a "Cplx.__call (2,0), a")
(!call is (!call c1 "a" "b" "c") !true)
(!call is a "Cplx.__call (2,0), a, b, c")

;   delegate

(!define t ("_VALUES": ("a": 1
                        "b": "text"
                        "c": !true)))
(!define mt ("__pairs": (!lambda (op)
                (!return next (!index op "_VALUES")))))
(!call setmetatable t mt)

(!define r ())
(!for (k) ((!call pairs t))
      (!assign (!index r (!add (!len r) 1)) k))
(!call tsort r)
(!call is (!call tconcat r ",") "a,b,c" "__pairs" )

;   Window

; create a namespace
(!define Window ())
; create a prototype with default values
(!assign (!index Window "prototype") ("x": 0 "y": 0 "width": 100 "heigth": 100))
; create a metatable
(!assign (!index Window "mt") ())
; declare the constructor function
(!assign (!index Window "new") (!lambda (o)
                (!call setmetatable o (!index Window "mt"))
                (!return o)))

(!assign (!index (!index Window "mt") "__index") (!lambda (table key)
                (!return (!index (!index Window "prototype") key))))

(!define w (!call (!index Window "new") ("x": 10 "y": 20)))
(!call is (!index w "x") 10 "table-access")
(!call is (!index w "width") 100)
(!call is (!call rawget w "x") 10)
(!call is (!call rawget w "width") !nil)

(!assign (!index (!index Window "mt") "__index") (!index Window "prototype"))   ; just a table
(!define w (!call (!index Window "new") ("x": 10 "y": 20)))
(!call is (!index w "x") 10 "table-access")
(!call is (!index w "width") 100)
(!call is (!call rawget w "x") 10)
(!call is (!call rawget w "width") !nil)

;   tables with default values
(!let setDefault_1 (!lambda (t d)
                (!let mt ("__index": (!lambda () (!return d))))
                (!call setmetatable t mt)))

(!define tab ("x": 10 "y": 20))
(!call is (!index tab "x") 10 "tables with default values")
(!call is (!index tab "z") !nil)
(!call setDefault_1 tab 0)
(!call is (!index tab "x") 10)
(!call is (!index tab "z") 0)

;   tables with default values
(!define mt ("__index": (!lambda (t) (!return (!index t "___")))))
(!let setDefault_2 (!lambda (t d)
                (!assign (!index t "___") d)
                (!call setmetatable t mt)))

(!define tab ("x": 10 "y": 20))
(!call is (!index tab "x") 10 "tables with default values")
(!call is (!index tab "z") !nil)
(!call setDefault_2 tab 0)
(!call is (!index tab "x") 10)
(!call is (!index tab "z") 0)

;   tables with default values
(!define key ())
(!define mt ("__index": (!lambda (t) (!return (!index t key)))))
(!let setDefault_3 (!lambda (t d)
                (!assign (!index t key) d)
                (!call setmetatable t mt)))

(!define tab ("x": 10 "y": 20))
(!call is (!index tab "x") 10 "tables with default values")
(!call is (!index tab "z") !nil)
(!call setDefault_3 tab 0)
(!call is (!index tab "x") 10)
(!call is (!index tab "z") 0)

;   private access
(!define t ())  ; original table
; keep a private access to original table
(!let _t t)
; create proxy
(!assign t ())
(!define w)
(!define r)
; create metatable
(!define mt ("__index": (!lambda (t k)
                                (!assign r (!concat "*access to element " (!call tostring k)))
                                (!return (!index _t k)))        ; access the original table
             "__newindex": (!lambda (t k v)
                                (!assign w (!mconcat "*update of element " (!call tostring k) " to " (!call tostring v)))
                                (!assign (!index _t k) v))))    ; update original table
(!call setmetatable t mt)

(!assign w !nil)
(!assign r !nil)
(!assign (!index t 2) "hello")
(!call is w "*update of element 2 to hello" "tracking table accesses")
(!call is (!index t 2) "hello")
(!call is r "*access to element 2")

;    private access
; create private index
(!define index ())
(!define w)
(!define r)
; create metatable
(!define mt ("__index": (!lambda (t k)
                                (!assign r (!concat "*access to element " (!call tostring k)))
                                (!return (!index (!index t index) k)))          ; access the original table
             "__newindex": (!lambda (t k v)
                                (!assign w (!mconcat "*update of element " (!call tostring k) " to " (!call tostring v)))
                                (!assign (!index (!index t index) k) v))))      ; update original table
(!let track (!lambda (t)
                (!let proxy ())
                (!assign (!index proxy index) t)
                (!call setmetatable proxy mt)
                (!return proxy)))

(!define t ())
(!assign t (!call track t))

(!assign w !nil)
(!assign r !nil)
(!assign (!index t 2) "hello")
(!call is w "*update of element 2 to hello" "tracking table accesses")
(!call is (!index t 2) "hello")
(!call is r "*access to element 2")

;   read-only table
(!let readOnly (!lambda (t)
                (!let proxy ())
                (!let mt ("__index": t
                          "__newindex": (!lambda (t k v)
                                                (!call error "attempt to update a read-only table" 2))))
                (!call setmetatable proxy mt)
                (!return proxy)))

(!define days (!call readOnly ("Sunday" "Monday" "Tuesday" "Wednesday" "Thurday" "Friday" "Saturday")))

(!call is (!index days 1) "Sunday" "read-only tables")

(!call error_contains (!lambda () (!assign (!index days 2) "Noday"))
                      ": attempt to update a read-only table")

;   declare global
(!let declare (!lambda (name initval)
                (!call rawset _G name (!or initval !false))))

(!call setmetatable _G ("__newindex": (!lambda (_ n)
                                                (!call error (!concat "attempt to write to undeclared variable " n) 2))
                        "__index": (!lambda (_ n)
                                                (!call error (!concat "attempt to read undeclared variable " n) 2))))

(!call error_contains (!lambda () (!assign new_a 1))
                      ": attempt to write to undeclared variable new_a"
                      "declaring global variables")

(!call declare "new_a")
(!assign new_a 1)
(!call is new_a 1)

;
(!define newindex ())
; create metatable
(!define mt ("__newindex": newindex))
(!define t (!call setmetatable () mt))
(!assign (!index t 1) 42)
(!call is (!index newindex 1) 42 "__newindex")


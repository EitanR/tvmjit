#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call (!index tvm "dofile") "TAP.tp")

(!let assert assert)
(!let collectgarbage collectgarbage)
(!let dofile dofile)
(!let load load)
(!let loadfile loadfile)
(!let next next)
(!let pairs pairs)
(!let pcall pcall)
(!let print print)
(!let rawequal rawequal)
(!let rawget rawget)
(!let rawlen rawlen)
(!let rawset rawset)
(!let select select)
(!let tonumber tonumber)
(!let tostring tostring)
(!let getfenv getfenv)
(!let setfenv setfenv)
(!let type type)
(!let xpcall xpcall)
(!let open (!index io "open"))
(!let unlink (!index os "remove"))

(!call plan 146)

(!call contains _VERSION "Lua 5.1" "variable _VERSION")

(!define (v msg) ((!call assert "text" "assert string")))
(!call is v "text" "function assert")
(!call is msg "assert string")
(!define (v msg) ((!call assert () "assert table")))
(!call is msg "assert table")

(!call error_contains (!lambda () (!call assert !false "ASSERTION TEST"))
                      ": ASSERTION TEST"
                      "function assert(false, msg)")

(!call error_contains (!lambda () (!call assert !false))
                      ": assertion failed!"
                      "function assert(false)")

(!call error_contains (!lambda () (!call assert !false !nil))
                      ": assertion failed!"
                      "function assert(false, nil)")

(!call is (!call collectgarbage "stop") 0 "function collectgarbage 'stop/restart/collect'")
(!call is (!call collectgarbage "step") !false)
(!call is (!call collectgarbage "restart") 0)
(!call is (!call collectgarbage "step") !false)
(!call is (!call collectgarbage "collect") 0)
(!call is (!call collectgarbage "setpause" 10) 200)
(!call is (!call collectgarbage "setstepmul" 200) 200)
(!call is (!call collectgarbage) 0)

(!call type_ok (!call collectgarbage "count") "number" "function collectgarbage 'count'")

(!call error_contains (!lambda () (!call collectgarbage "unknown"))
                      ": bad argument #1 to 'collectgarbage' (invalid option 'unknown')"
                      "function collectgarbage (invalid)")

(!define f (!call open "lib1.lua" "w"))
(!callmeth f write "
function norm (x, y)
    return (x^2 + y^2)^0.5
end

function twice (x)
    return 2*x
end
")
(!callmeth f close)
(!call dofile "lib1.lua")
(!define n (!call norm 3.4 1.0))
(!call contains (!call twice n) "7.088" "function dofile")

(!call unlink "lib1.lua")        ; clean up

(!call error_contains (!lambda () (!call dofile "no_file.lua"))
                      "cannot open no_file.lua: No such file or directory"
                      "function dofile (no file)")

(!define f (!call open "foo.lua" "w"))
(!callmeth f write "?syntax error?")
(!callmeth f close)
(!call error_contains (!lambda () (!call dofile "foo.lua"))
                     "unexpected symbol"
                     "function dofile (syntax error)")
(!call unlink "foo.lua") ; clean up

(!define f (!call load "function bar (x) return x end"))
(!call is bar !nil "function load(str)")
(!call f)
(!call is (!call bar "ok") "ok")
(!assign bar !nil)

(!define env ())
(!define f (!call load "function bar (x) return x end" "from string" "t" env))
(!call is (!index env "bar") !nil "function load(str)")
(!call f)
(!call is (!call (!index env "bar") "ok") "ok")

(!define (f msg) ((!call load "?syntax error?" "errorchunk")))
(!call is f !nil "function load(syntax error)")
(!call contains msg "unexpected symbol")

(!define (f msg) ((!call load "print 'ok'" "chunk txt" "b")))
(!call contains  msg "attempt to load chunk with wrong mode")
(!call is f !nil "mode")

(!define (f msg) ((!call load "\x1bLua" "chunk bin" "t")))
(!call contains  msg "attempt to load chunk with wrong mode")
(!call is f !nil "mode")

(!define f (!call open "foo.lua" "w"))
(!callmeth f write "
function foo (x)
    return x
end
")
(!callmeth f close)
(!define f (!call loadfile "foo.lua"))
(!call is foo !nil "function loadfile")
(!call f)
(!call is (!call foo "ok") "ok")

(!define (f msg) ((!call loadfile "foo.lua" "b")))
(!call contains msg "attempt to load chunk with wrong mode")
(!call is f !nil "mode")

(!define env ())
(!define f (!call loadfile "foo.lua" "t" env))
(!call is (!index env "foo") !nil "function loadfile")
(!call f)
(!call is (!call (!index env "foo") "ok") "ok")

(!call unlink "foo.lua") ; clean up

(!define (f msg) ((!call loadfile "no_file.lua")))
(!call is f !nil "function loadfile (no file)")
(!call is msg "cannot open no_file.lua: No such file or directory")

(!define f (!call open "foo.lua" "w"))
(!callmeth f write "?syntax error?")
(!callmeth f close)
(!define (f msg) ((!call loadfile "foo.lua")))
(!call is f !nil "function loadfile (syntax error)")
(!call contains msg "unexpected symbol")
(!call unlink "foo.lua") ; clean up

(!let loadstring load)

(!define f (!call loadstring "i = i + 1"))
(!assign i 0)
(!call f)
(!call is i 1 "function loadstring")
(!call f)
(!call is i 2)

(!assign i 32)
(!define i 0)
(!define f (!call loadstring "i = i + 1; return i"))
(!define g (!lambda () (!assign i (!add i 1))(!return i)))
(!call is (!call f) 33 "function loadstring")
(!call is (!call g) 1)

(!define (f msg) ((!call loadstring "?syntax error?")))
(!call is f !nil "function loadstring (syntax error)")
(!call contains msg "unexpected symbol")

(!define t ("a" "b" "c"))
(!define a (!call next t !nil))
(!call is a 1 "function next (array)")
(!define a (!call next t 1))
(!call is a 2)
(!define a (!call next t 2))
(!call is a 3)
(!define a (!call next t 3))
(!call is a !nil)

(!call error_contains (!lambda () (!assign a (!call next)))
                      ": bad argument #1 to 'next' (table expected, got no value)"
                      "function next (no arg)")

(!call error_contains (!lambda () (!assign a (!call next t 6)))
                      "invalid key to 'next'"
                      "function next (invalid key)")

(!define t ("a" "b" "c"))
(!define a (!call next t 2))
(!call is a 3 "function next (unorderer)")
(!define a (!call next t 1))
(!call is a 2)
(!define a (!call next t 3))
(!call is a !nil)

(!define t ())
(!define a (!call next t !nil))
(!call is a !nil "function next (empty table)")

(!define a ("a" "b" "c"))
(!define (f v s) ((!call pairs a)))
(!call type_ok f "function" "function pairs")
(!call type_ok v "table")
(!call is s !nil)
(!define s (!call f v s))
(!call is s 1)
(!define s (!call f v s))
(!call is s 2)
(!define s (!call f v s))
(!call is s 3)
(!define s (!call f v s))
(!call is s !nil)


(!define r (!call pcall assert !true))
(!call is r !true "function pcall")
(!define (r msg) ((!call pcall assert !false "catched")))
(!call is r !false)
(!call is msg "catched")
(!define r (!call pcall assert))
(!call is r !false)

(!define t ())
(!define a t)
(!call is (!call rawequal !nil !nil) !true "function rawequal -> true")
(!call is (!call rawequal !false !false) !true)
(!call is (!call rawequal 3 3) !true)
(!call is (!call rawequal "text" "text") !true)
(!call is (!call rawequal t a) !true)
(!call is (!call rawequal print print) !true)

(!call is (!call rawequal !nil 2) !false "function rawequal -> false")
(!call is (!call rawequal !false !true) !false)
(!call is (!call rawequal !false 2) !false)
(!call is (!call rawequal 3 2) !false)
(!call is (!call rawequal 3 "2") !false)
(!call is (!call rawequal "text" "2") !false)
(!call is (!call rawequal "text" 2) !false)
(!call is (!call rawequal t ()) !false)
(!call is (!call rawequal t 2) !false)
(!call is (!call rawequal print type) !false)
(!call is (!call rawequal print 2) !false)

(!call is (!call rawlen "text") 4 "function rawlen (string)")
(!call is (!call rawlen ("a" "b" "c")) 3 "function rawlen (table)")
(!call error_contains (!lambda () (!assign a (!call rawlen !true)))
                      ": bad argument #1 to 'rawlen' (table expected, got boolean)"
                      "function rawlen with bad arg")

(!define t ( "a": "letter a" "b": "letter b"))
(!call is (!call rawget t "a") "letter a" "function rawget")

(!define t ())
(!call is (!call rawset t "a" "letter a") t "function rawset")
(!call is (!index t "a") "letter a")

(!call error_contains (!lambda () (!define t ())(!call rawset t !nil 42))
                      "table index is nil"
                      "function rawset (table index is nil)")

(!call is (!call select "#") 0 "function select")
(!call is (!call select "#" "a" "b" "c") 3)
(!call eq_array ((!call select 1 "a" "b" "c")) ("a" "b" "c"))
(!call eq_array ((!call select 3 "a" "b" "c")) ("c"))
(!call eq_array ((!call select 5 "a" "b" "c")) ())
(!call eq_array ((!call select -1 "a" "b" "c")) ("c"))
(!call eq_array ((!call select -2 "a" "b" "c")) ("b" "c"))
(!call eq_array ((!call select -3 "a" "b" "c")) ("a" "b" "c"))

(!call error_contains (!lambda () (!call select 0 "a" "b" "c"))
                      ": bad argument #1 to 'select' (index out of range)"
                      "function select (out of range)")

(!call error_contains (!lambda () (!call select -4 "a" "b" "c"))
                      ": bad argument #1 to 'select' (index out of range)"
                      "function select (out of range)")

(!let t ())
(!let f (!lambda ()))
(!call is (!call setfenv f t) f "function setfenv")
(!call type_ok (!call getfenv f) "table")
(!call is (!call getfenv f) t)

(!call error_contains (!lambda () (!call setfenv -3 ()))
                      ": bad argument #1 to 'setfenv' (invalid level)"
                      "function setfenv (negative)")

(!call error_contains (!lambda () (!call setfenv 12 ()))
                      ": bad argument #1 to 'setfenv' (invalid level)"
                      "function setfenv (too depth)")

(!let t ())
(!call error_contains (!lambda () (!call setfenv t ()))
                      ": bad argument #1 to 'setfenv' (number expected, got table)"
                      "function setfenv (bad arg)")

(!call error_contains (!lambda () (!call setfenv print ()))
                      ": 'setfenv' cannot change environment of given object"
                      "function setfenv (forbidden)")

(!call is (!call type "Hello world") "string" "function type")
(!call is (!call type (!mul 10.4 3)) "number")
(!call is (!call type print) "function")
(!call is (!call type type) "function")
(!call is (!call type !true) "boolean")
(!call is (!call type !nil) "nil")
(!call is (!call type (!index io "stderr")) "userdata")
(!call is (!call type (!call type type)) "string")

(!define a !nil)
(!call is (!call type a) "nil" "function type")
(!define a 10)
(!call is (!call type a) "number")
(!define a "a string!!")
(!call is (!call type a) "string")
(!define a print)
(!call is (!call type a) "function")
(!call is (!call type (!lambda ())) "function")

(!call error_contains (!lambda () (!call type))
                      ": bad argument #1 to 'type' (value expected)"
                      "function type (no arg)")

(!call is (!call tonumber "text12") !nil "function tonumber")
(!call is (!call tonumber "12text") !nil)
(!call is (!call tonumber 3.14) 3.14)
(!call is (!call tonumber "3.14") 3.14)
(!call is (!call tonumber "  3.14  ") 3.14)
(!call is (!call tonumber 111 2) 7)
(!call is (!call tonumber "111" 2) 7)
(!call is (!call tonumber "  111  " 2) 7)
(!define a ())
(!call is (!call tonumber a) !nil)

(!call error_contains (!lambda () (!call tonumber))
                      ": bad argument #1 to 'tonumber' (value expected)"
                      "function tonumber (no arg)")

(!call error_contains (!lambda () (!call tonumber "111" 200))
                      ": bad argument #2 to 'tonumber' (base out of range)"
                      "function tonumber (bad base)")

(!call is (!call tostring "text") "text" "function tostring")
(!call is (!call tostring 3.14) "3.14")
(!call is (!call tostring !nil) "nil")
(!call is (!call tostring !true) "true")
(!call is (!call tostring !false) "false")
(!call contains (!call tostring ()) "table: ")
(!call contains (!call tostring print) "function: ")

(!call error_contains (!lambda () (!call tostring))
                      ": bad argument #1 to 'tostring' (value expected)"
                      "function tostring (no arg)")

(!call error_contains (!lambda () (!call xpcall assert !nil))
                      ": bad argument #2 to 'xpcall' (function expected, got nil)"
                      "function xpcall (no arg)")
(!call error_contains (!lambda () (!call xpcall assert))
                      ": bad argument #2 to 'xpcall' (function expected, got no value)"
                      "function xpcall (no arg)")

(!define backtrace (!lambda ()
                            (!return "not a back trace")))
(!define (r msg) ((!call xpcall assert backtrace)))
(!call is r !false "function xpcall (backtrace)")
(!call is msg "not a back trace")

(!define r (!call xpcall assert backtrace !true))
(!call is r !true "function xpcall")


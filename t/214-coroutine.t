#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call dofile "TAP.tp")

(!let coroutine coroutine)
(!let error error)
(!let getmetatable getmetatable)
(!let pcall pcall)
(!let print print)
(!let setmetatable setmetatable)
(!let xpcall xpcall)
(!let plan plan)
(!let is is)
(!let contains contains)
(!let error_contains error_contains)
(!let eq_array eq_array)
(!let type_ok type_ok)

(!call plan 30)

;
(!define output ())

(!let foo1 (!lambda (a)
                (!assign (!index output (!len output)) (!concat "foo " a))
                (!return (!call (!index coroutine "yield") (!mul 2 a)))))

(!define co (!call (!index coroutine "create") (!lambda (a b)
                (!assign (!index output (!len output)) (!mconcat "co-body " a " " b))
                (!define r (!call foo1 (!add a 1)))
                (!assign (!index output (!len output)) (!concat "co-body " r))
                (!define (r s) ((!call (!index coroutine "yield") (!add a b) (!sub a b))))
                (!assign (!index output (!len output)) (!mconcat "co-body " r " " s))
                (!return b "end"))))

(!call eq_array ((!call (!index coroutine "resume") co 1 10)) (!true 4) "foo1")
(!call eq_array ((!call (!index coroutine "resume") co "r")) (!true 11 -9))
(!call eq_array ((!call (!index coroutine "resume") co "x" "y")) (!true 10 "end"))
(!call eq_array ((!call (!index coroutine "resume") co "x" "y")) (!false "cannot resume dead coroutine"))
(!call eq_array output (
    "co-body 1 10"
    "foo 2"
    "co-body r"
    "co-body x y"
))

;
(!define co (!call (!index coroutine "create") (!lambda ()
                (!assign output "hi"))))
(!call contains co "thread: " "basics")

(!call is (!call (!index coroutine "status") co) "suspended")
(!assign output "")
(!call (!index coroutine "resume") co)
(!call is output "hi")
(!call is (!call (!index coroutine "status") co) "dead")

(!call error_contains (!lambda () (!call (!index coroutine "create") !true))
                      ": bad argument #1 to 'create' (function expected, got boolean)")

(!call error_contains (!lambda () (!call (!index coroutine "resume") !true))
                      ": bad argument #1 to 'resume' (coroutine expected)")

(!call error_contains (!lambda () (!call (!index coroutine "status") !true))
                      ": bad argument #1 to 'status' (coroutine expected)")

;
(!define output ())
(!define co (!call (!index coroutine "create") (!lambda ()
                (!loop i 1 10 1
                        (!assign (!index output (!len output)) i)
                        (!call (!index coroutine "yield"))))))

(!call (!index coroutine "resume") co)
(!define (thr ismain) ((!call (!index coroutine "running") co)))
(!call type_ok thr "thread" "running")
(!call is ismain !true "running")
(!call is (!call (!index coroutine "status") co) "suspended" "basics")
(!call (!index coroutine "resume") co)
(!call (!index coroutine "resume") co)
(!call (!index coroutine "resume") co)
(!call (!index coroutine "resume") co)
(!call (!index coroutine "resume") co)
(!call (!index coroutine "resume") co)
(!call (!index coroutine "resume") co)
(!call (!index coroutine "resume") co)
(!call (!index coroutine "resume") co)
(!call (!index coroutine "resume") co)
(!call eq_array ((!call (!index coroutine "resume") co)) (!false "cannot resume dead coroutine"))
(!call eq_array output (1 2 3 4 5 6 7 8 9 10))

;
(!define co (!call (!index coroutine "create") (!lambda (a b)
                (!call (!index coroutine "yield") (!add a b) (!sub a b)))))

(!call eq_array ((!call (!index coroutine "resume") co 20 10)) (!true 30 10) "basics")


(!define co (!call (!index coroutine "create") (!lambda ()
                (!return 6 7))))

(!call eq_array ((!call (!index coroutine "resume") co)) (!true 6 7) "basics")

;
(!define co (!call (!index coroutine "wrap") (!lambda (!vararg)
                (!return (!call pcall (!lambda (!vararg)
                                               (!return (!call (!index coroutine "yield") !vararg)))
                                      !vararg)))))
(!call eq_array ((!call co "Hello")) ("Hello"))
(!call eq_array ((!call co "World")) (!true "World"))

(!define co (!call (!index coroutine "wrap") (!lambda (!vararg)
                (!define backtrace (!lambda ()
                                            (!return "not a back trace")))
                (!return (!call xpcall (!lambda (!vararg)
                                                (!return (!call (!index coroutine "yield") !vararg)))
                                       backtrace !vararg)))))
(!call eq_array ((!call co "Hello")) ("Hello"))
(!call eq_array ((!call co "World")) (!true "World"))

;
(!define output ())
(!define co (!call (!index coroutine "wrap") (!lambda ()
                (!while !true
                        (!let t (!call setmetatable () ("__eq": (!lambda (!vararg)
                                        (!return (!call (!index coroutine "yield") !vararg))))))
                        (!let t2 (!call setmetatable () (!call getmetatable t)))
                        (!assign (!index output (!len output)) (!eq t t2))))))
(!call co)
(!call co !true)
(!call co !false)
(!call eq_array output (!true !false))

;
(!define co (!call (!index coroutine "wrap") print))
(!call type_ok co "function")

(!call error_contains (!lambda () (!call (!index coroutine "wrap") !true))
                      ": bad argument #1 to 'wrap' (function expected, got boolean)")

(!define co (!call (!index coroutine "wrap") (!lambda () (!call error "in coro"))))
(!call error_contains (!lambda () (!call co))
                      ": in coro")

;
(!define co (!call (!index coroutine "create") (!lambda ()
                (!call error "in coro"))))
(!define (r msg) ((!call (!index coroutine "resume") co)))
(!call is r !false)
(!call contains msg ": in coro")

;
(!call error_contains (!lambda () (!call (!index coroutine "yield")))
                      "attempt to yield")


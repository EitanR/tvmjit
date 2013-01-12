#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!let TAP (!call dofile "TAP.tp"))

(!let getinfo (!index debug "getinfo"))
(!let gethook (!index debug "gethook"))
(!let getlocal (!index debug "getlocal"))
(!let getmetatable (!index debug "getmetatable"))
(!let getregistry (!index debug "getregistry"))
(!let getupvalue (!index debug "getupvalue"))
(!let getuservalue (!index debug "getuservalue"))
(!let sethook (!index debug "sethook"))
(!let setlocal (!index debug "setlocal"))
(!let setmetatable (!index debug "setmetatable"))
(!let setupvalue (!index debug "setupvalue"))
(!let setuservalue (!index debug "setuservalue"))
(!let traceback (!index debug "traceback"))
(!let upvalueid (!index debug "upvalueid"))
(!let upvaluejoin (!index debug "upvaluejoin"))

(!let base_getmetatable getmetatable)
(!let open (!index io "open"))
(!let unlink (!index os "remove"))
(!let co_create (!index coroutine "create"))

(!let plan plan)
(!let is is)
(!let type_ok type_ok)
(!let contains contains)
(!let error_contains error_contains)
(!let pass pass)
(!let fail fail)

(!call plan 51)

(!define info (!call getinfo is))
(!call type_ok info "table" "function getinfo (function)")
(!call is (!index info "func") is " .func")

(!define info (!call getinfo is "L"))
(!call type_ok info "table" "function getinfo (function, opt)")
(!call type_ok (!index info "activelines") "table")

(!define info (!call getinfo 1))
(!call type_ok info "table" "function getinfo (level)")
(!call contains (!index info "func") "function: " " .func")

(!call is (!call getinfo 12) !nil "function getinfo (too depth)")

(!call error_contains (!lambda () (!call getinfo "bad"))
                      "bad argument #1 to 'getinfo' (function or level expected)"
                      "function getinfo with bad arg")

(!call error_contains (!lambda () (!call getinfo is "X"))
                      "bad argument #2 to 'getinfo' (invalid option)"
                      "function getinfo with bad option")

(!define (name value) ((!call getlocal 0 1)))
(!call type_ok name "string" "function getlocal (level)")
(!call is value 0)

(!call error_contains (!lambda () (!call getlocal 42 1))
                      "bad argument #1 to 'getlocal' (level out of range)"
                      "function getlocal (out of range)")

(!define (name value) ((!call getlocal contains 1)))
(!call type_ok name "string" "function getlocal (func)")
(!call is value !nil)

(!define t ())
(!call is (!call getmetatable t) !nil "function getmetatable")
(!define t1 ())
(!call setmetatable t t1)
(!call is (!call getmetatable t) t1)

(!define a !true)
(!call is (!call getmetatable a) !nil)
(!call setmetatable a t1)
(!call is (!call getmetatable t) t1)

(!define a 3.14)
(!call is (!call getmetatable a) !nil)
(!call setmetatable a t1)
(!call is (!call getmetatable t) t1)

(!define reg (!call getregistry))
(!call type_ok reg "table" "function getregistry")
(!call type_ok (!index reg "_LOADED") "table")

(!define name (!call getupvalue plan 1))
(!call type_ok name "string" "function getupvalue")

(!call sethook)
(!define (hook mask count) ((!call gethook)))
(!call is hook !nil "function gethook")
(!call is mask "")
(!call is count 0)
(!define f (!lambda ()))
(!call sethook f "c" 42)
(!define (hook mask count) ((!call gethook)))
(!call is hook f "function gethook")
(!call is mask "c")
(!call is count 42)

(!define co (!call co_create (!lambda () (!call println "thread"))))
(!define hook (!call gethook co))
(!call type_ok hook "function" "function gethook(thread)")

(!define name (!call setlocal 0 1 0))
(!call type_ok name "string" "function setlocal (level)")

(!define name (!call setlocal 0 42 0))
(!call is name !nil "function setlocal (level)")

(!call error_contains (!lambda () (!call setlocal 42 1 !true))
                      "bad argument #1 to 'setlocal' (level out of range)"
                      "function getlocal (out of range)")

(!define t ())
(!define t1 ())
(!call is (!call setmetatable t t1) t "function setmetatable")
(!call is (!call base_getmetatable t) t1)

(!call error_contains (!lambda () (!call setmetatable t !true))
                      ": bad argument #2 to 'setmetatable' (nil or table expected)")

(!define name (!call setupvalue plan 1 TAP))
(!call type_ok name "string" "function setupvalue")

(!define name (!call setupvalue plan 42 !true))
(!call is name !nil)

(!define u (!call open "file.txt" "w"))
(!define old (!call getuservalue u))
(!call type_ok old "table" "function getuservalue")
(!call is (!call getuservalue !true) !nil)
(!define data ())
(!define r (!call setuservalue u data))
(!call is r u "function setuservalue")
(!call is (!call getuservalue u) data)
(!define r (!call setuservalue u old))
(!call is (!call getuservalue u) old)
(!call unlink "file.txt")

(!call error_contains (!lambda () (!call setuservalue () data))
                      ": bad argument #1 to 'setuservalue' (userdata expected, got table)")

(!call error_contains (!lambda () (!call setuservalue u !true))
                      ": bad argument #2 to 'setuservalue' (table expected, got boolean)")

(!call contains (!call traceback) "stack traceback:\n" "function traceback")

(!call contains (!call traceback "message\n") "message\n\nstack traceback:\n" "function traceback with message")

(!call contains (!call traceback !false) "false" "function traceback")

(!define id (!call upvalueid plan 1))
(!call type_ok id "userdata" "function upvalueid")

(!call upvaluejoin pass 1 fail 1)

(!call error_contains (!lambda () (!call upvaluejoin !true 1 !nil 1))
                      "bad argument #1 to 'upvaluejoin' (function expected, got boolean)"
                      "function upvaluejoin with bad arg")

(!call error_contains (!lambda () (!call upvaluejoin pass 1 !true 1))
                      "bad argument #3 to 'upvaluejoin' (function expected, got boolean)"
                      "function upvaluejoin with bad arg")


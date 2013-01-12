#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call dofile "TAP.tp")

(!let exe (!or RUN_TVM (!index arg -1)))
(!let execute (!index os "execute"))
(!let unlink (!index os "remove"))
(!let plan plan)
(!let diag diag)
(!let is is)
(!let isnt isnt)
(!let contains contains)
(!let skip_all skip_all)

(!if (!not (!call pcall (!index io "popen") exe " -e \"a=1\""))
     (!call skip_all "io.popen not supported"))

(!call plan 19)
(!call diag exe)

(!define f (!call (!index io "open") "hello.tp" "w"))
(!callmeth f write "\
(!call print \"Hello World\")\
")
(!callmeth f close)

(!define cmd (!concat exe " hello.tp"))
(!define f (!call (!index io "popen") cmd))
(!call is (!callmeth f read) "Hello World" "file")
(!callmeth f close)

(!define cmd (!concat exe " no_file.tp 2>&1"))
(!define f (!call (!index io "popen") cmd))
(!call contains (!callmeth f read) ": cannot open no_file.tp" "no file")
(!callmeth f close)

(!call execute (!concat exe " -b hello.tp hello.tpc"))
(!define cmd (!concat exe " hello.tpc"))
(!define f (!call (!index io "popen") cmd))
(!call is (!callmeth f read) "Hello World" "bytecode")
(!callmeth f close)

(!call unlink "hello.tpc")      ; clean up

(!define cmd (!concat exe " < hello.tp"))
(!define f (!call (!index io "popen") cmd))
(!call is (!callmeth f read) "Hello World" "redirect")
(!callmeth f close)

(!define cmd (!concat exe " -e\"(!assign a 1)\" -e \"(!call print a)\""))
(!define f (!call (!index io "popen") cmd))
(!call is (!callmeth f read) "1" "-e")
(!callmeth f close)

(!define cmd (!concat exe " -e \"(!call error \\\"msg\\\")\"  2>&1"))
(!define f (!call (!index io "popen") cmd))
(!call contains (!callmeth f read) ": (command line):1: msg" "error")
(!call is (!callmeth f read) "stack traceback:" "backtrace")
(!callmeth f close)

(!define cmd (!concat exe " -e \"(!call error (!call setmetatable () ( \\\"__tostring\\\": (!lambda () (!return \\\"MSG\\\")))))\"  2>&1"))
(!define f (!call (!index io "popen") cmd))
(!call contains (!callmeth f read) ": MSG" "error with object")
(!call is (!callmeth f read) "stack traceback:" "backtrace")
(!callmeth f close)

(!define cmd (!concat exe " -e \"(!call error ())\"  2>&1"))
(!define f (!call (!index io "popen") cmd))
(!call contains (!callmeth f read) ": (error object is not a string)" "error")
(!callmeth f close)

(!define cmd (!concat exe " -e\"(!assign a 1)\" -e \"(!call print a)\" hello.tp"))
(!define f (!call (!index io "popen") cmd))
(!call is (!callmeth f read) "1" "-e & script")
(!call is (!callmeth f read) "Hello World")
(!callmeth f close)

(!define cmd (!concat exe " -e \"?syntax error?\" 2>&1"))
(!define f (!call (!index io "popen") cmd))
(!call contains (!callmeth f read) ":1:" "-e bad")
(!callmeth f close)

(!define cmd (!concat exe " -e 2>&1"))
(!define f (!call (!index io "popen") cmd))
(!call contains (!callmeth f read) "usage: " "no file")
(!callmeth f close)

(!define cmd (!concat exe " -v 2>&1"))
(!define f (!call (!index io "popen") cmd))
(!call contains (!callmeth f read) "TvmJIT" "-v")
(!callmeth f close)

(!define cmd (!concat exe " -v hello.tp 2>&1"))
(!define f (!call (!index io "popen") cmd))
(!call contains (!callmeth f read) "TvmJIT" "-v & script")
(!call is (!callmeth f read) "Hello World")
(!callmeth f close)

(!define cmd (!concat exe " -E hello.tp 2>&1"))
(!define f (!call (!index io "popen") cmd))
(!call is (!callmeth f read) "Hello World")
(!callmeth f close)

(!define cmd (!concat exe " -u 2>&1"))
(!define f (!call (!index io "popen") cmd))
(!call contains (!callmeth f read) "usage: " "unknown option")
(!callmeth f close)

(!call unlink "hello.tp")       ; clean up


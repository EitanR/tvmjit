#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call (!index tvm "dofile") "TAP.tp")

(!let pcall pcall)
(!let open (!index io "open"))
(!let popen (!index io "popen"))
(!let unlink (!index os "remove"))

(!let exe (!or RUN_TVM (!index arg -1)))
(!let plan plan)
(!let is is)
(!let contains contains)
(!let skip_all skip_all)

(!if (!not (!call pcall popen exe " -e \"a=1\""))
     (!call skip_all "io.popen not supported"))

(!call plan 5)

(!define f (!call open "lib1.tp" "w"))
(!callmeth f write "\
(!assign norm (!lambda (x y)\
                (!return (!pow (!add (!pow x 2) (!pow y 2)) 0.5))))\
\
(!assign twice (!lambda (x)\
                (!return (!mul 2 x))))\
")
(!callmeth f close)

(!define cmd (!concat exe " -e \"(!call (!index tvm \\\"dofile\\\"))(!define n (!call norm 3.4 1.0))(!call print (!call twice n))\" < lib1.tp"))
(!define f (!call popen cmd))
(!call contains (!callmeth f read) "7.088" "function dofile (stdin)")
(!callmeth f close)

(!call unlink "lib1.tp")        ; clean up

(!define f (!call open "foo.tp" "w"))
(!callmeth f write "(!assign foo (!lambda (x) (!return x)))")
(!callmeth f close)

(!define cmd (!concat exe " -e \"(!define f (!call (!index tvm \\\"loadfile\\\")))(!call print (!call tostring foo))(!call f)(!call print (!call foo \\\"ok\\\"))\" < foo.tp"))
(!define f (!call popen cmd))
(!call is (!callmeth f read) "nil" "function loadfile (stdin)")
(!call is (!callmeth f read) "ok")
(!callmeth f close)

(!call unlink "foo.tp")         ; clean up

(!define f (!call open "dbg.txt" "w"))
(!callmeth f write "print 'ok'\n")
(!callmeth f write "error 'dbg'\n")
(!callmeth f write "cont\n")
(!callmeth f close)

(!define cmd (!concat exe " -e \"(!call (!index debug \\\"debug\\\"))\" < dbg.txt"))
(!define f (!call popen cmd))
(!call is (!callmeth f read) "ok" "function debug.debug")
(!call is (!callmeth f read) !nil)
(!callmeth f close)

(!call unlink "dbg.txt")        ; clean up


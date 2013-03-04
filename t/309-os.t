#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call (!index tvm "dofile") "TAP.tp")

(!let clock (!index os "clock"))
(!let date (!index os "date"))
(!let difftime (!index os "difftime"))
(!let execute (!index os "execute"))
(!let getenv (!index os "getenv"))
(!let remove (!index os "remove"))
(!let rename (!index os "rename"))
(!let setlocale (!index os "setlocale"))
(!let time (!index os "time"))
(!let tmpname (!index os "tmpname"))
(!let open (!index io "open"))
(!let popen (!index io "popen"))
(!let pcall pcall)

(!let exe (!or RUN_TVM (!index arg -1)))
(!let plan plan)
(!let diag diag)
(!let is is)
(!let ok ok)
(!let type_ok type_ok)
(!let contains contains)
(!let like like)
(!let skip skip)

(!call plan 51)

(!let clk (!call clock))
(!call type_ok clk "number" "function clock")
(!call ok (!le clk (!call clock)))

(!let d (!call date "!*t" 0))
(!call is (!index d "year") 1970 "function date")
(!call is (!index d "month") 1)
(!call is (!index d "day") 1)
(!call is (!index d "hour") 0)
(!call is (!index d "min") 0)
(!call is (!index d "sec") 0)
(!call is (!index d "wday") 5)
(!call is (!index d "yday") 1)
(!call is (!index d "isdst") !false)

(!call is (!call date "!%d/%m/%y %H:%M:%S" 0) "01/01/70 00:00:00" "function date")
(!call like (!call date "%H:%M:%S") "^%d%d:%d%d:%d%d" "function date")

(!call is (!call difftime 1234 1200) 34 "function difftime")
(!call is (!call difftime 1234) 1234)

(!define r (!call execute))
(!call is r !true "function execute")

(!define (r s n) ((!call execute "__IMPROBABLE__")))
(!call is r !nil "function execute")
(!call is s "exit")
(!call type_ok n "number")

(!define cmd (!concat exe " -e \"(!call print \\\"# hello from external tVM\\\")(!call (!index os \\\"exit\\\") 2)\""))
(!define (r s n) ((!call execute cmd)))
(!call is r !nil)
(!call is s "exit" "function execute & exit")
(!call is n 2 "exit value")

(!define cmd (!concat exe " -e \"(!call print \\\"# hello from external tVM\\\")(!call (!index os \\\"exit\\\") !false)\""))
(!define (r s n) ((!call execute cmd)))
(!call is r !nil)
(!call is s "exit" "function execute & exit")
(!call is n 1 "exit value")

(!define cmd (!concat exe " -e \"(!call print \\\"# hello from external tVM\\\")(!call (!index os \\\"exit\\\") !true !true)\""))
(!call is (!call execute cmd) !true "function execute & exit")

(!define cmd (!concat exe " -e \"(!call print \\\"reached\\\")(!call (!index os \\\"exit\\\"))(!call print \\\"not reached\\\")\""))
(!define (r f) ((!call pcall popen cmd)))
(!if r
     (!do (!call is (!callmeth f read) "reached" "function exit")
          (!call is (!callmeth f read) !nil)
          (!define code (!callmeth f close))
          (!call is code !true "exit code"))
     (!call skip "io.popen not supported" 3))

(!define cmd (!concat exe " -e \"(!call print \\\"reached\\\")(!call (!index os \\\"exit\\\") 3)(!call print \\\"not reached\\\")\""))
(!define (r f) ((!call pcall popen cmd)))
(!if r
     (!do (!call is (!callmeth f read) "reached" "function exit")
          (!call is (!callmeth f read) !nil)
          (!define (r s n) ((!callmeth f close)))
          (!call is r !nil)
          (!call is s "exit" "exit code")
          (!call is n 3 "exit value"))
     (!call skip "io.popen not supported" 5))

(!call is (!call getenv "__IMPROBABLE__") !nil "function getenv")

(!define user (!or (!call getenv "LOGNAME")
                   (!call getenv "USERNAME")))
(!call type_ok user "string" "function getenv")

(!define f (!call open "./file.rm" "w"))
(!callmeth f write "file to remove")
(!callmeth f close)
(!define r (!call remove "./file.rm"))
(!call is r !true "function remove")

(!define (r msg) ((!call remove "./file.rm")))
(!call is r !nil "function remove")
(!call contains msg "file.rm: No such file or directory")

(!define f (!call open "./file.old" "w"))
(!callmeth f write "file to rename")
(!callmeth f close)
(!call remove "./file.new")
(!define r (!call rename "./file.old" "./file.new"))
(!call is r !true "function rename")
(!call remove "./file.new")        ; clean up

(!define (r msg) ((!call rename "./file.old" "./file.new")))
(!call is r !nil "function rename")
(!call contains msg "file.old: No such file or directory")

(!call is (!call setlocale "C" "all") "C" "function setlocale")
(!call is (!call setlocale) "C")

(!call is (!call setlocale "unk_loc" "all") !nil "function setlocale (unknown locale)")

(!call like (!call time) "^%d+%.?%d*$" "function time")

(!call like (!call time !nil) "^%d+%.?%d*$" "function time")

(!call like (!call time (
    "sec": 0
    "min": 0
    "hour": 0
    "day": 1
    "month": 1
    "year": 2000
    "isdst": 0
)) "^946%d+$" "function time")

(!call error_contains (!lambda () (!call time ()))
           ": field 'day' missing in date table"
           "function time (missing field)")

(!define fname (!call tmpname))
(!call type_ok fname "string" "function tmpname")
(!call ok (!ne fname (!call tmpname)))


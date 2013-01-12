#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call dofile "TAP.tp")

(!let close (!index io "close"))
(!let flush (!index io "flush"))
(!let open (!index io "open"))
(!let input (!index io "input"))
(!let output (!index io "output"))
(!let popen (!index io "popen"))
(!let lines (!index io "lines"))
(!let tmpfile (!index io "tmpfile"))
(!let write (!index io "write"))
(!let pcall pcall)
(!let tostring tostring)
(!let type type)
(!let unlink (!index os "remove"))

(!let exe (!or RUN_TVM (!index arg -1)))
(!let plan plan)
(!let is is)
(!let contains contains)
(!let like like)
(!let error_contains error_contains)
(!let eq_array eq_array)
(!let skip skip)

(!call plan 59)

(!call like (!index io "stdin") "^file %(0?[Xx]?%x+%)$" "variable stdin")

(!call like (!index io "stdout") "^file %(0?[Xx]?%x+%)$" "variable stdout")

(!call like (!index io "stderr") "^file %(0?[Xx]?%x+%)$" "variable stderr")

(!let (r msg) ((!call close (!index io "stderr"))))
(!call is r !nil "close (std)")
(!call is msg "cannot close standard file")

(!call is (!call flush) !true "function flush")

(!call unlink "file.no")
(!define (f msg) ((!call open "file.no")))
(!call is f !nil "function open")
(!call is msg "file.no: No such file or directory")

(!call unlink "./file.txt")
(!assign f (!call open "./file.txt" "w"))
(!callmeth f write "file with text\n")
(!callmeth f close)
(!assign f (!call open "./file.txt"))
(!call contains f "file (" "function open")

(!call is (!callmeth f close) !true "function close")

(!call error_contains (!lambda () (!callmeth f close))
                      ": attempt to use a closed file"
                      "function close (closed)")

(!assign f (!call open "./file.txt"))
(!call is (!call type f) "userdata")
(!call contains (!call tostring f) "file (")
(!callmeth f close)
(!call is (!call type f) "userdata")
(!call is (!call tostring f) "file (closed)")

(!call is (!call (!index io "type") "not a file") !nil "function type")
(!assign f (!call open "file.txt"))
(!call is (!call (!index io "type") f) "file")
(!call like (!call tostring f) "^file %(0?[Xx]?%x+%)$")
(!call close f)
(!call is (!call (!index io "type") f) "closed file")
(!call is (!call tostring f) "file (closed)")

(!call is (!index io "stdin") (!call input) "function input")
(!call is (!index io "stdin") (!call input !nil))
(!assign f (!index io "stdin"))
(!call like (!call input "file.txt") "^file %(0?[Xx]?%x+%)$")
(!call is f (!call input f))

(!call is (!call output) (!index io "stdout") "function output")
(!call is (!call output !nil) (!index io "stdout"))
(!assign f (!index io "stdout"))
(!call like (!call output "output.new") "^file %(0?[Xx]?%x+%)$")
(!call is f (!call output f))
(!call unlink "output.new")

(!define r)
(!massign (r f) ((!call pcall popen (!concat exe " -e \"(!call print \\\"standard output\\\")\""))))
(!if r
     (!do (!call is (!call type f) "userdata" "popen (read)")
          (!call is (!callmeth f read) "standard output")
          (!call is (!callmeth f close) !true))
     (!call skip "io.popen not supported" 3))

(!massign (r f) ((!call pcall popen "perl -pe \"s/e/a/\"" "w")))
(!if r
     (!do (!call is (!call type f) "userdata" "popen (write)")
          (!callmeth f write "# hello\n") ; not tested : hallo
          (!call is (!callmeth f close) !true))
     (!call skip "io.popen not supported" 2))

(!for (line) ((!call lines "file.txt"))
      (!call is line "file with text" "function lines(filename)"))

(!assign f (!call tmpfile))
(!call is (!call (!index io "type") f) "file" "function tmpfile")
(!callmeth f write "some text")
(!callmeth f close)

(!call write)                   ; not tested
(!call write "# text" 12 "\n")  ; not tested :  # text12

(!let (r msg) ((!callmeth (!index io "stderr") close)))
(!call is r !nil "method close (std)")
(!call is msg "cannot close standard file")

(!assign f (!call open "./file.txt"))
(!call is (!callmeth f close) !true "method close")

(!call is (!callmeth (!index io "stderr") flush) !true "method flush")

(!call error_contains (!lambda () (!callmeth f flush))
                      ": attempt to use a closed file"
                      "method flush (closed)")

(!call error_contains (!lambda () (!callmeth f read))
                      ": attempt to use a closed file"
                      "method read (closed)")

(!define f (!call open "./file.txt"))
(!define s (!callmeth f read))
(!call is (!len s) 14 "method read")
(!call is s "file with text")
(!assign s (!callmeth f read))
(!call is s !nil)
(!callmeth f close)

(!assign f (!call open "./file.txt"))
(!define s1 (!callmeth f read))
(!define s2 (!callmeth f read))
(!call is (!len s1) 14 "method read")
(!call is s1 "file with text")
(!call is s2 !nil)
(!callmeth f close)

(!assign f (!call open "./file.txt"))
(!assign s (!callmeth f read "*a"))
(!call is (!len s) 15 "method slurp")
(!call is s "file with text\n")
(!callmeth f close)

(!assign f (!call open "file.txt"))
(!for (line) ((!callmeth f lines))
    (!call is line "file with text" "method lines"))
(!call is (!call (!index io "type") f) "file")
(!callmeth f close)
(!call is (!call (!index io "type") f) "closed file")

(!call error_contains (!lambda () (!callmeth f seek "end" 0))
                      ": attempt to use a closed file"
                      "method seek (closed)")

(!assign f (!call open "file.txt"))
(!call error_contains (!lambda () (!callmeth f seek "bad" 0))
                      ": bad argument #1 to 'seek' (invalid option 'bad')"
                      "method seek (invalid)")

(!assign f (!call open "file.txt"))
(!call is (!callmeth f setvbuf "no") !true "method setvbuf 'no'")

(!call is (!callmeth f setvbuf "full" 4096) !true "method setvbuf 'full'")

(!call is (!callmeth f setvbuf "line" 132) !true "method setvbuf 'line'")
(!callmeth f close)

(!call unlink "./file.txt")     ; clean up

(!assign f (!call open "./file.out" "w"))
(!callmeth f close)
(!call error_contains (!lambda () (!callmeth f write "end"))
                      ": attempt to use a closed file"
                      "method write (closed)")

(!assign f (!call open "./file.out" "w"))
(!call is (!callmeth f write "end") f "method write")
(!callmeth f close)

(!call unlink "./file.out")     ; clean up


#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call dofile "TAP.tp")

(!call plan 162)

(!let test_files (
    "rx_captures"
    "rx_charclass"
    "rx_metachars"
))

(!let todo_info (
    147: "LuaJIT TODO. \\0"
    149: "LuaJIT TODO. \\0"
    151: "LuaJIT TODO. [^\\0]"
    153: "LuaJIT TODO. [^\\0]"
))

(!let split (!lambda (line)
                (!define (pattern target result desc) ("" "" "" ""))
                (!define idx 0)
                (!define c (!callmeth line sub idx idx))
                (!while (!and (!ne c "") (!ne c "\t"))  ; pattern
                        (!if (!eq c "\"")
                             (!assign pattern (!concat pattern "\\\""))
                             (!assign pattern (!concat pattern c)))
                        (!assign idx (!add idx 1))
                        (!assign c (!callmeth line sub idx idx)))
                (!if (!eq pattern "''")
                     (!assign pattern ""))
                (!while (!and (!ne c "") (!eq c "\t"))  ; sep
                        (!assign idx (!add idx 1))
                        (!assign c (!callmeth line sub idx idx)))
                (!while (!and (!ne c "") (!ne c "\t"))  ; target
                        (!if (!eq c "\"")
                             (!assign target (!concat target "\\\""))
                             (!assign target (!concat target c)))
                        (!assign idx (!add idx 1))
                        (!assign c (!callmeth line sub idx idx)))
                (!if (!eq target "''")
                     (!assign target ""))
                (!while (!and (!ne c "") (!eq c "\t"))  ; sep
                        (!assign idx (!add idx 1))
                        (!assign c (!callmeth line sub idx idx)))
                (!while (!and (!ne c "") (!ne c "\t"))  ; result
                        (!if (!eq c "\\")
                             (!do (!assign idx (!add idx 1))
                                  (!assign c (!callmeth line sub idx idx))
                                  (!cond ((!eq c "f")  (!assign result (!concat result "\f")))
                                         ((!eq c "n")  (!assign result (!concat result "\n")))
                                         ((!eq c "r")  (!assign result (!concat result "\r")))
                                         ((!eq c "t")  (!assign result (!concat result "\t")))
                                         ((!eq c "x")
                                          (!assign idx (!add idx 1))
                                          (!assign c (!callmeth line sub idx idx))
                                          (!if (!eq c "0")
                                               (!do (!assign idx (!add idx 1))
                                                    (!assign c (!callmeth line sub idx idx))
                                                    (!cond ((!eq c "1") (!assign result (!concat result "\x01")))
                                                           ((!eq c "2") (!assign result (!concat result "\x02")))
                                                           ((!eq c "3") (!assign result (!concat result "\x03")))
                                                           ((!eq c "4") (!assign result (!concat result "\x04")))
                                                           (!true       (!assign result (!concat result "\x00")))))
                                               (!assign result (!mconcat result "\\x" c))))
                                         ((!eq c "\t") (!assign result (!concat result "\\")))
                                         (!true        (!assign result (!mconcat result "\\" c)))))
                             (!assign result (!concat result c)))
                        (!assign idx (!add idx 1))
                        (!assign c (!callmeth line sub idx idx)))
                (!if (!eq result "''")
                     (!assign result ""))
                (!while (!and (!ne c "") (!eq c "\t"))  ; sep
                        (!assign idx (!add idx 1))
                        (!assign c (!callmeth line sub idx idx)))
                (!while (!and (!ne c "") (!ne c "\t"))  ; desc
                        (!assign desc (!concat desc c))
                        (!assign idx (!add idx 1))
                        (!assign c (!callmeth line sub idx idx)))
                (!return pattern target result desc)))

(!define test_number 0)
(!let dirname (!callmeth (!index arg 0) sub 0 (!sub (!callmeth (!index arg 0) find "314") 1)))
(!loop i 0 (!sub (!len test_files) 1) 1
        (!let filename (!index test_files i))
        (!let (f msg) ((!call (!index io "open") (!concat dirname filename) "r")))
        (!if (!eq f !nil)
             (!do (!call diag msg)
                  (!break)))
        (!for (line) ((!callmeth f lines))
                (!if (!eq (!callmeth line len) 0)
                     (!break))
                (!let (pattern target result desc) ((!call split line)))
                (!assign test_number (!add test_number 1))
                (!if (!index todo_info test_number)
                     (!call todo (!index todo_info test_number)))
                (!let code (!mconcat "\
                    (!let t ((!call (!index string \"match\") \"" target  "\" \"" pattern "\")))\
                    (!if (!eq (!len t) 0)\
                         (!return \"nil\")\
                         (!return (!call (!index table \"concat\") t \"\\t\")))"))
                (!let (compiled msg) ((!call load code)))
                (!if (!not compiled)
                     (!call error (!mconcat "can't compile : " code "\n" msg)))
                (!if (!eq (!callmeth result sub 0 0) "/")
                     (!do (!let pattern (!callmeth result sub 1 (!sub (!callmeth result len) 2)))
                          (!call error_like compiled pattern desc))
                     (!do (!define out)
                          (!call pcall (!lambda () (!assign out (!call compiled))))
                          (!call is out result desc))))
        (!callmeth f close))


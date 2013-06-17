#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call (!index tvm "dofile") "TAP.tp")

(!let char (!index string "char"))
(!let load (!index tvm "load"))
(!let plan plan)
(!let is is)
(!let contains contains)

(!call plan 34)

(!call is "\x41" "A")
(!call is "\x3d" "=")
(!call is "\x3D" "=")

(!call is "\u003d" "=")
(!call is "\u003D" "=")
(!call is "\u00e7" "ç")
(!call is "\u20ac" "€")

(!call is "\a" (!call char 7))
(!call is "\b" (!call char 8))
(!call is "\f" (!call char 12))
(!call is "\n" (!call char 10))
(!call is "\r" (!call char 13))
(!call is "\t" (!call char 9))
(!call is "\v" (!call char 11))
(!call is "\\" (!call char 92))

(!call is (!len "A\x00B") 3)

(!define (f msg) ((!call load "(!let a \"A\\xyz\")")))
(!call contains msg ": invalid escape sequence near '\"A'")

(!define (f msg) ((!call load "(!let a \"A\\uvwyz\")")))
(!call contains msg ": invalid escape sequence near '\"A'")

(!define (f msg) ((!call load "(!let a \"A\\0\")")))
(!call contains msg ": invalid escape sequence near '\"A'")

(!define (f msg) ((!call load "(!let a = \"A\\Z\")")))
(!call contains msg ": invalid escape sequence near '\"A'")

(!define (f msg) ((!call load "(!let a \" unfinished string")))
(!call contains msg ": unfinished string near")

(!define (f msg) ((!call load "(!let a \" unfinished string\n")))
(!call contains msg ": unfinished string near")

(!define (f msg) ((!call load "(!let a \" unfinished string\\\n")))
(!call contains msg ": invalid escape sequence near '\"")

(!define (f msg) ((!call load "(!let a \" unfinished string\\")))
(!call contains msg ": unfinished string near")

(!call is 3.0 3)
(!call is 314.16e-2 3.1416)
(!call is 0.31416E1 3.1416)
(!call is 0xff 255)
(!call is 0x56 86)
(!call is 0x0.1E (!div 0x1E 0x100))             ; 0.1171875
(!call is 0xA23p-4 (!div 0xA23 (!pow 2 4)))     ; 162.1875
(!call is 0X1.921FB54442D18P+1 (!mul (!add 1 (!div 0x921FB54442D18 0x10000000000000)) 2))


(!define (f msg) ((!call load "(!let a 12e34e56)")))
(!call contains msg ": malformed number near")

(!define iden\:t\(fier\))
(!call is iden\:t\(fier\) !nil "iden\\:t\\(fier\\)")


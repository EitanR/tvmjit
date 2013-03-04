#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call (!index tvm "dofile") "TAP.tp")

(!let escape (!index tvm "escape"))
(!let quote (!index tvm "quote"))
(!let wchar (!index tvm "wchar"))
(!let dofile (!index tvm "dofile"))
(!let load (!index tvm "load"))
(!let loadfile (!index tvm "loadfile"))
(!let open (!index io "open"))
(!let unlink (!index os "remove"))

(!let plan plan)
(!let is is)
(!let error_contains error_contains)
(!let type_ok type_ok)

(!call plan 44)

(!call contains (!index tvm "_VERSION") "TvmJIT 0.0.1" "variable _VERSION")

(!call is (!call escape "a(b:c)d e") "a\\(b\\:c\\)d\\ e")

(!call is (!call quote "a string with \"quotes\" and \n new line") "\"a string with \\\"quotes\\\" and \\\
 new line\"" "function quote")

(!call is (!call quote "a string with \b and \b2") "\"a string with \\x08 and \\x082\"")

(!call is (!call quote "a string with \x0c") "\"a string with \\x0C\"")

(!call is (!call wchar 65 66 67) "ABC" "function char")
(!call is (!call wchar) "")

(!call is (!call wchar 0xe7) "ç")
(!call is (!call wchar 0x20ac) "€")

(!call error_contains (!lambda () (!call wchar 0 "bad"))
                      ": bad argument #2 to 'wchar' (number expected, got string)"
                      "function wchar with bad arg")

(!call error_contains (!lambda () (!call wchar 0 999999))
                      ": bad argument #2 to 'wchar' (invalid value)"
                      "function wchar (invalid)")


(!define f (!call open "lib1.tp" "w"))
(!callmeth f write "\
(!assign norm (!lambda (x y)\
                (!return (!pow (!add (!pow x 2) (!pow y 2)) 0.5))))\
\
(!assign twice (!lambda (x)\
                (!return (!mul 2 x))))\
")
(!callmeth f close)
(!call dofile "lib1.tp")
(!define n (!call norm 3.4 1.0))
(!call contains (!call twice n) "7.088" "function dofile")

(!call unlink "lib1.tp")        ; clean up

(!call error_contains (!lambda () (!call dofile "no_file.tp"))
                      "cannot open no_file.tp: No such file or directory"
                      "function dofile (no file)")

(!define f (!call open "foo.tp" "w"))
(!callmeth f write "?syntax error?")
(!callmeth f close)
(!call error_contains (!lambda () (!call dofile "foo.tp"))
                      "foo.tp:"
                      "function dofile (syntax error)")
(!call unlink "foo.tp") ; clean up

(!define t ( "\
(!assign bar (!lambda (x)\
                (!return x)))\
"))
(!assign i -1)
(!let reader (!lambda ()
                (!assign i (!add i 1))
                (!return (!index t i))))
(!define (f msg) ((!call load reader)))
(!if msg
     (!call diag msg))
(!call type_ok f "function" "function load(reader)")
(!call is bar !nil)
(!call f)
(!call is (!call bar "ok") "ok")
(!assign bar !nil)

(!define t ("\
(!assign baz (!lambda (x)\
                (!return x)))\
"))
(!assign i -2)
(!let reader (!lambda ()
                (!assign i (!add i 1))
                (!return (!index t i))))
(!define (f msg) ((!call load reader)))
(!if msg (!call diag msg))
(!call type_ok f "function" "function load(pathological reader)")
(!call f)
(!call is baz !nil)

(!assign t ("?syntax error?"))
(!assign i -1)
(!define (f msg) ((!call load reader "errorchunk")))
(!call is f !nil "function load(syntax error)")
(!call contains msg "[string \"errorchunk\"]:")

(!define f (!call load (!lambda () (!return !nil))))
(!call type_ok f "function" "when reader returns nothing")

(!define (f msg) ((!call load (!lambda () (!return ())))))
(!call is f !nil "reader function must return a string")
(!call contains msg "reader function must return a string")

(!define f (!call load "(!assign bar (!lambda (x) (!return x)))"))
(!call is bar !nil "function load(str)")
(!call f)
(!call is (!call bar "ok") "ok")
(!assign bar !nil)

(!define env ())
(!define f (!call load "(!assign bar (!lambda (x) (!return x)))" "from string" "t" env))
(!call is (!index env "bar") !nil "function load(str)")
(!call f)
(!call is (!call (!index env "bar") "ok") "ok")

(!define (f msg) ((!call load "?syntax error?" "errorchunk")))
(!call is f !nil "function load(syntax error)")
(!call contains msg "[string \"errorchunk\"]:")

(!define (f msg) ((!call load "(!call print \"ok\")" "chunk txt" "b")))
(!call contains  msg "attempt to load chunk with wrong mode")
(!call is f !nil "mode")

(!define (f msg) ((!call load "\x1bLua" "chunk bin" "t")))
(!call contains  msg "attempt to load chunk with wrong mode")
(!call is f !nil "mode")

(!define f (!call open "foo.tp" "w"))
(!callmeth f write "(!assign foo (!lambda (x) (!return x)))")
(!callmeth f close)
(!define f (!call loadfile "foo.tp"))
(!call is foo !nil "function loadfile")
(!call f)
(!call is (!call foo "ok") "ok")

(!define (f msg) ((!call loadfile "foo.tp" "b")))
(!call contains msg "attempt to load chunk with wrong mode")
(!call is f !nil "mode")

(!define env ())
(!define f (!call loadfile "foo.tp" "t" env))
(!call is (!index env "foo") !nil "function loadfile")
(!call f)
(!call is (!call (!index env "foo") "ok") "ok")

(!call unlink "foo.tp") ; clean up

(!define (f msg) ((!call loadfile "no_file.tp")))
(!call is f !nil "function loadfile (no file)")
(!call is msg "cannot open no_file.tp: No such file or directory")

(!define f (!call open "foo.tp" "w"))
(!callmeth f write "?syntax error?")
(!callmeth f close)
(!define (f msg) ((!call loadfile "foo.tp")))
(!call is f !nil "function loadfile (syntax error)")
(!call contains msg "foo.tp:")
(!call unlink "foo.tp") ; clean up

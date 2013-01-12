#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call dofile "TAP.tp")

(!let plan plan)
(!let error_contains error_contains)
(!let is is)

(!call plan 51)

(!call is (!neg "1") -1 "!neg \"1\"")

(!call error_contains (!lambda () (!return (!neg "text")))
                      ": attempt to perform arithmetic on a string value"
                      "!neg \"text\"")

(!call is (!len "text") 4 "!len \"text\"")

(!call is (!not "text") !false "!not \"text\"")

(!call is (!add "10" 2) 12 "!add \"10\" 2")

(!call is (!sub "2" 10) -8 "!sub \"2\" 10")

(!call is (!mul "3.14" 1) 3.14 "!mul \"3.14\" 1")

(!call is (!div "-7" 0.5) -14 "!div \"-7\" 0.5")

(!call is (!mod "-25" 3) 2 "!mod \"-25\" 3")

(!call is (!pow "3" 3) 27 "!pow \"3\" 3")

(!call error_contains (!lambda () (!return (!add "10" !true)))
                      ": attempt to perform arithmetic on a boolean value"
                      "!add \"10\" !true")

(!call error_contains (!lambda () (!return (!sub "2" !nil)))
                      ": attempt to perform arithmetic on a nil value"
                      "!sub \"2\" !nil")

(!call error_contains (!lambda () (!return (!mul "3.14" !false)))
                      ": attempt to perform arithmetic on a boolean value"
                      "!mul \"3.14\" !false")

(!call error_contains (!lambda () (!return (!div "-7" ())))
                      ": attempt to perform arithmetic on a table value"
                      "!div \"-7\" ()")

(!call error_contains (!lambda () (!return (!mod "-25" !false)))
                      ": attempt to perform arithmetic on a boolean value"
                      "!mod \"-25\" !false")

(!call error_contains (!lambda () (!return (!pow "3" !true)))
                      ": attempt to perform arithmetic on a boolean value"
                      "!pow \"3\" !true")

(!call error_contains (!lambda () (!return (!add "10" "text")))
                      ": attempt to perform arithmetic on a string value"
                      "!add \"10\" \"text\"")

(!call error_contains (!lambda () (!return (!sub "2" "text")))
                      ": attempt to perform arithmetic on a string value"
                      "!sub \"2\" \"text\"")

(!call error_contains (!lambda () (!return (!mul "3.14" "text")))
                      ": attempt to perform arithmetic on a string value"
                      "!mul \"3.14\" \"text\"")

(!call error_contains (!lambda () (!return (!div "-7" "text")))
                      ": attempt to perform arithmetic on a string value"
                      "!div \"-7\" \"text\"")

(!call error_contains (!lambda () (!return (!mod "-25" "text")))
                      ": attempt to perform arithmetic on a string value"
                      "!mod \"-25\" \"text\"")

(!call error_contains (!lambda () (!return (!pow "3" "text")))
                      ": attempt to perform arithmetic on a string value"
                      "!pow \"3\" \"text\"")

(!call is (!add "10" "2") 12 "!add \"10\" \"2\"")

(!call is (!sub "2" "10") -8 "!sub \"2\" \"10\"")

(!call is (!mul "3.14" "1") 3.14 "!mul \"3.14\" \"1\"")

(!call is (!div "-7" "0.5") -14 "!div \"-7\" \"0.5\"")

(!call is (!mod "-25" "3") 2 "!mod \"-25\" \"3\"")

(!call is (!pow "3" "3") 27 "!pow \"3\" \"3\"")

(!call is (!concat "1" "end") "1end" "!concat \"1\" \"end\"")

(!call is (!concat "1" 2) "12" "!concat \"1\" 2")

(!call error_contains (!lambda () (!return (!concat "1" !true)))
                      ": attempt to concatenate a boolean value"
                      "!concat \"1\" !true")

(!call is (!eq "1.0" "1") !false "!eq \"1.0\" \"1\"")

(!call is (!ne "1" "2") !true "!ne \"1\" \"2\"")

(!call is (!eq "1" !true) !false "!eq \"1\" true")

(!call is (!ne "1" !nil) !true "!ne \"1\" !nil")

(!call is (!eq "1" 1) !false "!eq \"1\" 1")

(!call is (!ne "1" 1) !true "!ne \"1\" 1")

(!call is (!lt "1" "0") !false "!le \"1\" \"0\"")

(!call is (!le "1" "0") !false "!le \"1\" \"0\"")

(!call is (!gt "1" "0") !true "!gt \"1\" \"0\"")

(!call is (!ge "1" "0") !true "!ge \"1\" \"0\"")

(!call error_contains (!lambda () (!return (!lt "1" !false)))
                      ": attempt to compare string with boolean"
                      "!lt \"1\" false")

(!call error_contains (!lambda () (!return (!le "1" !nil)))
                      ": attempt to compare nil with string"
                      "!le \"1\" !nil")

(!call error_contains (!lambda () (!return (!gt "1" !true)))
                      ": attempt to compare boolean with string"
                      "!gt \"1\" !true")

(!call error_contains (!lambda () (!return (!ge "1" ())))
                      ": attempt to compare string with table"
                      "!ge \"1\" ()")

(!call error_contains (!lambda () (!return (!lt "1" 0)))
                      ": attempt to compare string with number"
                      "!lt \"1\" 0")

(!call error_contains (!lambda () (!return (!le "1" 0)))
                      ": attempt to compare number with string"
                      "!le \"1\" 0")

(!call error_contains (!lambda () (!return (!gt "1" 0)))
                      ": attempt to compare number with string"
                      "!gt \"1\" 0")

(!call error_contains (!lambda () (!return (!ge "1" 0)))
                       ": attempt to compare string with number"
                       "!ge \"1\" 0")

(!let a "text")
(!call is (!index a 1) !nil "index")

(!call error_contains (!lambda () (!let a "text")(!assign (!index a 1) 1))
                      ": attempt to index"
                      "index")


#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call dofile "TAP.tp")

(!let byte (!index string "byte"))
(!let char (!index string "char"))
(!let dump (!index string "dump"))
(!let escape (!index string "escape"))
(!let find (!index string "find"))
(!let format (!index string "format"))
(!let gmatch (!index string "gmatch"))
(!let gsub (!index string "gsub"))
(!let quote (!index string "quote"))
(!let len (!index string "len"))
(!let lower (!index string "lower"))
(!let match (!index string "match"))
(!let rep (!index string "rep"))
(!let reverse (!index string "reverse"))
(!let upper (!index string "upper"))
(!let sub (!index string "sub"))
(!let wchar (!index string "wchar"))
(!let getmetatable getmetatable)

(!let plan plan)
(!let is is)
(!let eq_array eq_array)
(!let error_contains error_contains)
(!let type_ok type_ok)

(!call plan 120)

(!call is (!call byte "ABC") 65 "function byte")
(!call is (!call byte "ABC" 0) 65)
(!call is (!call byte "ABC" 1) 66)
(!call is (!call byte "ABC" -1) 67)
(!call is (!call byte "ABC" 3) !nil)
(!call eq_array ((!call byte "ABC" 0 2)) (65 66 67))
(!call eq_array ((!call byte "ABC" 0 3)) (65 66 67))

(!call type_ok (!call getmetatable "ABC") "table" "literal string has metatable")

(!let s "ABC")
(!call is (!callmeth s byte 1) 66 "method s:byte")

(!call is (!call char 65 66 67) "ABC" "function char")
(!call is (!call char) "")

(!call error_contains (!lambda () (!call char 0 "bad"))
                      ": bad argument #2 to 'char' (number expected, got string)"
                      "function char with bad arg")

(!call error_contains (!lambda () (!call char 0 9999))
                      ": bad argument #2 to 'char' (invalid value)"
                      "function char (invalid)")

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

(!let d (!call dump plan))
(!call type_ok d "string" "function dump")

(!call error_contains(!lambda () (!call dump print))
                     ": unable to dump given function"
                     "function dump (C function)")

(!let s "hello world")
(!call eq_array ((!call find s "hello")) (0 4) "function find (mode plain)")
(!call eq_array ((!call find s "hello" 0 !true)) (0 4))
(!call eq_array ((!call find s "hello" 0)) (0 4))
(!call is (!call sub s 0 4) "hello")
(!call eq_array ((!call find s "world")) (6 10))
(!call eq_array ((!call find s "l")) (2 2))
(!call is (!call find s "lll") !nil)
(!call is (!call find s "hello" 2 !true) !nil)
(!call eq_array ((!call find s "world" 2 !true)) (6 10))
(!call is (!call find s "hello" 20) !nil)

(!let s "hello world")
(!call eq_array ((!call find s "^h.ll.")) (0 4) "function find (with regex & captures)")
(!call eq_array ((!call find s "w.rld" 1)) (6 10))
(!call is (!call find s "W.rld") !nil)
(!call eq_array ((!call find s "^(h.ll.)")) (0 4 "hello"))
(!call eq_array ((!call find s "^(h.)l(l.)")) (0 4 "he" "lo"))
(!let s "Deadline is 30/05/1999, firm")
(!let date "%d%d/%d%d/%d%d%d%d")
(!call is (!call sub s (!call find s date)) "30/05/1999")
(!let date "%f[%S]%d%d/%d%d/%d%d%d%d")
(!call is (!call sub s (!call find s date)) "30/05/1999")

(!call error_contains (!lambda () (!call find s "%f"))
                      ": missing '[' after '%f' in pattern"
                      "function find (invalid frontier)")

(!call is (!call format "pi = %.4f" (!index math "pi")) "pi = 3.1416" "function format")
(!let d 5)(!let m 11)(!let y 1990)
(!call is (!call format "%02d/%02d/%04d" d m y) "05/11/1990")
(!let (tag title)("h1" "a title"))
(!call is (!call format "<%s>%s</%s>" tag title tag) "<h1>a title</h1>")

(!call is (!call format "%q" "a string with \"quotes\" and \n new line") "\"a string with \\\"quotes\\\" and \\\n new line\"" "function format %q")

(!call is (!call format "%q" "a string with \b and \b2") "\"a string with \\x08 and \\x082\"" "function format %q")

(!call is (!call format "%s %s" 1 2 3) "1 2" "function format (too many arg)")

(!call is (!call format "%% %c %%" 65) "% A %" "function format (%%)")

(!let r (!call rep "ab" 100))
(!call is (!call format "%s %d" r (!callmeth r len)) (!concat r " 200"))

(!call error_contains (!lambda () (!call format "%s %s" 1))
                      ": bad argument #3 to 'format' (no value)"
                      "function format (too few arg)")

(!call error_contains (!lambda () (!call format "%d" "toto"))
                      ": bad argument #2 to 'format' (number expected, got string)"
                      "function format (bad arg)")

(!call error_contains (!lambda () (!call format "%k" "toto"))
                      ": invalid option '%k' to 'format'"
                      "function format (invalid option)")

(!call error_contains (!lambda () (!call format "%------s" "toto"))
                      ": invalid format (repeated flags)"
                      "function format (invalid format)")

(!call error_contains (!lambda () (!call format "pi = %.123f" (!index math "pi")))
                      ": invalid format (width or precision too long)"
                      "function format (invalid format)")

(!call error_contains (!lambda () (!call format "% 123s" "toto"))
                      ": invalid format (width or precision too long)"
                      "function format (invalid format)")

(!call is (!call escape "a(b:c)d e") "a\\(b\\:c\\)d\\ e")

(!call is (!call quote "a string with \"quotes\" and \n new line") "\"a string with \\\"quotes\\\" and \\\
 new line\"" "function quote")

(!call is (!call quote "a string with \b and \b2") "\"a string with \\x08 and \\x082\"")

(!call is (!call quote "a string with \x0c") "\"a string with \\x0C\"")

(!let s "hello")
(!let output ())
(!for (c) ((!call gmatch s ".."))
    (!call (!index table "insert") output c))
(!call eq_array output ("he" "ll") "function gmatch")
(!let output ())
(!for (c1 c2) ((!call gmatch s "(.)(.)"))
    (!call (!index table "insert") output c1)
    (!call (!index table "insert") output c2))
(!call eq_array output ("h" "e" "l" "l"))
(!let s "hello world from Lua")
(!let output ())
(!for (w) ((!call gmatch s "%a+"))
    (!call (!index table "insert") output w))
(!call eq_array output  ("hello" "world" "from" "Lua"))
(!let s "from=world, to=Lua")
(!let output ())
(!for (k v) ((!call gmatch s "(%w+)=(%w+)"))
    (!call (!index table "insert") output k)
    (!call (!index table "insert") output v))
(!call eq_array output ("from" "world" "to" "Lua"))

(!call is (!call gsub "hello world" "(%w+)" "%1 %1") "hello hello world world" "function gsub")
(!call is (!call gsub "hello world" "%w+" "%0 %0" 1) "hello hello world")
(!call is (!call gsub "hello world from Lua" "(%w+)%s*(%w+)" "%2 %1") "world hello Lua from")
(!call is (!call gsub "home = $HOME, user = $USER" "%$(%w+)" reverse) "home = EMOH, user = RESU")
(!call is (!call gsub "4+5 = $(!return (!add 4 5))$" "%$(.-)%$" (!lambda (s) (!return (!call (!call load s))))) "4+5 = 9")
(!let t ("name": "lua" "version": "5.1"))
(!call is (!call gsub "$name-$version.tar.gz" "%$(%w+)" t) "lua-5.1.tar.gz")

(!call is (!call gsub "Lua is cute" "cute" "great") "Lua is great")
(!call is (!call gsub "all lii" "l" "x") "axx xii")
(!call is (!call gsub "Lua is great" "^Sol" "Sun") "Lua is great")
(!call is (!call gsub "all lii" "l" "x" 1) "axl lii")
(!call is (!call gsub "all lii" "l" "x" 2) "axx lii")
(!call is (!call select 2 (!call gsub "string with 3 spaces" " " " ")) 3)

(!call eq_array ((!call gsub "hello, up-down!" "%A" ".")) ("hello..up.down." 4))
(!let text "hello world")
(!assign nvow (!call select 2 (!call gsub text "[AEIOUaeiou]" "")))
(!call is nvow 3)
(!call eq_array ((!call gsub "one, and two; and three" "%a+" "word")) ("word, word word; word word" 5))
(!let test "int x; /* x */  int y; /* y */")
(!call eq_array ((!call gsub test "/%*.*%*/" "<COMMENT>")) ("int x; <COMMENT>" 1))
(!call eq_array ((!call gsub test "/%*.-%*/" "<COMMENT>")) ("int x; <COMMENT>  int y; <COMMENT>" 2))
(!let s "a (enclosed (in) parentheses) line")
(!call eq_array ((!call gsub s "%b()" "")) ("a  line" 1))

(!call error_contains (!lambda () (!call gsub s "%b(" ""))
                      ": unbalanced pattern"
                      "function gsub (malformed pattern)")

(!call eq_array ((!call gsub "hello Lua!" "%a" "%0-%0")) ("h-he-el-ll-lo-o L-Lu-ua-a!" 8))
(!call eq_array ((!call gsub "hello Lua" "(.)(.)" "%2%1")) ("ehll ouLa" 4))

(!assign expand (!lambda (s)
                (!return (!call gsub s "$(%w+)" _G))))
(!assign name "Lua")(!assign status "great")
(!call is (!call expand "$name is $status, isn't it?") "Lua is great, isn't it?")
(!call is (!call expand "$othername is $status, isn't it?") "$othername is great, isn't it?")

(!assign expand (!lambda (s)
                (!return (!call gsub s "$(%w+)" (!lambda (n)
                                          (!return (!call tostring (!call rawget _G n)) 1))))))
(!call is (!call expand "print = $print; a = $a") "print = function: builtin#25; a = nil")

(!call error_contains (!lambda () (!call gsub "hello world" "(%w+)" "%2 %2"))
                      ": invalid capture index"
                      "function gsub (invalid index)")

(!call error_contains (!lambda () (!call gsub "hello world" "(%w+)" !true))
                      ": bad argument #3 to 'gsub' (string/function/table expected)"
                      "function gsub (bad type)")

(!call error_contains (!lambda ()
                                (!let expand (!lambda (s)
                                                (!return (!call gsub s "$(%w+)" _G))))
                                (!assign name "Lua")
                                (!assign status !true)
                                (!call expand "$name is $status, isn't it?"))
                      ": invalid replacement value (a boolean)"
                      "function gsub (invalid value)")

(!call is (!call len "") 0 "function len")
(!call is (!call len "test") 4)
(!call is (!call len "a\x00b\x00c") 5)
(!call is (!call len "\"") 1)

(!call is (!call lower "Test") "test" "function lower")
(!call is (!call lower "TeSt") "test")

(!let s "hello world")
(!call is (!call match s "^hello") "hello" "function match")
(!call is (!call match s "world" 2) "world")
(!call is (!call match s "World") !nil)
(!call eq_array ((!call match s "^(h.ll.)")) ("hello"))
(!call eq_array ((!call match s "^(h.)l(l.)")) ("he" "lo"))
(!let date "Today is 17/7/1990")
(!call is (!call match date "%d+/%d+/%d+") "17/7/1990")
(!call eq_array ((!call match date "(%d+)/(%d+)/(%d+)")) ("17" "7" "1990"))
(!call is (!call match "The number 1298 is even" "%d+") "1298")
(!let pair "name = Anna")
(!call eq_array ((!call match pair "(%a+)%s*=%s*(%a+)")) ("name" "Anna"))

(!let s "then he said: \"it's all right\"!")
(!call eq_array ((!call match s "([\"'])(.-)%1")) ("\"" "it's all right") "function match (back ref)")
(!let p "%[(=*)%[(.-)%]%1%]")
(!let s "a = [=[[[ something ]] ]==]x]=]; print(a)")
(!call eq_array ((!call match s p)) ("=" "[[ something ]] ]==]x"))

(!call is (!call match s "%g") "a" "match graphic char")

(!call error_contains (!lambda () (!call match "hello world" "%1"))
                      ": invalid capture index"
                      "function match invalid capture")

(!call is (!call rep "ab" 3) "ababab" "function rep")
(!call is (!call rep "ab" 0) "")
(!call is (!call rep "ab" -1) "")
(!call is (!call rep "" 5) "")

(!call is (!call reverse "abcde") "edcba" "function reverse")
(!call is (!call reverse "abcd") "dcba")
(!call is (!call reverse "") "")

(!call is (!call sub "abcde" 0 1) "ab" "function sub")
(!call is (!call sub "abcde" 2 3) "cd")
(!call is (!call sub "abcde" -2) "de")
(!call is (!call sub "abcde" 2 1) "")

(!call is (!call upper "Test") "TEST" "function upper")
(!call is (!call upper "TeSt") "TEST")


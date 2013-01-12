#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the LPeg library.
;   Copyright 2007, Lua.org & PUC-Rio
;

(!call dofile "TAP.tp")

(!let assert assert)
(!let error error)
(!let getmetatable getmetatable)
(!let pairs pairs)
(!let pcall pcall)
(!let print print)
(!let rawset rawset)
(!let select select)
(!let tonumber tonumber)
(!let type type)
(!let _G _G)
(!let char (!index string "char"))
(!let str_rep (!index string "rep"))
(!let str_upper (!index string "upper"))
(!let tconcat (!index table "concat"))
(!let unpack (!index table "unpack"))

(!let peg peg)
(!let any (!index peg "any"))
(!let arg (!index peg "arg"))
(!let backref (!index peg "backref"))
(!let capture (!index peg "capture"))
(!let choice (!index peg "choice"))
(!let not_followed_by (!index peg "not_followed_by"))
(!let constant (!index peg "constant"))
(!let empty (!index peg "empty"))
(!let eos (!index peg "eos"))
(!let except (!index peg "except"))
(!let fail (!index peg "fail"))
(!let fold (!index peg "fold"))
(!let grammar (!index peg "grammar"))
(!let group (!index peg "group"))
(!let literal (!index peg "literal"))
(!let followed_by (!index peg "followed_by"))
(!let many (!index peg "many"))
(!let matchtime (!index peg "matchtime"))
(!let optional (!index peg "optional"))
(!let position (!index peg "position"))
(!let range (!index peg "range"))
(!let replace (!index peg "replace"))
(!let sequence (!index peg "sequence"))
(!let set (!index peg "set"))
(!let some (!index peg "some"))
(!let subst (!index peg "subst"))
(!let succeed (!index peg "succeed"))
(!let table (!index peg "table"))
(!let variable (!index peg "variable"))

(!let plan plan)
(!let diag diag)
(!let is is)
(!let isnt isnt)
(!let ok ok)
(!let nok nok)
(!let type_ok type_ok)
(!let eq_array eq_array)
(!let is_deeply is_deeply)
(!let pass pass)

(!assign !ENV !nil)

(!call plan 4233)


;   most tests here do not need much stack space
(!call (!index peg "setmaxstack") 5)

(!let space (!call many (!call set " \t\n")))

(!let mt (!call getmetatable (!call any)))

(!define allchar ())
(!loop i 0 127 1 (!assign (!index allchar i) i))
(!assign allchar (!call char (!call unpack allchar)))
(!call is (!len allchar) 128)

(!let cs2str (!lambda (c)
                (!return (!callmeth (!call subst (!call many (!call choice c
                                                                           (!call replace (!call any) "")))) match allchar))))

(!let eqcharset (!lambda (c1 c2 desc)
                (!call is (!call cs2str c1) (!call cs2str c2) desc)))


(!call diag "General tests for LPeg library")
(!call type_ok (!call (!index peg "version")) "string")
(!call diag (!concat "version " (!call (!index peg "version"))))
(!call isnt (!call (!index peg "type") "alo") "pattern")
(!call isnt (!call (!index peg "type") literal) "pattern")
(!call is   (!call (!index peg "type") (!call literal "alo")) "pattern")

;   tests for some basic optimzations
(!call is (!callmeth (!call choice (!call fail)
                                   (!call literal "a")) match "a") 1 "some basic optimizations")
(!call is (!callmeth (!call choice (!call succeed)
                                   (!call literal "a")) match "a") 0)
(!call is (!callmeth (!call choice (!call literal "a")
                                   (!call fail)) match "b") !nil)
(!call is (!callmeth (!call choice (!call literal "a")
                                   (!call succeed)) match "b") 0)

(!call is (!callmeth (!call sequence (!call fail)
                                     (!call literal "a")) match "a") !nil)
(!call is (!callmeth (!call sequence (!call succeed)
                                     (!call literal "a")) match "a") 1)
(!call is (!callmeth (!call sequence (!call literal "a")
                                     (!call fail)) match "a") !nil)
(!call is (!callmeth (!call sequence (!call literal "a")
                                     (!call succeed)) match "a") 1)

(!call is (!callmeth (!call sequence (!call followed_by (!call fail))
                                     (!call literal "a")) match "a") !nil)
(!call is (!callmeth (!call sequence (!call followed_by (!call succeed))
                                     (!call literal "a")) match "a") 1)
(!call is (!callmeth (!call sequence (!call literal "a")
                                     (!call followed_by (!call fail))) match "a") !nil)
(!call is (!callmeth (!call sequence (!call literal "a")
                                     (!call followed_by (!call succeed))) match "a") 1)


;   tests for locale
(!do
  (!call assert (!eq (!call (!index peg "locale") peg) peg))
  (!define t ())
  (!call assert (!eq (!call (!index peg "locale") t peg) t))
  (!define x (!call (!index peg "locale")))
  (!for (n v) ((!call pairs x))
        (!call assert (!eq (!call type n) "string"))
        (!call eqcharset v (!index peg n) n)))

(!call ok  (!callmeth (!call any 3) match "aaaa"))
(!call ok  (!callmeth (!call any 4) match "aaaa"))
(!call nok (!callmeth (!call any 5) match "aaaa"))
(!call ok  (!callmeth (!call not_followed_by (!call any 3)) match "aa"))
(!call nok (!callmeth (!call not_followed_by (!call any 3)) match "aaa"))
(!call nok (!callmeth (!call not_followed_by (!call any 3)) match "aaaa"))
(!call nok (!callmeth (!call not_followed_by (!call any 4)) match "aaaa"))
(!call ok  (!callmeth (!call not_followed_by (!call any 5)) match "aaaa"))

(!call is  (!callmeth (!call literal "a") match "alo") 1)
(!call is  (!callmeth (!call literal "al") match "alo") 2)
(!call nok (!callmeth (!call literal "alu") match "alo"))
(!call is  (!callmeth (!call succeed) match "") 0)

(!let digit (!call set "0123456789"))
(!let upper (!call set "ABCDEFGHIJKLMNOPQRSTUVWXYZ"))
(!let lower (!call set "abcdefghijklmnopqrstuvwxyz"))
(!let letter (!call choice (!call set "") upper lower))
(!let alpha (!call choice letter digit (!call range)))

(!call eqcharset (!call set "") (!call fail))
(!call eqcharset upper (!call range "AZ"))
(!call eqcharset lower (!call range "az"))
(!call eqcharset (!call choice upper lower) (!call range "AZ" "az"))
(!call eqcharset (!call choice upper lower) (!call range "AZ" "cz" "aa" "bb" "90"))
(!call eqcharset digit (!call choice (!call set "01234567")
                                     (!call literal "8")
                                     (!call literal "9")))
(!call eqcharset upper (!call except letter lower))
(!call eqcharset (!call set "") (!call range))
(!call is (!call cs2str (!call set "")) "")

(!call eqcharset (!call set "\x00") (!call literal "\x00"))
(!call eqcharset (!call set "\x01\x00\x02") (!call range "\x00\x02"))
(!call eqcharset (!call set "\x01\x00\x02") (!call choice (!call range "\x01\x02")
                                                          (!call literal "\x00")))
(!call eqcharset (!call except (!call set "\x01\x00\x02") (!call literal "\x00")) (!call range "\x01\x02"))

(!let word (!call sequence (!call some alpha)
                           (!call many (!call except (!call any) alpha))))

(!call ok  (!callmeth (!call sequence (!call many word)
                                      (!call eos)) match "alo alo"))
(!call ok  (!callmeth (!call sequence (!call some word)
                                      (!call eos)) match "alo alo"))
(!call nok (!callmeth (!call sequence (!call optional word)
                                      (!call eos)) match "alo alo"))

(!call ok  (!callmeth (!call sequence (!call many digit)
                                      letter
                                      digit
                                      (!call eos)) match "1298a1"))
(!call nok (!callmeth (!call sequence (!call many digit)
                                      letter
                                      (!call eos)) match "1257a1"))

(!let b (!call grammar (0 : (!call sequence (!call literal "(")
                                            (!call many (!call choice (!call except (!call any) (!call set "()"))
                                                                      (!call sequence (!call followed_by (!call literal "("))
                                                                                      (!call variable 0))))
                                            (!call literal ")")))))

(!call ok  (!callmeth b match "(al())()"))
(!call nok (!callmeth (!call sequence b
                                      (!call eos)) match "(al())()"))
(!call ok  (!callmeth (!call sequence b
                                      (!call eos)) match "((al())()(é))"))
(!call nok (!callmeth b match "(al()()"))

(!call nok (!callmeth (!call except (!call some letter) (!call literal "for")) match "foreach"))
(!call ok  (!callmeth (!call except (!call some letter) (!call sequence (!call literal "for")
                                                                        (!call eos))) match "foreach"))
(!call nok (!callmeth (!call except (!call some letter) (!call sequence (!call literal "for")
                                                                        (!call eos))) match "for"))

(!let basiclookfor (!lambda (p)
                (!return (!call grammar (0 : (!call choice p
                                                           (!call sequence (!call any)
                                                                           (!call variable 0))))))))

(!let caplookfor (!lambda (p)
                (!return (!call basiclookfor (!call capture p)))))

(!call is (!callmeth (!call caplookfor (!call some letter)) match "   4achou123...") "achou")
(!define a ((!callmeth (!call many (!call caplookfor (!call some letter))) match " two words, one more  ")))
(!call eq_array a ("two" "words" "one" "more"))

(!call is (!callmeth (!call basiclookfor (!call sequence (!call sequence (!call followed_by b)
                                                                         (!call any))
                                                         (!call position))) match "  (  (a)") 6)

(!define a ((!callmeth (!call choice (!call capture (!call sequence (!call some digit)
                                                                    (!call constant "d")))
                                     (!call capture (!call sequence (!call some letter)
                                                                    (!call constant "l")))) match "123")))
(!call eq_array a ("123" "d"))

(!define a ((!callmeth (!call choice (!call sequence (!call capture (!call some digit))
                                                     (!call literal "d" (!call eos)))
                                     (!call capture (!call sequence (!call some letter)
                                                                    (!call constant "l")))) match "123d")))
(!call eq_array a ("123"))

(!define a ((!callmeth (!call choice (!call capture (!call sequence (!call some digit)
                                                                    (!call constant "d")))
                                     (!call capture (!call sequence (!call some letter)
                                                                    (!call constant "l")))) match "abcd")))
(!call eq_array a ("abcd" "l"))

(!define a ((!callmeth (!call sequence (!call constant 10 20 30)
                                       (!call literal "a")
                                       (!call position)) match "aaa")))
(!call eq_array a (10 20 30 1))
(!define a ((!callmeth (!call sequence (!call position)
                                       (!call constant 10 20 30)
                                       (!call literal "a")
                                       (!call position))  match "aaa")))
(!call eq_array a (0 10 20 30 1))
(!define a (!callmeth (!call table (!call sequence (!call position)
                                                   (!call constant 10 20 30)
                                                   (!call literal "a")
                                                   (!call position))) match "aaa"))
(!call eq_array a (0 10 20 30 1))
(!define a (!callmeth (!call table (!call sequence (!call position)
                                                   (!call constant 7 8)
                                                   (!call constant 10 20 30)
                                                   (!call literal "a")
                                                   (!call position))) match "aaa"))
(!call eq_array a (0 7 8 10 20 30 1))
(!define a ((!callmeth (!call sequence (!call constant)
                                       (!call constant)
                                       (!call constant 1)
                                       (!call constant 2 3 4)
                                       (!call constant)
                                       (!call literal "a")) match "aaa")))
(!call eq_array a (1 2 3 4))

(!define a ((!callmeth (!call sequence (!call position)
                                       (!call some letter)
                                       (!call position)) match "abcd")))
(!call eq_array a (0 4))

(!define t ((!callmeth (!call grammar (0 : (!call capture (!call choice (!call sequence (!call capture (!call any))
                                                                                        (!call variable 0))
                                                                        (!call eos))))) match "abc")))
(!call eq_array t ("abc" "a" "bc" "b" "c" "c" ""))

; test for small capture boundary
(!loop i 250 260 1
        (!call is (!len (!callmeth (!call capture (!call any i)) match (!call str_rep "a" i))) i "small capture boundary")
        (!call is (!len (!callmeth (!call capture (!call capture (!call any i))) match (!call str_rep "a" i))) i))

; tests for any*n
(!define n3 0)
(!loop n 1 550 1
        (!define x_1 (!call str_rep "x" (!sub n 1)))
        (!define x (!concat x_1 "a"))
        (!call nok (!callmeth (!call any n) match x_1))
        (!call is  (!callmeth (!call any n) match x n))
        (!call ok  (!or (!lt n 4)
                        (!eq (!callmeth (!call choice (!call any n)
                                                      (!call literal "xxx")) match x_1) 3)))
        (!call is  (!callmeth (!call capture (!call any n)) match x) x)
        (!call is  (!callmeth (!call capture (!call capture (!call any n))) match x) x)
        (!call ok  (!or (!lt n 13)
                        (!eq (!callmeth (!call sequence (!call constant 20)
                                                        (!call sequence (!call any (!sub n 13))
                                                                        (!call any 10))
                                                        (!call any 3)) match x) 20)))
        (!if (!eq (!mod n 3) 0)
             (!assign n3 (!add n3 1)))
        (!call is (!callmeth (!call sequence (!call any n3)
                                             (!call position)
                                             (!call any n3)
                                             (!call any n3)) match x) n3))

(!call is (!callmeth (!call empty) match "x") 0)
(!call is (!callmeth (!call empty) match "") 0)
(!call is (!callmeth (!call capture (!call empty)) match "x") "")
(!call is (!callmeth (!call choice (!call sequence (!call constant 0)
                                                   (!call any 10))
                                   (!call sequence (!call constant 1)
                                                   (!call literal "xuxu"))) match "xuxu") 1)
(!call is (!callmeth (!call choice (!call sequence (!call constant 0)
                                                   (!call any 10))
                                   (!call sequence (!call constant 1)
                                                   (!call literal "xuxu"))) match "xuxuxuxuxu") 0)
(!call is (!callmeth (!call capture (!call some (!call any 2))) match "abcde") "abcd")
(!define p (!call choice (!call sequence (!call constant 0) (!call any 1))
                         (!call sequence (!call constant 1) (!call any 2))
                         (!call sequence (!call constant 2) (!call any 3))
                         (!call sequence (!call constant 3) (!call any 4))))


; test for alternation optimization
(!call is (!callmeth (!call choice (!call some (!call literal "a"))
                                   (!call literal "ab")
                                   (!call many (!call literal "x"))) match "ab") 1 "alternation optimization")
(!call is (!callmeth (!call many (!call choice (!call some(!call literal "a"))
                                               (!call literal "ab")
                                               (!call sequence (!call many (!call literal "x"))
                                                               (!call any 1)))) match "ab") 2)
(!call is (!callmeth (!call choice (!call literal "ab")
                                   (!call literal "cd")
                                   (!call literal "")
                                   (!call literal "cy")
                                   (!call literal "ak")) match "98") 0)
(!call is (!callmeth (!call choice (!call literal "ab")
                                   (!call literal "cd")
                                   (!call literal "ax")
                                   (!call literal "cy")) match "ax") 2)
(!call is (!callmeth (!call choice (!call sequence (!call literal "a")
                                                   (!call many (!call literal "b"))
                                                   (!call literal "c"))
                                   (!call literal "cd")
                                   (!call literal "ax")
                                   (!call literal "cy")) match "ax") 2)
(!call is (!callmeth (!call many (!call choice (!call literal "ab")
                                               (!call literal "cd")
                                               (!call literal "ax")
                                               (!call literal "cy"))) match "ax") 2)
(!call is (!callmeth (!call choice (!call sequence (!call any 1)
                                                   (!call literal "x"))
                                   (!call sequence (!call set "")
                                                   (!call literal "xu"))
                                   (!call literal "ay")) match "ay") 2)
(!call is (!callmeth (!call choice (!call literal "abc")
                                   (!call literal "cde")
                                   (!call literal "aka")) match "aka") 3)
(!call is (!callmeth (!call choice (!call sequence (!call set "abc")
                                                   (!call literal "x"))
                                   (!call literal "cde")
                                   (!call literal "aka")) match "ax") 2)
(!call is (!callmeth (!call choice (!call sequence (!call set "abc")
                                                   (!call literal "x"))
                                   (!call literal "cde")
                                   (!call literal "aka")) match "aka") 3)
(!call is (!callmeth (!call choice (!call sequence (!call set "abc")
                                                   (!call literal "x"))
                                   (!call literal "cde")
                                   (!call literal "aka")) match "cde") 3)
(!call is (!callmeth (!call choice (!call sequence (!call set "abc")
                                                   (!call literal "x"))
                                   (!call literal "ide")
                                   (!call sequence (!call set "ab")
                                                   (!call literal "ka"))) match "aka") 3)
(!call is (!callmeth (!call choice (!call literal "ab")
                                   (!call sequence (!call set "abc")
                                                   (!call many (!call literal "y"))
                                                   (!call literal "x"))
                                   (!call literal "cde")
                                   (!call literal "aka")) match "ax") 2)
(!call is (!callmeth (!call choice (!call literal "ab")
                                   (!call sequence (!call set "abc")
                                                   (!call many (!call literal "y"))
                                                   (!call literal "x"))
                                   (!call literal "cde")
                                   (!call literal "aka")) match "aka") 3)
(!call is (!callmeth (!call choice (!call literal "ab")
                                   (!call sequence (!call set "abc")
                                                   (!call many (!call literal "y"))
                                                   (!call literal "x"))
                                   (!call literal "cde")
                                   (!call literal "aka")) match "cde") 3)
(!call is (!callmeth (!call choice (!call literal "ab")
                                   (!call sequence (!call set "abc")
                                                   (!call many (!call literal "y"))
                                                   (!call literal "x"))
                                   (!call literal "ide")
                                   (!call sequence (!call set "ab")
                                                   (!call literal "ka"))) match "aka") 3)
(!call is (!callmeth (!call choice (!call literal "ab")
                                   (!call sequence (!call set "abc")
                                                   (!call many (!call literal "y"))
                                                   (!call literal "x"))
                                   (!call literal "ide")
                                   (!call sequence (!call set "ab")
                                                   (!call literal "ka"))) match "ax") 2)
(!call is (!callmeth (!call choice (!call sequence (!call any 1)
                                                   (!call literal "x"))
                                   (!call literal "cde")
                                   (!call sequence (!call set "ab")
                                                   (!call literal "ka"))) match "aka") 3)
(!call is (!callmeth (!call choice (!call sequence (!call any 1)
                                                   (!call literal "x"))
                                   (!call literal "cde")
                                   (!call sequence (!call any 1)
                                                   (!call literal "ka"))) match "aka") 3)
(!call is (!callmeth (!call choice (!call sequence (!call any 1)
                                                   (!call literal "x"))
                                   (!call literal "cde")
                                   (!call sequence (!call any 1)
                                                   (!call literal "ka"))) match "cde") 3)
(!call is (!callmeth (!call choice (!call literal "eb")
                                   (!call literal "cd")
                                   (!call many (!call literal "e"))
                                   (!call literal "x")) match "ee") 2)
(!call is (!callmeth (!call choice (!call literal "ab")
                                   (!call literal "cd")
                                   (!call many (!call literal "e"))
                                   (!call literal "x")) match "abcd") 2)
(!call is (!callmeth (!call choice (!call literal "ab")
                                   (!call literal "cd")
                                   (!call many (!call literal "e"))
                                   (!call literal "x")) match "eeex") 3)
(!call is (!callmeth (!call choice (!call literal "ab")
                                   (!call literal "cd")
                                   (!call many (!call literal "e"))
                                   (!call literal "x")) match "cd") 2)
(!call is (!callmeth (!call choice (!call literal "ab")
                                   (!call literal "cd")
                                   (!call many (!call literal "e"))
                                   (!call literal "x")) match "x") 0)
(!call is (!callmeth (!call choice (!call literal "ab")
                                   (!call literal "cd")
                                   (!call many (!call literal "e"))
                                   (!call literal "x")
                                   (!call literal "")) match "zee") 0)
(!call is (!callmeth (!call choice (!call literal "ab")
                                   (!call literal "cd")
                                   (!call some (!call literal "e"))
                                   (!call literal "x")) match "abcd") 2)
(!call is (!callmeth (!call choice (!call literal "ab")
                                   (!call literal "cd")
                                   (!call some (!call literal "e"))
                                   (!call literal "x")) match "eeex") 3)
(!call is (!callmeth (!call choice (!call literal "ab")
                                   (!call literal "cd")
                                   (!call some (!call literal "e"))
                                   (!call literal "x")) match "cd") 2)
(!call is (!callmeth (!call choice (!call literal "ab")
                                   (!call literal "cd")
                                   (!call some (!call literal "e"))
                                   (!call literal "x")) match "x") 1)
(!call is (!callmeth (!call choice (!call literal "ab")
                                   (!call literal "cd")
                                   (!call some (!call literal "e"))
                                   (!call literal "x")
                                   (!call literal "")) match "zee") 0)

(!let pi "3.14159 26535 89793 23846 26433 83279 50288 41971 69399 37510")
(!call is (!callmeth (!call subst (!call many (!call choice (!call replace (!call literal "1") "a")
                                                            (!call replace (!call literal "5") "b")
                                                            (!call replace (!call literal "9") "c")
                                                            (!call any)))) match pi)
          (!callmeth (!call subst (!call many (!call replace (!call any) ("1": "a" "5": "b" "9": "c")))) match pi))


(!call diag "+")

; tests for capture optimizations
(!call is (!callmeth (!call sequence (!call choice (!call any 3)
                                                   (!call sequence (!call any 4) (!call position)))
                                     (!call literal "a")) match "abca") 4 "capture optimizations")

(!define t ((!callmeth (!call many (!call sequence (!call choice (!call literal "a")
                                                                 (!call position))
                                                   (!call literal "x")))  match "axxaxx")))
(!call eq_array t (2 5))

; test for table captures
(!define t (!callmeth (!call table (!call some letter)) match "alo"))
(!call eq_array t () "table captures")

(!define (t n) ((!callmeth (!call sequence (!call table (!call some (!call capture letter)))
                                           (!call constant "t")) match "alo")))
(!call is n "t")
(!call is (!call tconcat t) "alo")

(!define t (!callmeth (!call table (!call capture (!call some (!call capture letter)))) match "alo"))
(!call is (!call tconcat t ";") "alo;a;l;o")

(!define t (!callmeth (!call table (!call table (!call some (!call sequence (!call position)
                                                                            letter
                                                                            (!call position))))) match "alo"))
(!call is (!call tconcat (!index t 0) ";") "0;1;1;2;2;3")

(!define t (!callmeth (!call table (!call capture (!call sequence (!call capture (!call any))
                                                                  (!call any)
                                                                  (!call capture (!call any))))) match "alo"))
(!call eq_array t ("alo" "a" "o"))

; tests for groups
(!define p (!call group (!call any)))   ; no capture
(!call is (!callmeth p match "x") "x" "groups")
(!define p (!call group (!call sequence (!call replace (!call succeed) (!lambda ()))
                                        (!call any)))) ; no value
(!call is (!callmeth p match "x") "x")
(!define p (!call group (!call group (!call group (!call capture (!call any))))))
(!call is (!callmeth p match "x") "x")
(!define p (!call group (!call sequence (!call group (!call many (!call group (!call capture (!call any)))))
                                        (!call group (!call constant 1))
                                        (!call constant 2))))
(!define t ((!callmeth p match "abc")))
(!call eq_array t ("a" "b" "c" 1 2))

; test for non-pattern as arguments to pattern functions
(!define p (!call sequence (!call grammar ((!call optional (!call sequence (!call literal "a")
                                                                           (!call variable 0)))))
                           (!call literal "b")
                           (!call grammar ((!call sequence (!call literal "a")
                                                           (!call variable 1))
                                           (!call optional (!call variable 0))))))
(!call is (!callmeth p match "aaabaac") 6)

; a large table capture
(!define t (!callmeth (!call table (!call many (!call capture (!call literal "a")))) match (!call str_rep "a" 10000)))
(!call is (!len t) 10000 "a large table capture")
(!call is (!index t 0) "a")
(!call is (!index t (!sub (!len t) 1)) "a")

; test for errors
(!let checkerr (!lambda (msg !vararg)
                        (!define result (!call select 2 (!call pcall !vararg)))
                        (!call ok (!callmeth (!call grammar ((!call choice (!call literal msg)
                                                                           (!call sequence (!call any)
                                                                                           (!call variable 0))))) match result) result)))

(!call checkerr "rule '0' outside a grammar" (!index peg "match") (!call variable 0) "")
(!call checkerr "rule 'hiii' outside a grammar" (!index peg "match") (!call variable "hiii") "")
(!call checkerr "rule 'hiii' is not defined" grammar ((!call variable "hiii")) "")
(!call checkerr "rule <a table> is not defined" grammar ((!call variable ())) "")

(!call checkerr "rule 'A' is not a pattern" grammar ( "A": ()))
(!call checkerr "rule <a function> is not a pattern" grammar ( print: ()))


; test for non-pattern as arguments to pattern functions

(!define b (!call sequence (!call grammar ((!call optional (!call sequence (!call literal "a")
                                                                           (!call variable 0)))))
                           (!call literal "b")
                           (!call grammar ((!call sequence (!call literal "a") (!call variable 1))
                                           (!call optional (!call variable 0))))))
(!call is (!callmeth p match "aaabaac") 6)

(!call checkerr "rule '0' is left recursive" grammar ((!call sequence (!call variable 0) (!call literal "a"))) "a")
(!call checkerr "rule '0' outside a grammar" (!index peg "match") (!call variable 0) "")
(!call checkerr "rule 'hiii' outside a grammar" (!index peg "match") (!call variable "hiii") "")
(!call checkerr "rule 'hiii' is not defined" grammar ((!call variable "hiii")) "")
(!call checkerr "rule <a table> is not defined" grammar ((!call variable ())) "")


(!call diag "+")

; bug in 0.10 (rechecking a grammar, after tail-call optimization)
(!call grammar ((!call grammar ((!call sequence (!call many (!call choice (!call any 3)
                                                                          (!call literal "xuxu")))
                                                (!call variable "xuxu"))
                                "xuxu": (!call any)))))


(!let Space (!call many (!call set " \n\t")))
(!let Number (!call sequence (!call some (!call range "09")) Space))
(!let FactorOp (!call sequence (!call capture (!call set "+-")) Space))
(!let TermOp (!call sequence (!call capture (!call set "*/")) Space))
(!let Open (!call sequence (!call literal "(") Space))
(!let Close (!call sequence (!call literal ")") Space))


(!let f_factor (!lambda (v1 op v2 d)
                (!call assert (!eq d !nil))
                (!if (!eq op "+")
                     (!return (!add v1 v2))
                     (!return (!sub v1 v2)))))


(!let f_term (!lambda (v1 op v2 d)
                (!call assert (!eq d !nil))
                (!if (!eq op "*")
                     (!return (!mul v1 v2))
                     (!return (!div v1 v2)))))

(!define G (!call grammar ("Exp"
  "Exp": (!call fold (!call sequence (!call variable "Factor")
                                     (!call many (!call group (!call sequence FactorOp
                                                                              (!call variable "Factor"))))) f_factor)
  "Factor": (!call fold (!call sequence (!call variable "Term")
                                        (!call many (!call group (!call sequence TermOp
                                                                                 (!call variable "Term"))))) f_term)
  "Term": (!call choice (!call replace Number tonumber)
                        (!call sequence Open (!call variable "Exp") Close))
)))

(!define G (!call sequence Space G (!call eos)))

(!for (r s) ((!call pairs (23 : " 3 + 5*8 / (1+1) "
                           5 : "3+4/2"
                           4 : "3+3-3- 9*2+3*9/1-  8")))
      (!call ok (!eq (!callmeth G match s) r)))

; test for grammars (errors deep in calling non-terminals)
(!let g (!call grammar (0 : (!call choice (!call variable 1)
                                          (!call literal "a"))
                        1 : (!call sequence (!call literal "a")
                                            (!call variable 2)
                                            (!call literal "x"))
                        2 : (!call choice (!call sequence (!call literal "b")
                                                          (!call variable 2))
                                          (!call literal "c")))))

(!call is (!callmeth g match "abbbcx") 6)
(!call is (!callmeth g match "abbbbx") 1)


; tests for \x00
(!call is  (!callmeth (!call some (!call range "\x00\x01")) match "\x00\x01\x00") 3 "\\x00")
(!call is  (!callmeth (!call some (!call set "\x00\x01ab")) match "\x00\x01\x00a") 4)
(!call is  (!callmeth (!call some (!call any)) match "\x00\x01\x00a") 4)
(!call is  (!callmeth (!call literal "\x00\x01\x00a") match "\x00\x01\x00a") 4)
(!call is  (!callmeth (!call literal "\x00\x00\x00") match "\x00\x00\x00") 3)
(!call nok (!callmeth (!call literal "\x00\x00\x00") match "\x00\x00"))

; tests for predicates
(!call nok (!callmeth (!call sequence (!call not_followed_by (!call literal "a"))
                                      (!call any 2)) match "alo") "predicates")
(!call is  (!callmeth (!call sequence (!call not_followed_by (!call not_followed_by (!call literal "a")))
                                      (!call any 2)) match "alo") 2)
(!call is  (!callmeth (!call sequence (!call followed_by (!call literal "a"))
                                      (!call any 2)) match "alo") 2)
(!call is  (!callmeth (!call sequence (!call followed_by (!call followed_by (!call literal "a")))
                                      (!call any 2)) match "alo") 2)
(!call nok (!callmeth (!call sequence (!call followed_by (!call followed_by (!call literal "c")))
                                      (!call any 2)) match "alo"))
(!call is  (!callmeth (!call subst (!call many (!call choice (!call sequence (!call followed_by (!call followed_by (!call literal "a")))
                                                                             (!call any))
                                                             (!call replace (!call any) ".")))) match "aloal") "a..a.")
(!call is  (!callmeth (!call subst (!call many (!call choice (!call sequence (!call followed_by (!call replace (!call followed_by (!call literal "a")) ""))
                                                                             (!call any))
                                                             (!call replace (!call any) ".")))) match "aloal") "a..a.")
(!call is  (!callmeth (!call subst (!call many (!call choice (!call sequence (!call not_followed_by (!call not_followed_by (!call literal "a")))
                                                                             (!call any))
                                                             (!call replace (!call any) ".")))) match "aloal") "a..a.")
(!call is  (!callmeth (!call subst (!call many (!call choice (!call sequence (!call not_followed_by (!call replace (!call not_followed_by (!call literal "a")) ""))
                                                                             (!call any))
                                                             (!call replace (!call any) ".")))) match "aloal") "a..a.")

; bug in 0.9
(!call is  (!callmeth (!call sequence (!call literal "a")
                                      (!call followed_by (!call literal "b"))) match "ab") 1 "bug in 0.9")
(!call nok (!callmeth (!call sequence (!call literal "a")
                                      (!call followed_by (!call literal "b"))) match "a"))

(!call nok (!callmeth (!call followed_by (!call set "567")) match ""))
(!call is  (!callmeth (!call sequence (!call followed_by (!call set "567"))
                                      (!call any)) match "6") 1)

; tests for Tail Calls

; create a grammar for a simple DFA for even number of 0s and 1s
; finished in '$':
;
; ->1 <---0---> 2
;   ^           ^
;   |           |
;   1           1
;   |           |
;   V           V
;   3 <---0---> 4
;
; this grammar should keep no backtracking information
(!define p (!call grammar (0 : (!call choice (!call sequence (!call literal "0") (!call variable 1))
                                             (!call sequence (!call literal "1") (!call variable 2))
                                             (!call literal "$"))
                           1 : (!call choice (!call sequence (!call literal "0") (!call variable 0))
                                             (!call sequence (!call literal "1") (!call variable 3)))
                           2 : (!call choice (!call sequence (!call literal "0") (!call variable 3))
                                             (!call sequence (!call literal "1") (!call variable 0)))
                           3 : (!call choice (!call sequence (!call literal "0") (!call variable 2))
                                             (!call sequence (!call literal "1") (!call variable 1))))))

(!call ok  (!callmeth p match (!concat (!call str_rep "00" 10000) "$")) "Tail Calls")
(!call ok  (!callmeth p match (!concat (!call str_rep "01" 10000) "$")))
(!call ok  (!callmeth p match (!concat (!call str_rep "011" 10000) "$")))
(!call nok (!callmeth p match (!concat (!call str_rep "011" 10001) "$")))

; this grammar does need backtracking info.
(!define lim 10000)
(!define p (!call grammar ((!call choice (!call sequence (!call literal "0")
                                                         (!call variable 0))
                                         (!call literal "0")))))
(!call nok (!call1 pcall (!index peg "match") p (!call str_rep "0" lim)) "this grammar does need backtracking info")
(!call (!index peg "setmaxstack") (!mul 2 lim))
(!call nok (!call1 pcall (!index peg "match") p (!call str_rep "0" lim)))
(!call (!index peg "setmaxstack") (!add (!mul 2 lim) 2))
(!call ok  (!call1 pcall (!index peg "match") p (!call str_rep "0" lim)))

; tests for optional start position
(!call ok  (!callmeth (!call literal "a") match "abc" 0) "optional start position")
(!call ok  (!callmeth (!call literal "b") match "abc" 1))
(!call ok  (!callmeth (!call literal "c") match "abc" 2))
(!call nok (!callmeth (!call any) match "abc" 4))
(!call ok  (!callmeth (!call literal "a") match "abc" -3))
(!call ok  (!callmeth (!call literal "b") match "abc" -2))
(!call ok  (!callmeth (!call literal "c") match "abc" -1))
(!call ok  (!callmeth (!call literal "abc") match "abc" -4))    ; truncate to position 1

(!call ok  (!callmeth (!call empty) match "abc" 10))    ; empty string is everywhere!
(!call ok  (!callmeth (!call empty) match "" 10))
(!call nok (!callmeth (!call any) match "" 1))
(!call nok (!callmeth (!call any) match "" -1))
(!call nok (!callmeth (!call any) match "" 0))


(!call diag "+")

; tests for argument captures
(!call nok (!call1 pcall arg 0) "argument captures")
(!call nok (!call1 pcall arg -1))
(!call nok (!call1 pcall arg (!pow 2 18)))
(!call nok (!call1 pcall (!index peg "match") (!call arg 1) "a" 0))
(!call is  (!callmeth (!call arg 1) match "a" 0 print) print)
(!define x ((!callmeth (!call sequence (!call arg 1) (!call arg 2)) match "" 0 10 20)))
(!call eq_array x (10 20))

(!call is (!callmeth (!call sequence (!call matchtime (!call sequence (!call group (!call arg 3) "a")
                                                                      (!call matchtime (!call backref "a")
                                                                                       (!lambda (s i x)
                                                                                                (!call assert (!eq s "a"))
                                                                                                (!call assert (!eq i 0))
                                                                                                (!return i (!add x 1))))
                                                                      (!call arg 2))
                                                      (!lambda (s i a b c)
                                                               (!call assert (!eq s "a"))
                                                               (!call assert (!eq i 0))
                                                               (!call assert (!eq c !nil))
                                                               (!return i (!add (!mul 2 a) (!mul 3 b)))))
                                     (!call literal "a")) match "a" 0 !false 100 1000) (!add (!mul 2 1001) (!mul 3 100)))

; tests for Lua functions
(!define t ())
(!define s)
(!define p (!lambda (s1 i)
                    (!call assert (!eq s s1))
                    (!assign (!index t (!len t)) i)
                    (!return !nil)))
(!assign s "hi, this is a test")
(!call is (!callmeth (!call many (!call choice (!call except (!call matchtime (!call empty) p) (!call eos))
                                               (!call any 2))) match s) (!len s) "Lua functions")
(!call is (!len t) (!div (!len s) 2))
(!call is (!index t 0) 0)
(!call is (!index t 1) 2)

(!call nok (!callmeth (!call matchtime (!call empty) p) match s))

(!define p (!call choice (!call matchtime (!call empty) (!lambda (s i) (!return i)))
                         (!call matchtime (!call empty) (!lambda (s i) (!return !nil)))))
(!call ok (!callmeth p match "alo"))

(!define p (!call sequence (!call matchtime (!call empty) (!lambda (s i) (!return i)))
                           (!call matchtime (!call empty) (!lambda (s i) (!return !nil)))))
(!call nok (!callmeth p match "alo"))

(!define t ())
(!define p (!lambda (s1 i)
                (!call assert (!eq s s1))
                (!assign (!index t (!len t)) i)
                (!return i)))
(!assign s "hi, this is a test")
(!call is (!callmeth (!call many (!call sequence (!call any)
                                                 (!call matchtime (!call empty) p))) match s) (!len s))
(!call is (!len t) (!len s))
(!call is (!index t 0) 1)
(!call is (!index t 1) 2)

(!define t ())
(!define p (!call matchtime (!call empty)
                            (!lambda (s1 i)
                                     (!call assert (!eq s s1))
                                     (!assign (!index t (!len t)) i)
                                     (!return (!and (!lt i (!len s1))
                                                    (!add i 1))))))
(!assign s "hi, this is a test")
(!call is (!callmeth (!call many p) match s) (!len s))
(!call is (!len t) (!add (!len s) 1))
(!call is (!index t 0) 0)
(!call is (!index t 1) 1)

(!define p (!lambda (s1 i)
                    (!return (!callmeth (!call some (!call literal "a")) match s1 i))))
(!call is  (!callmeth (!call matchtime (!call empty) p) match "aaaa") 4)
(!call is  (!callmeth (!call matchtime (!call empty) p) match "abaa") 1)
(!call nok (!callmeth (!call matchtime (!call empty) p) match "baaa"))
(!call nok (!call1 pcall (!index peg "match") (!call matchtime (!call empty) (!lambda () (!return (!pow 2 20)))) s))
(!call nok (!call1 pcall (!index peg "match") (!call matchtime (!call empty) (!lambda () (!return -1))) s))
(!call nok (!call1 pcall (!index peg "match") (!call matchtime (!call empty) (!lambda (s i) (!return (!sub i 1)))) s))
(!call nok (!call1 pcall (!index peg "match") (!call sequence (!call many (!call any))
                                                              (!call matchtime (!call empty) (!lambda (_ i) (!return (!sub i 1))))) s))
(!call ok  (!callmeth (!call sequence (!call many (!call any))
                                      (!call matchtime (!call empty) (!lambda (_ i) (!return i)))
                                      (!call eos)) match s))
(!call nok (!call1 pcall (!index peg "match") (!call sequence (!call many (!call any))
                                                              (!call matchtime (!call empty) (!lambda (_ i) (!return (!add i 1))))) s))
(!call ok  (!callmeth (!call sequence (!call matchtime (!call empty) (!lambda (s i) (!return (!len s))))
                                      (!call eos)) match s))
(!call nok (!call1 pcall (!index peg "match") (!call sequence (!call matchtime (!call empty) (!lambda (s i) (!return (!add (!len s) 2))))
                                                              (!call eos)) s))
(!call nok (!callmeth (!call sequence (!call matchtime (!call empty) (!lambda (s i) (!return (!sub (!len s) 1))))
                                      (!call eos)) match s))
(!call is  (!callmeth (!call sequence (!call many (!call any))
                                      (!call matchtime (!call empty) (!lambda (_ i) (!return !true)))) match s) (!len s))
(!loop i 0 (!len s) 1
        (!call is (!callmeth (!call matchtime (!call empty) (!lambda (_ _) (!return i))) match s) i))

(!define p (!call sequence (!call many (!call choice (!call matchtime (!call empty) (!lambda (s i) (!return (!and (!ne (!mod i 2) 0)
                                                                                                                  (!add i 1)))))
                                                     (!call matchtime (!call empty) (!lambda (s i) (!return (!and (!and (!eq (!mod i 2) 0)
                                                                                                                        (!lt (!add i 2) (!len s)))
                                                                                                                  (!add i 3)))))))
                           (!call eos)))
(!call ok (!callmeth p match (!call str_rep "a" 14000)))

; tests for Function Replacements
(!define f (!lambda (a !vararg)
                (!if (!ne a "x") (!return (a !vararg)))))

(!define t (!callmeth (!call replace (!call many (!call capture (!call any))) f) match "abc"))
(!call eq_array t ("a" "b" "c") "Function Replacements")

(!define t (!callmeth (!call replace (!call replace (!call many (!call capture (!call any))) f) f) match "abc"))
(!call is_deeply t (("a" "b" "c")))

(!define t (!callmeth (!call replace (!call replace (!call many(!call any)) f) f) match "abc")) ; no capture
(!call is_deeply t (("abc")))

(!define t (!callmeth (!call replace (!call sequence (!call replace (!call many (!call any)) f) (!call position)) f) match "abc"))
(!call is_deeply t (("abc") 3))

(!define t (!callmeth (!call replace (!call sequence (!call replace (!call many (!call capture (!call any))) f) (!call position)) f) match "abc"))
(!call is_deeply t (("a" "b" "c") 3))

(!define t (!callmeth (!call replace (!call sequence (!call replace (!call many (!call capture (!call any))) f) (!call position)) f) match "xbc"))
(!call eq_array t (3))

(!define t (!callmeth (!call replace (!call capture (!call many (!call capture (!call any)))) f) match "abc"))
(!call eq_array t ("abc" "a" "b" "c"))

(!define g (!lambda (!vararg) (!return 1 !vararg)))
(!define t ((!callmeth (!call replace (!call replace (!call many (!call capture (!call any))) g) g) match "abc")))
(!call eq_array t (1 1 "a" "b" "c"))

(!define t ((!callmeth (!call replace (!call replace (!call sequence (!call constant !nil !nil 4)
                                                                     (!call constant !nil 3)
                                                                     (!call constant !nil !nil)) g) g) match "")))
(!define t1 (1 1 !nil !nil 4 !nil 3 !nil !nil))
(!loop i 1 10 1
        (!call is (!index t i) (!index t1 i)))

(!define t ((!callmeth (!call many (!call replace (!call capture (!call any)) (!lambda (x) (!return x (!concat x "x"))))) match "abc")))
(!call eq_array t ("a" "ax" "b" "bx" "c" "cx"))

(!define t (!callmeth (!call table (!call many (!call sequence (!call replace (!call capture (!call any)) (!lambda (x y) (!return y x)))
                                                               (!call constant 1)))) match "abc"))
(!call eq_array t (!nil "a" 1 !nil "b" 1 !nil "c" 1))

; tests for Query Replacements
(!call is (!callmeth (!call replace (!call capture (!call many (!call capture (!call any)))) ("abc": 10)) match "abc") 10 "Query Replacements")
(!call is (!callmeth (!call replace (!call many (!call capture (!call any))) ("a": 10)) match "abc") 10)
(!call is (!callmeth (!call replace (!call many (!call set "ba")) ("ab": 40)) match "abc") 40)
(!define t (!callmeth (!call table (!call many (!call replace (!call set "ba") ("a": 40)))) match "abc"))
(!call eq_array t (40))

(!call is (!callmeth (!call subst (!call many (!call replace (!call capture (!call any)) ("a": "." "d": "..")))) match "abcdde") ".bc....e")
(!call is (!callmeth (!call subst (!call many (!call replace (!call capture (!call any)) ("f": ".")))) match "abcdde") "abcdde")
(!call is (!callmeth (!call subst (!call many (!call replace (!call capture (!call any)) ("d": ".")))) match "abcdde") "abc..e")
(!call is (!callmeth (!call subst (!call many (!call replace (!call capture (!call any)) ("e": ".")))) match "abcdde") "abcdd.")
(!call is (!callmeth (!call subst (!call many (!call replace (!call capture (!call any)) ("e": "." "f": "+")))) match "eefef") "..+.+")
(!call is (!callmeth (!call subst (!call many (!call capture (!call any)))) match "abcdde") "abcdde")
(!call is (!callmeth (!call subst (!call capture (!call many (!call capture (!call any))))) match "abcdde") "abcdde")
(!call is (!callmeth (!call sequence (!call any)
                                     (!call subst (!call many (!call any)))) match "abcdde") "bcdde")
(!call is (!callmeth (!call subst (!call many (!call choice (!call replace (!call capture (!call literal "0")) "x")
                                                            (!call any)))) match "abcdde") "abcdde")

(!call is (!callmeth (!call subst (!call many (!call choice (!call replace (!call capture (!call literal "0")) "x")
                                                            (!call any)))) match "0ab0b0") "xabxbx")
(!call is (!callmeth (!call subst (!call many (!call choice (!call replace (!call capture (!call literal "0")) "x")
                                                            (!call replace (!call any) ("b": 3))))) match "b0a0b") "3xax3")
(!call is (!callmeth (!call sequence (!call replace (!call replace (!call any) "%0%0") ("aa": -3))
                                     (!call literal "x")) match "ax") -3)
(!call is (!callmeth (!call sequence (!call replace (!call replace (!call replace (!call capture (!call any)) "%0%1") ("aa": "z")) ("z": -3))
                                     (!call literal "x")) match "ax") -3)

(!call is (!callmeth (!call subst (!call sequence (!call constant 0)
                                                  (!call replace (!call any) ""))) match "4321") "0")

(!call is (!callmeth (!call subst (!call many (!call replace (!call any) "%0"))) match "abcd") "abcd")
(!call is (!callmeth (!call subst (!call many (!call replace (!call any) "%0.%0"))) match "abcd") "a.ab.bc.cd.d")
(!call is (!callmeth (!call subst (!call many (!call choice (!call replace (!call literal "a") "%0.%0")
                                                            (!call any)))) match "abcad") "a.abca.ad")
(!call is (!callmeth (!call replace (!call capture (!call literal "a")) "%1%%%0") match "a") "a%a")
(!call is (!callmeth (!call subst (!call many (!call replace (!call any) ".xx"))) match "abcd") ".xx.xx.xx.xx")
(!call is (!callmeth (!call replace (!call sequence (!call position)
                                                    (!call any 3)
                                                    (!call position)) "%2%1%1 - %0 ") match "abcde") "300 - abc ")

(!call ok  (!call1 pcall (!index peg "match") (!call replace (!call any) "%0") "abc"))
(!call nok (!call1 pcall (!index peg "match") (!call replace (!call any) "%1") "abc"))    ; out of range
(!call nok (!call1 pcall (!index peg "match") (!call replace (!call any) "%9") "abc"))    ; out of range

(!define p (!call capture (!call any)))
(!assign p (!call sequence p p))
(!assign p (!call sequence p p))
(!assign p (!call replace (!call sequence p p (!call capture (!call any))) "%9 - %1"))
(!call is (!callmeth p match "1234567890") "9 - 1")

(!call is (!callmeth (!call constant print) match "") print)

; too many captures (just ignore extra ones)
(!define p (!call replace (!call many (!call capture (!call any))) "%2-%9-%0-%9"))
(!call is (!callmeth p match "01234567890123456789") "1-8-01234567890123456789-8" "too many captures (just ignore extra ones)")
(!define s (!call str_rep "12345678901234567890" 20))
(!call is (!callmeth (!call replace (!call many (!call capture (!call any))) "%9-%1-%0-%3") match s) (!mconcat "9-1-" s "-3"))

; string captures with non-string subcaptures
(!define p (!call replace (!call sequence (!call constant "alo")
                                          (!call capture (!call any))) "%1 - %2 - %1"))
(!call is (!callmeth p match "x") "alo - x - alo" "string captures with non-string subcaptures")

(!call nok (!call1 pcall (!index peg "match") (!call replace (!call constant !true) "%1") "a"))

; long strings for string capture
(!define l 10000)
(!define s (!mconcat (!call str_rep "a" l) (!call str_rep "b" l) (!call str_rep "c" l)))

(!define p (!call replace (!call sequence (!call capture (!call some (!call literal "a")))
                                          (!call capture (!call some (!call literal "b")))
                                          (!call capture (!call some (!call literal "c")))) "%3%2%1"))

(!call is (!callmeth p match s) (!mconcat (!call str_rep "c" l) (!call str_rep "b" l) (!call str_rep "a" l)))


(!call diag "+")

; accumulator capture
(!let f (!lambda (x)
                 (!return (!add x 1))))
(!call is (!callmeth (!call fold(!call sequence (!call constant 0)
                                                (!call many (!call capture (!call any)))) f) match "alo alo") 7 "accumulator capture")

(!define t ((!callmeth (!call fold (!call constant 1 2 3) error) match "")))
(!call eq_array t (1))

(!define p (!call fold (!call sequence (!call table (!call succeed))
                                                    (!call many (!call group (!call sequence (!call capture (!call some (!call range "az")))
                                                                                             (!call literal "=")
                                                                                             (!call capture (!call some (!call range "az")))
                                                                                             (!call literal ";"))))) rawset))
(!define t (!callmeth p match "a=b;c=du;xux=yuy;"))
(!call eq_array t ("a": "b" "c": "du" "xux": "yuy"))

; tests for loop checker
(!let haveloop (!lambda (p)
                (!call assert (!not (!call pcall (!lambda (p) (!return (!call many p))) p)))
                (!call pass)))
(!call haveloop (!call optional (!call literal "x")))
(!call is (!callmeth (!call many (!call sequence (!call choice (!call empty) (!call any)) (!call set "al"))) match "alo") 2)
(!call haveloop (!call literal ""))
(!call haveloop (!call many (!call literal "x")))
(!call haveloop (!call optional (!call literal "x")))
(!call haveloop (!call choice (!call literal "x") (!call any) (!call any 2) (!call optional (!call literal "a"))))
(!call haveloop (!call not_followed_by (!call literal "ab")))
(!call haveloop (!call not_followed_by (!call not_followed_by (!call literal "ab"))))
(!call haveloop (!call choice (!call followed_by (!call followed_by (!call literal "ab"))) (!call literal "xy")))
(!call haveloop (!call not_followed_by (!call followed_by (!call many (!call literal "ab")))))
(!call haveloop (!call followed_by (!call not_followed_by (!call some (!call literal "ab")))))
(!call haveloop (!call followed_by (!call variable 2)))
(!call haveloop (!call choice (!call variable 2) (!call variable 0) (!call optional (!call literal "a"))))
(!call haveloop (!call grammar (0 : (!call sequence (!call variable 1) (!call variable 2))
                                1 : (!call variable 2)
                                2 : (!call empty ))))
(!call is (!callmeth (!call many (!call grammar (0 : (!call sequence (!call variable 1) (!call variable 2))
                                                 1 : (!call variable 2)
                                                 2 : (!call any)))) match "abc") 2)
(!call is (!callmeth (!call optional (!call empty)) match "a") 0)

(!let basiclookfor (!lambda (p)
                (!return (!call grammar (0 : (!call choice p (!call sequence (!call any) (!call variable 0))))))))

(!let find (!lambda (p s)
                (!return (!callmeth (!call basiclookfor (!call literal p)) match s))))


(!let badgrammar (!lambda (g exp)
                (!let (err msg) ((!call pcall grammar g)))
                (!call assert (!not err))
                (!if exp (!call assert (!call find exp msg)))
                (!call pass msg)))

(!call badgrammar (0 : (!call variable 0)) "rule '0'")
(!call badgrammar (0 : (!call variable 1)) "rule '1'")          ; invalid non-terminal
(!call badgrammar (0 : (!call variable "x")) "rule 'x'")        ; invalid non-terminal
(!call badgrammar (0 : (!call variable ())) "rule <a table>")   ; invalid non-terminal
(!call badgrammar (0 : (!call sequence (!call followed_by (!call literal "a")) (!call variable 1))) "rule '1'")
(!call badgrammar (0 : (!call sequence (!call not_followed_by (!call literal "a")) (!call variable 1))) "rule '1'")
(!call badgrammar (0 : (!call sequence (!call eos) (!call variable 1))) "rule '1'")
(!call badgrammar (0 : (!call sequence (!call any) (!call variable 1))
                   1 : (!call variable 1)) "rule '1'")
(!call badgrammar (0 : (!call empty)
                   1 : (!call sequence (!call any) (!call many (!call variable 0)))) "loop in rule '1'")
(!call badgrammar ((!call variable 1) (!call many (!call variable 2)) (!call literal "")) "rule '1'")
(!call badgrammar ((!call sequence (!call variable 1) (!call many (!call variable 2))) (!call many (!call variable 2)) (!call empty)) "rule '0'")
(!call badgrammar ((!call followed_by (!call sequence (!call variable 0) (!call literal "a")))) "rule '0'")
(!call badgrammar ((!call not_followed_by (!call sequence (!call variable 0) (!call literal "a")))) "rule '0'")

(!call is (!callmeth (!call grammar ((!call sequence (!call literal "a")
                                                     (!call not_followed_by (!call variable 0))))) match "aaa") 1)
(!call is (!callmeth (!call grammar ((!call sequence (!call literal "a")
                                                     (!call not_followed_by (!call variable 0))))) match "aaaa") !nil)

; simple tests for maximum sizes:
(!define p (!call literal "a"))
(!loop i 1 14 1
        (!assign p (!call sequence p p)))

(!define p ())
(!loop i 0 100 1
        (!assign (!index p i) (!call literal "a")))
(!define p (!call grammar p))


; strange values for rule labels

(!define p (!call grammar ("print"
                           "print": (!call variable print)
                           print: (!call variable _G)
                           _G: (!call literal "a"))))

(!call ok (!callmeth p match "a"))

; initial rule
(!define g ())
(!loop i 1 10 1
        (!assign (!index g (!concat "i" i)) (!call sequence (!call literal "a") (!call variable (!concat "i" (!add i 1))))))
(!assign (!index g "i11") (!call literal ""))
(!loop i 1 10 1
        (!assign (!index g 0) (!concat "i" i))
        (!define p (!call grammar g))
        (!call is (!callmeth p match "aaaaaaaaaaa") (!sub 11 i)))

(!call diag "+")


(!let space (!call many (!call set " \t\n")))

; tests for back references
(!call nok (!call1 pcall (!index peg "match") (!call backref "x") "") "back references")
(!call nok (!call1 pcall (!index peg "match") (!call sequence (!call group (!call any) "a")
                                                              (!call backref "b")) "a"))

(!define p (!call sequence (!call group (!call sequence (!call capture (!call any))
                                                        (!call capture (!call any))) "k")
                           (!call table (!call backref "k"))))
(!define t (!callmeth p match "ab"))
(!call eq_array t ("a" "b"))


(!define t ())
(!let foo (!lambda (p)
                   (!assign (!index t (!len t)) p)
                   (!return (!concat p "x"))))

(!define p (!call sequence (!call group (!call replace (!call capture (!call any 2)) foo) "x") (!call backref "x")
                           (!call group (!call replace (!call backref "x")           foo) "x") (!call backref "x")
                           (!call group (!call replace (!call backref "x")           foo) "x") (!call backref "x")
                           (!call group (!call replace (!call backref "x")           foo) "x") (!call backref "x")))
(!define x ((!callmeth p match "ab")))
(!call eq_array x ("abx" "abxx" "abxxx" "abxxxx"))
(!call eq_array t ("ab"
                   "ab" "abx"
                   "ab" "abx" "abxx"
                   "ab" "abx" "abxx" "abxxx"))


; tests for match-time captures

(!let id (!lambda (s i !vararg)
                (!return !true !vararg)))

(!call is (!callmeth (!call matchtime (!call subst (!call many (!call choice (!call matchtime (!call replace (!call set "abc") ("a": "x" "c": "y")) id)
                                                                             (!call replace (!call some (!call range "09")) char)
                                                                             (!call any)))) id) match "acb98+68c") "xyb\x62+\x44y" "match-time captures")

(!define p (!call grammar ("S"
                           "S": (!call choice (!call sequence (!call variable "atom")
                                                              space)
                                              (!call matchtime (!call table (!call sequence (!call literal "(")
                                                                                            space
                                                                                            (!call choice (!call matchtime (!call some (!call variable "S")) id)
                                                                                                          (!call succeed))
                                                                                            (!call literal ")")
                                                                                            space)) id))
                           "atom": (!call matchtime (!call capture (!call some (!call range "AZ" "az" "09"))) id))))
(!define x (!callmeth p match "(a g () ((b) c) (d (e)))"))
(!call is_deeply x ("a" "g" () (("b") "c") ("d" ("e"))))

(!define x ((!callmeth (!call many (!call matchtime (!call any) id)) match (!call str_rep "a" 500))))
(!call is (!len x) 500)

(!define id (!lambda (s i x)
                (!if (!eq x "a")
                     (!return (!add i 1) 1 3 7)
                     (!return !nil 2 4 6 8))))

(!define p (!call many (!call choice (!call matchtime (!call empty) id)
                                     (!call matchtime (!call any 2) id)
                                     (!call matchtime (!call any) id))))
(!call is (!call tconcat ((!callmeth p match "abababab"))) (!call str_rep "137" 4))

(!let ref (!lambda (s i x)
                (!return (!callmeth (!call literal x) match s (!sub i (!len x))))))

(!call is  (!callmeth (!call matchtime (!call many (!call any)) ref) match "alo") 3)
(!call is  (!callmeth (!call sequence (!call any)
                                      (!call matchtime (!call many (!call any)) ref)) match "alo") 3)
(!call nok (!callmeth (!call sequence (!call any)
                                      (!call matchtime (!call many (!call capture (!call any))) ref)) match "alo"))

(!let ref (!lambda (s i x)
                (!return (!and (!eq i (!call tonumber x)) i) "xuxu")))

(!call ok  (!callmeth (!call matchtime (!call any) ref) match "1"))
(!call nok (!callmeth (!call matchtime (!call any) ref) match "0"))
(!call ok  (!callmeth (!call matchtime (!call many (!call any)) ref) match "02"))

(!let ref (!lambda (s i a b)
                (!if (!eq a b) (!return i (!call str_upper a)))))

(!define p (!call matchtime (!call sequence (!call capture (!call some (!call range "az")))
                                            (!call literal "-")
                                            (!call capture (!call some (!call range "az")))) ref))
(!define p (!call sequence (!call many (!call except (!call any) p))
                           p
                           (!call many (!call any))
                           (!call eos)))

(!call is (!callmeth p match "abbbc-bc ddaa") "BC")

(!define c (!call sequence (!call literal "[")
                           (!call group (!call many (!call literal "=")) "init")
                           (!call literal "[")
                           (!call replace (!call grammar ((!call choice (!call matchtime (!call sequence (!call literal "]")
                                                                                                         (!call capture (!call many (!call literal "=")))
                                                                                                         (!call literal "]")
                                                                                                         (!call backref "init")) (!lambda (_ _ s1 s2) (!return (!eq s1 s2))))
                                                                        (!call sequence (!call any)
                                                                                        (!call variable 0))))) (!lambda ()))))

(!call is  (!callmeth c match "[==[]]====]]]]==]===[]") 17)
(!call is  (!callmeth c match "[[]=]====]=]]]==]===[]") 13)
(!call nok (!callmeth c match "[[]=]====]=]=]==]===[]"))


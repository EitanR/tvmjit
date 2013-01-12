#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-TestMore library.
;   Copyright (c) 2009-2011 Francois Perrad
;

(!call require "TAP")

(!let tostring tostring)
(!let abs (!index math "abs"))
(!let acos (!index math "acos"))
(!let asin (!index math "asin"))
(!let atan (!index math "atan"))
(!let atan2 (!index math "atan2"))
(!let ceil (!index math "ceil"))
(!let cos (!index math "cos"))
(!let cosh (!index math "cosh"))
(!let deg (!index math "deg"))
(!let exp (!index math "exp"))
(!let floor (!index math "floor"))
(!let fmod (!index math "fmod"))
(!let frexp (!index math "frexp"))
(!let huge (!index math "huge"))
(!let ldexp (!index math "ldexp"))
(!let log (!index math "log"))
(!let log10 (!index math "log10"))
(!let max (!index math "max"))
(!let min (!index math "min"))
(!let modf (!index math "modf"))
(!let pi (!index math "pi"))
(!let pow (!index math "pow"))
(!let rad (!index math "rad"))
(!let random (!index math "random"))
(!let randomseed (!index math "randomseed"))
(!let sin (!index math "sin"))
(!let sinh (!index math "sinh"))
(!let sqrt (!index math "sqrt"))
(!let tan (!index math "tan"))
(!let tanh (!index math "tanh"))


(!let plan plan)
(!let is is)
(!let type_ok type_ok)
(!let like like)
(!let error_like error_like)
(!let eq_array eq_array)

(!call plan 44)

(!call like (!call tostring pi) "^3%.14" "variable pi")

(!call type_ok huge "number" "variable huge")

(!call is (!call abs -12.34) 12.34 "function abs")
(!call is (!call abs 12.34) 12.34)

(!call like (!call acos 0.5) "^1%.047" "function acos")

(!call like (!call asin 0.5) "^0%.523" "function asin")

(!call like (!call atan 0.5) "^0%.463" "function atan")

(!call like (!call atan2 1 2) "^0%.463" "function atan2")

(!call is (!call ceil 12.34) 13 "function ceil")
(!call is (!call ceil -12.34) -12)

(!call like (!call cos 0) "^1$" "function cos")

(!call like (!call cosh 0) "^1$" "function cosh")

(!call is (!call deg pi) 180 "function deg")

(!call like (!call exp 1.0) "^2%.718" "function exp")

(!call is (!call floor 12.34) 12 "function floor")
(!call is (!call floor -12.34) -13)

(!call is (!call fmod 7 3) 1 "function fmod")
(!call is (!call fmod -7 3) -1)

(!call eq_array ((!call frexp 1.5)) (0.75 1) "function frexp")

(!call is (!call ldexp 1.2 3) 9.6 "function ldexp")

(!call like (!call log 47) "^3%.85" "function log")
(!call like (!call log 47 2) "^5%.554" "function log (base 2)")
(!call like (!call log 47 10) "^1%.672" "function log (base 10)")

(!call like (!call log10 47) "^1%.672" "function log10")

(!call error_like (!lambda () (!call max))
                       "^[^:]+:%d+: bad argument #1 to 'max' %(number expected, got no value%)"
                       "function max 0")

(!call is (!call max 1) 1 "function max")
(!call is (!call max 1 2) 2)
(!call is (!call max 1 2 3 -4) 3)

(!call error_like (!lambda () (!call min))
                       "^[^:]+:%d+: bad argument #1 to 'min' %(number expected, got no value%)"
                       "function min 0")

(!call is (!call min 1) 1 "function min")
(!call is (!call min 1 2) 1)
(!call is (!call min 1 2 3 -4) -4)

(!call eq_array ((!call modf 2.25)) (2 0.25) "function modf")

(!call is (!call pow -2 3) -8 "function pow")

(!call like (!call rad 180) "^3%.14" "function rad")

(!call like (!call random) "^%d%.%d+" "function random no arg")

(!call like (!call random 9) "^%d$" "function random 1 arg")

(!call like (!call random 10 19) "^1%d$" "function random 2 arg")

(!call randomseed 12)
(!let a (!call random))
(!call randomseed 12)
(!let b (!call random))
(!call is a b "function randomseed")

(!call like (!call sin (!div pi 2)) "^1$" "function sin")

(!call like (!call sinh 1) "^1%.175" "function sinh")

(!call like (!call sqrt 2) "^1%.414" "function sqrt")

(!call like (!call tan (!div pi 3)) "^1%.732" "function tan")

(!call like (!call tanh 1) "^0%.761" "function sinh")


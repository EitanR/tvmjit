#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;

(!call (!index tvm "dofile") "TAP.tp")

(!let tobit (!index bit "tobit"))
(!let tohex (!index bit "tohex"))
(!let bnot (!index bit "bnot"))
(!let bor (!index bit "bor"))
(!let band (!index bit "band"))
(!let bxor (!index bit "bxor"))
(!let lshift (!index bit "lshift"))
(!let rshift (!index bit "rshift"))
(!let arshift (!index bit "arshift"))
(!let rol (!index bit "rol"))
(!let ror (!index bit "ror"))
(!let bswap (!index bit "bswap"))

(!let plan plan)
(!let is is)

(!call plan 24)

(!call is (!call tobit 0xffffffff) -1 "function tobit")
(!call is (!call tobit (!add 0xffffffff 1)) 0)
(!call is (!call tobit (!add (!pow 2 40) 1234)) 1234)

(!call is (!call tohex 1) "00000001" "function tohex")
(!call is (!call tohex -1) "ffffffff")
(!call is (!call tohex 0xffffffff) "ffffffff")
(!call is (!call tohex -1 -8) "FFFFFFFF")
(!call is (!call tohex 0x21 4) "0021")
(!call is (!call tohex 0x87654321 4) "4321")

(!call is (!call bnot 0xedcba987) 0x12345678 "function bnot")

(!call is (!call bor 1 2 4 8) 15 "function bor")
(!call is (!call band 0x12345678 0xff) 0x00000078 "function band")
(!call is (!call bxor 0xa5a5f0f0 0xaa55ff00) 0x0ff00ff0 "function bxor")

(!call is (!call lshift 1 0) 1 "function lshift")
(!call is (!call lshift 1 8) 256)
(!call is (!call lshift 1 40) 256)
(!call is (!call rshift 256 8) 1 "function rshift")
(!call is (!call rshift -256 8) 16777215)
(!call is (!call arshift 256 8) 1 "function arshift")
(!call is (!call arshift -256 8) -1)

(!call is (!call rol 0x12345678 12) 0x45678123 "function rol")
(!call is (!call ror 0x12345678 12) 0x67812345 "function ror")

(!call is (!call bswap 0x12345678) 0x78563412 "function bswap")
(!call is (!call bswap 0x78563412) 0x12345678)


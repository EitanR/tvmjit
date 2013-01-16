#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.

(!assign json (!call dofile "json/parser_peg.tp"))
(!assign parse (!index json "parse"))

(!assign (!index _G "no_duplicate") !false)
(!call dofile "../t/json/json_common.tp")


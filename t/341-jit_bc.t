#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;

(!call (!index tvm "dofile") "TAP.tp")

(!let plan plan)
(!let is is)
(!let type_ok type_ok)

(!call plan 6)

(!let bc (!call require "jit.bc"))
(!call type_ok bc "table" "jit.bc")

(!call type_ok (!index bc "on") "function" "function jit.bc.on")
(!call type_ok (!index bc "off") "function" "function jit.bc.off")
(!call type_ok (!index bc "start") "function" "function jit.bc.start")
(!call type_ok (!index bc "dump") "function" "function jit.bc.dump")
(!call type_ok (!index bc "line") "function" "function jit.bc.line")


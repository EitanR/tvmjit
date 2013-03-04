#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;

(!call (!index tvm "dofile") "TAP.tp")

(!let require require)

(!let plan plan)
(!let is is)
(!let type_ok type_ok)

(!call plan 3)

(!let ffi (!call require "ffi"))
(!call ok ffi "ffi loaded")
(!call type_ok ffi "table")

(!call (!index ffi "cdef") "\
int printf(const char *fmt, ...);\
")

(!call is (!call (!index (!index ffi "C") "printf") "#\tHello %s!\n" "world") 15 "printf")

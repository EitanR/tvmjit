#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;

(!call require "TAP")

(!let plan plan)
(!let is is)
(!let type_ok type_ok)

(!call plan 21)

(!call type_ok (!index jit "on") "function" "function jit.on")
(!call type_ok (!index jit "off") "function" "function jit.off")
(!call type_ok (!index jit "flush") "function" "function jit.flush")

(!call is (!index jit "version") "TvmJIT 0.0.1" "jit.version")
(!call is (!index jit "version_num") 1 "jit.version_num")

(!call type_ok (!index jit "os") "string" "jit.os")
(!call type_ok (!index jit "arch") "string" "jit.arch")

(!call type_ok (!index jit "opt") "table" "jit.opt")
(!call type_ok (!index (!index jit "opt") "start") "function" "function jit.opt.start")

(!call type_ok (!index jit "util") "table" "jit.util")
(!call type_ok (!index (!index jit "util") "funcbc") "function" "function jit.util.funcbc")
(!call type_ok (!index (!index jit "util") "funcinfo") "function" "function jit.util.funcinfo")
(!call type_ok (!index (!index jit "util") "funck") "function" "function jit.util.funck")
(!call type_ok (!index (!index jit "util") "funcuvname") "function" "function jit.util.funcuvname")
(!call type_ok (!index (!index jit "util") "ircalladdr") "function" "function jit.util.ircalladdr")
(!call type_ok (!index (!index jit "util") "traceexitstub") "function" "function jit.util.traceexitstub")
(!call type_ok (!index (!index jit "util") "traceinfo") "function" "function jit.util.traceinfo")
(!call type_ok (!index (!index jit "util") "traceir") "function" "function jit.util.traceir")
(!call type_ok (!index (!index jit "util") "tracek") "function" "function jit.util.tracek")
(!call type_ok (!index (!index jit "util") "tracemc") "function" "function jit.util.tracemc")
(!call type_ok (!index (!index jit "util") "tracesnap") "function" "function jit.util.tracesnap")


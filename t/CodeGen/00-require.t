#!/usr/bin/tvmjit
;
;   TvmJIT : <http://github.com/fperrad/tvmjit/>
;   Copyright (C) 2013 Francois Perrad.
;
;   Major portions taken verbatim or adapted from the lua-CodeGen library.
;   Copyright (c) 2010-2011 Francois Perrad
;

(!call require "TAP")

(!call plan 2)

(!let m (!call require "CodeGen"))
(!call type_ok m "table")

(!call is (!index m "_NAME") "CodeGen" "_NAME" )


----------------------------------------------------------------------------
-- LuaJIT x64 disassembler wrapper module.
--
-- Copyright (C) 2013 Francois Perrad.
--
-- Major portions taken verbatim or adapted from the LuaJIT.
-- Copyright (C) 2005-2013 Mike Pall.
-- Released under the MIT license.
----------------------------------------------------------------------------
-- This module just exports the 64 bit functions from the combined
-- x86/x64 disassembler module. All the interesting stuff is there.
------------------------------------------------------------------------------

local dis_x86 = require("jit.dis_x86")

return {
    create =    dis_x86.create64,
    disass =    dis_x86.disass64,
    regname =   dis_x86.regname64,
}

----------------------------------------------------------------------------
-- LuaJIT MIPSEL disassembler wrapper module.
--
-- Copyright (C) 2013 Francois Perrad.
--
-- Major portions taken verbatim or adapted from the LuaJIT.
-- Copyright (C) 2005-2012 Mike Pall.
-- Released under the MIT license.
----------------------------------------------------------------------------
-- This module just exports the little-endian functions from the
-- MIPS disassembler module. All the interesting stuff is there.
------------------------------------------------------------------------------

local dis_mips = require("jit.dis_mips")

return {
    create =    dis_mips.create_el,
    disass =    dis_mips.disass_el,
    regname =   dis_mips.regname,
}

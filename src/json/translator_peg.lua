
--
--  TvmJIT : <http://github.com/fperrad/tvmjit/>
--  Copyright (C) 2013 Francois Perrad.
--
--      see http://http://www.json.org/
--      see RFC 4627
--

local error = error
local loadstring = tvm.load
local tonumber = tonumber
local quote = tvm.quote
local wchar = tvm.wchar
local tconcat = table.concat
local peg = require 'lpeg'
local C = peg.C
local Cmt = peg.Cmt
local Cp = peg.Cp
local Cs = peg.Cs
local P = peg.P
local R = peg.R
local S = peg.S
local V = peg.V


local function find (patt)
    return P{ patt + (P(1) * V(1)) }
end

local function gsub (patt, repl)
    return Cs(((patt / repl) + P(1))^0)
end

local special = {
    ['"']  = '"',
    ['\\'] = '\\',
    ['/']  = '/',
    ['b']  = "\b",
    ['f']  = "\f",
    ['n']  = "\n",
    ['r']  = "\r",
    ['t']  = "\t",
}

local xdigit = R('09', 'AF', 'af')
local escape_xdigit = P'\\u' * C(xdigit * xdigit * xdigit * xdigit)
local gsub_escape_xdigit = gsub(escape_xdigit, function (s) return wchar(tonumber(s, 16)) end)
local escape_special = P'\\' * C(S'"\\/bfnrt')
local gsub_escape_special = gsub(escape_special, special)
local escape_illegal = P'\\' * (P(1) - S'"\\/bfnrtu')
local find_escape_illegal = find(escape_illegal)

local function unescape (str)
    if find_escape_illegal:match(str) then
        error "illegal escape sequence"
    end
    return gsub_escape_special:match(gsub_escape_xdigit:match(str))
end


local buffer

local g = P {
    'json';
    json    = (V'object'
             + V'array'
             + Cmt(P(0), function ()
                            error("object/array expected at top")
                         end))
            * (P(-1)
             + Cmt(Cp(), function (s, pos)
                            error("<eos> expected at " .. pos)
                         end)),
    value   = V'_false'
            + V'null'
            + V'_true'
            + V'object'
            + V'array'
            + V'number'
            + V'string'
            + Cmt(Cp() * -V'end_array', function (s, pos)
                                            error("unexpected character at " .. pos)
                                        end),
    object  = V'begin_object' / function () buffer[#buffer+1] = '(\n' end
            * (V'member'
             * ((V'value_separator'
               + Cmt(Cp() * -V'end_object', function (s, pos)
                                                error("',' expected at " .. pos)
                                            end) * 1)
              * V'member')^0)^-1
            * V'end_object' / function () buffer[#buffer+1] = ')' end,
    member  = (V'string'
             + Cmt(Cp() * -V'end_object', function (s, pos)
                                                error("<string> expected at " .. pos)
                                          end))
            * ((V'name_separator' / function () buffer[#buffer+1] = ': ' end)
             + Cmt(Cp(), function (s, pos)
                            error("':' expected at " .. pos)
                         end))
            * V'value'
            * P(0) / function () buffer[#buffer+1] = '\n' end,
    array   = (V'begin_array' / function () buffer[#buffer+1] = '( ' end)
            * (V'value'
             * (((V'value_separator' / function () buffer[#buffer+1] = ' ' end)
               + Cmt(Cp() * -V'end_array', function (s, pos)
                                                error("',' expected at " .. pos)
                                           end) * 1)
              * V'value')^0)^-1
            * (V'end_array' / function () buffer[#buffer+1] = ' )' end),

    _false  = P'false' / function () buffer[#buffer+1] = '!false' end,
    null    = P'null' / function () buffer[#buffer+1] = '!nil' end,
    _true   = P'true' / function () buffer[#buffer+1] = '!true' end,

    number  = C(P'-'^-1 * V'int' * V'frac'^-1 * V'exp'^-1) /
                function (s) buffer[#buffer+1] = s end,
    int     = P'0' + (R'19' * R'09'^0),
    frac    = P'.' * R'09'^1,
    exp     = S'Ee' * S'-+'^-1 * R'09'^1,

    string  = P'"'
            * (((V'char'^0 / unescape) / quote) / function (s) buffer[#buffer+1] = s end)
            * P'"',
    char    = P'\\\\' + P'\\"' + (P(1) - P'"' - R'\0\31'),

    begin_array     = V'ws' * P'[' * V'ws',
    begin_object    = V'ws' * P'{' * V'ws',
    end_array       = V'ws' * P']' * V'ws',
    end_object      = V'ws' * P'}' * V'ws',
    name_separator  = V'ws' * P':' * V'ws',
    value_separator = V'ws' * P',' * V'ws',
    ws              = S" \t\n\r"^0,
}

local function translate (s)
    buffer = { '(!return ' }
    g:match(s)
    buffer[#buffer+1] = ')'
    return tconcat(buffer)
end

local function parse (s)
    local code = translate(s)
    local f, msg = loadstring(code)
    if msg then
        error(msg)
    end
    return f()
end

return {
    parse = parse,
    translate = translate,
}


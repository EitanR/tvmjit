
--
--  TvmJIT : <http://github.com/fperrad/tvmjit/>
--  Copyright (C) 2013 Francois Perrad.
--
--      see http://http://www.json.org/
--      see RFC 4627
--

local peg = require 'lpeg'
local P = peg.P
local R = peg.R
local S = peg.S
local V = peg.V

local g = P {
    'json';
    json    = V'object'
            + V'array',
    value   = V'_false'
            + V'null'
            + V'_true'
            + V'object'
            + V'array'
            + V'number'
            + V'string',
    object  = V'begin_object'
            * (V'member' * (V'value_separator' * V'member')^0)^-1
            * V'end_object',
    member  = V'string' * V'name_separator' * V'value',
    array   = V'begin_array'
            * (V'value' * (V'value_separator' * V'value')^0)^-1
            * V'end_array',

    _false  = P'false',
    null    = P'null',
    _true   = P'true',

    number  = P'-'^-1 * V'int' * V'frac'^-1 * V'exp'^-1,
    int     = P'0' + (R'19' * R'09'^0),
    frac    = P'.' * R'09'^1,
    exp     = S'Ee' * S'-+'^-1 * R'09'^1,

    string  = P'"' * V'char'^0 * P'"',
    char    = P'\\\\' + P'\\"' + (P(1) - P'"' - R'\0\31'),

    begin_array     = V'ws' * P'[' * V'ws',
    begin_object    = V'ws' * P'{' * V'ws',
    end_array       = V'ws' * P']' * V'ws',
    end_object      = V'ws' * P'}' * V'ws',
    name_separator  = V'ws' * P':' * V'ws',
    value_separator = V'ws' * P',' * V'ws',
    ws              = S" \t\n\r"^0,
}

return {
    parse = function (s)
                return g:match(s) == #s+1
            end
}


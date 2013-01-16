
--
--  TvmJIT : <http://github.com/fperrad/tvmjit/>
--  Copyright (C) 2013 Francois Perrad.
--
--      see http://http://www.json.org/
--      see RFC 4627
--

local peg = peg
local any = peg.any
local choice = peg.choice
local except = peg.except
local grammar = peg.grammar
local literal = peg.literal
local optional = peg.optional
local many = peg.many
local range = peg.range
local sequence = peg.sequence
local set = peg.set
local some = peg.some
local variable = peg.variable


local g = grammar {
    'json';
    json    = choice(variable'object',
                     variable'array'),
    value   = choice(variable'_false',
                     variable'null',
                     variable'_true',
                     variable'object',
                     variable'array',
                     variable'number',
                     variable'string'),
    object  = sequence(variable'begin_object',
                       optional(sequence(variable'member',
                                         many(sequence(variable'value_separator',
                                                       variable'member')))),
                       variable'end_object'),
    member  = sequence(variable'string',
                       variable'name_separator',
                       variable'value'),
    array   = sequence(variable'begin_array',
                       optional(sequence(variable'value',
                                         many(sequence(variable'value_separator',
                                                       variable'value')))),
                       variable'end_array'),

    _false  = literal'false',
    null    = literal'null',
    _true   = literal'true',

    number  = sequence(optional(literal'-'),
                       variable'int',
                       optional(variable'frac'),
                       optional(variable'exp')),
    int     = choice(literal'0', sequence(range'19', many(range'09'))),
    frac    = sequence(literal'.', some(range'09')),
    exp     = sequence(set'Ee', optional(set'-+'), some(range'09')),

    string  = sequence(literal'"', many(variable'char'), literal'"'),
    char    = choice(literal'\\\\', literal'\\"', except(any(), literal'"', range'\0\31')),

    begin_array     = sequence(variable'ws', literal'[', variable'ws'),
    begin_object    = sequence(variable'ws', literal'{', variable'ws'),
    end_array       = sequence(variable'ws', literal']', variable'ws'),
    end_object      = sequence(variable'ws', literal'}', variable'ws'),
    name_separator  = sequence(variable'ws', literal':', variable'ws'),
    value_separator = sequence(variable'ws', literal',', variable'ws'),
    ws              = many(set" \t\n\r"),
}

return {
    parse = function (s)
                return g:match(s) == #s
            end
}


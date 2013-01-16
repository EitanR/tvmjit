
--
--  TvmJIT : <http://github.com/fperrad/tvmjit/>
--  Copyright (C) 2013 Francois Perrad.
--
--      see http://http://www.json.org/
--      see RFC 4627
--

local peg = peg
local error = error
local tonumber = tonumber
local rawset = rawset
local wchar = string.wchar
local any = peg.any
local capture = peg.capture
local choice = peg.choice
local empty = peg.empty
local eos = peg.eos
local except = peg.except
local fold = peg.fold
local grammar = peg.grammar
local group = peg.group
local literal = peg.literal
local optional = peg.optional
local position = peg.position
local many = peg.many
local matchtime = peg.matchtime
local not_followed_by = peg.not_followed_by
local range = peg.range
local replace = peg.replace
local sequence = peg.sequence
local set = peg.set
local some = peg.some
local subst = peg.subst
local table = peg.table
local variable = peg.variable


local function find (patt)
    return grammar{ choice(patt, sequence(any(), variable(0))) }
end

local function gsub (patt, repl)
    return subst(many(choice(replace(patt, repl), any())))
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

local xdigit = range('09', 'AF', 'af')
local escape_xdigit = sequence(literal'\\u', capture(sequence(xdigit, xdigit, xdigit, xdigit)))
local gsub_escape_xdigit = gsub(escape_xdigit, function (s) return wchar(tonumber(s, 16)) end)
local escape_special = sequence(literal'\\', capture(set'"\\/bfnrt'))
local gsub_escape_special = gsub(escape_special, special)
local escape_illegal = sequence(literal'\\', except(any(), set'"\\/bfnrtu'))
local find_escape_illegal = find(escape_illegal)

local function unescape (str)
    if find_escape_illegal:match(str) then
        error "illegal escape sequence"
    end
    return gsub_escape_special:match(gsub_escape_xdigit:match(str))
end

local g = grammar {
    'json';
    json    = sequence(choice(variable'object',
                              variable'array',
                              matchtime(empty(), function ()
                                                     error("object/array expected at top")
                                                 end)),
                       choice(eos(),
                              matchtime(position(), function (s, pos)
                                                        error("<eos> expected at " .. pos)
                                                    end))),
    value   = choice(variable'_false',
                     variable'null',
                     variable'_true',
                     variable'object',
                     variable'array',
                     variable'number',
                     variable'string',
                     matchtime(sequence(position(),
                                        not_followed_by(variable'end_array')),
                               function (s, pos)
                                   error("unexpected character at " .. pos)
                               end)),
    object  = fold(sequence(table(variable'begin_object'),
                            optional(sequence(variable'member',
                                              many(sequence(choice(variable'value_separator',
                                                                   matchtime(sequence(position(),
                                                                                      not_followed_by(variable'end_object')),
                                                                             function (s, pos)
                                                                                 error("',' expected at " .. pos)
                                                                             end)),
                                                            variable'member')))),
                            variable'end_object'),
                   function (t, k, v)
                       if t[k] then
                           error("duplicated key " .. k)
                       end
                       return rawset(t, k, v)
                   end),
    member  = group(sequence(choice(variable'string',
                                    matchtime(sequence(position(),
                                                       not_followed_by(variable'end_object')),
                                              function (s, pos)
                                                  error("<string> expected at " .. pos)
                                              end)),
                             choice(variable'name_separator',
                                    matchtime(position(), function (s, pos)
                                                              error("':' expected at " .. pos)
                                                          end)),
                             variable'value')),
    array   = table(sequence(variable'begin_array',
                             optional(sequence(variable'value',
                                               many(sequence(choice(variable'value_separator',
                                                                    matchtime(sequence(position(),
                                                                                       not_followed_by(variable'end_array')),
                                                                              function (s, pos)
                                                                                  error("',' expected at " .. pos)
                                                                              end)),
                                                             variable'value')))),
                             variable'end_array')),

    _false  = replace(literal'false', function () return false end),
    null    = replace(literal'null', function () return nil end),
    _true   = replace(literal'true', function () return true end),

    number  = replace(capture(sequence(optional(literal'-'),
                                       variable'int',
                                       optional(variable'frac'),
                                       optional(variable'exp'))),
                      tonumber),
    int     = choice(literal'0', sequence(range'19', many(range'09'))),
    frac    = sequence(literal'.', some(range'09')),
    exp     = sequence(set'Ee', optional(set'-+'), some(range'09')),

    string  = sequence(literal'"', replace(many(variable'char'), unescape), literal'"'),
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
                return g:match(s)
            end
}


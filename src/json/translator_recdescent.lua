
--
--  TvmJIT : <http://github.com/fperrad/tvmjit/>
--  Copyright (C) 2013 Francois Perrad.
--
--      see http://http://www.json.org/
--      see RFC 4627
--

local peg = peg
local error = error
local loadstring = load
local tonumber = tonumber
local quote = string.quote
local wchar = string.wchar
local tconcat = table.concat
local any = peg.any
local capture = peg.capture
local choice = peg.choice
local eos = peg.eos
local except = peg.except
local grammar = peg.grammar
local literal = peg.literal
local optional = peg.optional
local position = peg.position
local many = peg.many
local range = peg.range
local replace = peg.replace
local sequence = peg.sequence
local set = peg.set
local some = peg.some
local subst = peg.subst
local variable = peg.variable


local ws = many(set" \t\n\r")
local eos = sequence(ws, eos())
local capt_true = sequence(ws, capture(literal'true'), position())
local capt_false = sequence(ws, capture(literal'false'), position())
local capt_null = sequence(ws, capture(literal'null'), position())
local capt_open_bracket = sequence(ws, capture(literal'['), position())
local capt_close_bracket = sequence(ws, capture(literal']'), position())
local capt_open_brace = sequence(ws, capture(literal'{'), position())
local capt_close_brace = sequence(ws, capture(literal'}'), position())
local capt_quote = sequence(ws, capture(literal'"'), position())
local capt_comma = sequence(ws, capture(literal','), position())
local capt_colon = sequence(ws, capture(literal':'), position())
local digit = range'09'
local int = choice(literal'0', sequence(range'19', many(digit)))
local frac = sequence(literal'.', some(digit))
local exp = sequence(set'Ee', optional(set'-+'), some(digit))
local number = sequence(optional(literal'-'), int, optional(frac), optional(exp))
local capt_number = sequence(ws, capture(number), position())

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

local double_quote = literal'"'
local ch = choice(literal'\\\\', literal'\\"', except(any(), double_quote, range'\0\31'))
local capt_string = sequence(ws, double_quote, replace(replace(many(ch), unescape), quote), double_quote, position())

local translate_value

local function translate_object (s, pos, buffer)
    local exist = {}
    local _, posn = capt_close_brace:match(s, pos)
    if posn then
        buffer[#buffer] = '()'
        return posn
    end
    buffer[#buffer] = '(\n'
    posn = pos
    while true do
        local key, posk = capt_string:match(s, posn)
        if not posk then
            error("<string> expected at " .. posn)
        end
        if exist[key] then
            error("duplicated key " .. key)
        end
        exist[key] = true
        _, posn = capt_colon:match(s, posk)
        if not posn then
            error("':' expected at " .. pos)
        end
        buffer[#buffer] = key
        buffer[#buffer] = ': '
        local posv = translate_value(s, posn, buffer)
        _, posn = capt_close_brace:match(s, posv)
        if posn then
            buffer[#buffer] = '\n)'
            return posn
        end
        _, posn = capt_comma:match(s, posv)
        if not posn then
            error("',' expected at " .. pos)
        end
        buffer[#buffer] = '\n'
    end
end

local function translate_array (s, pos, buffer)
    local _, posn = capt_close_bracket:match(s, pos)
    if posn then
        buffer[#buffer] = '()'
        return posn
    end
    buffer[#buffer] = '( '
    posn = pos
    while true do
        local posv = translate_value(s, posn, buffer)
        _, posn = capt_close_bracket:match(s, posv)
        if posn then
            buffer[#buffer] = ' )'
            return posn
        end
        _, posn = capt_comma:match(s, posv)
        if not posn then
            error("',' expected at " .. pos)
        end
        buffer[#buffer] = ' '
    end
end

function translate_value (s, pos, buffer)
    local _, posn = capt_false:match(s, pos)
    if posn then
        buffer[#buffer] = '!false'
        return posn
    end
    _, posn = capt_null:match(s, pos)
    if posn then
        buffer[#buffer] = '!nil'
        return posn
    end
    _, posn = capt_true:match(s, pos)
    if posn then
        buffer[#buffer] = '!true'
        return posn
    end
    _, posn = capt_open_brace:match(s, pos)
    if posn then
        return translate_object(s, posn, buffer)
    end
    _, posn = capt_open_bracket:match(s, pos)
    if posn then
        return translate_array(s, posn, buffer)
    end
    local capt, posn = capt_number:match(s, pos)
    if posn then
        buffer[#buffer] = capt
        return posn
    end
    capt, posn = capt_string:match(s, pos)
    if posn then
        buffer[#buffer] = capt
        return posn
    end
    error("unexpected character at " .. pos)
end

local function translate_json (s, pos, buffer)
    local _, posn = capt_open_brace:match(s, pos)
    if posn then
        return translate_object(s, posn, buffer)
    end
    _, posn = capt_open_bracket:match(s, pos)
    if posn then
        return translate_array(s, posn, buffer)
    end
    error("object/array expected at top")
end

local function translate (s)
    local buffer = { '(!return ' }
    local pos = translate_json(s, 0, buffer)
    if not eos:match(s, pos) then
        error("<eos> expected at " .. pos)
    end
    buffer[#buffer] = ')'
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


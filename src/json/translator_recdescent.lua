
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
local Cp = peg.Cp
local Cs = peg.Cs
local P = peg.P
local R = peg.R
local S = peg.S
local V = peg.V


local ws = S" \t\n\r"^0
local eos = ws * P(-1)
local capt_true = ws * C(P'true') * Cp()
local capt_false = ws * C(P'false') * Cp()
local capt_null = ws * C(P'null') * Cp()
local capt_open_bracket = ws * C(P'[') * Cp()
local capt_close_bracket = ws * C(P']') * Cp()
local capt_open_brace = ws * C(P'{') * Cp()
local capt_close_brace = ws * C(P'}') * Cp()
local capt_quote = ws * C(P'"') * Cp()
local capt_comma = ws * C(P',') * Cp()
local capt_colon = ws * C(P':') * Cp()
local digit = R'09'
local int = P'0' + (R'19' * digit^0)
local frac = P'.' * digit^1
local exp = S'Ee' * S'-+'^-1 * digit^1
local number = P'-'^-1 * int * frac^-1 * exp^-1
local capt_number = ws * C(number) * Cp()

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

local double_quote = P'"'
local ch = P'\\\\' + P'\\"' + (P(1) - double_quote - R'\0\31')
local capt_string = ws * double_quote * ((ch^0) / unescape) / quote * double_quote * Cp()

local translate_value

local function translate_object (s, pos, buffer)
    local exist = {}
    local _, posn = capt_close_brace:match(s, pos)
    if posn then
        buffer[#buffer+1] = '()'
        return posn
    end
    buffer[#buffer+1] = '(\n'
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
        buffer[#buffer+1] = key
        buffer[#buffer+1] = ': '
        local posv = translate_value(s, posn, buffer)
        _, posn = capt_close_brace:match(s, posv)
        if posn then
            buffer[#buffer+1] = '\n)'
            return posn
        end
        _, posn = capt_comma:match(s, posv)
        if not posn then
            error("',' expected at " .. pos)
        end
        buffer[#buffer+1] = '\n'
    end
end

local function translate_array (s, pos, buffer)
    local _, posn = capt_close_bracket:match(s, pos)
    if posn then
        buffer[#buffer+1] = '()'
        return posn
    end
    buffer[#buffer+1] = '( '
    posn = pos
    while true do
        local posv = translate_value(s, posn, buffer)
        _, posn = capt_close_bracket:match(s, posv)
        if posn then
            buffer[#buffer+1] = ' )'
            return posn
        end
        _, posn = capt_comma:match(s, posv)
        if not posn then
            error("',' expected at " .. pos)
        end
        buffer[#buffer+1] = ' '
    end
end

function translate_value (s, pos, buffer)
    local _, posn = capt_false:match(s, pos)
    if posn then
        buffer[#buffer+1] = '!false'
        return posn
    end
    _, posn = capt_null:match(s, pos)
    if posn then
        buffer[#buffer+1] = '!nil'
        return posn
    end
    _, posn = capt_true:match(s, pos)
    if posn then
        buffer[#buffer+1] = '!true'
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
        buffer[#buffer+1] = capt
        return posn
    end
    capt, posn = capt_string:match(s, pos)
    if posn then
        buffer[#buffer+1] = capt
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
    local pos = translate_json(s, 1, buffer)
    if not eos:match(s, pos) then
        error("<eos> expected at " .. pos)
    end
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


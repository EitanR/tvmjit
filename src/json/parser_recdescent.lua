
--
--  TvmJIT : <http://github.com/fperrad/tvmjit/>
--  Copyright (C) 2013 Francois Perrad.
--
--      see http://http://www.json.org/
--      see RFC 4627
--

local error = error
local tonumber = tonumber
local wchar = tvm.wchar
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
local capt_number = ws * (number / tonumber) * Cp()

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

local quote = P'"'
local ch = P'\\\\' + P'\\"' + (P(1) - quote - R'\0\31')
local capt_string = ws * quote * ((ch^0) / unescape) * quote * Cp()

local parse_value

local function parse_object (s, pos)
    local result = {}
    local _, posn = capt_close_brace:match(s, pos)
    if posn then
        return result, posn
    end
    posn = pos
    while true do
        local key, posk = capt_string:match(s, posn)
        if not posk then
            error("<string> expected at " .. posn)
        end
        if result[key] then
            error("duplicated key " .. key)
        end
        _, posn = capt_colon:match(s, posk)
        if not posn then
            error("':' expected at " .. pos)
        end
        local val, posv = parse_value(s, posn)
        result[key] = val
        _, posn = capt_close_brace:match(s, posv)
        if posn then
            return result, posn
        end
        _, posn = capt_comma:match(s, posv)
        if not posn then
            error("',' expected at " .. pos)
        end
    end
end

local function parse_array (s, pos)
    local result = {}
    local _, posn = capt_close_bracket:match(s, pos)
    if posn then
        return result, posn
    end
    posn = pos
    local n = 0
    while true do
        local val, posv = parse_value(s, posn)
        result[n] = val
        n = n + 1
        _, posn = capt_close_bracket:match(s, posv)
        if posn then
            return result, posn
        end
        _, posn = capt_comma:match(s, posv)
        if not posn then
            error("',' expected at " .. pos)
        end
    end
end

function parse_value (s, pos)
    local _, posn = capt_false:match(s, pos)
    if posn then
        return false, posn
    end
    _, posn = capt_null:match(s, pos)
    if posn then
        return nil, posn
    end
    _, posn = capt_true:match(s, pos)
    if posn then
        return true, posn
    end
    _, posn = capt_open_brace:match(s, pos)
    if posn then
        return parse_object(s, posn)
    end
    _, posn = capt_open_bracket:match(s, pos)
    if posn then
        return parse_array(s, posn)
    end
    local capt, posn = capt_number:match(s, pos)
    if posn then
        return capt, posn
    end
    capt, posn = capt_string:match(s, pos)
    if posn then
        return capt, posn
    end
    error("unexpected character at " .. pos)
end

local function parse_json (s, pos)
    local _, posn = capt_open_brace:match(s, pos)
    if posn then
        return parse_object(s, posn)
    end
    _, posn = capt_open_bracket:match(s, pos)
    if posn then
        return parse_array(s, posn)
    end
    error("object/array expected at top")
end

local function parse (s)
    local result, pos = parse_json(s, 1)
    if not eos:match(s, pos) then
        error("<eos> expected at " .. pos)
    end
    return result
end

return {
    parse = parse
}


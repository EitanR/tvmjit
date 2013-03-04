
--
--  TvmJIT : <http://github.com/fperrad/tvmjit/>
--  Copyright (C) 2013 Francois Perrad.
--

local _G = _G
local arg = arg
local assert = assert
local error = error
local tonumber = tonumber
local print = print
local char = string.char
local quote = tvm.quote
local tconcat = table.concat
local peg = require 'lpeg'
local locale = peg.locale()
local C = peg.C
local Cb = peg.Cb
local Cg = peg.Cg
local Cmt = peg.Cmt
local Cp = peg.Cp
local Cs = peg.Cs
local P = peg.P
local R = peg.R
local S = peg.S


local lineno
local function inc_lineno (s)
    local _, n = string.gsub(s, '\n', '')
    lineno = lineno + n
end

local function syntaxerror (err)
    error(err .. " at " .. lineno)
end

local bom = P"\xEF\xBB\xBF"
local hspace = S' \t'
local ch_ident = R('09', 'AZ', 'az', '__')

local identifier = R('AZ', 'az', '__') * ch_ident^0
local capt_identifier = C(identifier) * Cp()

local ws; do
    local pod_begin = S'\n\r' * P'=begin'
    local pod_end = S'\n\r' * P'=end'
    local open = pod_begin * hspace^1 * Cg(identifier, 'name')
    local close = pod_end * hspace^1 C(identifier)
    local closeeq = Cmt(close * Cb'name', function (s, n, a, b) return a == b end)
    local pod_comment = (open * (P(1) - closeeq)^0 * close)
                      + (pod_begin * (P(1) - pod_end)^0 * pod_end)
    local comment = P'#' * (P(1) - P'\n')^0
    ws = (S' \f\t\r\v'
        + (pod_comment / inc_lineno)
        + (P'\n' / inc_lineno)
        + comment)^0
end
local capt_ws = C(ws) * Cp()

local number; do
    local binint = R'01'^1 * (P'_' + R'01'^1)^0
    local octint = R'07'^1 * (P'_' + R'07'^1)^0
    local decint = locale.digit^1 * (P'_' + locale.digit^1)^0
    local hexint = locale.xdigit^1 * (P'_' + locale.xdigit^1)^0
    local integer = (P'0' * (P'b' * P'_'^-1 * (binint / function (s) return tonumber((s:gsub('_', '')), 2) end)
                           + P'o' * P'_'^-1 * (octint / function (s) return tonumber((s:gsub('_', '')), 8) end)
                           + P'x' * P'_'^-1 * (hexint / function (s) return tonumber((s:gsub('_', '')), 16) end)
                           + P'd' * P'_'^-1 * (decint / function (s) return tonumber((s:gsub('_', '')), 10) end)))
                  + (decint / function (s) return tonumber((s:gsub('_', ''))) end)
    local escale = S'Ee' * S'+-'^-1 * decint
    local dec_number = (P'.' * decint * escale^-1)
                     + (decint * P'.' * decint * escale^-1)
                     + (decint * escale)
    number = (P'NaN' / function () return 0/0 end)
           + (P'Inf' / function () return 1/0 end)
           + (dec_number / function (s) return tonumber((s:gsub('_',''))) end)
           + integer
end
local capt_number = number * Cp()

local tok_string; do
    local function gsub (patt, repl)
        return Cs(((patt / repl) + P(1))^0)
    end

    local special = {
        ["'"]  = "'",
        ['"']  = '"',
        ['\\'] = '\\',
        ['/']  = '/',
        ['a']  = "\a",      -- BELL
        ['b']  = "\b",      -- BACKSPACE
        ['e']  = "\x1B",    -- ESCAPE
        ['f']  = "\f",      -- FORM FEED
        ['n']  = "\n",      -- LINE FEED
        ['r']  = "\r",      -- CARRIAGE RETURN
        ['t']  = "\t",      -- TAB
    }

    local escape_special = P'\\' * C(S"'\"\\/abefnrt")
    local gsub_escape_special = gsub(escape_special, special)
    local escape_xdigit = P'\\x' * C(locale.xdigit * locale.xdigit)
    local gsub_escape_xdigit = gsub(escape_xdigit, function (s)
                                                        return char(tonumber(s, 16))
                                                   end)
    local escape_octal = P'\\o' * C(R'07' * R'07'^-1 * R'07'^-1)
    local gsub_escape_octal = gsub(escape_octal, function (s)
                                                        local n = tonumber(s, 8)
                                                        if n >= 256 then
                                                            syntaxerror("octal escape too large near " .. s)
                                                        end
                                                        return char(n)
                                                 end)
    local escape_decimal = P'\\c' * C(locale.digit * locale.digit^-1 * locale.digit^-1)
    local gsub_escape_decimal = gsub(escape_decimal, function (s)
                                                        local n = tonumber(s)
                                                        if n >= 256 then
                                                            syntaxerror("decimal escape too large near " .. s)
                                                        end
                                                        return char(n)
                                                     end)

    local function unescape (str)
        return gsub_escape_special:match(gsub_escape_xdigit:match(gsub_escape_octal:match(gsub_escape_decimal:match(str))))
    end

    local ch_dq = P'\\\\' + P'\\"' + (P(1) - P'"' - R'\0\31')
    local double_quote_string = (((P'"' * Cs(ch_dq^0) * P'"') / unescape) / quote)

    local ch_sq = (P"\\\\" / "\\") + (P"\\'" / "'") + (P(1) - P"'" - R'\0\31')
    local simple_quote_string = ((P"'" * Cs(ch_sq^0) * P"'") / quote)

    tok_string = simple_quote_string + double_quote_string
end
local capt_string = tok_string * Cp()


local tok_comma = P','
local capt_comma = C(tok_comma) * Cp()
local tok_left_paren = P'('
local capt_left_paren = C(tok_left_paren) * Cp()
local tok_right_paren = P')'
local capt_right_paren = C(tok_right_paren) * Cp()
local tok_semicolon = P';'
local capt_semicolon = C(tok_semicolon) * Cp()

local statement;
local simpleexpr;


local function skip_ws (s, pos)
    local capt, posn = capt_ws:match(s, pos)
    return posn
end


local function statlist (s, pos, buffer)
    -- statlist -> { stat `;' }
    pos = skip_ws(s, pos)
    while not P(-1):match(s, pos) do
        buffer[#buffer+1] = '\n'
        pos = statement(s, pos, buffer)
        pos = skip_ws(s, pos)
        local capt, posn = capt_semicolon:match(s, pos)
        if not posn then
            syntaxerror "; expected"
        end
        pos = skip_ws(s, posn)
    end
    return pos
end


local function explist (s, pos, buffer)
    -- explist -> expr { `,' expr }
    pos = simpleexpr(s, pos, buffer)
    pos = skip_ws(s, pos)
    local capt, posn = capt_comma:match(s, pos)
    while posn do
        buffer[#buffer+1] = ' '
        pos = skip_ws(s, posn)
        pos = simpleexpr(s, pos, buffer)
        pos = skip_ws(s, pos)
        capt, posn = capt_comma:match(s, pos)
    end
    return pos
end


local function funcargs (s, pos, buffer)
    -- funcargs -> `(' [ explist ] `)'
    local capt, posn = capt_left_paren:match(s, pos)
    if posn then
        pos = skip_ws(s, posn)
        capt, posn = capt_right_paren:match(s, pos)
        if posn then
            return posn
        end
        pos = explist(s, pos, buffer)
        capt, posn = capt_right_paren:match(s, pos)
        if posn then
            return posn
        else
            syntaxerror ") expected"
        end
    end
    syntaxerror "function arguments expected"
end


function simpleexpr (s, pos, buffer, one)
    -- simpleexp -> NUMBER | STRING
    local capt, posn = capt_number:match(s, pos)
    if posn then
        if capt ~= capt then
            buffer[#buffer+1] = '(!div 0 0)'
        elseif capt == 1/0 then
            buffer[#buffer+1] = '(!div 1 0)'
        else
            buffer[#buffer+1] = tostring(capt)
        end
        return posn
    end
    capt, posn = capt_string:match(s, pos)
    if posn then
        buffer[#buffer+1] = capt
        return posn
    end
    syntaxerror "P expected"
end


local function callstat (s, pos, buffer)
    local lineno = lineno
    pos = skip_ws(s, pos)
    buffer[#buffer+1] = '(!line '
    buffer[#buffer+1] = lineno
    buffer[#buffer+1] = ')'
    capt, posn = capt_identifier:match(s, pos)
    if not posn then
        syntaxerror "identifier expected"
    end
    buffer[#buffer+1] = '(!call '
    buffer[#buffer+1] = capt
    buffer[#buffer+1] = ' ('
    pos = funcargs(s, posn, buffer)
    buffer[#buffer+1] = '))'
    return pos
end


function statement (s, pos, buffer)
    return callstat(s, pos, buffer)
end


local prelude = [[
(!line "@prelude(nqp/translator.lua)" 1)

(!let stringify (!lambda (v)
                (!return (!call tostring v))))

(!let print (!lambda (a)
                (!let out (!index io "stdout"))
                (!loop i 0 (!sub (!len a) 1) 1
                        (!callmeth out write (!call stringify (!index a i))))))

(!let say (!lambda (a)
                (!let out (!index io "stdout"))
                (!loop i 0 (!sub (!len a) 1) 1
                        (!callmeth out write (!call stringify (!index a i))))
                (!callmeth out write "\n")))

]]

local function translate (s, fname)
    local pos = (bom * Cp()):match(s, 1) or 1
    lineno = 1
    local buffer = { prelude, '(!line ', quote(fname), ' ', lineno, ')' }
    pos = statlist(s, pos, buffer)
    if not P(-1):match(s, pos) then
        syntaxerror("<eof> expected at " .. pos)
    end
    buffer[#buffer+1] = "\n; end of generation"
    return tconcat(buffer)
end


local fname = arg and arg[1]
if fname then
    local f, msg = _G.io.open(fname, 'r')
    if not f then
        error(msg)
    end
    local s = f:read'*a'
    f:close()
    local code = translate(s, '@' .. fname)
    print(code)
else
    return translate
end

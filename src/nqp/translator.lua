
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
local quote = string.quote
local tconcat = table.concat
local any = peg.any
local backref = peg.backref
local capture = peg.capture
local choice = peg.choice
local not_followed_by = peg.not_followed_by
local eos = peg.eos()
local except = peg.except
local group = peg.group
local locale = peg.locale()
local literal = peg.literal
local many = peg.many
local matchtime = peg.matchtime
local optional = peg.optional
local position = peg.position()
local range = peg.range
local replace = peg.replace
local sequence = peg.sequence
local set = peg.set
local some = peg.some
local subst = peg.subst


local lineno
local function inc_lineno (s)
    local _, n = string.gsub(s, '\n', '')
    lineno = lineno + n
end

local function syntaxerror (err)
    error(err .. " at " .. lineno)
end

local bom = literal"\xEF\xBB\xBF"
local hspace = set' \t'
local ch_ident = range('09', 'AZ', 'az', '__')

local identifier = sequence(range('AZ', 'az', '__'), many(ch_ident))
local capt_identifier = sequence(capture(identifier), position)

local ws; do
    local pod_begin = sequence(set'\n\r', literal'=begin')
    local pod_end = sequence(set'\n\r', literal'=end')
    local open = sequence(pod_begin, some(hspace), group(identifier, 'name'))
    local close = sequence(pod_end, some(hspace), capture(identifier))
    local closeeq = matchtime(sequence(close, backref'name'), function (s, n, a, b) return a == b end)
    local pod_comment = choice(sequence(open, many(except(any(), closeeq)), close),
                               sequence(pod_begin, many(except(any(), pod_end)), pod_end))
    local comment = sequence(literal'#', many(except(any(), literal'\n')))
    ws = many(choice(set' \f\t\r\v',
                     replace(pod_comment, inc_lineno),
                     replace(literal'\n', inc_lineno),
                     comment))
end
local capt_ws = sequence(capture(ws), position)

local number; do
    local binint = sequence(some(range'01'), many(choice(literal'_', some(range'01'))))
    local octint = sequence(some(range'07'), many(choice(literal'_', some(range'07'))))
    local decint = sequence(some(locale.digit), many(choice(literal'_', some(locale.digit))))
    local hexint = sequence(some(locale.xdigit), many(choice(literal'_', some(locale.xdigit))))
    local integer = choice(sequence(literal'0', choice(sequence(literal'b', optional(literal'_'), replace(binint, function (s) return tonumber((s:gsub('_', '')), 2) end)),
                                                       sequence(literal'o', optional(literal'_'), replace(octint, function (s) return tonumber((s:gsub('_', '')), 8) end)),
                                                       sequence(literal'x', optional(literal'_'), replace(hexint, function (s) return tonumber((s:gsub('_', '')), 16) end)),
                                                       sequence(literal'd', optional(literal'_'), replace(decint, function (s) return tonumber((s:gsub('_', '')), 10) end)))),
                           replace(decint, function (s) return tonumber((s:gsub('_', ''))) end))
    local escale = sequence(set'Ee', optional(set'+-'), decint)
    local dec_number = choice(sequence(literal'.', decint, optional(escale)),
                              sequence(decint, literal'.', decint, optional(escale)),
                              sequence(decint, escale))
    number = choice(replace(literal'NaN', function () return 0/0 end),
                    replace(literal'Inf', function () return 1/0 end),
                    replace(dec_number, function (s) return tonumber((s:gsub('_',''))) end),
                    integer)
end
local capt_number = sequence(number, position)

local tok_string; do
    local function gsub (patt, repl)
        return subst(many(choice(replace(patt, repl), any())))
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

    local escape_special = sequence(literal'\\', capture(set"'\"\\/abefnrt"))
    local gsub_escape_special = gsub(escape_special, special)
    local escape_xdigit = sequence(literal'\\x', capture(sequence(locale.xdigit, locale.xdigit)))
    local gsub_escape_xdigit = gsub(escape_xdigit, function (s)
                                                       return char(tonumber(s, 16))
                                                   end)
    local escape_octal = sequence(literal'\\o', capture(sequence(range'07', optional(range'07'), optional(range'07'))))
    local gsub_escape_octal = gsub(escape_octal, function (s)
                                                        local n = tonumber(s, 8)
                                                        if n >= 256 then
                                                            syntaxerror("octal escape too large near " .. s)
                                                        end
                                                        return char(n)
                                                    end)
    local escape_decimal = sequence(literal'\\c', capture(sequence(locale.digit, optional(locale.digit), optional(locale.digit))))
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

    local ch_dq = choice(literal'\\\\', literal'\\"', except(any(), literal'"', range'\0\31'))
    local double_quote_string = replace(replace(sequence(literal'"', subst(many(ch_dq)), literal'"'), unescape), quote)

    local ch_sq = choice(replace(literal"\\\\", "\\"), replace(literal"\\'", "'"), except(any(), literal"'", range'\0\31'))
    local simple_quote_string = replace(sequence(literal"'", subst(many(ch_sq)), literal"'"), quote)

    tok_string = choice(simple_quote_string, double_quote_string)
end
local capt_string = sequence(tok_string, position)


local tok_comma = literal','
local capt_comma = sequence(capture(tok_comma), position)
local tok_left_paren = literal'('
local capt_left_paren = sequence(capture(tok_left_paren), position)
local tok_right_paren = literal')'
local capt_right_paren = sequence(capture(tok_right_paren), position)
local tok_semicolon = literal';'
local capt_semicolon = sequence(capture(tok_semicolon), position)

local statement;
local simpleexpr;


local function skip_ws (s, pos)
    local capt, posn = capt_ws:match(s, pos)
    return posn
end


local function statlist (s, pos, buffer)
    -- statlist -> { stat `;' }
    pos = skip_ws(s, pos)
    while not eos:match(s, pos) do
        buffer[#buffer] = '\n'
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
        buffer[#buffer] = ' '
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
            buffer[#buffer] = '(!div 0 0)'
        elseif capt == 1/0 then
            buffer[#buffer] = '(!div 1 0)'
        else
            buffer[#buffer] = tostring(capt)
        end
        return posn
    end
    capt, posn = capt_string:match(s, pos)
    if posn then
        buffer[#buffer] = capt
        return posn
    end
    syntaxerror "literal expected"
end


local function callstat (s, pos, buffer)
    local lineno = lineno
    pos = skip_ws(s, pos)
    buffer[#buffer] = '(!line '
    buffer[#buffer] = lineno
    buffer[#buffer] = ')'
    capt, posn = capt_identifier:match(s, pos)
    if not posn then
        syntaxerror "identifier expected"
    end
    buffer[#buffer] = '(!call '
    buffer[#buffer] = capt
    buffer[#buffer] = ' ('
    pos = funcargs(s, posn, buffer)
    buffer[#buffer] = '))'
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
    local pos = sequence(bom, position):match(s, 0) or 0
    lineno = 1
    local buffer = { prelude, '(!line ', quote(fname), ' ', lineno, ')' }
    pos = statlist(s, pos, buffer)
    if not eos:match(s, pos) then
        syntaxerror("<eof> expected at " .. pos)
    end
    buffer[#buffer] = "\n; end of generation"
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

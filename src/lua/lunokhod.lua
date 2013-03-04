
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
local function inc_lineno ()
    lineno = lineno + 1
end
local function inc_lineno2 ()
    lineno = lineno + 0.5       -- called twice time ???
end
local function syntaxerror (err)
    error(err .. " at " .. lineno)
end

local bytecode = P"\27"
local bom = P"\xEF\xBB\xBF"
local shebang = P'#!' * (P(1) - S"\f\n\r")^0
local long_string; do
    local equals = P'=' ^0
    local open = P'[' * Cg(equals, 'init') * P'[' * (P"\n" / inc_lineno2)^-1
    local close = P']' * C(equals) * P']'
    local closeeq = Cmt(close * Cb'init', function (s, i, a, b) return a == b end)
    long_string = (open * C(((P"\n" / inc_lineno2) + (P(1) - closeeq))^0) * close) / quote
end
local ws; do
    local comment = P'--' * ((long_string / function () return end) + (P(1) - S"\f\n\r"))^0
    ws = (S" \f\t\r\v" + (P"\n" / inc_lineno) + comment)^0
end
local capt_ws = C(ws) * Cp()

local ch_ident = R('09', 'AZ', 'az', '__')
local tok_identifier; do
    local reserved = {
        ['and'] = true,
        ['break'] = true,
        ['do'] = true,
        ['else'] = true,
        ['elseif'] = true,
        ['end'] = true,
        ['false'] = true,
        ['for'] = true,
        ['function'] = true,
        ['goto'] = true,
        ['if'] = true,
        ['in'] = true,
        ['local'] = true,
        ['nil'] = true,
        ['not'] = true,
        ['or'] = true,
        ['repeat'] = true,
        ['return'] = true,
        ['then'] = true,
        ['true'] = true,
        ['until'] = true,
        ['while'] = true,
    }
    local check_reserved = function (tok)
        if not reserved[tok] then
            return tok
        end
    end
    tok_identifier = (R('AZ', 'az', '__') * ch_ident^0) / check_reserved
end
local capt_identifier = tok_identifier * Cp()

local tok_number; do
    local int = locale.digit^1
    local frac = P'.' * locale.digit^0
    local sign = S'-+'
    local exp = S'Ee' * sign^-1 * locale.digit^1
    local xint = P'0' * S'xX' * locale.xdigit^1
    local xfrac = P'.' * locale.xdigit^0
    local xexp = S'Pp' * sign^-1 * locale.digit^1
    tok_number = (xint * xfrac^-1 * xexp^-1) + (P'-'^-1 * int * frac^-1 * exp^-1)
end
local capt_number = C(tok_number) * Cp()

local tok_string; do
    local function gsub (patt, repl)
        return Cs(((patt / repl) + P(1))^0)
    end

    local special = {
        ["'"]  = "'",
        ['"']  = '"',
        ['\\'] = '\\',
        ['/']  = '/',
        ['a']  = "\a",
        ['b']  = "\b",
        ['f']  = "\f",
        ['n']  = "\n",
        ['r']  = "\r",
        ['t']  = "\t",
        ['v']  = "\v",
    }

    local escape_special = P'\\' * C(S"'\"\\/abfnrtv")
    local gsub_escape_special = gsub(escape_special, special)
    local escape_xdigit = P'\\x' * C(locale.xdigit * locale.xdigit)
    local gsub_escape_xdigit = gsub(escape_xdigit, function (s)
                                                        return char(tonumber(s, 16))
                                                   end)
    local escape_decimal = P'\\' * C(locale.digit * locale.digit^-1 * locale.digit^-1)
    local gsub_escape_decimal = gsub(escape_decimal, function (s)
                                                        local n = tonumber(s)
                                                        if n >= 256 then
                                                            syntaxerror("decimal escape too large near " .. s)
                                                        end
                                                        return char(n)
                                                     end)

    local unescape = function(str)
        return gsub_escape_special:match(gsub_escape_xdigit:match(gsub_escape_decimal:match(str)))
    end

    local zap = (P"\\z" * S"\n\r"^1 * locale.space^1) / ""
    local ch_sq = zap + P"\\\\" + P"\\'" + (P(1) - P"'" - R'\0\31')
    local ch_dq = zap + P'\\\\' + P'\\"' + (P(1) - P'"' - R'\0\31')
    local simple_quote_string = ((P"'" * Cs(ch_sq^0) * P"'") / unescape) / quote
    local double_quote_string = ((P'"' * Cs(ch_dq^0) * P'"') / unescape) / quote
    tok_string = simple_quote_string + double_quote_string + long_string
end
local capt_string = tok_string * Cp()


local not_ch_ident = -ch_ident
local tok_and = P'and' * not_ch_ident
local capt_and = C(tok_and) * Cp()
local tok_break = P'break' * not_ch_ident
local capt_break = C(tok_break) * Cp()
local tok_do = P'do' * not_ch_ident
local capt_do = C(tok_do) * Cp()
local tok_else = P'else' * not_ch_ident
local capt_else = C(tok_else) * Cp()
local tok_elseif = P'elseif' * not_ch_ident
local capt_elseif = C(tok_elseif) * Cp()
local tok_end = P'end' * not_ch_ident
local capt_end = C(tok_end) * Cp()
local tok_false = P'false' * not_ch_ident
local capt_false = C(tok_false) * Cp()
local tok_for = P'for' * not_ch_ident
local capt_for = C(tok_for) * Cp()
local tok_function = P'function' * not_ch_ident
local capt_function = C(tok_function) * Cp()
local tok_goto = P'goto' * not_ch_ident
local capt_goto = C(tok_goto) * Cp()
local tok_if = P'if' * not_ch_ident
local capt_if = C(tok_if) * Cp()
local tok_in = P'in' * not_ch_ident
local capt_in = C(tok_in) * Cp()
local tok_local = P'local' * not_ch_ident
local capt_local = C(tok_local) * Cp()
local tok_nil = P'nil' * not_ch_ident
local capt_nil = C(tok_nil) * Cp()
local tok_not = P'not' * not_ch_ident
local capt_not = C(tok_not) * Cp()
local tok_or = P'or' * not_ch_ident
local capt_or = C(tok_or) * Cp()
local tok_repeat = P'repeat' * not_ch_ident
local capt_repeat = C(tok_repeat) * Cp()
local tok_return = P'return' * not_ch_ident
local capt_return = C(tok_return) * Cp()
local tok_then = P'then' * not_ch_ident
local capt_then = C(tok_then) * Cp()
local tok_true = P'true' * not_ch_ident
local capt_true = C(tok_true) * Cp()
local tok_until = P'until' * not_ch_ident
local capt_until = C(tok_until) * Cp()
local tok_while = P'while' * not_ch_ident
local capt_while = C(tok_while) * Cp()


local tok_colon = P':'
local capt_colon = C(tok_colon) * Cp()
local tok_comma = P','
local capt_comma = C(tok_comma) * Cp()
local tok_dbcolon = P'::'
local capt_dbcolon = C(tok_dbcolon) * Cp()
local tok_dot = P'.' * -P'.'
local capt_dot = C(tok_dot) * Cp()
local tok_equal = P'='
local capt_equal = C(tok_equal) * Cp()
local tok_left_brace = P'{'
local capt_left_brace = C(tok_left_brace) * Cp()
local tok_left_bracket = P'[' * -P'[' * -P'='
local capt_left_bracket = C(tok_left_bracket) * Cp()
local tok_left_paren = P'('
local capt_left_paren = C(tok_left_paren) * Cp()
local tok_right_brace = P'}'
local capt_right_brace = C(tok_right_brace) * Cp()
local tok_right_bracket = P']'
local capt_right_bracket = C(tok_right_bracket) * Cp()
local tok_right_paren = P')'
local capt_right_paren = C(tok_right_paren) * Cp()
local tok_semicolon = P';'
local capt_semicolon = C(tok_semicolon) * Cp()
local tok_sel = S'.:'
local capt_sel = C(tok_sel) * Cp()
local tok_sep = S',;'
local capt_sep = C(tok_sep) * Cp()
local tok_vararg = P'...'
local capt_vararg = C(tok_vararg) * Cp()

local unopr = tok_not + P'-' + P'#'
local capt_unopr = C(unopr) * Cp()
local binopr = P'+' + P'-' + P'*' + P'/' + P'%' + P'^' + P'..' +
               P'~=' + P'==' + P'<=' + P'<' + P'>=' + P'>' + tok_and + tok_or
local capt_binopr = C(binopr) * Cp()


local statement;
local expr;


local function block_follow (s, pos, withuntil)
    if P'else':match(s, pos) then
        return true
    end
    if P'elseif':match(s, pos) then
        return true
    end
    if P'end':match(s, pos) then
        return true
    end
    if P(-1):match(s, pos) then
        return true
    end
    if P'until':match(s, pos) then
        return withuntil
    end
    return false
end


local function skip_ws (s, pos)
    local capt, posn = capt_ws:match(s, pos)
    return posn
end


local function statlist (s, pos, buffer)
    -- statlist -> { stat [`;'] }
    pos = skip_ws(s, pos)
    while not block_follow(s, pos, true) do
        buffer[#buffer+1] = '\n'
        if tok_return:match(s, pos) then
            return statement(s, pos, buffer)
        end
        pos = statement(s, pos, buffer)
        pos = skip_ws(s, pos)
    end
    return pos
end


local function fieldsel (s, pos, buffer)
    -- fieldsel -> ['.' | ':'] NAME
    local capt, posn = capt_sel:match(s, pos)
    assert(posn)
    pos = skip_ws(s, posn)
    capt, posn = capt_identifier:match(s, pos)
    if not posn then
        syntaxerror "<name> expected"
    end
    buffer[#buffer+1] = quote(capt)
    return posn
end


local function yindex (s, pos, buffer)
    -- index -> '[' expr ']'
    local capt, posn = capt_left_bracket:match(s, pos)
    assert(posn)
    pos = skip_ws(s, posn)
    pos = expr(s, pos, buffer, true)
    capt, posn = capt_right_bracket:match(s, pos)
    if not posn then
        syntaxerror "] expected"
    end
    return posn
end


local function recfield (s, pos, buffer)
    -- recfield -> (NAME | `['exp1`]') = exp1
    local capt, posn = capt_identifier:match(s, pos)
    if posn then
        buffer[#buffer+1] = '"'
        buffer[#buffer+1] = capt
        buffer[#buffer+1] = '"'
        pos = posn
    else
        pos = yindex(s, pos, buffer)
    end
    pos = skip_ws(s, pos)
    capt, posn = capt_equal:match(s, pos)
    if not posn then
        syntaxerror "= expected"
    end
    buffer[#buffer+1] = ': '
    pos = skip_ws(s, posn)
    return expr(s, pos, buffer, true)
end


local function listfield (s, pos, buffer, list)
    -- listfield -> exp
    if #list == 0 then
        buffer[#buffer+1] = '!nil '
        list[1] = true
    end
    return expr(s, pos, buffer)
end


local function field (s, pos, buffer, list)
    -- field -> listfield | recfield
    local capt, posn = capt_identifier:match(s, pos)
    if posn then
        if (ws * tok_equal):match(s, posn) then
            return recfield(s, pos, buffer)
        else
            return listfield(s, pos, buffer, list)
        end
    end
    if tok_left_bracket:match(s, pos) then
        return recfield(s, pos, buffer)
    end
    return listfield(s, pos, buffer, list)
end


local function constructor (s, pos, buffer)
    -- constructor -> '{' [ field { sep field } [sep] ] '}'
    local capt, posn = capt_left_brace:match(s, pos)
    if not posn then
        syntaxerror "{ expected"
    end
    buffer[#buffer+1] = '('
    pos = skip_ws(s, posn)
    local list = {}
    repeat
        if tok_right_brace:match(s, pos) then
            break
        end
        pos = field(s, pos, buffer, list)
        pos = skip_ws(s, pos)
        capt, posn = capt_sep:match(s, pos)
        if posn then
            buffer[#buffer+1] = ' '
            pos = skip_ws(s, posn)
        end
    until not posn
    capt, posn = capt_right_brace:match(s, pos)
    if not posn then
        syntaxerror "} expected"
    end
    buffer[#buffer+1] = ')'
    return posn
end


local function parlist (s, pos, buffer, ismethod)
    -- parlist -> [ param { `,' param } ]
    -- param -> NAME | `...'
    if ismethod then
        buffer[#buffer+1] = 'self'
    end
    if not tok_right_paren:match(s, pos) then
        if ismethod then
            buffer[#buffer+1] = ' '
        end
        repeat
            local capt, posn = capt_identifier:match(s, pos)
            if posn then
                buffer[#buffer+1] = capt
                pos = posn
            else
                capt, posn = capt_vararg:match(s, pos)
                if posn then
                    buffer[#buffer+1] = '!vararg'
                    return posn
                else
                    syntaxerror "<name> or '...' expected"
                end
            end
            pos = skip_ws(s, pos)
            capt, posn = capt_comma:match(s, pos)
            if posn then
                buffer[#buffer+1] = ' '
                pos = skip_ws(s, posn)
            end
        until not posn
    end
    return pos
end


local function body (s, pos, buffer, ismethod)
    -- body ->  `(' parlist `)' block END
    local capt, posn = capt_left_paren:match(s, pos)
    if not posn then
        syntaxerror "( expected"
    end
    buffer[#buffer+1] = '('
    pos = skip_ws(s, posn)
    pos = parlist(s, pos, buffer, ismethod)
    pos = skip_ws(s, pos)
    capt, posn = capt_right_paren:match(s, pos)
    if not posn then
        syntaxerror ") expected"
    end
    buffer[#buffer+1] = ')'
    pos = statlist(s, posn, buffer)
    pos = skip_ws(s, pos)
    capt, posn = capt_end:match(s, pos)
    if not posn then
        syntaxerror "'end' expected"
    end
    buffer[#buffer+1] = ')'
    return posn
end


local function explist (s, pos, buffer)
    -- explist -> expr { `,' expr }
    pos = expr(s, pos, buffer)
    pos = skip_ws(s, pos)
    local capt, posn = capt_comma:match(s, pos)
    while posn do
        buffer[#buffer+1] = ' '
        pos = skip_ws(s, posn)
        pos = expr(s, pos, buffer)
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
    -- funcargs -> constructor
    if tok_left_brace:match(s, pos) then
        return constructor(s, pos, buffer)
    end
    -- funcargs -> STRING
    capt, posn = capt_string:match(s, pos)
    if posn then
        buffer[#buffer+1] = capt
        return posn
    end
    syntaxerror "function arguments expected"
end


local function primaryexpr (s, pos, buffer)
    -- primaryexp -> NAME | '(' expr ')'
    pos = skip_ws(s, pos)
    local capt, posn = capt_left_paren:match(s, pos)
    if posn then
        pos = expr(s, posn, buffer, true)
        pos = skip_ws(s, pos)
        capt, posn = capt_right_paren:match(s, pos)
        if posn then
            return posn
        else
            syntaxerror ") expected"
        end
    end
    capt, posn = capt_identifier:match(s, pos)
    if posn then
        buffer[#buffer+1] = capt
        return posn
    end
    syntaxerror "unexpected symbol"
end


local function suffixedexpr (s, pos, buffer, one)
    -- suffixedexp ->
    --    primaryexp { `.' NAME | `[' exp `]' | `:' NAME funcargs | funcargs }
    local buf = {}
    pos = primaryexpr(s, pos, buf)
    local exp = tconcat(buf)
    while true do
        buf = {}
        pos = skip_ws(s, pos)
        if tok_dot:match(s, pos) then
            buf[#buf+1] = '(!index '
            buf[#buf+1] = exp
            buf[#buf+1] = ' '
            pos = fieldsel(s, pos, buf)
            buf[#buf+1] = ')'
            exp = tconcat(buf)
        elseif tok_left_bracket:match(s, pos) then
            buf[#buf+1] = '(!index '
            buf[#buf+1] = exp
            buf[#buf+1] = ' '
            pos = yindex(s, pos, buf)
            buf[#buf+1] = ')'
            exp = tconcat(buf)
        elseif tok_colon:match(s, pos) then
            local _, posn = capt_colon:match(s, pos)
            if one then
                buf[#buf+1] = '(!callmeth1 '
            else
                buf[#buf+1] = '(!callmeth '
            end
            buf[#buf+1] = exp
            buf[#buf+1] = ' '
            pos = skip_ws(s, posn)
            local capt, posn = capt_identifier:match(s, pos)
            if not posn then
                syntaxerror "<name> expected"
            end
            buf[#buf+1] = capt
            buf[#buf+1] = ' '
            pos = skip_ws(s, posn)
            pos = funcargs(s, pos, buf)
            buf[#buf+1] = ')'
            exp = tconcat(buf)
        elseif tok_left_paren:match(s, pos) or tok_left_brace:match(s, pos) or tok_string:match(s, pos) then
            if one then
                buf[#buf+1] = '(!call1 '
            else
                buf[#buf+1] = '(!call '
            end
            buf[#buf+1] = exp
            buf[#buf+1] = ' '
            pos = funcargs(s, pos, buf)
            buf[#buf+1] = ')'
            exp = tconcat(buf)
        else
            buffer[#buffer+1] = exp
            return pos
        end
    end
end


local function simpleexpr (s, pos, buffer, one)
    -- simpleexp -> NUMBER | STRING | NIL | TRUE | FALSE | ... |
     --             constructor | FUNCTION body | suffixedexp
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
    capt, posn = capt_nil:match(s, pos)
    if posn then
        buffer[#buffer+1] = '!nil'
        return posn
    end
    capt, posn = capt_true:match(s, pos)
    if posn then
        buffer[#buffer+1] = '!true'
        return posn
    end
    capt, posn = capt_false:match(s, pos)
    if posn then
        buffer[#buffer+1] = '!false'
        return posn
    end
    capt, posn = capt_vararg:match(s, pos)
    if posn then
        buffer[#buffer+1] = '!vararg'
        return posn
    end
    if tok_left_brace:match(s, pos) then
        return constructor(s, pos, buffer)
    end
    capt, posn = capt_function:match(s, pos)
    if posn then
        buffer[#buffer+1] = '(!lambda '
        pos = skip_ws(s, posn)
        return body(s, pos, buffer)
    end
    return suffixedexpr(s, pos, buffer, one)
end


local unop = {
    ['not']   = '(!not ',
    ['-']     = '(!neg ',
    ['#']     = '(!len1 ',
}
local binop = {
    ['+']     = '(!add ',
    ['-']     = '(!sub ',
    ['*']     = '(!mul ',
    ['/']     = '(!div ',
    ['%']     = '(!mod ',
    ['^']     = '(!pow ',
    ['..']    = '(!concat ',
    ['~=']    = '(!ne ',
    ['==']    = '(!eq ',
    ['<=']    = '(!le ',
    ['<']     = '(!lt ',
    ['>=']    = '(!ge ',
    ['>']     = '(!gt ',
    ['and']   = '(!and ',
    ['or']    = '(!or ',
}
local priority = {
    --        { left right }
    ['+']     = { 6, 6 },
    ['-']     = { 6, 6 },
    ['*']     = { 7, 7 },
    ['/']     = { 7, 7 },
    ['%']     = { 7, 7 },
    ['^']     = { 10, 9 },      -- right associative
    ['..']    = { 5, 4 },       -- right associative
    ['~=']    = { 3, 3 },
    ['==']    = { 3, 3 },
    ['<=']    = { 3, 3 },
    ['<']     = { 3, 3 },
    ['>=']    = { 3, 3 },
    ['>']     = { 3, 3 },
    ['and']   = { 2, 2 },
    ['or']    = { 1, 1 },
}


function expr (s, pos, buffer, one, limit)
    -- expr -> (simpleexp | unop expr) { binop expr }
    limit = limit or 0
    local capt, posn = capt_unopr:match(s, pos)
    local buf = {}
    if posn then
        buf[#buf+1] = unop[capt]
        pos = skip_ws(s, posn)
        pos = expr(s, pos, buf, false, 8)      -- UNARY_PRIORITY
        buf[#buf+1] = ')'
    else
        pos = simpleexpr(s, pos, buf, one)
    end
    local exp = tconcat(buf)
    pos = skip_ws(s, pos)
    capt, posn = capt_binopr:match(s, pos)
    while posn and priority[capt][1] > limit do
        buf = { binop[capt], exp, ' ' }
        pos = skip_ws(s, posn, buf)
        pos = expr(s, pos, buf, false, priority[capt][2])
        pos = skip_ws(s, pos)
        buf[#buf+1] = ')'
        exp = tconcat(buf)
        capt, posn = capt_binopr:match(s, pos)
    end
    buffer[#buffer+1] = exp
    return pos
end


local function block (s, pos, buffer)
    -- block -> statlist
    local pos = statlist(s, pos, buffer)
    buffer[#buffer+1] = ')'
    return pos
end


local function assignment (s, pos, buffer, n)
    -- assignment -> `,' suffixedexp assignment
    local capt, posn = capt_comma:match(s, pos)
    if posn then
        if n == 1 then
            local var = buffer[#buffer]
            buffer[#buffer] = '(!line '
            buffer[#buffer+1] = lineno
            buffer[#buffer+1] = ')(!massign ('
            buffer[#buffer+1] = var
        end
        buffer[#buffer+1] = ' '
        pos = skip_ws(s, posn)
        pos = suffixedexpr(s, pos, buffer)
        pos = skip_ws(s, pos)
        return assignment(s, pos, buffer, n + 1)
    else
        -- assignment -> `=' explist
        capt, posn = capt_equal:match(s, pos)
        if not posn then
            syntaxerror "= expected"
        end
        if n == 1 then
            local var = buffer[#buffer]
            buffer[#buffer] = '(!line '
            buffer[#buffer+1] = lineno
            buffer[#buffer+1] = ')(!assign '
            buffer[#buffer+1] = var
            buffer[#buffer+1] = ' '
        else
            buffer[#buffer+1] = ') ('
        end
        pos = skip_ws(s, posn)
        pos = explist(s, pos, buffer)
        buffer[#buffer+1] = ')'
        if n ~= 1 then
            buffer[#buffer+1] = ')'
        end
        return pos
    end
end


local function breakstat (s, pos, buffer)
    local capt, posn = capt_break:match(s, pos)
    assert(posn)
    buffer[#buffer+1] = '(!line '
    buffer[#buffer+1] = lineno
    buffer[#buffer+1] = ')(!break)'
    return posn
end


local function gotostat (s, pos, buffer)
    local capt, posn = capt_goto:match(s, pos)
    assert(posn)
    buffer[#buffer+1] = '(!line '
    buffer[#buffer+1] = lineno
    buffer[#buffer+1] = ')(!goto '
    pos = skip_ws(s, posn)
    capt, posn = capt_identifier:match(s, pos)
    if not posn then
        syntaxerror "<name> expected"
    end
    buffer[#buffer+1] = capt
    buffer[#buffer+1] = ')'
    return posn
end


local function labelstat (s, pos, buffer)
    -- label -> '::' NAME '::'
    local capt, posn = capt_identifier:match(s, pos)
    if not posn then
        syntaxerror "<name> expected"
    end
    buffer[#buffer+1] = '(!line '
    buffer[#buffer+1] = lineno
    buffer[#buffer+1] = ')(!label '
    buffer[#buffer+1] = capt
    buffer[#buffer+1] = ')'
    pos = skip_ws(s, posn)
    capt, posn = capt_dbcolon:match(s, pos)
    if not posn then
        syntaxerror ":: expected"
    end
    return posn
end


local function whilestat (s, pos, buffer)
    -- whilestat -> WHILE cond DO block END
    local capt, posn = capt_while:match(s, pos)
    assert(posn)
    buffer[#buffer+1] = '(!line '
    buffer[#buffer+1] = lineno
    buffer[#buffer+1] = ')(!while '
    pos = skip_ws(s, posn)
    pos = expr(s, pos, buffer, true)
    buffer[#buffer+1] = '\n'
    pos = skip_ws(s, pos)
    capt, posn = capt_do:match(s, pos)
    if not posn then
        syntaxerror "do expected"
    end
    pos = skip_ws(s, posn)
    pos = block(s, pos, buffer)
    pos = skip_ws(s, pos)
    capt, posn = capt_end:match(s, pos)
    if not posn then
        syntaxerror "end expected"
    end
    return posn
end


local function repeatstat (s, pos, buffer)
    -- repeatstat -> REPEAT block UNTIL cond
    local capt, posn = capt_repeat:match(s, pos)
    assert(posn)
    buffer[#buffer+1] = '(!line '
    buffer[#buffer+1] = lineno
    buffer[#buffer+1] = ')(!repeat'
    pos = skip_ws(s, posn)
    pos = statlist(s, pos, buffer)
    pos = skip_ws(s, pos)
    capt, posn = capt_until:match(s, pos)
    if not posn then
        syntaxerror "until expected"
    end
    pos = skip_ws(s, posn)
    buffer[#buffer+1] = '\n'
    pos = expr(s, pos, buffer, true)
    buffer[#buffer+1] = ')'
    return pos
end


local function forbody (s, pos, buffer, name)
    -- forbody -> DO block
    buffer[#buffer+1] = '\n'
    local capt, posn = capt_do:match(s, pos)
    if not posn then
        syntaxerror "do expected"
    end
    if name then
        buffer[#buffer+1] = "(!define "
        buffer[#buffer+1] = name
        buffer[#buffer+1] = " "
        buffer[#buffer+1] = name
        buffer[#buffer+1] = ")"
    end
    pos = skip_ws(s, posn)
    return block(s, pos, buffer)
end


local function fornum (s, pos, buffer, name)
    -- fornum -> NAME = exp1,exp1[,exp1] forbody
    local capt, posn = capt_equal:match(s, pos)
    if not posn then
        syntaxerror "= expected"
    end
    buffer[#buffer+1] = '(!line '
    buffer[#buffer+1] = lineno
    buffer[#buffer+1] = ')(!loop '
    buffer[#buffer+1] = name
    buffer[#buffer+1] = ' '
    pos = skip_ws(s, posn)
    pos = expr(s, pos, buffer, true) -- initial value
    capt, posn = capt_comma:match(s, pos)
    if not posn then
        syntaxerror ", expected"
    end
    buffer[#buffer+1] = ' '
    pos = skip_ws(s, posn)
    pos = expr(s, pos, buffer, true) -- limit
    capt, posn = capt_comma:match(s, pos)
    if posn then
        buffer[#buffer+1] = ' '
        pos = skip_ws(s, posn)
        pos = expr(s, pos, buffer, true) -- optional step
    else
        buffer[#buffer+1] = ' 1 ' -- default step = 1
    end
    return forbody(s, pos, buffer, name)
end


local function forlist (s, pos, buffer, name1)
    -- forlist -> NAME {,NAME} IN explist forbody
    buffer[#buffer+1] = '(!line '
    buffer[#buffer+1] = lineno
    buffer[#buffer+1] = ')(!for ('
    buffer[#buffer+1] = name1
    local capt, posn = capt_comma:match(s, pos)
    while posn do
        buffer[#buffer+1] = ' '
        pos = skip_ws(s, posn)
        local capt, posnn = capt_identifier:match(s, pos)
        if not posnn then
            syntaxerror "<name> expected"
        end
        buffer[#buffer+1] = capt
        pos = skip_ws(s, posnn)
        capt, posn = capt_comma:match(s, pos)
    end
    capt, posn = capt_in:match(s, pos)
    if not posn then
        syntaxerror "in expected"
    end
    buffer[#buffer+1] = ') ('
    pos = skip_ws(s, posn)
    pos = explist(s, pos, buffer)
    buffer[#buffer+1] = ')'
    return forbody(s, pos, buffer)
end


local function forstat (s, pos, buffer)
    -- forstat -> FOR (fornum | forlist) END
    local capt, posn = capt_for:match(s, pos)
    assert(posn)
    pos = skip_ws(s, posn)
    capt, posn = capt_identifier:match(s, pos)
    if not posn then
        syntaxerror "<name> expected"
    end
    pos = skip_ws(s, posn)
    if tok_equal:match(s, pos) then
        pos = fornum(s, pos, buffer, capt)
    elseif tok_comma:match(s, pos) or tok_in:match(s, pos) then
        pos = forlist(s, pos, buffer, capt)
    else
        syntaxerror "'=' or 'in' expected"
    end
    pos = skip_ws(s, pos)
    capt, posn = capt_end:match(s, pos)
    if not posn then
        syntaxerror "end expected"
    end
    return posn
end


local function test_then_block (s, pos, buffer)
    -- test_then_block -> [IF | ELSEIF] cond THEN block
    local capt, posn = capt_if:match(s, pos)
    if not posn then
        capt, posn = capt_elseif:match(s, pos)
        assert(posn)
    end
    buffer[#buffer+1] = '(!if '
    pos = skip_ws(s, posn)
    pos = expr(s, pos, buffer, true)
    buffer[#buffer+1] = '\n'
    pos = skip_ws(s, pos)
    capt, posn = capt_then:match(s, pos)
    if not posn then
        syntaxerror "then expected"
    end
    buffer[#buffer+1] = '(!do'
    pos = skip_ws(s, posn)
    return block(s, pos, buffer)
end

local function ifstat (s, pos, buffer)
    -- ifstat -> IF cond THEN block {ELSEIF cond THEN block} [ELSE block] END
    buffer[#buffer+1] = '(!line '
    buffer[#buffer+1] = lineno
    buffer[#buffer+1] = ')'
    pos = test_then_block(s, pos, buffer)
    local n = 1
    while tok_elseif:match(s, pos) do
        pos = test_then_block(s, pos, buffer)
        n = n + 1
    end
    local capt, posn = capt_else:match(s, pos)
    if posn then
        buffer[#buffer+1] = '(!do'
        pos = skip_ws(s, posn)
        pos = block(s, pos, buffer)
    end
    capt, posn = capt_end:match(s, pos)
    if not posn then
        syntaxerror "end expected"
    end
    for i = 1, n, 1 do
        buffer[#buffer+1] = ')'
    end
    return posn
end


local function localfunc (s, pos, buffer)
    local capt, posn = capt_function:match(s, pos)
    assert(posn)
    pos = skip_ws(s, posn)
    capt, posn = capt_identifier:match(s, pos)
    if not posn then
        syntaxerror "<name> expected"
    end
    buffer[#buffer+1] = '(!line '
    buffer[#buffer+1] = lineno
    buffer[#buffer+1] = ')(!define '
    buffer[#buffer+1] = capt
    buffer[#buffer+1] = ')(!assign '
    buffer[#buffer+1] = capt
    buffer[#buffer+1] = ' (!lambda '
    pos = skip_ws(s, posn)
    pos = body(s, pos, buffer)
    buffer[#buffer+1] = ')\n'
    return pos
end


local function localstat (s, pos, buffer)
    -- stat -> LOCAL NAME {`,' NAME} [`=' explist]
    buffer[#buffer+1] = '(!line '
    buffer[#buffer+1] = lineno
    buffer[#buffer+1] = ')(!define '
    local multi = false
    local capt, posn
    repeat
        capt, posn = capt_identifier:match(s, pos)
        if not pos then
            syntaxerror "<name> expected"
        end
        local ident = capt
        buffer[#buffer+1] = ident
        pos = skip_ws(s, posn)
        capt, posn = capt_comma:match(s, pos)
        if posn then
            if not multi then
                multi = true
                buffer[#buffer] = '('
                buffer[#buffer+1] = ident
            end
            buffer[#buffer+1] = ' '
            pos = skip_ws(s, posn)
        end
    until not posn
    if multi then
        buffer[#buffer+1] = ')'
    end
    capt, posn = capt_equal:match(s, pos)
    if posn then
        buffer[#buffer+1] = ' '
        if multi then
            buffer[#buffer+1] = '('
        end
        pos = skip_ws(s, posn, buffer)
        pos = explist(s, pos, buffer)
        if multi then
            buffer[#buffer+1] = ')'
        end
    end
    buffer[#buffer+1] = ')'
    return pos
end


local function funcname (s, pos, buffer)
    -- funcname -> NAME {fieldsel} [`:' NAME]
    local exp, posn = capt_identifier:match(s, pos)
    if not posn then
        syntaxerror "identifier expected"
    end
    pos = skip_ws(s, posn)
    posn = tok_dot:match(s, pos)
    while posn do
        local buf = { '(!index ', exp, ' ' }
        pos = fieldsel(s, pos, buf)
        buf[#buf+1] = ')'
        exp = tconcat(buf)
        pos = skip_ws(s, pos)
        posn = tok_dot:match(s, pos)
    end
    posn = tok_colon:match(s, pos)
    if posn then
        local buf = { '(!index ', exp, ' ' }
        pos = fieldsel(s, pos, buf)
        buf[#buf+1] = ')'
        exp = tconcat(buf)
        pos = skip_ws(s, pos)
    end
    buffer[#buffer+1] = exp
    return pos, posn
end


local function funcstat (s, pos, buffer)
    -- funcstat -> FUNCTION funcname body
    local capt, posn = capt_function:match(s, pos)
    assert(posn)
    pos = skip_ws(s, posn)
    buffer[#buffer+1] = '(!line '
    buffer[#buffer+1] = lineno
    buffer[#buffer+1] = ')(!assign '
    local posn, ismethod = funcname(s, pos, buffer)
    buffer[#buffer+1] = ' (!lambda '
    pos = skip_ws(s, posn)
    pos = body(s, pos, buffer, ismethod)
    buffer[#buffer+1] = ')\n'
    return pos
end


local function exprstat (s, pos, buffer)
    -- stat -> func | assignment
    local buf = {}
    local lineno = lineno
    pos = suffixedexpr(s, pos, buf)
    pos = skip_ws(s, pos)
    if tok_equal:match(s, pos) or tok_comma:match(s, pos) then
        buffer[#buffer+1] = tconcat(buf)
        return assignment(s, pos, buffer, 1)
    else
        buffer[#buffer+1] = '(!line '
        buffer[#buffer+1] = lineno
        buffer[#buffer+1] = ')'
        buffer[#buffer+1] = tconcat(buf)
        return pos
    end
end


local function retstat (s, pos, buffer)
    -- stat -> RETURN [explist] [';']
    buffer[#buffer+1] = '(!line '
    buffer[#buffer+1] = lineno
    buffer[#buffer+1] = ')(!return '
    if not block_follow(s, pos, true) and not tok_semicolon:match(s, pos) then
        pos = explist(s, pos, buffer)
    end
    buffer[#buffer+1] = ')'
    local capt, posn = capt_semicolon:match(s, pos)
    if posn then
        return posn
    end
    return pos
end


function statement (s, pos, buffer)
    -- stat -> ';' (empty statement)
    pos = skip_ws(s, pos)
    local capt, posn = capt_semicolon:match(s, pos)
    if posn then
        return posn
    end
    -- stat -> ifstat
    if tok_if:match(s, pos) then
        return ifstat(s, pos, buffer)
    end
    -- stat -> whilestat
    if tok_while:match(s, pos) then
        return whilestat(s, pos, buffer)
    end
    -- stat -> DO block END
    capt, posn = capt_do:match(s, pos)
    if posn then
        buffer[#buffer+1] = '(!line '
        buffer[#buffer+1] = lineno
        buffer[#buffer+1] = ')(!do'
        pos = block(s, posn, buffer)
        capt, posn = capt_end:match(s, pos)
        if posn then
            return posn
        else
            syntaxerror "'end' expected"
        end
    end
    -- stat -> forstat
    if tok_for:match(s, pos) then
        return forstat(s, pos, buffer)
    end
    -- stat -> repeatstat
    if tok_repeat:match(s, pos) then
        return repeatstat(s, pos, buffer)
    end
    -- stat -> funcstat
    if tok_function:match(s, pos) then
        return funcstat(s, pos, buffer)
    end
    -- stat -> localstat
    capt, posn = capt_local:match(s, pos)
    if posn then
        pos = skip_ws(s, posn)
        if tok_function:match(s, pos) then
            return localfunc(s, pos, buffer)
        else
            return localstat(s, pos, buffer)
        end
    end
    -- stat -> label
    capt, posn = capt_dbcolon:match(s, pos)
    if posn then
        pos = skip_ws(s, posn)
        return labelstat(s, pos, buffer)
    end
    -- stat -> retstat
    capt, posn = capt_return:match(s, pos)
    if posn then
        pos = skip_ws(s, posn)
        return retstat(s, pos, buffer)
    end
    -- stat -> breakstat
    if tok_break:match(s, pos) then
        return breakstat(s, pos, buffer)
    end
    -- stat -> 'goto' NAME
    if tok_goto:match(s, pos) then
        return gotostat(s, pos, buffer)
    end
    -- stat -> func | assignment
    return exprstat(s, pos, buffer)
end


local function translate (s, fname)
    if bytecode:match(s) then
        return s
    end
    local pos = (bom * Cp()):match(s, 1) or 1
    pos = (shebang * Cp()):match(s, pos) or pos
    lineno = 1
    local buffer = { '(!line ', quote(fname), ' ', lineno, ')' }
    pos = statlist(s, pos, buffer)
    if not P(-1):match(s, pos) then
        syntaxerror("<eof> expected at " .. pos)
    end
    buffer[#buffer+1] = "\n; end of generation"
    return tconcat(buffer)
end

_G._COMPILER = translate

local fname = arg and arg[1]
if fname then
    local f, msg = _G.io.open(fname, 'r')
    if not f then
        error(msg)
    end
    local s = f:read'*a'
    f:close()
    local code = translate(s, '@' .. fname)
    print "; bootstrap"
    print(code)
end


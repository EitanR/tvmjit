
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
local function inc_lineno ()
    lineno = lineno + 1
end
local function inc_lineno2 ()
    lineno = lineno + 0.5       -- called twice time ???
end
local function syntaxerror (err)
    error(err .. " at " .. lineno)
end

local bytecode = literal"\27"
local bom = literal"\xEF\xBB\xBF"
local shebang = sequence(literal'#!', many(except(any(), set"\f\n\r")))
local equals = many(literal'=')
local open = sequence(literal'[', group(equals, 'init'), literal'[', optional(replace(literal"\n", inc_lineno2)))
local close = sequence(literal']', capture(equals), literal']')
local closeeq = matchtime(sequence(close, backref'init'), function (s, i, a, b) return a == b end)
local long_string = replace(sequence(open, capture(many(choice(replace(literal"\n", inc_lineno2), except(any(), closeeq)))), close), quote)
local comment = sequence(literal'--', choice(replace(long_string, function () return end), many(except(any(), set"\f\n\r"))))
local ws = many(choice(set" \f\t\r\v", replace(literal"\n", inc_lineno), comment))
local capt_ws = sequence(capture(ws), position)

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
local ch_ident = range('09', 'AZ', 'az', '__')
local identifier = sequence(range('AZ', 'az', '__'), many(ch_ident))
local capt_identifier = sequence(replace(identifier, check_reserved), position)

local digit = range'09'
local int = some(digit)
local frac = sequence(literal'.', many(digit))
local sign = set'-+'
local exp = sequence(set'Ee', optional(sign), some(digit))
local xdigit = range('09', 'AF', 'af')
local xint = sequence(literal'0', set'xX', some(xdigit))
local xfrac = sequence(literal'.', many(xdigit))
local xexp = sequence(set'Pp', optional(sign), some(digit))
local number = choice(sequence(xint, optional(xfrac), optional(xexp)),
                      sequence(optional(literal'-'), int, optional(frac), optional(exp)))
local capt_number = sequence(capture(number), position)


local function gsub (patt, repl)
    return subst(many(choice(replace(patt, repl), any())))
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

local escape_special = sequence(literal'\\', capture(set"'\"\\/abfnrtv"))
local gsub_escape_special = gsub(escape_special, special)
local escape_xdigit = sequence(literal'\\x', capture(sequence(xdigit, xdigit)))
local gsub_escape_xdigit = gsub(escape_xdigit, function (s)
                                                    return char(tonumber(s, 16))
                                               end)
local escape_decimal = sequence(literal'\\', capture(sequence(digit, optional(digit), optional(digit))))
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

local zap = replace(sequence(literal"\\z", some(set"\n\r"), some(literal" ")), "")
local ch_sq = choice(zap, literal"\\\\", literal"\\'", except(any(), literal"'", range'\0\31'))
local ch_dq = choice(zap, literal'\\\\', literal'\\"', except(any(), literal'"', range'\0\31'))
local simple_quote_string = replace(replace(sequence(literal"'", subst(many(ch_sq)), literal"'"), unescape), quote)
local double_quote_string = replace(replace(sequence(literal'"', subst(many(ch_dq)), literal'"'), unescape), quote)
local tok_string = choice(simple_quote_string, double_quote_string, long_string)
local capt_string = sequence(tok_string, position)


local not_ch_ident = not_followed_by(ch_ident)
local tok_and = sequence(literal'and', not_ch_ident)
local capt_and = sequence(capture(tok_and), position)
local tok_break = sequence(literal'break', not_ch_ident)
local capt_break = sequence(capture(tok_break), position)
local tok_do = sequence(literal'do', not_ch_ident)
local capt_do = sequence(capture(tok_do), position)
local tok_else = sequence(literal'else', not_ch_ident)
local capt_else = sequence(capture(tok_else), position)
local tok_elseif = sequence(literal'elseif', not_ch_ident)
local capt_elseif = sequence(capture(tok_elseif), position)
local tok_end = sequence(literal'end', not_ch_ident)
local capt_end = sequence(capture(tok_end), position)
local tok_false = sequence(literal'false', not_ch_ident)
local capt_false = sequence(capture(tok_false), position)
local tok_for = sequence(literal'for', not_ch_ident)
local capt_for = sequence(capture(tok_for), position)
local tok_function = sequence(literal'function', not_ch_ident)
local capt_function = sequence(capture(tok_function), position)
local tok_goto = sequence(literal'goto', not_ch_ident)
local capt_goto = sequence(capture(tok_goto), position)
local tok_if = sequence(literal'if', not_ch_ident)
local capt_if = sequence(capture(tok_if), position)
local tok_in = sequence(literal'in', not_ch_ident)
local capt_in = sequence(capture(tok_in), position)
local tok_local = sequence(literal'local', not_ch_ident)
local capt_local = sequence(capture(tok_local), position)
local tok_nil = sequence(literal'nil', not_ch_ident)
local capt_nil = sequence(capture(tok_nil), position)
local tok_not = sequence(literal'not', not_ch_ident)
local capt_not = sequence(capture(tok_not), position)
local tok_or = sequence(literal'or', not_ch_ident)
local capt_or = sequence(capture(tok_or), position)
local tok_repeat = sequence(literal'repeat', not_ch_ident)
local capt_repeat = sequence(capture(tok_repeat), position)
local tok_return = sequence(literal'return', not_ch_ident)
local capt_return = sequence(capture(tok_return), position)
local tok_then = sequence(literal'then', not_ch_ident)
local capt_then = sequence(capture(tok_then), position)
local tok_true = sequence(literal'true', not_ch_ident)
local capt_true = sequence(capture(tok_true), position)
local tok_until = sequence(literal'until', not_ch_ident)
local capt_until = sequence(capture(tok_until), position)
local tok_while = sequence(literal'while', not_ch_ident)
local capt_while = sequence(capture(tok_while), position)


local tok_colon = literal':'
local capt_colon = sequence(capture(tok_colon), position)
local tok_comma = literal','
local capt_comma = sequence(capture(tok_comma), position)
local tok_dbcolon = literal'::'
local capt_dbcolon = sequence(capture(tok_dbcolon), position)
local tok_dot = sequence(literal'.', not_followed_by(literal'.'))
local capt_dot = sequence(capture(tok_dot), position)
local tok_equal = literal'='
local capt_equal = sequence(capture(tok_equal), position)
local tok_left_brace = literal'{'
local capt_left_brace = sequence(capture(tok_left_brace), position)
local tok_left_bracket = sequence(literal'[', not_followed_by(literal'['), not_followed_by(literal'='))
local capt_left_bracket = sequence(capture(tok_left_bracket), position)
local tok_left_paren = literal'('
local capt_left_paren = sequence(capture(tok_left_paren), position)
local tok_right_brace = literal'}'
local capt_right_brace = sequence(capture(tok_right_brace), position)
local tok_right_bracket = literal']'
local capt_right_bracket = sequence(capture(tok_right_bracket), position)
local tok_right_paren = literal')'
local capt_right_paren = sequence(capture(tok_right_paren), position)
local tok_semicolon = literal';'
local capt_semicolon = sequence(capture(tok_semicolon), position)
local tok_sel = set'.:'
local capt_sel = sequence(capture(tok_sel), position)
local tok_sep = set',;'
local capt_sep = sequence(capture(tok_sep), position)
local tok_vararg = literal'...'
local capt_vararg = sequence(capture(tok_vararg), position)

local unopr = choice(tok_not, literal'-', literal'#')
local capt_unopr = sequence(capture(unopr), position)
local binopr = choice(literal'+', literal'-', literal'*', literal'/', literal'%', literal'^', literal'..',
                      literal'~=', literal'==', literal'<=', literal'<', literal'>=', literal'>', tok_and, tok_or)
local capt_binopr = sequence(capture(binopr), position)


local statement;
local expr;


local function block_follow (s, pos, withuntil)
    if literal'else':match(s, pos) then
        return true
    end
    if literal'elseif':match(s, pos) then
        return true
    end
    if literal'end':match(s, pos) then
        return true
    end
    if eos:match(s, pos) then
        return true
    end
    if literal'until':match(s, pos) then
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
        buffer[#buffer] = '\n'
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
    buffer[#buffer] = quote(capt)
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
        buffer[#buffer] = '"'
        buffer[#buffer] = capt
        buffer[#buffer] = '"'
        pos = posn
    else
        pos = yindex(s, pos, buffer)
    end
    pos = skip_ws(s, pos)
    capt, posn = capt_equal:match(s, pos)
    if not posn then
        syntaxerror "= expected"
    end
    buffer[#buffer] = ': '
    pos = skip_ws(s, posn)
    return expr(s, pos, buffer, true)
end


local function listfield (s, pos, buffer)
    -- listfield -> exp
    return expr(s, pos, buffer)
end


local function field (s, pos, buffer)
    -- field -> listfield | recfield
    local capt, posn = capt_identifier:match(s, pos)
    if posn then
        if sequence(ws, tok_equal):match(s, posn) then
            return recfield(s, pos, buffer)
        else
            return listfield(s, pos, buffer)
        end
    end
    if tok_left_bracket:match(s, pos) then
        return recfield(s, pos, buffer)
    end
    return listfield(s, pos, buffer)
end


local function constructor (s, pos, buffer)
    -- constructor -> '{' [ field { sep field } [sep] ] '}'
    local capt, posn = capt_left_brace:match(s, pos)
    if not posn then
        syntaxerror "{ expected"
    end
    buffer[#buffer] = '('
    pos = skip_ws(s, posn)
    repeat
        if tok_right_brace:match(s, pos) then
            break
        end
        pos = field(s, pos, buffer)
        pos = skip_ws(s, pos)
        capt, posn = capt_sep:match(s, pos)
        if posn then
            buffer[#buffer] = ' '
            pos = skip_ws(s, posn)
        end
    until not posn
    capt, posn = capt_right_brace:match(s, pos)
    if not posn then
        syntaxerror "} expected"
    end
    buffer[#buffer] = ')'
    return posn
end


local function parlist (s, pos, buffer, ismethod)
    -- parlist -> [ param { `,' param } ]
    -- param -> NAME | `...'
    if ismethod then
        buffer[#buffer] = 'self'
    end
    if not tok_right_paren:match(s, pos) then
        if ismethod then
            buffer[#buffer] = ' '
        end
        repeat
            local capt, posn = capt_identifier:match(s, pos)
            if posn then
                buffer[#buffer] = capt
                pos = posn
            else
                capt, posn = capt_vararg:match(s, pos)
                if posn then
                    buffer[#buffer] = '!vararg'
                    return posn
                else
                    syntaxerror "<name> or '...' expected"
                end
            end
            pos = skip_ws(s, pos)
            capt, posn = capt_comma:match(s, pos)
            if posn then
                buffer[#buffer] = ' '
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
    buffer[#buffer] = '('
    pos = skip_ws(s, posn)
    pos = parlist(s, pos, buffer, ismethod)
    pos = skip_ws(s, pos)
    capt, posn = capt_right_paren:match(s, pos)
    if not posn then
        syntaxerror ") expected"
    end
    buffer[#buffer] = ')'
    pos = statlist(s, posn, buffer)
    pos = skip_ws(s, pos)
    capt, posn = capt_end:match(s, pos)
    if not posn then
        syntaxerror "'end' expected"
    end
    buffer[#buffer] = ')'
    return posn
end


local function explist (s, pos, buffer)
    -- explist -> expr { `,' expr }
    pos = expr(s, pos, buffer)
    pos = skip_ws(s, pos)
    local capt, posn = capt_comma:match(s, pos)
    while posn do
        buffer[#buffer] = ' '
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
        buffer[#buffer] = capt
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
        buffer[#buffer] = capt
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
            buf[#buf] = '(!index '
            buf[#buf] = exp
            buf[#buf] = ' '
            pos = fieldsel(s, pos, buf)
            buf[#buf] = ')'
            exp = tconcat(buf)
        elseif tok_left_bracket:match(s, pos) then
            buf[#buf] = '(!index '
            buf[#buf] = exp
            buf[#buf] = ' '
            pos = yindex(s, pos, buf)
            buf[#buf] = ')'
            exp = tconcat(buf)
        elseif tok_colon:match(s, pos) then
            local _, posn = capt_colon:match(s, pos)
            if one then
                buf[#buf] = '(!callmeth1 '
            else
                buf[#buf] = '(!callmeth '
            end
            buf[#buf] = exp
            buf[#buf] = ' '
            pos = skip_ws(s, posn)
            local capt, posn = capt_identifier:match(s, pos)
            if not posn then
                syntaxerror "<name> expected"
            end
            buf[#buf] = capt
            buf[#buf] = ' '
            pos = skip_ws(s, posn)
            pos = funcargs(s, pos, buf)
            buf[#buf] = ')'
            exp = tconcat(buf)
        elseif tok_left_paren:match(s, pos) or tok_left_brace:match(s, pos) or tok_string:match(s, pos) then
            if one then
                buf[#buf] = '(!call1 '
            else
                buf[#buf] = '(!call '
            end
            buf[#buf] = exp
            buf[#buf] = ' '
            pos = funcargs(s, pos, buf)
            buf[#buf] = ')'
            exp = tconcat(buf)
        else
            buffer[#buffer] = exp
            return pos
        end
    end
end


local function simpleexpr (s, pos, buffer, one)
    -- simpleexp -> NUMBER | STRING | NIL | TRUE | FALSE | ... |
     --             constructor | FUNCTION body | suffixedexp
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
    capt, posn = capt_nil:match(s, pos)
    if posn then
        buffer[#buffer] = '!nil'
        return posn
    end
    capt, posn = capt_true:match(s, pos)
    if posn then
        buffer[#buffer] = '!true'
        return posn
    end
    capt, posn = capt_false:match(s, pos)
    if posn then
        buffer[#buffer] = '!false'
        return posn
    end
    capt, posn = capt_vararg:match(s, pos)
    if posn then
        buffer[#buffer] = '!vararg'
        return posn
    end
    if tok_left_brace:match(s, pos) then
        return constructor(s, pos, buffer)
    end
    capt, posn = capt_function:match(s, pos)
    if posn then
        buffer[#buffer] = '(!lambda '
        pos = skip_ws(s, posn)
        return body(s, pos, buffer)
    end
    return suffixedexpr(s, pos, buffer, one)
end


local unop = {
    ['not']   = '(!not ',
    ['-']     = '(!neg ',
    ['#']     = '(!len ',
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
        buf[#buf] = unop[capt]
        pos = skip_ws(s, posn)
        pos = expr(s, pos, buf, false, 8)      -- UNARY_PRIORITY
        buf[#buf] = ')'
    else
        pos = simpleexpr(s, pos, buf, one)
    end
    local exp = tconcat(buf)
    pos = skip_ws(s, pos)
    capt, posn = capt_binopr:match(s, pos)
    while posn and priority[capt][0] > limit do
        buf = { binop[capt], exp, ' ' }
        pos = skip_ws(s, posn, buf)
        pos = expr(s, pos, buf, false, priority[capt][1])
        pos = skip_ws(s, pos)
        buf[#buf] = ')'
        exp = tconcat(buf)
        capt, posn = capt_binopr:match(s, pos)
    end
    buffer[#buffer] = exp
    return pos
end


local function block (s, pos, buffer)
    -- block -> statlist
    local pos = statlist(s, pos, buffer)
    buffer[#buffer] = ')'
    return pos
end


local function assignment (s, pos, buffer, n)
    -- assignment -> `,' suffixedexp assignment
    local capt, posn = capt_comma:match(s, pos)
    if posn then
        if n == 1 then
            local var = buffer[#buffer-1]
            buffer[#buffer-1] = '(!line '
            buffer[#buffer] = lineno
            buffer[#buffer] = ')(!massign ('
            buffer[#buffer] = var
        end
        buffer[#buffer] = ' '
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
            local var = buffer[#buffer-1]
            buffer[#buffer-1] = '(!line '
            buffer[#buffer] = lineno
            buffer[#buffer] = ')(!assign '
            buffer[#buffer] = var
            buffer[#buffer] = ' '
        else
            buffer[#buffer] = ') ('
        end
        pos = skip_ws(s, posn)
        pos = explist(s, pos, buffer)
        buffer[#buffer] = ')'
        if n ~= 1 then
            buffer[#buffer] = ')'
        end
        return pos
    end
end


local function breakstat (s, pos, buffer)
    local capt, posn = capt_break:match(s, pos)
    assert(posn)
    buffer[#buffer] = '(!line '
    buffer[#buffer] = lineno
    buffer[#buffer] = ')(!break)'
    return posn
end


local function gotostat (s, pos, buffer)
    local capt, posn = capt_goto:match(s, pos)
    assert(posn)
    buffer[#buffer] = '(!line '
    buffer[#buffer] = lineno
    buffer[#buffer] = ')(!goto '
    pos = skip_ws(s, posn)
    capt, posn = capt_identifier:match(s, pos)
    if not posn then
        syntaxerror "<name> expected"
    end
    buffer[#buffer] = capt
    buffer[#buffer] = ')'
    return posn
end


local function labelstat (s, pos, buffer)
    -- label -> '::' NAME '::'
    local capt, posn = capt_identifier:match(s, pos)
    if not posn then
        syntaxerror "<name> expected"
    end
    buffer[#buffer] = '(!line '
    buffer[#buffer] = lineno
    buffer[#buffer] = ')(!label '
    buffer[#buffer] = capt
    buffer[#buffer] = ')'
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
    buffer[#buffer] = '(!line '
    buffer[#buffer] = lineno
    buffer[#buffer] = ')(!while '
    pos = skip_ws(s, posn)
    pos = expr(s, pos, buffer, true)
    buffer[#buffer] = '\n'
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
    buffer[#buffer] = '(!line '
    buffer[#buffer] = lineno
    buffer[#buffer] = ')(!repeat'
    pos = skip_ws(s, posn)
    pos = statlist(s, pos, buffer)
    pos = skip_ws(s, pos)
    capt, posn = capt_until:match(s, pos)
    if not posn then
        syntaxerror "until expected"
    end
    pos = skip_ws(s, posn)
    buffer[#buffer] = '\n'
    pos = expr(s, pos, buffer, true)
    buffer[#buffer] = ')'
    return pos
end


local function forbody (s, pos, buffer, name)
    -- forbody -> DO block
    buffer[#buffer] = '\n'
    local capt, posn = capt_do:match(s, pos)
    if not posn then
        syntaxerror "do expected"
    end
    if name then
        buffer[#buffer] = "(!define "
        buffer[#buffer] = name
        buffer[#buffer] = " "
        buffer[#buffer] = name
        buffer[#buffer] = ")"
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
    buffer[#buffer] = '(!line '
    buffer[#buffer] = lineno
    buffer[#buffer] = ')(!loop '
    buffer[#buffer] = name
    buffer[#buffer] = ' '
    pos = skip_ws(s, posn)
    pos = expr(s, pos, buffer, true) -- initial value
    capt, posn = capt_comma:match(s, pos)
    if not posn then
        syntaxerror ", expected"
    end
    buffer[#buffer] = ' '
    pos = skip_ws(s, posn)
    pos = expr(s, pos, buffer, true) -- limit
    capt, posn = capt_comma:match(s, pos)
    if posn then
        buffer[#buffer] = ' '
        pos = skip_ws(s, posn)
        pos = expr(s, pos, buffer, true) -- optional step
    else
        buffer[#buffer] = ' 1 ' -- default step = 1
    end
    return forbody(s, pos, buffer, name)
end


local function forlist (s, pos, buffer, name1)
    -- forlist -> NAME {,NAME} IN explist forbody
    buffer[#buffer] = '(!line '
    buffer[#buffer] = lineno
    buffer[#buffer] = ')(!for ('
    buffer[#buffer] = name1
    local capt, posn = capt_comma:match(s, pos)
    while posn do
        buffer[#buffer] = ' '
        pos = skip_ws(s, posn)
        local capt, posnn = capt_identifier:match(s, pos)
        if not posnn then
            syntaxerror "<name> expected"
        end
        buffer[#buffer] = capt
        pos = skip_ws(s, posnn)
        capt, posn = capt_comma:match(s, pos)
    end
    capt, posn = capt_in:match(s, pos)
    if not posn then
        syntaxerror "in expected"
    end
    buffer[#buffer] = ') ('
    pos = skip_ws(s, posn)
    pos = explist(s, pos, buffer)
    buffer[#buffer] = ')'
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
    buffer[#buffer] = '(!if '
    pos = skip_ws(s, posn)
    pos = expr(s, pos, buffer, true)
    buffer[#buffer] = '\n'
    pos = skip_ws(s, pos)
    capt, posn = capt_then:match(s, pos)
    if not posn then
        syntaxerror "then expected"
    end
    buffer[#buffer] = '(!do'
    pos = skip_ws(s, posn)
    return block(s, pos, buffer)
end

local function ifstat (s, pos, buffer)
    -- ifstat -> IF cond THEN block {ELSEIF cond THEN block} [ELSE block] END
    buffer[#buffer] = '(!line '
    buffer[#buffer] = lineno
    buffer[#buffer] = ')'
    pos = test_then_block(s, pos, buffer)
    local n = 1
    while tok_elseif:match(s, pos) do
        pos = test_then_block(s, pos, buffer)
        n = n + 1
    end
    local capt, posn = capt_else:match(s, pos)
    if posn then
        buffer[#buffer] = '(!do'
        pos = skip_ws(s, posn)
        pos = block(s, pos, buffer)
    end
    capt, posn = capt_end:match(s, pos)
    if not posn then
        syntaxerror "end expected"
    end
    for i = 1, n, 1 do
        buffer[#buffer] = ')'
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
    buffer[#buffer] = '(!line '
    buffer[#buffer] = lineno
    buffer[#buffer] = ')(!define '
    buffer[#buffer] = capt
    buffer[#buffer] = ')(!assign '
    buffer[#buffer] = capt
    buffer[#buffer] = ' (!lambda '
    pos = skip_ws(s, posn)
    pos = body(s, pos, buffer)
    buffer[#buffer] = ')\n'
    return pos
end


local function localstat (s, pos, buffer)
    -- stat -> LOCAL NAME {`,' NAME} [`=' explist]
    buffer[#buffer] = '(!line '
    buffer[#buffer] = lineno
    buffer[#buffer] = ')(!define '
    local multi = false
    local capt, posn
    repeat
        capt, posn = capt_identifier:match(s, pos)
        if not pos then
            syntaxerror "<name> expected"
        end
        local ident = capt
        buffer[#buffer] = ident
        pos = skip_ws(s, posn)
        capt, posn = capt_comma:match(s, pos)
        if posn then
            if not multi then
                multi = true
                buffer[#buffer-1] = '('
                buffer[#buffer] = ident
            end
            buffer[#buffer] = ' '
            pos = skip_ws(s, posn)
        end
    until not posn
    if multi then
        buffer[#buffer] = ')'
    end
    capt, posn = capt_equal:match(s, pos)
    if posn then
        buffer[#buffer] = ' '
        if multi then
            buffer[#buffer] = '('
        end
        pos = skip_ws(s, posn, buffer)
        pos = explist(s, pos, buffer)
        if multi then
            buffer[#buffer] = ')'
        end
    end
    buffer[#buffer] = ')'
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
        buf[#buf] = ')'
        exp = tconcat(buf)
        pos = skip_ws(s, pos)
        posn = tok_dot:match(s, pos)
    end
    posn = tok_colon:match(s, pos)
    if posn then
        local buf = { '(!index ', exp, ' ' }
        pos = fieldsel(s, pos, buf)
        buf[#buf] = ')'
        exp = tconcat(buf)
        pos = skip_ws(s, pos)
    end
    buffer[#buffer] = exp
    return pos, posn
end


local function funcstat (s, pos, buffer)
    -- funcstat -> FUNCTION funcname body
    local capt, posn = capt_function:match(s, pos)
    assert(posn)
    pos = skip_ws(s, posn)
    buffer[#buffer] = '(!line '
    buffer[#buffer] = lineno
    buffer[#buffer] = ')(!assign '
    local posn, ismethod = funcname(s, pos, buffer)
    buffer[#buffer] = ' (!lambda '
    pos = skip_ws(s, posn)
    pos = body(s, pos, buffer, ismethod)
    buffer[#buffer] = ')\n'
    return pos
end


local function exprstat (s, pos, buffer)
    -- stat -> func | assignment
    local buf = {}
    local lineno = lineno
    pos = suffixedexpr(s, pos, buf)
    pos = skip_ws(s, pos)
    if tok_equal:match(s, pos) or tok_comma:match(s, pos) then
        buffer[#buffer] = tconcat(buf)
        return assignment(s, pos, buffer, 1)
    else
        buffer[#buffer] = '(!line '
        buffer[#buffer] = lineno
        buffer[#buffer] = ')'
        buffer[#buffer] = tconcat(buf)
        return pos
    end
end


local function retstat (s, pos, buffer)
    -- stat -> RETURN [explist] [';']
    buffer[#buffer] = '(!line '
    buffer[#buffer] = lineno
    buffer[#buffer] = ')(!return '
    if not block_follow(s, pos, true) and not tok_semicolon:match(s, pos) then
        pos = explist(s, pos, buffer)
    end
    buffer[#buffer] = ')'
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
        buffer[#buffer] = '(!line '
        buffer[#buffer] = lineno
        buffer[#buffer] = ')(!do'
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
    local pos = sequence(bom, position):match(s, 0) or 0
    pos = sequence(shebang, position):match(s, pos) or pos
    lineno = 1
    local buffer = { '(!line ', quote(fname), ' ', lineno, ')' }
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
    local code = translate(s, fname)
    print "; bootstrap"
    print(code)
else
    return translate
end



--
--  TvmJIT : <http://github.com/fperrad/tvmjit/>
--  Copyright (C) 2013 Francois Perrad.
--
--
--  see http://lolcode.com/specs/1.2
--

local arg = arg
local assert = assert
local error = error
local tonumber = tonumber
local tostring = tostring
local print = print
local wchar = tvm.wchar
local quote = tvm.quote
local tconcat = table.concat
local peg = require 'lpeg'
local locale = peg.locale()
local C = peg.C
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

local ch_ident = R('09', 'AZ', 'az', '__')
local tok_identifier = R('AZ', 'az') * ch_ident^0
local capt_identifier = C(tok_identifier) * Cp()

local not_ch_ident = -ch_ident
local tok_a = P'A' * not_ch_ident
local capt_a = C(tok_a) * Cp()
local tok_an = P'AN' * not_ch_ident
local capt_an = C(tok_an) * Cp()
local tok_fail = P'FAIL' * not_ch_ident
local capt_fail = C(tok_fail) * Cp()
local tok_found_yr = P'FOUND' * S' \t'^0 * P'YR' * not_ch_ident
local capt_found_yr = C(tok_found_yr) * Cp()
local tok_gimmeh = P'GIMMEH' * not_ch_ident
local capt_gimmeh = C(tok_gimmeh) * Cp()
local tok_gtfo = P'GTFO' * not_ch_ident
local capt_gtfo = C(tok_gtfo) * Cp()
local tok_hai = P'HAI' * not_ch_ident
local capt_hai = C(tok_hai) * Cp()
local tok_how_duz_i = P'HOW' * S' \t'^0 * P'DUZ' * S' \t'^0 * P'I' * not_ch_ident
local capt_how_duz_i = C(tok_how_duz_i) * Cp()
local tok_if_u_say_so = P'IF' * S' \t'^0 * P'U' * S' \t'^0 * P'SAY' * S' \t'^0 * P'SO' * not_ch_ident
local capt_if_u_say_so = C(tok_if_u_say_so) * Cp()
local tok_im_in_yr = P'IM' * S' \t'^0 * P'IN' * S' \t'^0 * P'YR' * not_ch_ident
local capt_im_in_yr = C(tok_im_in_yr) * Cp()
local tok_is_now_a = P'IS' * S' \t'^0 * P'NOW' * S' \t'^0 * P'A' * not_ch_ident
local capt_is_now_a = C(tok_is_now_a) * Cp()
local tok_itz = P'ITZ' * not_ch_ident
local capt_itz = C(tok_itz) * Cp()
local tok_i_has_a = P'I' * S' \t'^0 * P'HAS' * S' \t'^0 * P'A' * not_ch_ident
local capt_i_has_a = C(tok_i_has_a) * Cp()
local tok_kthxbye = P'KTHXBYE' * not_ch_ident
local capt_kthxbye = C(tok_kthxbye) * Cp()
local tok_maek = P'MAEK' * not_ch_ident
local capt_maek = C(tok_maek) * Cp()
local tok_mebbe = P'MEBBE' * not_ch_ident
local capt_mebbe = C(tok_mebbe) * Cp()
local tok_mkay = P'MKAY' * not_ch_ident
local capt_mkay = C(tok_mkay) * Cp()
local tok_noob = P'NOOB' * not_ch_ident
local capt_noob = C(tok_noob) * Cp()
local tok_no_wai = P'NO' * S' \t'^0 * P'WAI' * not_ch_ident
local capt_no_wai = C(tok_no_wai) * Cp()
local tok_oic = P'OIC' * not_ch_ident
local capt_oic = C(tok_oic) * Cp()
local tok_o_rly = P'O' * S' \t'^0 * P'RLY?' * not_ch_ident
local capt_o_rly = C(tok_o_rly) * Cp()
local tok_r = P'R' * not_ch_ident
local capt_r = C(tok_r) * Cp()
local tok_troof = P'TROOF' * not_ch_ident
local capt_troof = C(tok_troof) * Cp()
local tok_visible = P'VISIBLE' * not_ch_ident
local capt_visible = C(tok_visible) * Cp()
local tok_win = P'WIN' * not_ch_ident
local capt_win = C(tok_win) * Cp()
local tok_wtf = P'WTF?' * not_ch_ident
local capt_wtf = C(tok_wtf) * Cp()
local tok_ya_rly = P'YA' * S' \t'^0 * P'RLY' * not_ch_ident
local capt_ya_rly = C(tok_ya_rly) * Cp()
local tok_yr = P'YR' * not_ch_ident
local capt_yr = C(tok_yr) * Cp()

local tok_omg = P'OMG' * not_ch_ident
local tok_omgwtf = P'OMGWTF' * not_ch_ident
local tok_case = tok_omg + tok_omgwtf
local capt_case = C(tok_case) * Cp()

local tok_numbar = P'NUMBAR' * not_ch_ident
local tok_numbr = P'NUMBR' * not_ch_ident
local tok_yarn = P'YARN' * not_ch_ident
local tok_type = tok_noob + tok_numbar + tok_numbr + tok_yarn
local capt_type = C(tok_type) * Cp()

local tok_not = P'NOT' * not_ch_ident
local tok_unop = tok_not
local capt_unop = C(tok_unop) * Cp()

local tok_biggr_of = P'BIGGR' * S' \t'^0 * P'OF' * not_ch_ident
local tok_both_of = P'BOTH' * S' \t'^0 * P'OF' * not_ch_ident
local tok_both_saem = P'BOTH' * S' \t'^0 * P'SAEM' * not_ch_ident
local tok_diffrint = P'DIFFRINT' * not_ch_ident
local tok_diff_of = P'DIFF' * S' \t'^0 * P'OF' * not_ch_ident
local tok_either_of = P'EITHER' * S' \t'^0 * P'OF' * not_ch_ident
local tok_mod_of = P'MOD' * S' \t'^0 * P'OF' * not_ch_ident
local tok_produkt_of = P'PRODUKT' * S' \t'^0 * P'OF' * not_ch_ident
local tok_quoshunt_of = P'QUOSHUNT' * S' \t'^0 * P'OF' * not_ch_ident
local tok_smallr_of = P'SMALLR' * S' \t'^0 * P'OF' * not_ch_ident
local tok_sum_of = P'SUM' * S' \t'^0 * P'OF' * not_ch_ident
local tok_won_of = P'WON' * S' \t'^0 * P'OF' * not_ch_ident
local tok_binop = tok_sum_of + tok_diff_of + tok_produkt_of + tok_quoshunt_of + tok_mod_of
                + tok_biggr_of + tok_smallr_of
                + tok_both_of + tok_either_of + tok_won_of
                + tok_both_saem + tok_diffrint
local capt_binop = C(tok_binop) * Cp()

local tok_all_of = P'ALL' * S' \t'^0 * P'OF' * not_ch_ident
local tok_any_of = P'ANY' * S' \t'^0 * P'OF' * not_ch_ident
local tok_smoosh = P'SMOOSH' * not_ch_ident
local tok_infop = tok_all_of + tok_any_of + tok_smoosh
local capt_infop = C(tok_infop) * Cp()

local tok_bang = P'!' * -P'!'
local capt_bang = C(tok_bang) * Cp()

local whitespace = S' \t\v'
local newline = P'\r\n' + P'\r' + P'\n'
local empty_line = locale.space^0
local pos_empty_line = (C(empty_line) / inc_lineno) * Cp()
local single_comment = P'BTW' * (P(1) - newline)^0
local capt_btw = C(single_comment) * Cp()
local multi_comment = C(P'OBTW' * (P(1) - P'TLDR')^0 * P'TLDR' * empty_line) / inc_lineno
local capt_obtw = C(multi_comment) * Cp()
local continuation = C((P'...' + P(wchar(0x2026))) * newline * -newline) / inc_lineno
local ws = (whitespace^1 + continuation + multi_comment)^0
local capt_ws = C(ws) * Cp()
local tok_delim = whitespace^0 * (P',' + (single_comment^-1 * newline))
local delim = whitespace^0 * (P',' + (single_comment^-1 * newline * empty_line / inc_lineno))
local capt_delim = C(delim) * Cp()


local tok_float = P'-'^-1 * ((locale.digit^1 * P'.' * locale.digit^0)
                           + (P'.' * locale.digit^1))
local capt_float = C(tok_float) * Cp()
local tok_integer = P'-'^-1 * locale.digit^1 * -P'.'
local capt_integer = C(tok_integer) * Cp()

local tok_string; do
    local function gsub (patt, repl)
        return Cs(((patt / repl) + P(1))^0)
    end

    local special = {
        [')']  = "\n",
        ['>']  = "\t",
        ['o']  = "\a",
        ["'"]  = "'",
        ['"']  = '"',
        [':'] = ':',
    }

    local escape_special = P':' * C(S")>o\":")
    local gsub_escape_special = gsub(escape_special, special)
    local escape_xdigit = P':(' * C(locale.xdigit^1) * P')'
    local gsub_escape_xdigit = gsub(escape_xdigit, function (s)
                                                        return wchar(tonumber(s, 16))
                                                   end)

    local function unescape (str)
        return gsub_escape_special:match(gsub_escape_xdigit:match(str))
    end

    local ch_dq = P'::' + P':"' + (P(1) - P'"' - R'\0\31')
    tok_string = (((P'"' * Cs(ch_dq^0) * P'"') / unescape) / quote)
end
local capt_string = tok_string * Cp()

local tok_literal = tok_string + tok_integer + tok_float + tok_win + tok_fail +tok_noob
local tok_expr = tok_maek + tok_unop + tok_binop + tok_infop + tok_literal


local expression;
local statement;

local function skip_ws (s, pos)
    local capt, posn = capt_ws:match(s, pos)
    return posn
end

local function maek (s, pos, buffer)
    pos = skip_ws(s, pos)
    local buf = {}
    pos = expression(s, pos, buf)
    local exp = tconcat(buf)
    pos = skip_ws(s, pos)
    local capt, posn = capt_a:match(s, pos)
    if posn then
        pos = skip_ws(s, posn)
    end
    local capt, posn = capt_type:match(s, pos)
    if not posn then
        syntaxerror "type expected"
    end
    if     capt == 'NOOB' then
        buffer[#buffer+1] = '!nil'
    elseif capt == 'NUMBR' then
        buffer[#buffer+1] = '(!call (!index math "floor") (!call assert (!call tonumber '
        buffer[#buffer+1] = exp
        buffer[#buffer+1] = ') "cannot cast"))'
    elseif capt == 'NUMBAR' then
        buffer[#buffer+1] = '(!call assert (!call tonumber '
        buffer[#buffer+1] = exp
        buffer[#buffer+1] = ') "cannot cast")'
    elseif capt == 'TROOF' then
        buffer[#buffer+1] = '(!call _TRUTH '
        buffer[#buffer+1] = exp
        buffer[#buffer+1] = ')'
    elseif capt == 'YARN' then
        buffer[#buffer+1] = '(!call tostring '
        buffer[#buffer+1] = exp
        buffer[#buffer+1] = ')'
    end
    return posn
end

local tmpl_unop = {
    ['NOT']         = { '(!not (!call _TRUTH ', '))' },
}
local function unop (s, pos, buffer, op)
    local tmpl = assert(tmpl_unop[op])
    pos = skip_ws(s, pos)
    buffer[#buffer+1] = tmpl[1]
    pos = expression(s, pos, buffer)
    buffer[#buffer+1] = tmpl[2]
    return pos
end

local tmpl_binop = {
    ['SUM OF']      = { '(!add ', ' ', ')' },
    ['DIFF OF']     = { '(!sub ', ' ', ')' },
    ['PRODUKT OF']  = { '(!mul ', ' ', ')' },
    ['QUOSHUNT OF'] = { '(!div ', ' ', ')' },
    ['MOD OF']      = { '(!mod ', ' ', ')' },
    ['BIGGR OF']    = { '(!call (!index math "max") ', ' ', ')' },
    ['SMALLR OF']   = { '(!call (!index math "min") ', ' ', ')' },
    ['BOTH OF']     = { '(!call _AND ', ' ', ')' },
    ['EITHER OF']   = { '(!call _OR ',  ' ', ')' },
    ['WON OF']      = { '(!call _XOR ', ' ', ')' },
    ['BOTH SAEM']   = { '(!eq ',  ' ', ')' },
    ['DIFFRINT']    = { '(!ne ',  ' ', ')' },
}
local function binop (s, pos, buffer, op)
    local tmpl = assert(tmpl_binop[op])
    pos = skip_ws(s, pos)
    buffer[#buffer+1] = tmpl[1]
    pos = expression(s, pos, buffer)
    pos = skip_ws(s, pos)
    local capt, posn = capt_an:match(s, pos)
    if posn then
        pos = skip_ws(s, posn)
    end
    buffer[#buffer+1] = tmpl[2]
    pos = expression(s, pos, buffer)
    buffer[#buffer+1] = tmpl[3]
    return pos
end

local tmpl_infop = {
    ['ALL OF']      = { '(!call _MAND ', ' ', ')' },
    ['ANY OF']      = { '(!call _MOR ',  ' ', ')' },
    ['SMOOSH']      = { '(!mconcat ', ' ', ')' },
}
local function infop (s, pos, buffer, op)
    local tmpl = assert(tmpl_infop[op])
    pos = skip_ws(s, pos)
    buffer[#buffer+1] = tmpl[1]
    while not tok_mkay:match(s, pos) and not tok_delim:match(s, pos) do
        pos = expression(s, pos, buffer)
        pos = skip_ws(s, pos)
        local capt, posn = capt_an:match(s, pos)
        if posn then
            pos = skip_ws(s, posn)
        end
        buffer[#buffer+1] = tmpl[2]
    end
    local capt, posn = capt_mkay:match(s, pos)
    if posn then
        pos = posn
    end
    buffer[#buffer+1] = tmpl[3]
    return pos
end

local function literal (s, pos, buffer, omg)
    local capt, posn = capt_string:match(s, pos)
    if posn then
        if capt:match':%b{}' then
            if omg then
                syntaxerror "interpolation not allowed"
            end
            buffer[#buffer+1] = '(!mconcat '
            buffer[#buffer+1] = capt:gsub(":(%b{})", function (s)
                                                        s = s:sub(2, -2)
                                                        return '" ' .. tostring(s) .. ' "'
                                                     end)
            buffer[#buffer+1] = ')'
        else
            buffer[#buffer+1] = capt
        end
        return posn
    end
    capt, posn = capt_integer:match(s, pos)
    if posn then
        buffer[#buffer+1] = capt
        return posn
    end
    capt, posn = capt_float:match(s, pos)
    if posn then
        buffer[#buffer+1] = capt
        return posn
    end
    capt, posn = capt_win:match(s, pos)
    if posn then
        buffer[#buffer+1] = '!true'
        return posn
    end
    capt, posn = capt_fail:match(s, pos)
    if posn then
        buffer[#buffer+1] = '!false'
        return posn
    end
    capt, posn = capt_noob:match(s, pos)
    if posn then
        buffer[#buffer+1] = '!nil'
        return posn
    end
    syntaxerror "LITERAL expected"
end

function expression (s, pos, buffer)
    local capt, posn = capt_maek:match(s, pos)
    if posn then
        return maek(s, posn, buffer)
    end
    capt, posn = capt_unop:match(s, pos)
    if posn then
        return unop(s, posn, buffer, capt:gsub('%s+', ' '))
    end
    capt, posn = capt_binop:match(s, pos)
    if posn then
        return binop(s, posn, buffer, capt:gsub('%s+', ' '))
    end
    capt, posn = capt_infop:match(s, pos)
    if posn then
        return infop(s, posn, buffer, capt:gsub('%s+', ' '))
    end
    if tok_win:match(s, pos) or tok_fail:match(s, pos) or tok_noob:match(s, pos) then
        return literal(s, pos, buffer)
    end
    capt, posn = capt_identifier:match(s, pos)
    if posn then
        local arity = buffer.arity[capt]
        if arity then
            buffer[#buffer+1] = '(!call '
            buffer[#buffer+1] = capt
            pos = skip_ws(s, posn)
            for _ = 1, arity do
                buffer[#buffer+1] = ' '
                pos = expression(s, pos, buffer)
                pos = skip_ws(s, pos)
            end
            buffer[#buffer+1] = ')'
            return pos
        else
            buffer[#buffer+1] = capt
            return posn
        end
    end
    return literal(s, pos, buffer)
end

local function i_has_a (s, pos, buffer)
    pos = skip_ws(s, pos)
    buffer[#buffer+1] = '(!line '
    buffer[#buffer+1] = lineno
    buffer[#buffer+1] = ')'
    local capt, posn = capt_identifier:match(s, pos)
    if not posn then
        syntaxerror "identifier expected"
    end
    buffer[#buffer+1] = '(!define '
    buffer[#buffer+1] = capt
    pos = skip_ws(s, posn)
    capt, posn = capt_itz:match(s, pos)
    if posn then
        pos = skip_ws(s, posn)
        capt, posn = capt_a:match(s, pos)
        if posn then
            pos = skip_ws(s, posn)
            capt, posn = capt_type:match(s, pos)
            if not posn then
                syntaxerror "type expected"
            end
            if     capt == 'NOOB' then
                buffer[#buffer+1] = ' !nil)'
            elseif capt == 'NUMBR' then
                buffer[#buffer+1] = ' 0)'
            elseif capt == 'NUMBAR' then
                buffer[#buffer+1] = ' 0.0)'
            elseif capt == 'TROOF' then
                buffer[#buffer+1] = ' !false)'
            elseif capt == 'YARN' then
                buffer[#buffer+1] = ' "")'
            end
            return posn
        else
            buffer[#buffer+1] = ' '
            pos = expression(s, pos, buffer)
        end
    end
    buffer[#buffer+1] = ')'
    return pos
end

local function r (s, pos, buffer, varname)
    pos = skip_ws(s, pos)
    buffer[#buffer+1] = '(!line '
    buffer[#buffer+1] = lineno
    buffer[#buffer+1] = ')(!assign '
    buffer[#buffer+1] = varname
    buffer[#buffer+1] = ' '
    pos = expression(s, pos, buffer)
    buffer[#buffer+1] = ')'
    return pos
end

local function is_now_a (s, pos, buffer, varname)
    pos = skip_ws(s, pos)
    buffer[#buffer+1] = '(!line '
    buffer[#buffer+1] = lineno
    buffer[#buffer+1] = ')(!assign '
    buffer[#buffer+1] = varname
    local capt, posn = capt_type:match(s, pos)
    if not posn then
        syntaxerror "type expected"
    end
    if     capt == 'NOOB' then
        buffer[#buffer+1] = ' !nil'
    elseif capt == 'NUMBR' then
        buffer[#buffer+1] = ' (!call (!index math "floor") (!call assert (!call tonumber '
        buffer[#buffer+1] = varname
        buffer[#buffer+1] = ') "cannot cast")))'
    elseif capt == 'NUMBAR' then
        buffer[#buffer+1] = ' (!call assert (!call tonumber '
        buffer[#buffer+1] = varname
        buffer[#buffer+1] = ') "cannot cast"))'
    elseif capt == 'TROOF' then
        buffer[#buffer+1] = ' (!not (!not '
        buffer[#buffer+1] = varname
        buffer[#buffer+1] = ')))'
    elseif capt == 'YARN' then
        buffer[#buffer+1] = ' (!call tostring '
        buffer[#buffer+1] = varname
        buffer[#buffer+1] = '))'
    end
    return posn
end

local function gimmeh (s, pos, buffer)
    pos = skip_ws(s, pos)
    buffer[#buffer+1] = '(!line '
    buffer[#buffer+1] = lineno
    buffer[#buffer+1] = ')'
    local capt, posn = capt_identifier:match(s, pos)
    if not posn then
        syntaxerror "identifier expected"
    end
    buffer[#buffer+1] = '(!assign '
    buffer[#buffer+1] = capt
    buffer[#buffer+1] = '(!call (!index io "read"))'
    return posn
end

local function visible (s, pos, buffer)
    pos = skip_ws(s, pos)
    buffer[#buffer+1] = '(!line '
    buffer[#buffer+1] = lineno
    buffer[#buffer+1] = ')'
    buffer[#buffer+1] = '(!call _VISIBLE '
    while not tok_bang:match(s, pos) and not tok_delim:match(s, pos) do
        pos = expression(s, pos, buffer)
        buffer[#buffer+1] = ' '
        pos = skip_ws(s, pos)
    end
    local capt, posn = capt_bang:match(s, pos)
    if posn then
        pos = posn
    else
        buffer[#buffer+1] = '\"\\n\"'
    end
    buffer[#buffer+1] = ')'
    return pos
end

local function funcargs (s, pos, buffer, name)
    local arity = 0
    while tok_yr:match(s, pos) do
        local capt, posn = capt_yr:match(s, pos)
        pos = skip_ws(s, posn)
        capt, posn = capt_identifier:match(s, pos)
        if not posn then
            syntaxerror "identifier expected"
        end
        pos = skip_ws(s, posn)
        buffer[#buffer+1] = capt
        buffer[#buffer+1] = ' '
        arity = arity + 1
        capt, posn = capt_an:match(s, pos)
        if posn then
            pos = skip_ws(s, posn)
        end
    end
    buffer.arity[name] = arity
    return pos
end

local function how_duz_i (s, pos, buffer)
    if buffer.in_function then
        syntaxerror "cannot define nested functions"
    end
    buffer.in_function = true
    pos = skip_ws(s, pos)
    buffer[#buffer+1] = '(!line '
    buffer[#buffer+1] = lineno
    buffer[#buffer+1] = ')(!let '
    local capt, posn = capt_identifier:match(s, pos)
    if not posn then
        syntaxerror "identifier expected"
    end
    pos = skip_ws(s, posn)
    buffer[#buffer+1] = capt
    buffer[#buffer+1] = ' (!lambda ('
    pos = funcargs(s, pos, buffer, capt)
    capt, pos = capt_delim:match(s, pos)
    if not pos then
       syntaxerror "statement delimiter expected"
    end
    buffer[#buffer+1] = ') (!define IT)'
    pos = skip_ws(s, pos)
    while not tok_if_u_say_so:match(s, pos) do
        buffer[#buffer+1] = '\n'
        pos = statement(s, pos, buffer)
        capt, pos = capt_delim:match(s, pos)
        if not pos then
            syntaxerror "statement delimiter expected"
        end
        pos = skip_ws(s, pos)
    end
    capt, pos = capt_if_u_say_so:match(s, pos)
    buffer[#buffer+1] = '\n(!return IT)))'
    buffer.in_function = false
    return pos
end

local function gtfo (s, pos, buffer)
    if not buffer.in_function then
        syntaxerror "GTFO not allowed here"
    end
    pos = skip_ws(s, pos)
    buffer[#buffer+1] = '(!line '
    buffer[#buffer+1] = lineno
    buffer[#buffer+1] = ')(!return)'
    return pos
end

local function found_yr (s, pos, buffer)
    if not buffer.in_function then
        syntaxerror "FOUND YR not allowed here"
    end
    pos = skip_ws(s, pos)
    buffer[#buffer+1] = '(!line '
    buffer[#buffer+1] = lineno
    buffer[#buffer+1] = ')(!return '
    pos = expression(s, pos , buffer)
    buffer[#buffer+1] = ')'
    return pos
end

local function wtf (s, pos, buffer)
    local capt, posn = capt_delim:match(s, pos)
    if not posn then
        syntaxerror "statement delimiter expected"
    end
    buffer[#buffer+1] = '(!line '
    buffer[#buffer+1] = lineno
    buffer[#buffer+1] = ')(!do '
    pos = skip_ws(s, posn)
    local case = {}
    local lbl = 1
    while not tok_oic:match(s, pos) do
        local capt, posn = capt_case:match(s, pos)
        if not posn then
            syntaxerror "OMG or OMGWTF expected"
        end
        pos = skip_ws(s, posn)
        if capt == 'OMG' then
            buffer[#buffer+1] = '(!if (!ne IT '
            pos = literal(s, pos, buffer, true)
            local lit = buffer[#buffer]
            if case[lit] then
                syntaxerror "duplicated OMG"
            end
            case[lit] = true
            buffer[#buffer+1] = ') (!goto L' .. lbl .. '))'
        end
        capt, posn = capt_delim:match(s, pos)
        if not posn then
            syntaxerror "statement delimiter expected"
        end
        pos = skip_ws(s, posn)
        while not tok_oic:match(s, pos)
          and not tok_case:match(s, pos)
          and not tok_gtfo:match(s, pos) do
            buffer[#buffer+1] = '\n'
            pos = statement(s, pos, buffer)
            capt, posn = capt_delim:match(s, pos)
            if not posn then
                syntaxerror "statement delimiter expected"
            end
            pos = skip_ws(s, posn)
        end
        capt, posn = capt_gtfo:match(s, pos)
        if posn then
            buffer[#buffer+1] = '\n(!line '
            buffer[#buffer+1] = lineno
            buffer[#buffer+1] = ')(!goto L0)'
            capt, posn = capt_delim:match(s, posn)
            if not posn then
                syntaxerror "statement delimiter expected"
            end
            pos = skip_ws(s, posn)
        end
        buffer[#buffer+1] = '\n(!label L' .. lbl .. ')\n'
        lbl = lbl + 1
    end
    buffer[#buffer+1] = '(!label L0)\n)'
    capt, pos = capt_oic:match(s, pos)
    return pos
end

local function o_rly (s, pos, buffer)
    local capt, posn = capt_delim:match(s, pos)
    if not posn then
        syntaxerror "statement delimiter expected"
    end
    pos = skip_ws(s, posn)
    local capt, posn = capt_ya_rly:match(s, pos)
    if not posn then
        syntaxerror "YA RLY expected"
    end
    pos = skip_ws(s, posn)
    buffer[#buffer+1] = '(!line '
    buffer[#buffer+1] = lineno
    buffer[#buffer+1] = ')(!if (!call _TRUTH IT) (!do'
    local buf = { ')' }
    capt, posn = capt_delim:match(s, pos)
    if not posn then
        syntaxerror "statement delimiter expected"
    end
    pos = skip_ws(s, posn)
    while not tok_oic:match(s, pos)
      and not tok_no_wai:match(s, pos)
      and not tok_mebbe:match(s, pos) do
        buffer[#buffer+1] = '\n'
        pos = statement(s, pos, buffer)
        capt, posn = capt_delim:match(s, pos)
        if not posn then
            syntaxerror "statement delimiter expected"
        end
        pos = skip_ws(s, posn)
    end
    buffer[#buffer+1] = ')'
    while tok_mebbe:match(s, pos) do
        capt, posn = capt_mebbe:match(s, pos)
        buffer[#buffer+1] = '\n(!if '
        buf[#buf+1] = ')'
        pos = skip_ws(s, posn)
        pos = expression(s, pos, buffer)
        capt, posn = capt_delim:match(s, pos)
        if not posn then
            syntaxerror "statement delimiter expected"
        end
        pos = skip_ws(s, posn)
        buffer[#buffer+1] = '(!do'
        while not tok_oic:match(s, pos)
          and not tok_no_wai:match(s, pos)
          and not tok_mebbe:match(s, pos) do
            buffer[#buffer+1] = '\n'
            pos = statement(s, pos, buffer)
            capt, posn = capt_delim:match(s, pos)
            if not posn then
                syntaxerror "statement delimiter expected"
            end
            pos = skip_ws(s, posn)
        end
        buffer[#buffer+1] = ')'
    end
    capt, posn = capt_no_wai:match(s, pos)
    if posn then
        pos = skip_ws(s, posn)
        capt, posn = capt_delim:match(s, pos)
        if not posn then
            syntaxerror "statement delimiter expected"
        end
        pos = skip_ws(s, posn)
        buffer[#buffer+1] = '(!do'
        while not tok_oic:match(s, pos) do
            buffer[#buffer+1] = '\n'
            pos = statement(s, pos, buffer)
            capt, posn = capt_delim:match(s, pos)
            if not posn then
                syntaxerror "statement delimiter expected"
            end
            pos = skip_ws(s, posn)
        end
        buffer[#buffer+1] = ')'
    end
    buffer[#buffer+1] = tconcat(buf)
    capt, pos = capt_oic:match(s, pos)
    return pos
end

function statement (s, pos, buffer)
    pos = skip_ws(s, pos)
    local capt, posn = capt_btw:match(s, pos)
    if posn then
        return posn
    end
    capt, posn = capt_obtw:match(s, pos)
    if posn then
        return posn
    end
    capt, posn = capt_im_in_yr:match(s, pos)
    if posn then
        return im_in_yr(s, posn, buffer)
    end
    capt, posn = capt_o_rly:match(s, pos)
    if posn then
        return o_rly(s, posn, buffer)
    end
    capt, posn = capt_wtf:match(s, pos)
    if posn then
        return wtf(s, posn, buffer)
    end
    capt, posn = capt_i_has_a:match(s, pos)
    if posn then
        return i_has_a(s, posn, buffer)
    end
    capt, posn = capt_gimmeh:match(s, pos)
    if posn then
        return gimmeh(s, posn, buffer)
    end
    capt, posn = capt_visible:match(s, pos)
    if posn then
        return visible(s, posn, buffer)
    end
    capt, posn = capt_how_duz_i:match(s, pos)
    if posn then
        return how_duz_i(s, posn, buffer)
    end
    capt, posn = capt_gtfo:match(s, pos)
    if posn then
        return gtfo(s, posn, buffer)
    end
    capt, posn = capt_found_yr:match(s, pos)
    if posn then
        return found_yr(s, posn, buffer)
    end
    if tok_expr:match(s, pos) then
        buffer[#buffer+1] = '(!line '
        buffer[#buffer+1] = lineno
        buffer[#buffer+1] = ')(!assign IT '
        pos = expression(s, pos, buffer)
        buffer[#buffer+1] = ')'
        return pos
    end
    capt, posn = capt_identifier:match(s, pos)
    if posn then
        local varname = capt
        pos = skip_ws(s, posn)
        capt, posn = capt_r:match(s, pos)
        if posn then
            return r(s, posn, buffer, varname)
        end
        capt, posn = capt_is_now_a:match(s, pos)
        if posn then
            return is_now_a(s, posn, buffer, varname)
        end
        buffer[#buffer+1] = '(!line '
        buffer[#buffer+1] = lineno
        buffer[#buffer+1] = ')(!assign IT '
        local arity = buffer.arity[varname]
        if arity then
            buffer[#buffer+1] = '(!call '
            buffer[#buffer+1] = varname
            pos = skip_ws(s, pos)
            for _ = 1, arity do
                buffer[#buffer+1] = ' '
                pos = expression(s, pos, buffer)
                pos = skip_ws(s, pos)
            end
            buffer[#buffer+1] = ')'
        else
            buffer[#buffer+1] = varname
        end
        buffer[#buffer+1] = ')'
        return pos
    end
    assert(0)
end

function program (s, pos, buffer)
    pos = skip_ws(s, pos)
    local capt, posn = capt_hai:match(s, pos)
    if not posn then
        syntaxerror "HAI expected"
    end
    pos = skip_ws(s, posn)
    capt, posn = capt_float:match(s, pos)
    if posn then
        if capt ~= '1.2' then
            syntaxerror "bad version"
        end
        pos = skip_ws(s, posn)
    end
    capt, posn = capt_delim:match(s, pos)
    if not posn then
        syntaxerror "statement delimiter expected"
    end
    pos = pos_empty_line:match(s, pos)
    while not tok_kthxbye:match(s, pos) do
        buffer[#buffer+1] = '\n'
        pos = statement(s, pos, buffer)
        capt, pos = capt_delim:match(s, pos)
        if not pos then
            syntaxerror "statement delimiter expected"
        end
    end
    capt, posn = capt_kthxbye:match(s, pos)
    if not posn then
        syntaxerror "KTHXBYE expected"
    end
    capt, posn = capt_delim:match(s, posn)
    if not posn then
        syntaxerror "delim expected"
    end
    return posn
end

local prelude = [[
(!line "@prelude(lolcode/translator.lua)" 1)

(!let _TRUTH (!lambda (v)
                (!let t (!call type v))
                (!cond ((!eq t "string") (!return (!ne v "")))
                       ((!eq t "number") (!return (!ne v 0)))
                       ((!eq t "table")  (!return (!ne (!len v) 0)))
                       (!true            (!return v)))))
(!let _AND (!lambda (a b)
                (!assign a (!call _TRUTH a))
                (!if (!not a) (!return !false)
                              (!return (!call _TRUTH b)))))
(!let _OR (!lambda (a b)
                (!assign a (!call _TRUTH a))
                (!if a (!return !true)
                       (!return (!call _TRUTH b)))))
(!let _XOR (!lambda (a b)
                (!assign a (!call _TRUTH a))
                (!assign b (!call _TRUTH b))
                (!return (!or (!and a (!not b)) (!and (!not a) b)))))
(!let _MAND (!lambda (!vararg)
                (!let t (!vararg))
                (!loop i 1 (!len t) 1
                        (!if (!not (!call _TRUTH (!index t i))) (!return !false)))
                (!return !true)))
(!let _MOR (!lambda (!vararg)
                (!let t (!vararg))
                (!loop i 1 (!len t) 1
                        (!if (!call _TRUTH (!index t i)) (!return !true)))
                (!return !false)))

(!let _VISIBLE (!lambda (!vararg)
                (!let t (!vararg))
                (!let out (!index io "stdout"))
                (!loop i 1 (!len t) 1
                        (!callmeth out write (!call tostring (!index t i))))))

(!define IT)
; end of prelude
]]

local function translate (s, fname)
    lineno = 1
    local buffer = {
        prelude, '(!line ', quote(fname), ' ', lineno, ')';
        in_function = false,
        arity = {},
    }
    local pos = program(s, pos_empty_line:match(s, 1), buffer)
    if not P(-1):match(s, pos_empty_line:match(s, pos)) then
        syntaxerror("<eof> expected at " .. pos)
    end
    buffer[#buffer+1] = "\n; end of generation"
    return tconcat(buffer)
end


local fname = arg and arg[1]
if fname then
    local f, msg = io.open(fname, 'r')
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

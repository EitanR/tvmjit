--
--  TvmJIT : <http://github.com/fperrad/tvmjit/>
--  Copyright (C) 2013 Francois Perrad.
--

--
--      Note: the interactive mode requires lua-linenoise built for Lua 5.1
--      see https://github.com/hoelzro/lua-linenoise
--

local load = tvm.load
local dofile = tvm.dofile

arg = {}
local compiler = dofile 'nqp/translator.tp'

local function print_version ()
    print "nqp/TvmJIT\tCopyright (C) 2013 Francois Perrad"
end

local function handle_script (argv, script)
    local fname = argv[script]
    local arg = {}
    arg[0] = ''
    for i = script+1, #argv do
        arg[#arg+1] = argv[i]
    end
    local chunk
    if fname == '-' then
        chunk = io.stdin:read'*a'
        fname = '=stdin'
    else
        local fh = assert(io.open(fname, 'r'))
        chunk = fh:read'*a'
        fh:close()
    end
    local code = compiler(chunk, '@' .. fname)
    assert(load(code, fname))(table.unpack(arg))
end

local function dotty ()
    local l = require 'linenoise'
    local prompt = '> '
    local history = 'history.txt'
    local name = '=stdin'
    l.historyload(history)
    local line = l.linenoise(prompt)
    while line do
        if line ~= '' then
            local r, msg = pcall(function ()
                        local code = compiler(line, name)
                        assert(load(code, name))()
            end)
            if not r then
                print(msg)
            end
            l.historyadd(line)
            l.historysave(history)
        end
        line = l.linenoise(prompt)
    end
end

local argv = {...}
local script = argv[1]
if script then
    handle_script(argv, 1)
else
    print_version()
    dotty()
end


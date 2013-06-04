--
--  TvmJIT : <http://github.com/fperrad/tvmjit/>
--  Copyright (C) 2013 Francois Perrad.
--

--
--      Note: the interactive mode requires lua-linenoise built for Lua 5.1
--      see https://github.com/hoelzro/lua-linenoise
--

local dofile = tvm.dofile
local load = tvm.load
local tostring = tostring
local unpack = unpack

arg = {}
local compiler = dofile 'nqp/compiler.tp'

local target;

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
    local ast = compiler(chunk, fname)
    if target == 'ast' then
        ast:reset'prelude'
        ast:reset'termination'
        print(ast:dump())
    else
        local code = tostring(ast:as_op())
        if target == 'op' then
            print(code)
        else
            assert(load(code, fname))(unpack(arg))
        end
    end
end

local function dotty ()
    assert(load(tostring(compiler('', '=prelude'):as_op()), name))()
    local l = require 'linenoise'
    local prompt = '> '
    local history = 'history.txt'
    local name = '=stdin'
    l.historyload(history)
    local line = l.linenoise(prompt)
    while line do
        if line ~= '' then
            local r, msg = pcall(function ()
                        local ast = compiler(line, name)[1]
                        if target == 'ast' then
                            print(ast:dump())
                        else
                            local code= tostring(ast:as_op())
                            if target == 'op' then
                                print(code)
                            else
                                assert(load(code, name))()
                            end
                        end
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
local n = 1
if argv[1] == '--ast' then
    target = 'ast'
    n = 2
end
if argv[1] == '--op' then
    target = 'op'
    n = 2
end
if argv[1] == '--help' then
    print[=[
usage: nqp.tp [options] [script [args]]
Available options are:
  --ast    dump the AST
  --op     dump the TP code
]=]
    os.exit()
end
local script = argv[n]
if script then
    handle_script(argv, n)
else
    print_version()
    dotty()
end


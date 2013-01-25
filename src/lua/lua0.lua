--
--  TvmJIT : <http://github.com/fperrad/tvmjit/>
--  Copyright (C) 2013 Francois Perrad.
--

--
--      lua0 uses Lua syntax, but array and string start at 0.
--      Note: the interactive mode requires lua-linenoise built for Lua 5.1
--      see https://github.com/hoelzro/lua-linenoise
--

arg = {}
local compiler = require 'lua/lunokhod'

local function print_version ()
    print "Lua0\tCopyright (C) 2013 Francois Perrad"
end

local function dostring (chunk, name)
    local code = compiler(chunk, name)
    assert(load(code, name))()
end

local function dolibrary (name)
    require(name)
end

local function handle_luainit ()
    local LUA_INIT = "LUA0_INIT"
    local init = os.getenv(LUA_INIT)
    if not init then return end
    if init:sub(0, 0) == '@' then
        dofile(init:sub(1))
    else
        dostring(init, '=' .. LUA_INIT)
    end
end

local function handle_script (argv, script)
    local fname = argv[script]
    local arg = {}
    for i = script+1, #argv-1 do
        arg[#arg] = argv[i]
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
    local code = compiler(chunk, fname)
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
        if #line > 0 then
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

local function collectargs (argv, opt)
    local i = 0
    while i < #argv do
        local arg = argv[i]
        if arg:sub(0, 0) ~= '-' then  -- not an option?
            return i
        end
        local arg1 = arg:sub(1, 1)
        if arg1 == '-' then
            if #arg > 2 then return nil end
            return argv[i+1] and i+1 or 0
        elseif arg1 == '' then
            return i
        elseif arg1 == 'i' then
            if #arg > 2 then return nil end
            opt.i = true
            opt.v = true
        elseif arg1 == 'v' then
            if #arg > 2 then return nil end
            opt.v = true
        elseif arg1 == 'e' then
            opt.e = true
            if #arg == 2 then
                i = i + 1
                if argv[i] == nil then return nil end
            end
        elseif arg1 == 'l' then
            if #arg == 2 then
                i = i + 1
                if argv[i] == nil then return nil end
            end
        else
            return nil  -- invalid option
        end
        i = i + 1
    end
    return i
end

local function runargs(argv, n)
    local i = 0
    while i < n do
        local arg = argv[i]
        local arg2 = arg:sub(0, 1)
        if arg2 == '-e' then
           local chunk = arg:sub(2)
           if chunk == '' then
                i = i + 1
                chunk = argv[i]
           end
           dostring(chunk, "=(command line)")
        elseif arg2 == '-l' then
           local name = arg:sub(2)
           if name == '' then
                i = i + 1
                name = argv[i]
           end
           dolibrary(name)
        end
        i = i + 1
    end
end

local argv = {...}
local opt = {}
local script = collectargs(argv, opt)
if not script then
    io.stderr:write [=[
usage: lua0.tp [options] [script [args]]
Available options are:
  -e stat  execute string 'stat'
  -i       enter interactive mode after executing 'script'
  -l name  require library 'name'
  -v       show version information
  --       stop handling options
  -        stop handling options and execute stdin
]=]
    os.exit(1)
end
if opt.v then
    print_version()
end
handle_luainit()
runargs(argv, script)
if argv[script] then
    handle_script(argv, script)
end
if opt.i then
    dotty()
elseif not argv[script] and not opt.e and not opt.v then
    print_version()
    dotty()
end


--
--  TvmJIT : <http://github.com/fperrad/tvmjit/>
--  Copyright (C) 2013 Francois Perrad.
--

local load = tvm.load
local dofile = tvm.dofile

arg = {}
local compiler = dofile 'lolcode/translator.tp'

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

local argv = {...}
local script = argv[1]
if script then
    handle_script(argv, 1)
else
    print[[
Usage: lolcode.tp filename.lol
]]
    os.exit(false)
end


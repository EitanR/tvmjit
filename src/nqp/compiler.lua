
--
--  TvmJIT : <http://github.com/fperrad/tvmjit/>
--  Copyright (C) 2013 Francois Perrad.
--

do -- mop

local assert = assert
local debug = debug
local error = error
local next = next
local pairs = pairs
local rawget = rawget
local rawset = rawset
local setmetatable = setmetatable
local tconcat = table.concat
local tonumber = tonumber
local tostring = tostring
local type = type
local _G = _G

local stdout = io.stdout
local stderr = io.stderr

local function print (...)
    local a = {...}
    for i = 1, #a do
        stdout:write(a[i]:str())
    end
end

local function say (...)
    local a = {...}
    for i = 1, #a do
        stdout:write(a[i]:str())
    end
    stdout:write"\n"
end

local function note (...)
    local a = {...}
    for i = 1, #a do
        stderr:write(a[i]:str())
    end
    stderr:write"\n"
end


local function argerror (caller, narg, extramsg)
    error("bad argument #" .. tostring(narg) .. " to "
          .. caller .. " (" .. extramsg .. ")")
end

local function typeerror (caller, narg, arg, tname)
    argerror(caller, narg, tname .. " expected, got " .. type(arg))
end

local function checktype (caller, narg, arg, tname)
    if type(arg) ~= tname then
        typeerror(caller, narg, arg, tname)
    end
end


function uml2dot (opt)
    opt = opt or {}
    local with_attr = not opt.no_attr
    local with_meth = not opt.no_meth
    local note = opt.note
    local out = {'digraph {\n\n    node [shape=record];\n\n'}
    if note then
        out[#out+1] = '    "__note__"\n'
        out[#out+1] = '        [label="' .. note .. '" shape=note];\n\n'
    end
    for classname, class in pairs(_G) do
        if type(class) == 'table' and class._CLASS == _G['NQP::Metamodel::ClassHOW'] then
            out[#out+1] = '    "' .. classname .. '"\n'
            out[#out+1] = '        [label="{'
            out[#out+1] = '\\N'
            if with_attr then
                local first = true
                for name in pairs(class._VALUES.attributes) do
                    if first then
                        out[#out+1] = '|'
                        first = false
                    end
                    out[#out+1] = name
                    out[#out+1] = '\\l'
                end
            end
            if with_meth then
                local first = true
                for name in pairs(class._VALUES.methods) do
                    if first then
                        out[#out+1] = '|'
                        first = false
                    end
                    out[#out+1] = name .. '()\\l'
                end
            end
            out[#out+1] = '}"];\n'
            local parents = class._VALUES.parents
            for i = 1, #parents do
                local parent = parents[i]
                out[#out+1] = '    "' .. classname .. '" -> "' .. parent._VALUES.name .. '" // extends\n'
                out[#out+1] = '        [arrowhead = onormal, arrowtail = none, arrowsize = 2.0];\n'
            end
            out[#out+1] = '\n'
        end
    end
    out[#out+1] = '}'
    return tconcat(out)
end


local function Mu_INIT (obj, class, args)
    for k, attr in pairs(class._VALUES.attributes) do
        if obj._VALUES[k] == nil then
            local val = args[k] or attr.default
            if type(val) == 'function' then
                val = val(obj)
            end
            obj._VALUES[k] = val
        end
    end
    local parents = class._VALUES.parents
    for i = 1, #parents do
        Mu_INIT(obj, parents[i], args)
    end
end

local function Mu_BUILD (class, args)
    local obj = {
        _VALUES = {},
        _CLASS = class,
    }
    Mu_INIT(obj, class, args)
    return obj
end


local p6class; do
do
    local function class_add_method (meta, name, func)
        checktype('add_method', 2, name, 'string')
        checktype('add_method', 3, func, 'function')
        local methods = meta._VALUES.methods
        if methods[name] then
            error("This class already has a method named " .. name)
        end
        methods[name] = func
        meta._VALUES.proto[name] = func
    end

    local proto = {
        add_method = class_add_method,
    }
    p6class = {
        _VALUES = {
            name = 'NQP::Metamodel::ClassHOW',
            proto = proto,
            attributes = {},
            methods = {
                add_method = class_add_method,
            },
            parents = {},
            roles = {},
            ISA = { p6class },
        },
    }
    p6class._CLASS = p6class
    setmetatable(p6class, {
        __index = p6class._VALUES.proto,
        __tostring = function (o) return o._VALUES.name end,
    })
end

local how = p6class
how.add_method(p6class, 'new', function (self, name)
                local mt = {
                    __tostring = function (o) return o:str() end,
                }
                local class = Mu_BUILD(p6class, { name = name, mt = mt })
                mt.__index = class._VALUES.proto
                return setmetatable(class, {
                        __index = class._VALUES.proto,
                        __tostring = function (o) return name end,
                }) end)
how.add_method(p6class, 'str', function (meta)
                return meta._VALUES.name end)
how.add_method(p6class, 'add_attribute', function (meta, attr)
                local name = attr.name
                checktype('add_attribute', 'name', name, 'string')
                local attributes = meta._VALUES.attributes
                if attributes[name] then
                    error("This class already has an attribute named " .. name)
                end
                attributes[name] = attr
                meta._VALUES.proto[name] = function (obj, val)
                                local t = rawget(obj, '_VALUES')
                                if val ~= nil then
                                    t[name] = val
                                else
                                    return t[name]
                                end
                                end
                end)
how.add_attribute(p6class, { name = 'name', default = '<anon>' })
how.add_attribute(p6class, { name = 'proto', default = function () return {} end })
how.add_attribute(p6class, { name = 'methods', default = function () return {} end })
how.add_attribute(p6class, { name = 'attributes', default = function () return {} end })
how.add_attribute(p6class, { name = 'parents', default = function () return {} end })
how.add_attribute(p6class, { name = 'ISA', default = function (self) return { self } end })
how.add_attribute(p6class, { name = 'mt' })
how.add_method(p6class, 'HOW', function (meta)
                return p6class._VALUES.proto end)
how.add_method(p6class, 'add_parent', function (meta, parent)
                if meta == parent then
                    error("Class '" .. meta:name() .. "' cannot inherit from itself.")
                end
                local parents = meta._VALUES.parents
                for i = 1, #parents do
                    if parents[i] == parent then
                        error("Already have " .. parent:name() .. " as a parent class.")
                    end
                end
                parents[#parents+1] = parent
                local ISA = meta._VALUES.ISA
                ISA[#ISA+1] = parent._VALUES.ISA
                setmetatable(meta._VALUES.proto, {
                        __index = function (t, k)
                            local function search (class)
                                local parents = class._VALUES.parents
                                for i = 1, #parents do
                                    local p = parents[i]
                                    local v = rawget(p._VALUES.proto, k) or search(p)
                                    if v then
                                        return v
                                    end
                                end
                            end -- search
                            local v = search(meta)
                            t[k] = v        -- save for next access
                            return v
                        end,
                })
                end)
_G['NQP::Metamodel::ClassHOW'] = p6class
how.add_method(p6class, 'can', function (meta, name)
                return meta._VALUES.proto[name] ~= nil
                end)
how.add_method(p6class, 'isa', function (meta, parent)
                local function walk (types)
                    for i = 1, #types do
                        local v = types[i]
                        if v == parent then
                            return true
                        elseif type(v) == 'table' then
                            local result = walk(v)
                            if result then
                                return result
                            end
                        end
                    end
                    return false
                end -- walk
                return walk(meta._VALUES.ISA)
                end)
end


local p6mu = p6class:new('Mu')
do
local how = p6class:HOW()
_G['Mu'] = p6mu
how.add_method(p6mu, 'new', function (class, args)
                return setmetatable(Mu_BUILD(class, args), class._VALUES.mt) end)
how.add_method(p6mu, 'reset', function (self, attrname)
                self._VALUES[attrname] = nil
                end)
how.add_method(p6mu, 'defined', function (self)
                return true end)
how.add_method(p6mu, 'WHAT', function (self)
                return rawget(self, '_CLASS') end)
how.add_method(p6mu, 'str', function (self)
                return self:WHAT()._VALUES.name end)
how.add_method(p6mu, 'gist', function (self)
                return self:WHAT()._VALUES.name end)
how.add_method(p6mu, 'print', function (self)
                print(self) end)
how.add_method(p6mu, 'say', function (self)
                self:gist():say() end)
end


local p6any = p6class:new('Any')
do
local how = p6class:HOW()
_G['Any'] = p6any
how.add_parent(p6any, p6mu)
how.add_method(p6any, 'can', function (self, name)
                local class = self:WHAT()
                return p6class.can(class, name)
                end)
how.add_method(p6any, 'isa', function (self, parent)
                local class = self:WHAT()
                return p6class.isa(class, parent)
                end)
how.add_method(p6any, 'perl', function (self)
                return self:WHAT().name end)
how.add_parent(p6class, p6any)
end

local p6str = p6class:new('str')
do
local find = string.find
local len = string.len
local lower = string.lower
local quote = tvm.quote
local reverse = string.reverse
local sub = string.sub
local upper = string.upper
local how = p6class:HOW()
p6str._VALUES.mt = {
        __index = p6str._VALUES.proto,
}
debug.setmetatable('', p6str._VALUES.mt)
_G['str'] = p6str
how.add_parent(p6str, p6any)
how.add_method(p6str, 'new', function (self, str)
                checktype('new', 1, str, 'string')
                return str end)
how.add_method(p6str, 'WHAT', function (self)
                return p6str end)
how.add_method(p6str, 'str', function (self)
                return self end)
how.add_method(p6str, 'bool', function (self)
                return self ~= '' and self ~= '0' end)
how.add_method(p6str, 'num', function (self)
                return assert(tonumber(self)) end)
how.add_method(p6str, 'gist', function (self)
                return self end)
how.add_method(p6str, 'perl', function (self)
                return quote(self) end)
how.add_method(p6str, 'print', function (self)
                print(self) end)
how.add_method(p6str, 'say', function (self)
                say(self) end)
how.add_method(p6str, 'elems', function (self)
                return len(self) end)
how.add_method(p6str, 'lc', function (self)
                return lower(self) end)
how.add_method(p6str, 'uc', function (self)
                return upper(self) end)
how.add_method(p6str, 'reverse', function (self)
                return reverse(self) end)
how.add_method(p6str, 'index', function (self, substring, pos)
                pos = pos or 0
                checktype('index', 1, substring, 'string')
                checktype('index', 2, pos, 'number')
                return find(self, substring, pos+1, true) - 1 end)
how.add_method(p6str, 'substr', function (self, start, length)
                checktype('substr', 1, start, 'number')
                checktype('substr', 2, length, 'number')
                return sub(self, start+1, start+length) end)
end

local p6bool = p6class:new('bool')
do
local how = p6class:HOW()
p6bool._VALUES.mt = {
        __index = p6bool._VALUES.proto,
        __tostring = function (o) return o:str() end,
}
debug.setmetatable(false, p6bool._VALUES.mt)
_G['bool'] = p6bool
how.add_parent(p6bool, p6any)
how.add_method(p6bool, 'new', function (self, bool)
                checktype('new', 1, bool, 'boolean')
                return bool end)
how.add_method(p6bool, 'WHAT', function (self)
                return p6bool end)
how.add_method(p6bool, 'str', function (self)
                return self and 'True' or 'False' end)
how.add_method(p6bool, 'bool', function (self)
                return self end)
how.add_method(p6bool, 'num', function (self)
                return self and 1.0 or 0.0 end)
how.add_method(p6bool, 'gist', function (self)
                return self:str() end)
how.add_method(p6bool, 'perl', function (self)
                return self:str() end)
end

local p6nil = p6class:new('nil')
do
local how = p6class:HOW()
p6nil._VALUES.mt = {
        __index = p6nil._VALUES.proto,
        __tostring = function (self) return self:str() end,
}
debug.setmetatable(nil, p6nil._VALUES.mt)
_G['nil'] = p6nil
how.add_parent(p6nil, p6any)
how.add_method(p6nil, 'new', function ()
                return nil end)
how.add_method(p6nil, 'WHAT', function ()
                return p6nil end)
how.add_method(p6nil, 'defined', function ()
                return false end)
how.add_method(p6nil, 'str', function ()
                return '' end)
how.add_method(p6nil, 'bool', function ()
                return false end)
how.add_method(p6nil, 'num', function ()
                return 0.0 end)
how.add_method(p6nil, 'gist', function ()
                return 'Nil' end)
how.add_method(p6nil, 'perl', function ()
                return 'Nil' end)
end

local p6num = p6class:new('num')
do
local how = p6class:HOW()
p6num._VALUES.mt = {
        __index = p6num._VALUES.proto,
}
debug.setmetatable(0, p6num._VALUES.mt)
_G['num'] = p6num
how.add_parent(p6num, p6any)
how.add_method(p6num, 'new', function (self, num)
                checktype('new', 1, num, 'number')
                return num end)
how.add_method(p6num, 'WHAT', function (self)
                return p6num end)
how.add_method(p6num, 'str', function (self)
                if self ~= self then
                    return 'NaN'
                elseif self == 1/0 then
                    return 'Inf'
                elseif self == -1/0 then
                    return '-Inf'
                else
                    return tostring(self)
                end end)
how.add_method(p6num, 'bool', function (self)
                return self ~= 0.0 end)
how.add_method(p6num, 'num', function (self)
                return self end)
how.add_method(p6num, 'gist', function (self)
                return tostring(self) end)
how.add_method(p6num, 'perl', function (self)
                return self:str() end)
end


local p6array = p6class:new('Array')
do
local how = p6class:HOW()
_G['Array'] = p6array
how.add_parent(p6array, p6any)
p6array._VALUES.mt = {
        __index = function (t, k)
            if type(k) == 'number' then
                if k < 0 then k = t.n - k end
                return rawget(t, k)
            else
                return p6array._VALUES.proto[k]
            end
        end,
        __newindex = function (t, k, v)
            if k > t.n then t.n = k end
            rawset(t, k, v)
        end,
        __tostring = function (t)
            return t:str()
        end,
}
how.add_method(p6array, 'new', function (class, t)
                checktype('new', 1, t, 'table')
                t.n = t.n or #t
                return setmetatable(t, class._VALUES.mt) end)
how.add_method(p6array, 'WHAT', function (self)
                return p6array end)
how.add_method(p6array, 'join', function (self, sep)
                sep = sep or ' '
                checktype('join', 1, sep, 'string')
                local t = {}
                for i = 1, self.n do t[#t+1] = self[i]:str() end
                return tconcat(t, sep) end)
how.add_method(p6array, 'str', function (self)
                return self:join() end)
how.add_method(p6array, 'bool', function (self)
                return self.n ~= 0 end)
how.add_method(p6array, 'num', function (self)
                return self.n end)
how.add_method(p6array, 'gist', function (self)
                local t = {}
                for i = 1, self.n do t[#t+1] = self[i]:gist() end
                return tconcat(t, ' ') end)
how.add_method(p6array, 'perl', function (self)
                local t = {}
                for i = 1, self.n do t[#t+1] = self[i]:perl() end
                return 'Array.new(' .. tconcat(t, ', ') .. ')' end)
how.add_method(p6array, 'elems', function (self)
                return self.n end)
how.add_method(p6array, 'end', function (self)
                return self.n - 1 end)
how.add_method(p6array, 'push', function (self, v)
                self.n = self.n + 1
                self[self.n] = v
                return self end)
how.add_method(p6array, 'pop', function (self)
                local v = self[self.n]
                self.n = self.n - 1
                return v end)
how.add_method(p6array, 'unshift', function (self, v)
                for i = 1, self.n do self[i+1] = self[i] end
                self[1] = v
                self.n = self.n + 1
                return self end)
how.add_method(p6array, 'shift', function (self)
                local v = self[1]
                for i = self.n, 1, -1 do self[i] = self[i+1] end
                self.n = self.n - 1
                return v end)
how.add_method(p6array, 'delete', function (self, ...)
                local a = {...}
                for i = 1, #a do self[a[i]] = nil end
                for i = self.n, 1, -1 do
                    if self[i] then self.n = i; break end
                end
                return self end)
how.add_method(p6array, 'exists', function (self, ...)
                local a = {...}
                for i = 1, #a do
                    if self[a[i]] == nil then return false end
                end
                return true end)
how.add_method(p6array, 'hash', function (self)
                local t = {}
                for i = 1, self.n, 2 do t[self[i]] = self[i+1] end
                return Hash:new(t) end)
end


local p6hash = p6class:new('Hash')
do
local how = p6class:HOW()
_G['Hash'] = p6hash
how.add_parent(p6hash, p6any)
p6hash._VALUES.mt = {
        __index = p6hash._VALUES.proto,
        __tostring = function (t)
            return t:str()
        end,
}
how.add_method(p6hash, 'new', function (class, t)
                return setmetatable(t, class._VALUES.mt) end)
how.add_method(p6hash, 'WHAT', function (self)
                return p6hash end)
how.add_method(p6hash, 'str', function (self)
                local t = {}
                for k, v in pairs(self) do
                    t[#t+1] = k:str()
                    t[#t+1] = "\t"
                    t[#t+1] = v:str()
                    t[#t+1] = "\n"
                end
                t[#t] = nil
                return tconcat(t) end)
how.add_method(p6hash, 'bool', function (self)
                return next(self) ~= nil end)
how.add_method(p6hash, 'num', function (self)
                return self:elems() end)
how.add_method(p6hash, 'gist', function (self)
                local t = {}
                for k, v in pairs(self) do
                    t[#t+1] = k:gist()
                    t[#t+1] = "\t"
                    t[#t+1] = v:gist()
                    t[#t+1] = "\n"
                end
                t[#t] = nil
                return tconcat(t) end)
how.add_method(p6hash, 'perl', function (self)
                local t = {}
                for k, v in pairs(self) do
                    t[#t+1] = k:perl() .. ' => ' .. v:perl()
                end
                return '(' .. tconcat(t, ', ') .. ').hash' end)
how.add_method(p6hash, 'elems', function (self)
                local n = 0
                for _ in pairs(self) do n = n + 1 end
                return n end)
how.add_method(p6hash, 'keys', function (self)
                local t = {}
                for k in pairs(self) do t[#t+1] = k end
                return Array:new(t) end)
how.add_method(p6hash, 'values', function (self)
                local t = {}
                for k, v in pairs(self) do t[#t+1] = v end
                return Array:new(t) end)
how.add_method(p6hash, 'kv', function (self)
                local t = {}
                for k, v in pairs(self) do t[#t+1] = k; t[#t+1] = v end
                return Array:new(t) end)
how.add_method(p6hash, 'invert', function (self)
                local t = {}
                for k, v in pairs(self) do t[v] = k end
                return Hash:new(t) end)
how.add_method(p6hash, 'push', function (self, ...)
                local t = {...}
                for i = 1, #t, 2 do self[t[i]] = t[i+1] end
                return self end)
end

end -- mop


do -- Op

local pairs = pairs
local setmetatable = setmetatable
local tconcat = table.concat
local type = type
local _G = _G
local how = _G['NQP::Metamodel::ClassHOW']:HOW()

local op = how:new('TVM::Op')
_G['TVM::Op'] = op
how.add_parent(op, _G['Any'])
op._VALUES.mt =  {
        __index = op._VALUES.proto,
        __tostring = function (o) return o:str() end,
}
how.add_method(op, 'new', function (class, args)
                return setmetatable({ _VALUES = args, _CLASS = class }, class._VALUES.mt) end)
how.add_method(op, 'str', function (self)
                local t = {}
                local values = self._VALUES
                if values[0] then
                    t[1] = '0: ' .. values[0]:str()
                end
                for i = 1, #values do
                    t[#t+1] = values[i]:str()
                end
                for k, v in pairs(values) do
                    if type(k) ~= 'number' or k < 0 or k > #values then
                        t[#t+1] = k:perl() .. ': ' .. v:str()
                    end
                end
                return ((values[1] == '!line' or values[1] == '!do') and '\n(' or '(') .. tconcat(t, ' ') .. ')' end)
how.add_method(op, 'push', function (self, v)
                local values = self._VALUES
                values[#values+1] = v
                return self end)
how.add_method(op, 'addkv', function (self, k, v)
                local values = self._VALUES
                values[k] = v
                return self end)


local ops = how:new('TVM::Ops')
_G['TVM::Ops'] = ops
how.add_parent(ops, _G['Array'])
how.add_method(ops, 'str', function (self)
                return self:join('') end)

end -- Op


do -- AST

local assert = assert
local error = error
local escape = tvm.escape
local pairs = pairs
local quote = tvm.quote
local tconcat = table.concat
local type = type
local _G = _G

local top = _G['TVM::Op']
local tops = _G['TVM::Ops']
local how = _G['NQP::Metamodel::ClassHOW']:HOW()

local ast = how:new('TVM::AST')
_G['TVM::AST'] = ast
how.add_parent(ast, _G['Any'])
how.add_attribute(ast, { name = 'lineno', type = num })
how.add_attribute(ast, { name = 'named', type = str })  -- SpecialArg
how.add_attribute(ast, { name = 'slurpy', type = bool })  -- SpecialArg
--how.add_attribute(ast, { name = 'flat', type = bool })  -- SpecialArg
how.add_method(ast, 'new', function (class, args)
                local obj = Mu.new(class, args)
                for i = 1, #args do
                    obj[i] = args[i]
                end
                return obj end)
how.add_method(ast, 'push', function (self, v)
                self[#self+1] = v
                end)
how.add_method(ast, 'str', function (self)
                local t = {}
                for k, v in pairs(self._VALUES) do
                    t[#t+1] = k:str() .. ' => ' .. v:perl()
                end
                return self:WHAT()._VALUES.name .. '(' .. tconcat(t, ', ') .. ')'
                end)
how.add_method(ast, 'dump', function (self, indent)
                indent = indent or ''
                local t = { indent .. '- ' .. self:str() .. '\n' }
                indent = indent .. '  '
                for i = 1, #self do
                    t[#t+1] = self[i]:dump(indent)
                end
                return tconcat(t)
                end)
how.add_method(ast, 'coerce', function (self, op, type, want)
                if want and want ~= type then
                    return top:new{ '!callmeth1', op, want }
                else
                    return op
                end
                end)


local unit = how:new('TVM::AST::CompUnit')
_G['TVM::AST::CompUnit'] = unit
how.add_parent(unit, ast)
how.add_attribute(unit, { name = 'filename', type = str })
how.add_attribute(unit, { name = 'prelude', type = str, default = "; prelude\n" })
how.add_attribute(unit, { name = 'termination', type = str, default = "\n\n; end" })
how.add_method(unit, 'as_op', function (self)
                local ops = tops:new{}
                local prelude = self:prelude()
                if prelude then
                    ops:push(prelude)
                end
                local filename = self:filename()
                if filename then
                    ops:push(top:new{ '!line', quote('@' .. filename), 1 })
                end
                for i = 1, #self do
                    ops:push(self[i]:as_op())
                end
                local termination = self:termination()
                if termination then
                    ops:push(termination)
                end
                return ops
                end)


local block = how:new('TVM::AST::Block')
_G['TVM::AST::Block'] = block
how.add_parent(block, ast)
how.add_attribute(block, { name = 'name', type = str })
how.add_attribute(block, { name = 'blocktype', type = str })
local function signature (op, params)
                local pargs = top:new{}
                local nargs = tops:new{}
                local lex = tops:new{}
                for i = 1, #params do
                    local p = params[i]
                    if p:isa(_G['TVM::AST::Var']) then
                        local name = p:name()
                        if p:slurpy() then
                            local sigil = string.sub(name, 1, 1)
                            nargs:push(top:new{ '!define', name, top:new{ '!callmeth1', top:new{ '!index', '_P6PKG', quote(sigil == '%' and 'Hash' or 'Array') }, 'new', top:new{ '_' } } })
                        else
                            local named = p:named()
                            if named then
                                nargs:push(top:new{ '!define', name, top:new{ '!index', '_', quote(named) } })
                            else
                                pargs:push(name)
                            end
                        end
                    else
                        lex:push(p:as_op())
                    end
                end
                if #pargs._VALUES ~= 0 then
                    op:push(top:new{ '!define', pargs, top:new{ top:new{ '!call', 'unpack', '_'} } })
                end
                op:push(nargs)
                op:push(lex)
end
local function statements (op, stmts)
                for i = 1, #stmts-1 do
                    op:push(stmts[i]:as_op())
                end
                local last = stmts[#stmts]
                local lineno = last:lineno()
                local ops = tops:new{}
                if lineno then
                    last:reset('lineno')
                    ops:push(top:new{ '!line', lineno })
                end
                ops:push(top:new{ '!return', last:as_op() })
                op:push(ops)
end
how.add_method(block, 'as_op', function (self)
                local blocktype = assert(self:blocktype())
                if blocktype == 'immediate' then
                    local op = top:new{ '!do' }
                    for i = 1, #self do
                        op:push(self[i]:as_op())
                    end
                    return op
                elseif blocktype == 'routine' then
                    local op = top:new{ '!lambda', top:new{ '_' } }
                    signature(op, assert(self[1]))
                    statements(op, assert(self[2][2]))
                    return op
                elseif blocktype == 'method' then
                    local op = top:new{ '!lambda', top:new{ 'self', '_' } }
                    signature(op, assert(self[1]))
                    statements(op, assert(self[2][2]))
                    return op
                else
                    error("block with blocktype=" .. blocktype)
                end
                end)


local stmts = how:new('TVM::AST::Stmts')
_G['TVM::AST::Stmts'] = stmts
how.add_parent(stmts, ast)
how.add_method(stmts, 'as_op', function (self)
                local ops = tops:new{}
                for i = 1, #self do
                    ops:push(self[i]:as_op())
                end
                return ops
                end)


local op = how:new('TVM::AST::Op')
_G['TVM::AST::Op'] = op
how.add_parent(op, ast)
how.add_attribute(op, { name = 'name', type = str })
how.add_attribute(op, { name = 'op', type = str })
how.add_method(op, 'as_op', function (self, want)
                local op = assert(self:op())
                local name = self:name()
                local ops = tops:new{}
                local lineno = self:lineno()
                if op == 'call' then
                    if lineno then
                        ops:push(top:new{ '!line', lineno })
                    end
                    local args = top:new{}
                    for i = (name and 1 or 2), #self do
                        local v = self[i]
                        local named = v:named()
                        if named then
                            args:addkv(named, v:as_op())
                        else
                            args:push(v:as_op())
                        end
                    end
                    ops:push(top:new{ '!call', (name and escape(name) or assert(self[1]):as_op()), args })
                elseif op == 'callmeth' then
                    if lineno then
                        ops:push(top:new{ '!line', lineno })
                    end
                    local obj = assert(self[1])
                    obj = obj:as_op()
                    local args = top:new{}
                    for i = (name and 2 or 3), #self do
                        local v = self[i]
                        local named = v:named()
                        if named then
                            args:addkv(named, v:as_op())
                        else
                            args:push(v:as_op())
                        end
                    end
                    if name then
                        ops:push(top:new{ '!callmeth', obj, escape(name), args })
                    else
                        ops:push(top:new{ '!call', top:new{ '!index', obj, assert(self[2]):as_op'str' }, obj, args })
                    end
                elseif op == 'if' or op == 'unless' then
                    if lineno then
                        ops:push(top:new{ '!line', lineno })
                    end
                    local expr = assert(self[1])
                    local _then = assert(self[2])
                    local _else = self[3]
                    local op1 = top:new{ '!if' }
                    if op == 'if' then
                        op1:push(expr:as_op'bool')
                    else
                        op1:push(top:new{ '!not', expr:as_op'bool' })
                    end
                    if _then:isa(_G['TVM::AST::Block']) then
                        op1:push(_then:as_op())
                    else
                        op1:push(top:new{ '!do', _then:as_op() })
                    end
                    if _else then
                        if _else:isa(_G['TVM::AST::Block']) then
                            op1:push(_else:as_op())
                        else
                            op1:push(top:new{ '!do', _else:as_op() })
                        end
                    end
                    ops:push(op1)
                elseif op == 'while' or op == 'until' then
                    if lineno then
                        ops:push(top:new{ '!line', lineno })
                    end
                    local expr = assert(self[1])
                    local blk = assert(self[2])
                    local op1 = top:new{ '!while' }
                    if op == 'while' then
                        op1:push(expr:as_op'bool')
                    else
                        op1:push(top:new{ '!not', expr:as_op'bool' })
                    end
                    op1:push(blk:as_op(options))
                    ops:push(op1)
                elseif op == 'for' then
                    if lineno then
                        ops:push(top:new{ '!line', lineno })
                    end
                    local expr = assert(self[1])
                    local blk = assert(self[2])
                    local params = blk[1]
                    local lex = top:new{ '_' }
                    local iter
                    local n
                    if #params == 0 then
                        lex:push'$_'
                        iter = '_iter1'
                    else
                        for i = 1, #params do
                            local p = params[i]
                            lex:push(p:name())
                        end
                        if #params <= 2 then
                            iter = '_iter' .. #params
                        else
                            iter = '_itern'
                            n = top:new{ #params }
                        end
                    end
                    local op1 = top:new{ '!for', lex,
                                                 top:new{ top:new{ '!callmeth', expr:as_op(options), iter, n } },
                                                 blk[2]:as_op(options) }
                    ops:push(op1)
                elseif op == 'list' then
                    local args = top:new{ n=#self }
                    if #self >= 1 then
                        args:addkv(0, self[1]:as_op())
                        for i = 2, #self do
                            args:push(self[i]:as_op())
                        end
                    end
                    local op1 = top:new{ '!callmeth', top:new{ '!index', '_P6PKG', quote'Array' } , 'new', top:new{ args } }
                    ops:push(op1)
                elseif op == 'hash' then
                    local args = top:new{}
                    for i = 1, #self, 2 do
                        args:addkv(self[i]:as_op(), self[i+1]:as_op())
                    end
                    local op1 = top:new{ '!callmeth', top:new{ '!index', '_P6PKG', quote'Hash' } , 'new', top:new{ args } }
                    ops:push(op1)
                elseif op == 'return' then
                    if lineno then
                        ops:push(top:new{ '!line', lineno })
                    end
                    local op1 = top:new{ '!return' }
                    for i = 1, #self do
                        local v = self[i]
                        op1:push(v:as_op())
                    end
                    ops:push(op1)
                elseif op == 'let' then
                    if lineno then
                        ops:push(top:new{ '!line', lineno })
                    end
                    local expr1 = assert(self[1])
                    local expr2 = assert(self[2])
                    local op1 = top:new{ '!let', expr1:as_op(), expr2:as_op() }
                    ops:push(op1)
                elseif op == 'op' then
                    local expr1 = assert(self[1])
                    local op1, returns
                    if     name == '&prefix:<~>' then
                        op1 = expr1:as_op'str'
                        returns = 'str'
                    elseif name == '&prefix:<+>' then
                        op1 = expr1:as_op'num'
                        returns = 'num'
                    elseif name == '&prefix:<->' then
                        op1 = top:new{ '!neg', expr1:as_op'num' }
                        returns = 'num'
                    elseif name == '&prefix:<?>' then
                        op1 = expr1:as_op'bool'
                        returns = 'bool'
                    elseif name == '&prefix:<!>' then
                        op1 = top:new{ '!not', expr1:as_op'bool' }
                        returns = 'bool'
                    elseif name == '&infix:<==>' then
                        local expr2 = assert(self[2])
                        op1 = top:new{ '!eq', expr1:as_op'num', expr2:as_op'num' }
                        returns = 'bool'
                    elseif name == '&infix:<!=>' then
                        local expr2 = assert(self[2])
                        op1 = top:new{ '!ne', expr1:as_op'num', expr2:as_op'num' }
                        returns = 'bool'
                    elseif name == '&infix:<eq>' then
                        local expr2 = assert(self[2])
                        op1 = top:new{ '!eq', expr1:as_op'str', expr2:as_op'str' }
                        returns = 'bool'
                    elseif name == '&infix:<ne>' then
                        local expr2 = assert(self[2])
                        op1 = top:new{ '!ne', expr1:as_op'str', expr2:as_op'str' }
                        returns = 'bool'
                    elseif name == '&infix:<=:=>' then
                        local expr2 = assert(self[2])
                        op1 = top:new{ '!call', 'rawequal', expr1:as_op(), expr2:as_op() }
                        returns = 'bool'
                    elseif name == '&infix:<+>' then
                        local expr2 = assert(self[2])
                        op1 = top:new{ '!add', expr1:as_op'num', expr2:as_op'num' }
                        returns = 'num'
                    elseif name == '&infix:<->' then
                        local expr2 = assert(self[2])
                        op1 = top:new{ '!sub', expr1:as_op'num', expr2:as_op'num' }
                        returns = 'num'
                    elseif name == '&infix:<*>' then
                        local expr2 = assert(self[2])
                        op1 = top:new{ '!mul', expr1:as_op'num', expr2:as_op'num' }
                        returns = 'num'
                    elseif name == '&infix:</>' then
                        local expr2 = assert(self[2])
                        op1 = top:new{ '!div', expr1:as_op'num', expr2:as_op'num' }
                        returns = 'num'
                    elseif name == '&infix:<%>' then
                        local expr2 = assert(self[2])
                        op1 = top:new{ '!mod', expr1:as_op'num', expr2:as_op'num' }
                        returns = 'num'
                    elseif name == '&infix:<~>' then
                        local expr2 = assert(self[2])
                        op1 = top:new{ '!concat', expr1:as_op'str', expr2:as_op'str' }
                        returns = 'str'
                    elseif name == '&infix:<<>' then
                        local expr2 = assert(self[2])
                        op1 = top:new{ '!lt', expr1:as_op'num', expr2:as_op'num' }
                        returns = 'bool'
                    elseif name == '&infix:<<=>' then
                        local expr2 = assert(self[2])
                        op1 = top:new{ '!le', expr1:as_op'num', expr2:as_op'num' }
                        returns = 'bool'
                    elseif name == '&infix:<>>' then
                        local expr2 = assert(self[2])
                        op1 = top:new{ '!gt', expr1:as_op'num', expr2:as_op'num' }
                        returns = 'bool'
                    elseif name == '&infix:<>=>' then
                        local expr2 = assert(self[2])
                        op1 = top:new{ '!ge', expr1:as_op'num', expr2:as_op'num' }
                        returns = 'bool'
                    elseif name == '&infix:<lt>' then
                        local expr2 = assert(self[2])
                        op1 = top:new{ '!lt', expr1:as_op'str', expr2:as_op'str' }
                        returns = 'bool'
                    elseif name == '&infix:<le>' then
                        local expr2 = assert(self[2])
                        op1 = top:new{ '!le', expr1:as_op'str', expr2:as_op'str' }
                        returns = 'bool'
                    elseif name == '&infix:<gt>' then
                        local expr2 = assert(self[2])
                        op1 = top:new{ '!gt', expr1:as_op'str', expr2:as_op'str' }
                        returns = 'bool'
                    elseif name == '&infix:<ge>' then
                        local expr2 = assert(self[2])
                        op1 = top:new{ '!ge', expr1:as_op'str', expr2:as_op'str' }
                        returns = 'bool'
                    elseif name == '&infix:<+|>' then
                        local expr2 = assert(self[2])
                        op1 = top:new{ '!call', top:new{ '!index', 'bit', quote'bor' },
                                                expr1:as_op'num',
                                                expr2:as_op'num' }
                        returns = 'num'
                    elseif name == '&infix:<+&>' then
                        local expr2 = assert(self[2])
                        op1 = top:new{ '!call', top:new{ '!index', 'bit', quote'band' },
                                                expr1:as_op'num',
                                                expr2:as_op'num' }
                        returns = 'num'
                    elseif name == '&infix:<+^>' then
                        local expr2 = assert(self[2])
                        op1 = top:new{ '!call', top:new{ '!index', 'bit', quote'bxor' },
                                                expr1:as_op'num',
                                                expr2:as_op'num' }
                        returns = 'num'
                    elseif name == '&infix:<?? !!>' then
                        local expr2 = assert(self[2])
                        local expr3 = assert(self[3])
                        op1 = top:new{ '!or', top:new{ '!and', expr1:as_op'bool',
                                                               expr2:as_op() },
                                              expr3:as_op() }
                    elseif name == '&postfix:<++>' then
                        op1 = top:new{ '!callmeth1', expr1:as_op(), '_postincr' }
                    elseif name == '&postfix:<-->' then
                        op1 = top:new{ '!callmeth1', expr1:as_op(), '_postdecr' }
                    elseif name == '&infix:<//>' then
                        local expr2 = assert(self[2])
                        op1 = top:new{ '!or', top:new{ '!and', top:new{ '!callmeth', expr1:as_op(), 'defined' },
                                                               expr1:as_op() },
                                              expr2:as_op() }
                    elseif name == '&infix:<:=>' then
                        if lineno then
                            ops:push(top:new{ '!line', lineno })
                        end
                        local expr2 = self[2]
                        if expr1:decl() then
                            ops:push(expr1:as_op())
                            expr1:reset'decl'
                        end
                        op1 = top:new{ '!assign', expr1:as_op(), expr2:isa(_G['TVM::AST::Var']) and expr2:as_op() or expr2:as_op'Box' }
                    else
                        error("op with name=" .. name)
                    end
                    op1 = self:coerce(op1, returns, want)
                    ops:push(op1)
                else
                    error("op with op=" .. op)
                end
                return ops
                end)


local bval = how:new('TVM::AST::BVal')
_G['TVM::AST::BVal'] = bval
how.add_parent(bval, ast)
how.add_attribute(bval, { name = 'value', type = bool })
how.add_method(bval, 'as_op', function (self, want)
                local value = assert(self:value())
                assert(type(value) == 'boolean')
                return self:coerce(value, 'bool', want)
                end)


local nval = how:new('TVM::AST::NVal')
_G['TVM::AST::NVal'] = nval
how.add_parent(nval, ast)
how.add_attribute(nval, { name = 'value', type = num })
how.add_method(nval, 'as_op', function (self, want)
                local value = assert(self:value())
                assert(type(value) == 'number')
                return self:coerce(value, 'num', want)
                end)


local sval = how:new('TVM::AST::SVal')
_G['TVM::AST::SVal'] = sval
how.add_parent(sval, ast)
how.add_attribute(sval, { name = 'value', type = str })
how.add_method(sval, 'as_op', function (self, want)
                local value = assert(self:value())
                assert(type(value) == 'string')
                return self:coerce(value, 'str', want)
                end)


local var = how:new('TVM::AST::Var')
_G['TVM::AST::Var'] = var
how.add_parent(var, ast)
how.add_attribute(var, { name = 'name', type = str })
how.add_attribute(var, { name = 'scope', type = str })
how.add_attribute(var, { name = 'decl', type = str })
how.add_method(var, 'as_op', function (self, want)
                local scope = assert(self:scope())
                if self:decl() then
                    local name = assert(self:name())
                    local lineno = self:lineno()
                    local ops = tops:new{}
                    if     scope == 'lexical' then
                        if lineno then
                            ops:push(top:new{ '!line', lineno })
                        end
                        ops:push(top:new{ '!define', name })
                    elseif scope == 'package' then
                        -- nothing
                    else
                        error("var decl with scope=" .. scope)
                    end
                    return ops
                else
                    local op1
                    if     scope == 'associative' then
                        op1 = top:new{ '!index', assert(self[1]):as_op(), assert(self[2]):as_op() }
                    elseif scope == 'positional' then
                        op1 = top:new{ '!index', assert(self[1]):as_op(), assert(self[2]):as_op'num' }
                    elseif scope == 'attribute' then
                        op1 = top:new{ '!index', top:new{ '!index', 'self', quote'_VALUES' }, quote(assert(self:name())) }
                    elseif scope == 'package' then
                        op1 = top:new{ '!index', '_P6PKG', quote(assert(self:name())) }
                    elseif scope == 'lexical' then
                        op1 = assert(self:name())
                    else
                        error("var with scope=" .. scope)
                    end
                    return self:coerce(op1, nil, want)
                end
                end)

end -- AST


do -- Parser

local _G = _G
local error = error
local quote = tvm.quote
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
local gsub = string.gsub
local function inc_lineno (s)
    local _, n = gsub(s, '\n', '')
    lineno = lineno + n
end

local function syntaxerror (err)
    error(err .. " at " .. lineno)
end

local bom = P"\xEF\xBB\xBF"
local hspace = S' \t'
local ch_ident = R('09', 'AZ', 'az', '__')
local not_ch_ident = -ch_ident

local identifier = R('AZ', 'az', '__') * ch_ident^0
local capt_identifier = C(identifier) * Cp()

local sigil = S'$@%&'
local twigil = S'*!?'
local name = identifier
local capt_name = C(name) * Cp()
local variable = sigil * twigil^-1 * name
local capt_variable = C(variable) * Cp()
local capt_funcname = P'&'^-1 * C(name) * Cp()
local paramvar = sigil * twigil^-1 * name
local capt_paramvar = C(paramvar) * S'!?'^-1 * Cp()
local capt_named = P':' * C(name) * Cp()

local ws; do
    local pod_begin = S'\n\r' * P'=begin'
    local pod_end = S'\n\r' * P'=end'
    local open = pod_begin * hspace^1 * Cg(identifier, 'name')
    local close = pod_end * hspace^1 * C(identifier)
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
    local gsub = string.gsub
    local tonumber = tonumber
    local binint = R'01'^1 * (P'_' + R'01'^1)^0
    local octint = R'07'^1 * (P'_' + R'07'^1)^0
    local decint = locale.digit^1 * (P'_' + locale.digit^1)^0
    local hexint = locale.xdigit^1 * (P'_' + locale.xdigit^1)^0
    local integer = (P'0' * (P'b' * P'_'^-1 * (binint / function (s) return tonumber((gsub(s, '_', '')), 2) end)
                           + P'o' * P'_'^-1 * (octint / function (s) return tonumber((gsub(s, '_', '')), 8) end)
                           + P'x' * P'_'^-1 * (hexint / function (s) return tonumber((gsub(s, '_', '')), 16) end)
                           + P'd' * P'_'^-1 * (decint / function (s) return tonumber((gsub(s, '_', '')), 10) end)))
                  + (decint / function (s) return tonumber((gsub(s, '_', ''))) end)
    local escale = S'Ee' * S'+-'^-1 * decint
    local dec_number = (P'.' * decint * escale^-1)
                     + (decint * P'.' * decint * escale^-1)
                     + (decint * escale)
    number = (P'NaN' / function () return 0/0 end)
           + (P'Inf' / function () return 1/0 end)
           + (dec_number / function (s) return tonumber((gsub(s, '_',''))) end)
           + integer
end
local capt_number = number * Cp()

local tok_string; do
    local char = string.char
    local tonumber = tonumber

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

local tok_angle; do
    local ch_angle = P(1) - P'>'
    tok_angle = ((P'<' * Cs(ch_angle^0) * P'>') / quote)
end
local capt_angle = tok_angle * Cp()

local tok_q = P'q' * S' \t'^0 * tok_angle
local capt_q = tok_q * Cp()

local tok_class = P'class' * not_ch_ident
local capt_class = C(tok_class) * Cp()
local tok_does = P'does' * not_ch_ident
local capt_does = C(tok_does) * Cp()
local tok_has = P'has' * not_ch_ident
local capt_has = C(tok_has) * Cp()
local tok_if = P'if' * not_ch_ident
local capt_if = C(tok_if) * Cp()
local tok_is = P'is' * not_ch_ident
local capt_is = C(tok_is) * Cp()
local tok_else = P'else' * not_ch_ident
local capt_else = C(tok_else) * Cp()
local tok_elsif = P'elsif' * not_ch_ident
local capt_elsif = C(tok_elsif) * Cp()
local tok_for = P'for' * not_ch_ident
local capt_for = C(tok_for) * Cp()
local tok_method = P'method' * not_ch_ident
local capt_method = C(tok_method) * Cp()
local tok_module = P'module' * not_ch_ident
local capt_module = C(tok_module) * Cp()
local tok_my = P'my' * not_ch_ident
local capt_my = C(tok_my) * Cp()
local tok_our = P'our' * not_ch_ident
local capt_our = C(tok_our) * Cp()
local tok_return = P'return' * not_ch_ident
local capt_return = C(tok_return) * Cp()
local tok_role = P'role' * not_ch_ident
local capt_role = C(tok_role) * Cp()
local tok_sub = P'sub' * not_ch_ident
local capt_sub = C(tok_sub) * Cp()
local tok_unless = P'unless' * not_ch_ident
local capt_unless = C(tok_unless) * Cp()
local tok_until = P'until' * not_ch_ident
local capt_until = C(tok_until) * Cp()
local tok_while = P'while' * not_ch_ident
local capt_while = C(tok_while) * Cp()


local tok_comma = P','
local capt_comma = C(tok_comma) * Cp()
local tok_left_paren = P'('
local capt_left_paren = C(tok_left_paren) * Cp()
local tok_right_paren = P')'
local capt_right_paren = C(tok_right_paren) * Cp()
local tok_left_bracket = P'['
local capt_left_bracket = C(tok_left_bracket) * Cp()
local tok_right_bracket = P']'
local capt_right_bracket = C(tok_right_bracket) * Cp()
local tok_left_curly = P'{'
local capt_left_curly = C(tok_left_curly) * Cp()
local tok_right_curly = P'}'
local capt_right_curly = C(tok_right_curly) * Cp()
local tok_semicolon = P';'
local capt_semicolon = C(tok_semicolon) * Cp()
local tok_colon = P':'
local capt_colon = C(tok_colon) * Cp()
local tok_dot = P'.'
local capt_dot = C(tok_dot) * Cp()
local tok_arrow = P'->'
local capt_arrow = C(tok_arrow) * Cp()

local postfix = P'++' + P'--'
local capt_postfix = C(postfix) * Cp()
local prefix = P'++' + P'--' + P'+' + P'~' + P'-' + P'?' + P'!' + P'|'
local capt_prefix = C(prefix) * Cp()
local infix = P'**' + P'*' + P'/' + P'%' + P'+&' + P'+|' + P'+^' + P'+' + (P'-'*-P'>') + P'~'
             + P'==' + P'!=' + P'<=' + P'<' + P'>=' + P'>' + P'eq' + P'ne' + P'le' + P'ge' + P'lt' + P'gt' + P'=:='
             + P'&&' + P'||' + P'//' + P':=' + P'::=' + P'='
local capt_infix = C(infix) * Cp()


local how = _G['NQP::Metamodel::ClassHOW']:HOW()
local parser = how:new('TVM::Parser')
_G['TVM::Parser'] = parser
how.add_parent(parser, _G['Any'])
how.add_attribute(parser, { name = 'src', type = str })
how.add_attribute(parser, { name = 'pos', type = num })
how.add_attribute(parser, { name = 'init' })
how.add_attribute(parser, { name = 'scope', default = function () return { ['$_']='lexical' } end })


local BVal = _G['TVM::AST::BVal']
local NVal = _G['TVM::AST::NVal']
local SVal = _G['TVM::AST::SVal']
local Var = _G['TVM::AST::Var']
local Op = _G['TVM::AST::Op']
local Block = _G['TVM::AST::Block']
local Stmts =  _G['TVM::AST::Stmts']
local CompUnit =  _G['TVM::AST::CompUnit']


how.add_method(parser, 'skip_ws', function (self, pos)
                if pos then
                    self:pos(pos)
                end
                local capt, posn = capt_ws:match(self:src(), self:pos())
                if posn then
                    self:pos(posn)
                end
                end)


how.add_method(parser, 'statlist', function (self)
                -- statlist -> { stat `;' }
                self:skip_ws()
                local stmts = Stmts:new{}
                while not P(-1):match(self:src(), self:pos())
                  and not tok_right_curly:match(self:src(), self:pos()) do
                    stmts:push(self:statement())
                    self:skip_ws()
                end
                return stmts end)


how.add_method(parser, 'yindex', function (self)
                -- index -> '[' expr ']'
                local capt, posn = capt_left_bracket:match(self:src(), self:pos())
                assert(posn)
                self:skip_ws(posn)
                local ast = self:expr()
                capt, posn = capt_right_bracket:match(self:src(), self:pos())
                if not posn then
                    syntaxerror "] expected"
                end
                self:skip_ws(posn)
                return ast
                end)


how.add_method(parser, 'zindex', function (self)
                -- index -> '{' expr '}'
                local capt, posn = capt_left_curly:match(self:src(), self:pos())
                assert(posn)
                self:skip_ws(posn)
                local ast = self:expr()
                capt, posn = capt_right_curly:match(self:src(), self:pos())
                if not posn then
                    syntaxerror "} expected"
                end
                self:skip_ws(posn)
                return ast
                end)


how.add_method(parser, 'explist', function (self, op)
                -- explist -> expr { `,' expr }
                local name, posn = capt_named:match(self:src(), self:pos())
                if posn then
                    self:pos(posn)
                    local capt, posn = capt_left_paren:match(self:src(), self:pos())
                    if posn then
                        self:pos(posn)
                        local ast = self:expr(name)
                        ast:named(name)
                        op:push(ast)
                        capt, posn = capt_right_paren:match(self:src(), self:pos())
                        if posn then
                            self:pos(posn)
                        else
                            syntaxerror ") expected"
                        end
                    else
                        syntaxerror "( expected"
                    end
                else
                    op:push(self:expr())
                end
                self:skip_ws()
                local capt, posn = capt_comma:match(self:src(), self:pos())
                while posn do
                    self:skip_ws(posn)
                    if tok_right_paren:match(self:src(), self:pos()) then
                        return
                    end
                    name, posn = capt_named:match(self:src(), self:pos())
                    if posn then
                        self:pos(posn)
                        capt, posn = capt_left_paren:match(self:src(), self:pos())
                        if posn then
                            self:pos(posn)
                            local ast = self:expr(name)
                            ast:named(name)
                            op:push(ast)
                            capt, posn = capt_right_paren:match(self:src(), self:pos())
                            if posn then
                                self:pos(posn)
                            else
                                syntaxerror ") expected"
                            end
                        else
                            syntaxerror "( expected"
                        end
                    else
                        op:push(self:expr())
                    end
                    self:skip_ws()
                    capt, posn = capt_comma:match(self:src(), self:pos())
                end
                end)


how.add_method(parser, 'funcargs', function (self, op)
                -- funcargs -> `(' [ explist ] `)'
                local capt, posn = capt_left_paren:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    capt, posn = capt_right_paren:match(self:src(), self:pos())
                    if posn then
                        self:pos(posn)
                        return
                    end
                    self:explist(op)
                    capt, posn = capt_right_paren:match(self:src(), self:pos())
                    if posn then
                        self:skip_ws(posn)
                        return
                    else
                        syntaxerror ") expected"
                    end
                end
                syntaxerror "function arguments expected"
                end)


how.add_method(parser, 'primaryexpr', function (self)
                -- primaryexp -> NAME | '(' expr ')'
                self:skip_ws()
                local capt, posn = capt_my:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    capt, posn = capt_variable:match(self:src(), self:pos())
                    if posn then
                        self:pos(posn)
                        self:scope()[capt] = 'lexical'
                        local init = self:init()
                        local sigil = string.sub(capt, 1, 1)
                        local var = Var:new{ name=capt, scope='lexical', decl=true }
                        if     sigil == '%' then
                            init:push(Op:new{ lineno=lineno, op='op', name='&infix:<:=>', var, Op:new{ op='hash' } })
                            return Var:new{ name=capt, scope='lexical' }
                        elseif sigil == '@' then
                            init:push(Op:new{ lineno=lineno, op='op', name='&infix:<:=>', var, Op:new{ op='list' } })
                            return Var:new{ name=capt, scope='lexical' }
                        else
                            return var
                        end
                    end
                    syntaxerror "variable expected"
                end
                capt, posn = capt_our:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    capt, posn = capt_variable:match(self:src(), self:pos())
                    if posn then
                        self:pos(posn)
                        self:scope()[capt] = 'package'
                        local init = self:init()
                        local sigil = string.sub(capt, 1, 1)
                        local var = Var:new{ name=capt, scope='package', decl=true }
                        if     sigil == '%' then
                            init:push(Op:new{ lineno=lineno, op='op', name='&infix:<:=>', var, Op:new{ op='hash' } })
                            return Var:new{ name=capt, scope='package' }
                        elseif sigil == '@' then
                            init:push(Op:new{ lineno=lineno, op='op', name='&infix:<:=>', var, Op:new{ op='list' } })
                            return Var:new{ name=capt, scope='package' }
                        else
                            return var
                        end
                    end
                    syntaxerror "variable expected"
                end
                local capt, posn = capt_has:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    return self:attributedef()
                end
                local capt, posn = capt_sub:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    return self:routinedef()
                end
                local capt, posn = capt_method:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    return self:methoddef()
                end
                local capt, posn = capt_class:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    return self:classdef()
                end
                local capt, posn = capt_role:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    return self:roledef()
                end
                local capt, posn = capt_module:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    return self:moduledef()
                end
                capt, posn = capt_left_paren:match(self:src(), self:pos())
                if posn then
                    self:pos(posn)
                    local op = Op:new{ op='list' }
                    self:explist(op)
                    capt, posn = capt_right_paren:match(self:src(), self:pos())
                    if posn then
                        self:pos(posn)
                        return (#op == 1) and op[1] or op
                    else
                        syntaxerror ") expected"
                    end
                end
                capt, posn = capt_variable:match(self:src(), self:pos())
                if posn then
                    self:pos(posn)
                    local scope = assert(self:scope()[capt])
                    return Var:new{ lineno=lineno, name=capt, scope=scope }
                end
                capt, posn = capt_identifier:match(self:src(), self:pos())
                if posn then
                    self:pos(posn)
                    return capt
                end
                syntaxerror "unexpected symbol"
                end)


how.add_method(parser, 'suffixedexpr', function (self)
                -- suffixedexp ->
                --    primaryexp { `{' exp `}' | `[' exp `]' | `.' NAME funcargs | funcargs }
                local op = self:primaryexpr()
                local capt, posn = capt_postfix:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    op = Op:new{ op='op', name='&postfix:<' .. capt .. '>', op }
                end
                while true do
                    capt, posn = capt_angle:match(self:src(), self:pos())
                    if posn then
                        self:pos(posn)
                        op = Var:new{ scope='associative', op, SVal:new{ value=capt } }
                    elseif tok_left_curly:match(self:src(), self:pos()) then
                        op = Var:new{ scope='associative', op, self:zindex() }
                    elseif tok_left_bracket:match(self:src(), self:pos()) then
                        op = Var:new{ scope='positional', op, self:yindex() }
                    elseif tok_left_paren:match(self:src(), self:pos()) then
                        if type(op) == 'string' then
                            op = Op:new{ lineno=lineno, op='call', name='&' .. op }
                        else
                            op = Op:new{ lineno=lineno, op='call', op }
                        end
                        self:funcargs(op)
                    elseif tok_dot:match(self:src(), self:pos()) then
                        local capt, posn = capt_dot:match(self:src(), self:pos())
                        self:pos(posn)
                        local capt, posn = capt_name:match(self:src(), self:pos())
                        if posn then
                            self:pos(posn)
                            if type(op) == 'string' then
                                local scope = assert(self:scope()[op])
                                op = Var:new{ scope=scope, name=op }
                            end
                            op = Op:new{ lineno=lineno, op='callmeth', name=capt, op }
                            if tok_left_paren:match(self:src(), self:pos()) then
                                self:funcargs(op)
                            end
                        else
                            syntaxerror "methname expected"
                        end
                    else
                        return op
                    end
                end
                end)


how.add_method(parser, 'simpleexpr', function (self)
                -- simpleexp -> NUMBER | STRING | suffixedexpr
                local capt, posn = capt_number:match(self:src(), self:pos())
                if posn then
                    self:pos(posn)
                    return NVal:new{ lineno=lineno, value=capt }
                end
                capt, posn = capt_string:match(self:src(), self:pos())
                if posn then
                    self:pos(posn)
                    return SVal:new{ lineno=lineno, value=capt }
                end
                capt, posn = capt_q:match(self:src(), self:pos())
                if posn then
                    self:pos(posn)
                    return SVal:new{ lineno=lineno, value=capt }
                end
                return self:suffixedexpr()
                end)


local priority = {
    --        { left right }
    ['+']     = { 6, 6 },
    ['+&']    = { 6, 6 },
    ['+|']    = { 6, 6 },
    ['+^']    = { 6, 6 },
    ['-']     = { 6, 6 },
    ['*']     = { 7, 7 },
    ['/']     = { 7, 7 },
    ['%']     = { 7, 7 },
    ['**']    = { 10, 9 },      -- right associative
    ['~']     = { 5, 4 },       -- right associative
    ['ne']    = { 3, 3 },
    ['eq']    = { 3, 3 },
    ['lt']    = { 3, 3 },
    ['le']    = { 3, 3 },
    ['gt']    = { 3, 3 },
    ['ge']    = { 3, 3 },
    ['!=']    = { 3, 3 },
    ['==']    = { 3, 3 },
    ['=:=']   = { 3, 3 },
    ['<=']    = { 3, 3 },
    ['<']     = { 3, 3 },
    ['>=']    = { 3, 3 },
    ['>']     = { 3, 3 },
    ['&&']    = { 2, 2 },
    ['//']    = { 2, 2 },
    ['||']    = { 2, 2 },
    [':=']    = { 1, 1 },
    ['=']     = { 1, 1 },       -- fails in TVM::AST::Op.as_op()
}

how.add_method(parser, 'expr', function (self, limit)
                -- expr -> (simpleexp | unop expr) { binop expr }
                limit = limit or 0
                local op
                local capt, posn = capt_prefix:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    op = Op:new{ lineno=lineno, op='op', name='&prefix:<' .. capt .. '>' }
                    op:push(self:expr(8))       -- UNARY_PRIORITY
                else
                    op = self:simpleexpr(s, pos, buf, one)
                end
                self:skip_ws(s)
                capt, posn = capt_infix:match(self:src(), self:pos())
                while posn and assert(priority[capt])[1] > limit do
                    self:skip_ws(posn)
                    op = Op:new{ lineno=lineno, op='op', name='&infix:<' .. capt .. '>', op }
                    op:push(self:expr(priority[capt][2]))
                    self:skip_ws()
                    capt, posn = capt_infix:match(self:src(), self:pos())
                end
                return op
                end)


how.add_method(parser, 'parameter', function (self)
                local named, posn = capt_colon:match(self:src(), self:pos())
                if posn then
                    self:pos(posn)
                end
                local capt, posn = capt_paramvar:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    self:scope()[capt] = 'lexical'
                    if named then
                        named = string.sub(capt, 2)
                    end
                    return Var:new{ lineno=lineno, name=capt, scope='lexical', named=named, decl=true }
                end
                syntaxerror "parameter expected"
                end)


how.add_method(parser, 'signature', function (self)
                local sig = Stmts:new{}
                sig:push(self:parameter())
                local capt, posn = capt_comma:match(self:src(), self:pos())
                while posn do
                    self:skip_ws(posn)
                    sig:push(self:parameter())
                    capt, posn = capt_comma:match(self:src(), self:pos())
                end
                return sig
                end)


how.add_method(parser, 'callsignature', function (self)
                local capt, posn = capt_left_paren:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    capt, posn = capt_right_paren:match(self:src(), self:pos())
                    if posn then
                        self:skip_ws(posn)
                        return Stmts:new{}
                    end
                    local sig = self:signature()
                    capt, posn = capt_right_paren:match(self:src(), self:pos())
                    if posn then
                        self:skip_ws(posn)
                        return sig
                    end
                    syntaxerror ") expected"
                end
                syntaxerror "( expected"
                end)


how.add_method(parser, 'routinedef', function (self)
                local lineno = lineno
                local capt, posn = capt_funcname:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    local name = '&' .. capt
                    local bl = Block:new{ blocktype='routine', self:callsignature(), self:block() }
                    self:scope()[name] = 'lexical'
                    self:init():push(Op:new{ lineno=lineno, op='op', name='&infix:<:=>', Var:new{ name=name, scope='lexical', decl=true }, bl })
                    return Var:new{ name=name, scope='lexical' }
                end
                syntaxerror "funcname expected"
                end)


how.add_method(parser, 'methoddef', function (self)
                local lineno = lineno
                local capt, posn = capt_name:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    self:scope()['self'] = 'lexical'
                    local bl = Block:new{ blocktype='method', self:callsignature(), self:block() }
                    local pkg = Var:new{ scope='lexical', name='_PKG' }
                    local how = Op:new{ op='callmeth', name='WHAT', pkg }
                    local add_method = Var:new{ scope='associative', how, SVal:new{ value=quote'add_method' } }
                    self:init():push(Op:new{ lineno=lineno, op='call', add_method, pkg, SVal:new{ value=quote(capt) }, bl })
                    return pkg
                end
                syntaxerror "methname expected"
                end)


how.add_method(parser, 'attributedef', function (self)
                local lineno = lineno
                local capt, posn = capt_variable:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    self:scope()[capt] = 'attribute'
                    local pkg = Var:new{ scope='lexical', name='_PKG' }
                    local how = Op:new{ op='callmeth', name='WHAT', pkg }
                    local add_attribute = Var:new{ scope='associative', how, SVal:new{ value=quote'add_attribute' } }
                    local attr = Op:new{ op='hash', SVal:new{ value='name' }, SVal:new{ value=quote(capt) } }
                    self:init():push(Op:new{ lineno=lineno, op='call', add_attribute, pkg, attr })
                    return pkg
                end
                syntaxerror "attrname expected"
                end)


how.add_method(parser, 'classdef', function (self)
                local lineno = lineno
                local capt, posn = capt_name:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    self:scope()[capt] = 'package'
                    local init = self:init()
                    local p6pkg = Var:new{ scope='lexical', name='_P6PKG' }
                    local p6class = Var:new{ scope='lexical', name='p6class' }
                    init:push(Op:new{ lineno=lineno, op='let', p6class, Var:new{ scope='associative', p6pkg, SVal:new{ value=quote'NQP::Metamodel::ClassHOW' } } })
                    local pkg = Var:new{ scope='lexical', name='_PKG' }
                    local class = Op:new{ op='callmeth', name='new', p6class, SVal:new{ value=quote(capt) } }
                    init:push(Op:new{ lineno=lineno, op='let', pkg, class })
                    init:push(Op:new{ lineno=lineno, op='op', name='&infix:<:=>', Var:new{ scope='associative', p6pkg, SVal:new{ value=quote(capt) } }, pkg })
                    local add_parent = Var:new{ scope='associative', p6class, SVal:new{ value=quote'add_parent' } }
                    local add_role = Var:new{ scope='associative', p6class, SVal:new{ value=quote'add_role' } }
                    while tok_is:match(self:src(), self:pos()) or tok_does:match(self:src(), self:pos()) do
                        local capt, posn = capt_is:match(self:src(), self:pos())
                        if posn then
                            self:skip_ws(posn)
                            capt, posn = capt_name:match(self:src(), self:pos())
                            if posn then
                                self:skip_ws(posn)
                                local parent = Var:new{ scope='associative', p6pkg, SVal:new{ value=quote(capt) } }
                                init:push(Op:new{ lineno=lineno, op='call', add_parent, pkg, parent })
                            else
                                syntaxerror "classname expected"
                            end
                        end
                        capt, posn = capt_does:match(self:src(), self:pos())
                        if posn then
                            self:skip_ws(posn)
                            capt, posn = capt_name:match(self:src(), self:pos())
                            if posn then
                                self:skip_ws(posn)
                                local role = Var:new{ scope='associative', p6pkg, SVal:new{ value=quote(capt) } }
                                init:push(Op:new{ lineno=lineno, op='call', add_role, pkg, role })
                            else
                                syntaxerror "classname expected"
                            end
                        end
                    end
                    local any = Var:new{ scope='associative', p6pkg, SVal:new{ value=quote'Any' } }
                    init:push(Op:new{ lineno=lineno, op='call', add_parent, pkg, any })
                    self:block()
                    return pkg
                end
                syntaxerror "classname expected"
                end)


how.add_method(parser, 'roledef', function (self)
                local lineno = lineno
                local capt, posn = capt_funcname:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    self:scope()[capt] = 'package'
                    local init = self:init()
                    local p6pkg = Var:new{ scope='lexical', name='_P6PKG' }
                    local p6role = Var:new{ scope='lexical', name='p6role' }
                    init:push(Op:new{ lineno=lineno, op='let', p6role, Var:new{ scope='associative', p6pkg, SVal:new{ value=quote'NQP::Metamodel::RoleHOW' } } })
                    local pkg = Var:new{ scope='lexical', name='_PKG' }
                    local role = Op:new{ op='callmeth', name='new', p6role, SVal:new{ value=quote(capt) } }
                    init:push(Op:new{ lineno=lineno, op='let', pkg, role })
                    init:push(Op:new{ lineno=lineno, op='op', name='&infix:<:=>', Var:new{ scope='associative', p6pkg, SVal:new{ value=quote(capt) } }, pkg })
                    self:block()
                    return pkg
                end
                syntaxerror "rolename expected"
                end)


how.add_method(parser, 'moduledef', function (self)
                local lineno = lineno
                local capt, posn = capt_funcname:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    self:scope()[capt] = 'package'
                    local init = self:init()
                    local p6pkg = Var:new{ scope='lexical', name='_P6PKG' }
                    local p6module = Var:new{ scope='lexical', name='p6module' }
                    init:push(Op:new{ lineno=lineno, op='let', p6role, Var:new{ scope='associative', p6pkg, SVal:new{ value=quote'NQP::Metamodel::ModuleHOW' } } })
                    local pkg = Var:new{ scope='lexical', name='_PKG' }
                    local module = Op:new{ op='callmeth', name='new', p6module, SVal:new{ value=quote(capt) } }
                    init:push(Op:new{ lineno=lineno, op='let', pkg, module })
                    init:push(Op:new{ lineno=lineno, op='op', name='&infix:<:=>', Var:new{ scope='associative', p6pkg, SVal:new{ value=quote(capt) } }, pkg })
                    self:block()
                    return pkg
                end
                syntaxerror "modname expected"
                end)


how.add_method(parser, 'block', function (self)
                local capt, posn = capt_left_curly:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    local lineno =lineno
                    local ast = self:statlist()
                    capt, posn = capt_right_curly:match(self:src(), self:pos())
                    if not posn then
                        syntaxerror "} expected"
                    end
                    self:skip_ws(posn)
                    capt, posn = capt_semicolon:match(self:src(), self:pos())
                    if posn then
                        self:skip_ws(posn)
                    end
                    return Block:new{ lineno=lineno, blocktype='immediate', Stmts:new{}, ast }
                end
                syntaxerror "Missing block"
                end)


how.add_method(parser, 'pblock', function (self)
                local sig
                local capt, posn = capt_arrow:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    sig = self:signature()
                end
                capt, posn = capt_left_curly:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    local lineno =lineno
                    local ast = self:statlist()
                    capt, posn = capt_right_curly:match(self:src(), self:pos())
                    if not posn then
                        syntaxerror "} expected"
                    end
                    self:skip_ws(posn)
                    return Block:new{ lineno=lineno, blocktype='immediate', sig or Stmts:new{}, ast }
                end
                syntaxerror "Missing block"
                end)


how.add_method(parser, 'xblock', function (self, op)
                op:push(self:expr())
                self:skip_ws()
                op:push(self:pblock())
                return op
                end)


how.add_method(parser, 'ifstat', function (self)
                local op = Op:new{ lineno=lineno, op='if' }
                local op1 = op
                self:xblock(op)
                local capt, posn = capt_elsif:match(self:src(), self:pos())
                while posn do
                    local opn = Op:new{ lineno=lineno, op='if' }
                    op:push(opn)
                    self:skip_ws(posn)
                    op = self:xblock(opn)
                    capt, posn = capt_elsif:match(self:src(), self:pos())
                end
                capt, posn = capt_else:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    op:push(self:pblock())
                end
                return op1
                end)


how.add_method(parser, 'unlessstat', function (self)
                local op = Op:new{ lineno=lineno, op='unless' }
                return self:xblock(op)
                end)


how.add_method(parser, 'whilestat', function (self)
                local op = Op:new{ lineno=lineno, op='while' }
                return self:xblock(op)
                end)


how.add_method(parser, 'untilstat', function (self)
                local op = Op:new{ lineno=lineno, op='until' }
                return self:xblock(op)
                end)


how.add_method(parser, 'forstat', function (self)
                local op = Op:new{ lineno=lineno, op='for' }
                return self:xblock(op)
                end)


how.add_method(parser, 'returnstat', function (self)
                local op = Op:new{ lineno=lineno, op='return', self:expr() }
                local capt, posn = capt_semicolon:match(self:src(), self:pos())
                self:skip_ws(posn)
                return op
                end)


how.add_method(parser, 'statement_mod_cond', function (self, ast)
                local capt, posn = capt_if:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    return Op:new{ lineno=lineno, op='if', self:expr(), Block:new{ blocktype='immediate', Stmts:new{}, ast } }
                end
                capt, posn = capt_unless:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    return Op:new{ lineno=lineno, op='unless', self:expr(), Block:new{ blocktype='immediate', Stmts:new{}, ast } }
                end
                return ast
                end)


how.add_method(parser, 'statement_mod_loop', function (self, ast)
                local capt, posn = capt_while:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    return Op:new{ lineno=lineno, op='while', self:expr(), Block:new{ blocktype='immediate', Stmts:new{}, ast } }
                end
                capt, posn = capt_until:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    return Op:new{ lineno=lineno, op='until', self:expr(), Block:new{ blocktype='immediate', Stmts:new{}, ast } }
                end
                capt, posn = capt_for:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    return Op:new{ lineno=lineno, op='for', self:expr(), Block:new{ blocktype='immediate', Stmts:new{}, ast } }
                end
                return ast
                end)


how.add_method(parser, 'statement', function (self)
                self:skip_ws()
                -- stat -> block
                if tok_left_curly:match(self:src(), self:pos()) then
                    return self:block()
                end
                -- stat -> ifstat
                local capt, posn = capt_if:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    return self:ifstat()
                end
                -- stat -> unlessstat
                capt, posn = capt_unless:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    return self:unlessstat()
                end
                -- stat -> whilestat
                capt, posn = capt_while:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    return self:whilestat()
                end
                -- stat -> untilstat
                capt, posn = capt_until:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    return self:untilstat()
                end
                -- stat -> forstat
                capt, posn = capt_for:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    return self:forstat()
                end
                -- stat -> returnstat
                capt, posn = capt_return:match(self:src(), self:pos())
                if posn then
                    self:skip_ws(posn)
                    return self:returnstat()
                end
                local ast = self:expr()
                ast = self:statement_mod_cond(ast)
                ast = self:statement_mod_loop(ast)
                if not P(-1):match(self:src(), self:pos())
               and not tok_right_curly:match(self:src(), self:pos()) then
                    capt, posn = capt_semicolon:match(self:src(), self:pos())
--                    if not posn then
--                        syntaxerror "; expected"
--                    end
                    self:skip_ws(posn)
                end
                if ast:isa(Var)
               and not P(-1):match(self:src(), self:pos())
               and not tok_right_curly:match(self:src(), self:pos()) then
                    return
                else
                    return ast
                end
                end)


local prelude = [[
(!line "@prelude(nqp/compiler.lua)" 1)

(!do
(!let assert assert)
(!let error error)
(!let next next)
(!let pairs pairs)
(!let rawget rawget)
(!let rawset rawset)
(!let setmetatable setmetatable)
(!let tconcat (!index table "concat"))
(!let tonumber tonumber)
(!let tostring tostring)
(!let type type)
(!let unpack (!index tvm "unpack"))
(!let _G _G)
(!assign (!index _G "_P6PKG") ())

(!let argerror (!lambda (caller narg extramsg)
                (!call error (!mconcat "bad argument #" (!call1 tostring narg) " to " caller " (" extramsg ")"))))

(!let typeerror (!lambda (caller narg arg tname)
                (!call argerror caller narg (!mconcat tname " expected, got " (!call1 type arg)))))

(!let checktype (!lambda (caller narg arg tname)
                (!if (!ne (!call1 type arg) tname)
                     (!call typeerror caller narg arg tname))))

(!let checkisa (!lambda (caller narg arg type)
                (!if (!not (!callmeth1 arg isa type))
                     (!call typeerror caller narg arg (!callmeth1 type str)))))

(!letrec Mu_INIT (!lambda (obj class args)
                (!for (k attr) ((!call pairs (!index (!index class "_VALUES") "attributes")))
                        (!if (!eq (!index (!index obj "_VALUES") k) !nil)
                             (!do (!define val (!or (!index args k) (!index attr "default")))
                                  (!if (!eq (!call1 type val) "function")
                                       (!assign val (!call1 val obj)))
                                  (!assign (!index (!index obj "_VALUES") k) val))))
                (!let parents (!index (!index class "_VALUES") "parents"))
                (!loop i 0 (!sub (!index parents "n") 1) 1
                        (!call Mu_INIT obj (!index parents i) args))))

(!let Mu_BUILD (!lambda (class args)
                (!let obj ("_VALUES": () "_CLASS": class))
                (!call Mu_INIT obj class (!or args ()))
                (!return obj)))

(!define p6class)
(!do
(!do
        (!let class_add_method (!lambda (a)
                (!define (meta name func) ((!call unpack a)))
                (!assign name (!or (!and (!eq (!call1 type name) "table") (!index name "_VALUES")) name))
                (!call checktype "add_method" 2 name "string")
                (!call checktype "add_method" 3 func "function")
                (!let methods (!index (!index meta "_VALUES") "methods"))
                (!if (!index methods name)
                     (!call error (!concat "This class already has a method named " name)))
                (!assign (!index methods name) func)
                (!assign (!index (!index (!index meta "_VALUES") "proto") name) func)))
        (!let proto ("add_method": class_add_method))
        (!assign p6class ("_VALUES": (
                "name": "NQP::Metamodel::ClassHOW"
                "proto": proto
                "attributes": ()
                "methods": ("add_method": class_add_method)
                "parents": ("n": 0)
                "roles": ("n": 0)
                "ISA": (0: p6class "n": 1) ) ))
        (!assign (!index p6class "_CLASS") p6class)
        (!call setmetatable p6class (
                "__index": (!index (!index p6class "_VALUES") "proto")
                "__tostring": (!lambda (o) (!return (!index (!index o "_VALUES") "name"))) )))

(!call (!index p6class "add_method") (p6class "new" (!lambda (self a)
                (!define name (!call unpack a))
                (!assign name (!or (!and (!eq (!call1 type name) "table") (!index name "_VALUES")) name))
                (!let mt ("__tostring": (!lambda (o) (!return (!callmeth o str))) ))
                (!let class (!call1 Mu_BUILD p6class ("name": name "mt": mt)))
                (!assign (!index mt "__index") (!index (!index class "_VALUES") "proto"))
                (!return (!call setmetatable class (
                        "__index": (!index (!index class "_VALUES") "proto")
                        "__tostring": (!lambda (o) (!return name)) ))))))
(!call (!index p6class "add_method") (p6class "str" (!lambda (meta)
                (!return (!index (!index meta "_VALUES") "name")))))
(!call (!index p6class "add_method") (p6class "add_attribute" (!lambda (a)
                (!define (meta attr) ((!call unpack a)))
                (!assign attr (!or (!index attr "_VALUES") attr))
                (!let name (!index attr "name"))
                (!call checktype "add_attribute" "name" name "string")
                (!let attributes (!index (!index meta "_VALUES") "attributes"))
                (!if (!index attributes name)
                     (!call error (!concat "This class already has an attribute named " name)))
                (!assign (!index attributes name) attr)
                (!assign (!index (!index (!index meta "_VALUES") "proto") name) (!lambda (obj val)
                                (!let t (!call1 rawget obj "_VALUES"))
                                (!if (!ne val !nil)
                                     (!assign (!index t name) (!call1 unpack val))
                                     (!return (!index t name))))))))
(!call (!index p6class "add_attribute") (p6class ("name": "name" "default": "<anon>")))
(!call (!index p6class "add_attribute") (p6class ("name": "proto" "default": (!lambda () (!return ())))))
(!call (!index p6class "add_attribute") (p6class ("name": "methods" "default": (!lambda () (!return ())))))
(!call (!index p6class "add_attribute") (p6class ("name": "attributes" "default": (!lambda () (!return ())))))
(!call (!index p6class "add_attribute") (p6class ("name": "parents" "default": (!lambda () (!return ("n": 0))))))
(!call (!index p6class "add_attribute") (p6class ("name": "roles" "default": (!lambda () (!return ("n": 0))))))
(!call (!index p6class "add_attribute") (p6class ("name": "ISA" "default": (!lambda (self) (!return (0: self "n": 1))))))
(!call (!index p6class "add_attribute") (p6class ("name": "mt")))
(!call (!index p6class "add_method") (p6class "HOW" (!lambda (meta)
                (!return (!index (!index p6class "_VALUES") "proto")))))
(!call (!index p6class "add_method") (p6class "add_role" (!lambda (a)
                (!let (meta role) ((!call unpack a)))
                (!let roles (!index (!index meta "_VALUES") "roles"))
                (!let n (!index roles "n"))
                (!loop i 0 (!sub n 1) 1
                        (!if (!eq (!index roles i) role)
                             (!call error (!mconcat "The role " (!index (!index role "_VALUES") "name") " has already been added."))))
                (!assign (!index roles n) role)
                (!assign (!index roles "n") (!add n 1))
                (!for (k v) ((!call pairs (!index (!index role "_VALUES") "methods")))
                        (!call (!index p6class "add_method") (meta k v)))
                (!for (_ v) ((!call pairs (!index (!index role "_VALUES") "attributes")))
                        (!call (!index p6class "add_attribute") (meta v))))))
(!call (!index p6class "add_method") (p6class "add_parent" (!lambda (a)
                (!let (meta parent) ((!call unpack a)))
                (!if (!eq meta parent)
                     (!call error (!mconcat "Class '" (!callmeth1 meta name) "' cannot inherit from itself.")))
                (!let parents (!index (!index meta "_VALUES") "parents"))
                (!let n (!index parents "n"))
                (!loop i 0 (!sub n 1) 1
                        (!if (!eq (!index parents i) parent)
                             (!call error (!mconcat "Already have " (!callmeth1 parent name) " as a parent class."))))
                (!assign (!index parents n) parent)
                (!assign (!index parents "n") (!add n 1))
                (!let ISA (!index (!index meta "_VALUES") "ISA"))
                (!let n (!index ISA "n"))
                (!assign (!index ISA n) (!index (!index parent "_VALUES") "ISA"))
                (!assign (!index ISA "n") (!add n 1))
                (!call setmetatable (!index (!index meta "_VALUES") "proto") (
                        "__index": (!lambda (t k)
                                        (!letrec search (!lambda (class)
                                                        (!let parents (!index (!index class "_VALUES") "parents"))
                                                        (!loop i 0 (!sub (!index parents "n") 1) 1
                                                                (!let p (!index parents i))
                                                                (!let v (!or (!call1 rawget (!index (!index p "_VALUES") "proto") k) (!call1 search p)))
                                                                (!if v (!return v)))))
                                        (!let v (!call1 search meta))
                                        (!assign (!index t k) v)
                                        (!return v)) )))))
(!assign (!index _P6PKG "NQP::Metamodel::ClassHOW") p6class)
(!call (!index p6class "add_method") (p6class "can" (!lambda (a)
                (!let (meta name) ((!call unpack a)))
                (!return (!ne (!index (!index (!index meta "_VALUES") "proto") name) !nil)))))
(!call (!index p6class "add_method") (p6class "isa" (!lambda (a)
                (!let (meta parent) ((!call unpack a)))
                (!letrec walk (!lambda (types)
                                (!loop i 0 (!sub (!index types "n") 1) 1
                                        (!define v (!index types i))
                                        (!if (!eq v parent)
                                             (!return !true)
                                             (!if (!eq (!call1 type v) "table")
                                                  (!do (!let result (!call1 walk v))
                                                       (!if result (!return result))))))
                                (!return !false)))
                (!return (!call walk (!index (!index meta "_VALUES") "ISA"))))))
(!call (!index p6class "add_method") (p6class "does" (!lambda (a)
                (!let (meta role) ((!call unpack a)))
                (!let roles (!index (!index meta "_VALUES") "roles"))
                (!loop i 0 (!sub (!index roles "n") 1) 1
                        (!if (!eq (!index roles i) role)
                             (!return !true)))
                (!return !false))))
)

(!let p6role (!callmeth1 p6class new ("NQP::Metamodel::RoleHOW")))
(!do
(!assign (!index _P6PKG "NQP::Metamodel::RoleHOW") p6role)
(!call (!index p6class "add_attribute") (p6role ("name": "name" "default": "<anon>")))
(!call (!index p6class "add_attribute") (p6role ("name": "methods" "default": (!lambda () (!return ())))))
(!call (!index p6class "add_attribute") (p6role ("name": "attributes" "default": (!lambda () (!return ())))))
(!call (!index p6class "add_method") (p6role "new" (!lambda (self a)
                (!define name (!call unpack a))
                (!assign name (!or (!and (!eq (!call1 type name) "table") (!index name "_VALUES")) name))
                (!let role (!call1 Mu_BUILD p6class ("name": name)))
                (!return (!call setmetatable role (
                        "__index": (!index (!index role "_VALUES") "proto")
                        "__tostring": (!lambda (o) (!return name)) ))))))
(!call (!index p6class "add_method") (p6role "str" (!lambda (meta)
                (!return (!index (!index meta "_VALUES") "name")))))
(!call (!index p6class "add_method") (p6role "HOW" (!lambda (meta)
                (!return (!index (!index p6role "_VALUES") "proto")))))
(!call (!index p6class "add_method") (p6role "add_method" (!lambda (a)
                (!let (meta name func) ((!call unpack a)))
                (!call checktype "add_method" 2 name "string")
                (!call checktype "add_method" 3 func "function")
                (!define methods (!index (!index meta "_VALUES") "methods"))
                (!if (!index methods name)
                     (!call error (!concat "This role already has a method named " name)))
                (!assign (!index methods name) func))))
(!call (!index p6class "add_method") (p6role "add_attribute" (!lambda (a)
                (!define (meta attr) ((!call unpack a)))
                (!assign attr (!or (!index attr "_VALUES") attr))
                (!let name (!index attr "name"))
                (!call checktype "add_attribute" "name" name "string")
                (!let attributes (!index (!index meta "_VALUES") "attributes"))
                (!if (!index attributes name)
                     (!call error (!concat "This role already has an attribute named " name)))
                (!assign (!index attributes name) attr))))
)

(!let p6module (!callmeth1 p6class new ("NQP::Metamodel::ModuleHOW")))
(!do
(!assign (!index _P6PKG "NQP::Metamodel::ModuleHOW") p6module)
(!call (!index p6class "add_attribute") (p6module ("name": "name" "default": "<anon>")))
(!assign (!index (!index p6module "_VALUES") "mt") (
        "__index": (!lambda (t k)
                        (!return (!or (!call1 rawget (!index t "_VALUES") k) (!index (!index (!index (!index t "_CLASS") "_VALUES") "proto") k))))
        "__newindex": (!lambda (t k v)
                        (!call rawset (!index t "_VALUES") k v))
        "__tostring": (!lambda (t)
                        (!return (!callmeth t str))) ))
(!call (!index p6class "add_method") (p6module "new" (!lambda (self a)
                (!define name (!call unpack a))
                (!assign name (!or (!and (!eq (!call1 type name) "table") (!index name "_VALUES")) name))
                (!return (!call setmetatable ("_VALUES": ("name": name) "_CLASS": p6module) (!index (!index p6module "_VALUES") "mt"))))))
(!call (!index p6class "add_method") (p6module "str" (!lambda (meta)
                (!return (!index (!index meta "_VALUES") "name")))))
(!call (!index p6class "add_method") (p6module "HOW" (!lambda (meta)
                (!return (!index (!index p6module "_VALUES") "proto")))))
)

(!let p6mu (!callmeth1 p6class new ("Mu")))
(!do
(!assign (!index _P6PKG "Mu") p6mu)
(!call (!index p6class "add_method") (p6mu "new" (!lambda (class a)
                (!define t (!or (!call unpack a) ()))
                (!assign t (!or (!index t "_VALUES") t))
                (!return (!call setmetatable (!call1 Mu_BUILD class t) (!index (!index class "_VALUES") "mt"))))))
(!call (!index p6class "add_method") (p6mu "reset" (!lambda (self a)
                (!define attrname (!call unpack a))
                (!assign attrname (!or (!and (!eq (!call1 type attrname) "table") (!index attrname "_VALUES")) attrname))
                (!assign (!index (!index self "_VALUES") attrname) !nil))))
(!call (!index p6class "add_method") (p6mu "_assign" (!lambda (self a)
                (!let v (!call unpack a))
                (!assign (!index self "_VALUES") (!index v "_VALUES"))
                (!assign (!index self "_CLASS") (!index v "_CLASS"))
                (!return (!call setmetatable self (!call1 getmetatable v))))))
(!call (!index p6class "add_method") (p6mu "defined" (!lambda (self)
                (!return !true))))
(!call (!index p6class "add_method") (p6mu "WHAT" (!lambda (self)
                (!return (!call rawget self "_CLASS")))))
(!call (!index p6class "add_method") (p6mu "Box" (!lambda (self)
                (!return self))))
(!call (!index p6class "add_method") (p6mu "Str" (!lambda (self)
                (!return (!callmeth (!index _P6PKG "Str") new ((!callmeth1 self str)))))))
(!call (!index p6class "add_method") (p6mu "Num" (!lambda (self)
                (!return (!callmeth (!index _P6PKG "Num") new ((!callmeth1 self num)))))))
(!call (!index p6class "add_method") (p6mu "Int" (!lambda (self)
                (!return (!callmeth (!index _P6PKG "Num") new ((!callmeth1 self int)))))))
(!call (!index p6class "add_method") (p6mu "Bool" (!lambda (self)
                (!return (!callmeth (!index _P6PKG "Bool") new ((!callmeth1 self bool)))))))
(!call (!index p6class "add_method") (p6mu "str" (!lambda (self)
                (!return (!index (!index (!callmeth1 self WHAT) "_VALUES") "name")))))
(!call (!index p6class "add_method") (p6mu "gist" (!lambda (self)
                (!return (!callmeth (!index _P6PKG "str") new ((!index (!index (!callmeth1 self WHAT) "_VALUES") "name")))))))
(!call (!index p6class "add_method") (p6mu "print" (!lambda (self)
                (!call (!index (!index _P6PKG "MAIN") "print") (self)))))
(!call (!index p6class "add_method") (p6mu "say" (!lambda (self)
                (!callmeth (!callmeth1 self gist) say))))
)

(!let p6any (!callmeth1 p6class new ("Any")))
(!do
(!assign (!index _P6PKG "Any") p6any)
(!call (!index p6class "add_parent") (p6any p6mu))
(!call (!index p6class "add_method") (p6any "clone" (!lambda (self)
                (!let class (!callmeth1 self WHAT))
                (!return (!callmeth class new (self))))))
(!call (!index p6class "add_method") (p6any "can" (!lambda (self a)
                (!define name (!call unpack a))
                (!assign name (!or (!and (!eq (!call1 type name) "table") (!index name "_VALUES")) name))
                (!let class (!callmeth1 self WHAT))
                (!return (!call (!index p6class "can") (class name))))))
(!call (!index p6class "add_method") (p6any "does" (!lambda (self a)
                (!let role (!call unpack a))
                (!let class (!callmeth1 self WHAT))
                (!return (!call (!index p6class "does") (class role))))))
(!call (!index p6class "add_method") (p6any "isa" (!lambda (self a)
                (!let parent (!call unpack a))
                (!let class (!callmeth1 self WHAT))
                (!return (!call (!index p6class "isa") (class parent))))))
(!call (!index p6class "add_method") (p6any "perl" (!lambda (self)
                (!return (!index (!callmeth1 self WHAT) "name")))))
(!call (!index p6class "add_parent") (p6class p6any))
(!call (!index p6class "add_parent") (p6role p6any))
(!call (!index p6class "add_parent") (p6module p6any))
)

(!let p6cool (!callmeth1 p6class new ("Cool")))
(!do
(!let abs (!index math "abs"))
(!let ceil (!index math "ceil"))
(!let floor (!index math "floor"))
(!let sqrt (!index math "sqrt"))
(!let exp (!index math "exp"))
(!let log (!index math "log"))
(!let log10 (!index math "log10"))
(!let cos (!index math "cos"))
(!let sin (!index math "sin"))
(!let tan (!index math "tan"))
(!let acos (!index math "acos"))
(!let asin (!index math "asin"))
(!let atan (!index math "atan"))
(!let find (!index string "find"))
(!let lower (!index string "lower"))
(!let sub (!index string "sub"))
(!let upper (!index string "upper"))
(!assign (!index _P6PKG "Cool") p6cool)
(!call (!index p6class "add_parent") (p6cool p6any))
(!call (!index p6class "add_method") (p6cool "end" (!lambda (self)
                (!return (!sub (!callmeth1 self elems) 1)))))
(!call (!index p6class "add_method") (p6cool "_preincr" (!lambda (self)
                (!return (!callmeth self succ)))))
(!call (!index p6class "add_method") (p6cool "_postincr" (!lambda (self)
                (!let old (!callmeth1 self clone))
                (!callmeth self succ)
                (!return old))))
(!call (!index p6class "add_method") (p6cool "_predecr" (!lambda (self)
                (!return (!callmeth self prec)))))
(!call (!index p6class "add_method") (p6cool "_postdecr" (!lambda (self)
                (!let old (!callmeth1 self clone))
                (!callmeth self prec)
                (!return old))))
(!call (!index p6class "add_method") (p6cool "abs" (!lambda (self)
                (!return (!call abs (!callmeth1 self num))))))
(!call (!index p6class "add_method") (p6cool "ceiling" (!lambda (self)
                (!return (!call ceil (!callmeth1 self num))))))
(!call (!index p6class "add_method") (p6cool "floor" (!lambda (self)
                (!return (!call floor (!callmeth1 self num))))))
(!call (!index p6class "add_method") (p6cool "sqrt" (!lambda (self)
                (!return (!call sqrt (!callmeth1 self num))))))
(!call (!index p6class "add_method") (p6cool "exp" (!lambda (self)
                (!return (!call exp (!callmeth1 self num))))))
(!call (!index p6class "add_method") (p6cool "ln" (!lambda (self)
                (!return (!call log (!callmeth1 self num))))))
(!call (!index p6class "add_method") (p6cool "log10" (!lambda (self)
                (!return (!call log10 (!callmeth1 self num))))))
(!call (!index p6class "add_method") (p6cool "cos" (!lambda (self)
                (!return (!call cos (!callmeth1 self num))))))
(!call (!index p6class "add_method") (p6cool "sin" (!lambda (self)
                (!return (!call sin (!callmeth1 self num))))))
(!call (!index p6class "add_method") (p6cool "tan" (!lambda (self)
                (!return (!call tan (!callmeth1 self num))))))
(!call (!index p6class "add_method") (p6cool "acos" (!lambda (self)
                (!return (!call acos (!callmeth1 self num))))))
(!call (!index p6class "add_method") (p6cool "asin" (!lambda (self)
                (!return (!call asin (!callmeth1 self num))))))
(!call (!index p6class "add_method") (p6cool "atan" (!lambda (self)
                (!return (!call atan (!callmeth1 self num))))))
(!call (!index p6class "add_method") (p6cool "lc" (!lambda (self)
                (!return (!call lower (!callmeth1 self str))))))
(!call (!index p6class "add_method") (p6cool "lcfirst" (!lambda (self)
                (!let s (!callmeth1 self str))
                (!return (!concat (!call1 lower (!call1 sub s 1 1)) (!call1 sub s 2))))))
(!call (!index p6class "add_method") (p6cool "uc" (!lambda (self)
                (!return (!call upper (!callmeth1 self str))))))
(!call (!index p6class "add_method") (p6cool "ucfirst" (!lambda (self)
                (!let s (!callmeth1 self str))
                (!return (!concat (!call1 upper (!call1 sub s 1 1)) (!call1 sub s 2))))))
(!call (!index p6class "add_method") (p6cool "index" (!lambda (self a)
                (!define (substring pos) ((!call unpack a)))
                (!assign substring (!or (!and (!eq (!call1 type substring) "table") (!index substring "_VALUES")) substring))
                (!assign pos (!or (!or (!and (!eq (!call1 type pos) "table") (!index pos "_VALUES")) pos) 0))
                (!call checktype "index" 1 substring "string")
                (!call checktype "index" 2 pos "number")
                (!return (!sub (!call1 find (!callmeth1 self str) substring (!add pos 1) !true) 1)))))
(!call (!index p6class "add_method") (p6cool "substr" (!lambda (self a)
                (!define (start length) ((!call unpack a)))
                (!assign start (!or (!and (!eq (!call1 type start) "table") (!index start "_VALUES")) start))
                (!assign length (!or (!and (!eq (!call1 type length) "table") (!index length "_VALUES")) length))
                (!call checktype "substr" 1 start "number")
                (!call checktype "substr" 2 length "number")
                (!return (!call sub (!callmeth1 self str) (!add start 1) (!add start length))))))
)

(!let p6str (!callmeth1 p6class new ("str")))
(!do
(!let len (!index string "len"))
(!let quote (!index tvm "quote"))
(!assign (!index (!index p6str "_VALUES") "mt") (
        "__index": (!index (!index p6str "_VALUES") "proto") ))
(!call (!index debug "setmetatable") "" (!index (!index p6str "_VALUES") "mt"))
(!assign (!index _P6PKG "str") p6str)
(!call (!index p6class "add_parent") (p6str p6cool))
(!call (!index p6class "add_method") (p6str "new" (!lambda (self a)
                (!let str (!call unpack a))
                (!call checktype "new" 1 str "string")
                (!return str))))
(!call (!index p6class "add_method") (p6str "WHAT" (!lambda (self)
                (!return p6str))))
(!call (!index p6class "add_method") (p6str "Box" (!lambda (self)
                (!return (!callmeth (!index _P6PKG "Str") new (self))))))
(!call (!index p6class "add_method") (p6str "str" (!lambda (self)
                (!return self))))
(!call (!index p6class "add_method") (p6str "bool" (!lambda (self)
                (!return (!and (!ne self "") (!ne self "0"))))))
(!call (!index p6class "add_method") (p6str "num" (!lambda (self)
                (!return (!call assert (!call1 tonumber self))))))
(!call (!index p6class "add_method") (p6str "int" (!lambda (self)
                (!return (!callmeth (!callmeth1 self num) int)))))
(!call (!index p6class "add_method") (p6str "gist" (!lambda (self)
                (!return self))))
(!call (!index p6class "add_method") (p6str "perl" (!lambda (self)
                (!return (!call quote self)))))
(!call (!index p6class "add_method") (p6str "print" (!lambda (self)
                (!call (!index (!index _P6PKG "MAIN") "print") self))))
(!call (!index p6class "add_method") (p6str "say" (!lambda (self)
                (!call (!index (!index _P6PKG "MAIN") "say") self))))
(!call (!index p6class "add_method") (p6str "elems" (!lambda (self)
                (!return (!call len self)))))
)

(!let p6bool (!callmeth1 p6class new ("bool")))
(!do
(!assign (!index (!index p6bool "_VALUES") "mt") ("__index": (!index (!index p6bool "_VALUES") "proto") ))
(!call (!index debug "setmetatable") !false (!index (!index p6bool "_VALUES") "mt"))
(!assign (!index _P6PKG "bool") p6bool)
(!call (!index p6class "add_parent") (p6bool p6cool))
(!call (!index p6class "add_method") (p6bool "new" (!lambda (self a)
                (!let bool (!call unpack a))
                (!call checktype "new" 1 bool "boolean")
                (!return bool))))
(!call (!index p6class "add_method") (p6bool "WHAT" (!lambda (self)
                (!return p6bool))))
(!call (!index p6class "add_method") (p6bool "Box" (!lambda (self)
                (!return (!callmeth (!index _P6PKG "Bool") new (self))))))
(!call (!index p6class "add_method") (p6bool "str" (!lambda (self)
                (!return (!or (!and self "True") "False")))))
(!call (!index p6class "add_method") (p6bool "bool" (!lambda (self)
                (!return self))))
(!call (!index p6class "add_method") (p6bool "num" (!lambda (self)
                (!return (!or (!and self 1.0) 0.0)))))
(!call (!index p6class "add_method") (p6bool "int" (!lambda (self)
                (!return (!or (!and self 1) 0)))))
(!call (!index p6class "add_method") (p6bool "gist" (!lambda (self)
                (!return (!callmeth self str)))))
(!call (!index p6class "add_method") (p6bool "perl" (!lambda (self)
                (!return (!callmeth self str)))))
)

(!let p6nil (!callmeth1 p6class new ("nil")))
(!do
(!assign (!index (!index p6nil "_VALUES") "mt") ("__index": (!index (!index p6nil "_VALUES") "proto") ))
(!call (!index debug "setmetatable") !nil (!index (!index p6nil "_VALUES") "mt"))
(!assign (!index _P6PKG "nil") p6nil)
(!call (!index p6class "add_parent") (p6nil p6any))
(!call (!index p6class "add_method") (p6nil "new" (!lambda () (!return !nil))))
(!call (!index p6class "add_method") (p6nil "WHAT" (!lambda () (!return p6nil))))
(!call (!index p6class "add_method") (p6nil "Box" (!lambda ()
                (!return (!callmeth (!index _P6PKG "Nil") new (self))))))
(!call (!index p6class "add_method") (p6nil "defined" (!lambda ()
                (!return !false))))
(!call (!index p6class "add_method") (p6nil "str" (!lambda ()
                (!return ""))))
(!call (!index p6class "add_method") (p6nil "bool" (!lambda ()
                (!return !false))))
(!call (!index p6class "add_method") (p6nil "num" (!lambda ()
                (!return 0.0))))
(!call (!index p6class "add_method") (p6nil "int" (!lambda ()
                (!return 0))))
(!call (!index p6class "add_method") (p6nil "gist" (!lambda ()
                (!return "Nil"))))
(!call (!index p6class "add_method") (p6nil "perl" (!lambda ()
                (!return "Nil"))))
)

(!let p6num (!callmeth1 p6class new ("num")))
(!do
(!let floor (!index math "floor"))
(!assign (!index (!index p6num "_VALUES") "mt") (
        "__index": (!index (!index p6num "_VALUES") "proto") ))
(!call (!index debug "setmetatable") 0 (!index (!index p6num "_VALUES") "mt"))
(!assign (!index _P6PKG "num") p6num)
(!call (!index p6class "add_parent") (p6num p6cool))
(!call (!index p6class "add_method") (p6num "new" (!lambda (self a)
                (!let num (!call unpack a))
                (!call checktype "new" 1 num "number")
                (!return num))))
(!call (!index p6class "add_method") (p6num "WHAT" (!lambda (self)
                (!return p6num))))
(!call (!index p6class "add_method") (p6num "Box" (!lambda (self)
                (!return (!callmeth (!index _P6PKG "Num") new (self))))))
(!call (!index p6class "add_method") (p6num "str" (!lambda (self)
                (!cond ((!ne self self)         (!return "NaN"))
                       ((!eq self (!div 1 0))   (!return "Inf"))
                       ((!eq self (!div -1 0))  (!return "-Inf"))
                       (!true                   (!return (!call tostring self)))))))
(!call (!index p6class "add_method") (p6num "bool" (!lambda (self)
                (!return (!ne self 0.0)))))
(!call (!index p6class "add_method") (p6num "num" (!lambda (self)
                (!return self))))
(!call (!index p6class "add_method") (p6num "int" (!lambda (self)
                (!return (!call floor self)))))
(!call (!index p6class "add_method") (p6num "gist" (!lambda (self)
                (!return (!call tostring self)))))
(!call (!index p6class "add_method") (p6num "perl" (!lambda (self)
                (!return (!callmeth self str)))))
(!call (!index p6class "add_method") (p6num "succ" (!lambda (self)
                (!return (!add self 1.0)))))
(!call (!index p6class "add_method") (p6num "prec" (!lambda (self)
                (!return (!sub self 1.0)))))
)

(!let p6str (!callmeth1 p6class new ("Str")))
(!do
(!assign (!index _P6PKG "Str") p6str)
(!call (!index p6class "add_parent") (p6str p6cool))
(!assign (!index (!index p6str "_VALUES") "mt") (
        "__index": (!index (!index p6str "_VALUES") "proto")
        "__tostring": (!lambda (o)
                        (!return (!index o "_VALUES"))) ))
(!call (!index p6class "add_method") (p6str "new" (!lambda (class a)
                (!define str (!call unpack a))
                (!assign str (!or (!and (!eq (!call1 type str) "table") (!index str "_VALUES")) str))
                (!call checktype "new" 1 str "string")
                (!return (!call setmetatable ("_VALUES": str "_CLASS": class) (!index (!index class "_VALUES") "mt"))))))
(!call (!index p6class "add_method") (p6str "WHAT" (!lambda (self)
                (!return p6str))))
(!call (!index p6class "add_method") (p6str "Str" (!lambda (self)
                (!return self))))
(!call (!index p6class "add_method") (p6str "str" (!lambda (self)
                (!return (!index self "_VALUES")))))
(!call (!index p6class "add_method") (p6str "bool" (!lambda (self)
                (!return (!callmeth (!index self "_VALUES") bool)))))
(!call (!index p6class "add_method") (p6str "num" (!lambda (self)
                (!return (!callmeth (!index self "_VALUES") num)))))
(!call (!index p6class "add_method") (p6str "int" (!lambda (self)
                (!return (!callmeth (!index self "_VALUES") int)))))
(!call (!index p6class "add_method") (p6str "gist" (!lambda (self)
                (!return self))))
(!call (!index p6class "add_method") (p6str "perl" (!lambda (self)
                (!return (!callmeth (!index self "_VALUES") perl)))))
(!call (!index p6class "add_method") (p6str "print" (!lambda (self)
                (!call (!index (!index _P6PKG "MAIN") "print") (self)))))
(!call (!index p6class "add_method") (p6str "say" (!lambda (self)
                (!call (!index (!index _P6PKG "MAIN") "say") (self)))))
(!call (!index p6class "add_method") (p6str "elems" (!lambda (self)
                (!return (!callmeth (!index self "_VALUES") elems)))))
)

(!let p6bool (!callmeth1 p6class new ("Bool")))
(!do
(!assign (!index _P6PKG "Bool") p6bool)
(!call (!index p6class "add_parent") (p6bool p6cool))
(!assign (!index (!index p6bool "_VALUES") "mt") (
        "__index": (!index (!index p6bool "_VALUES") "proto")
        "__tostring": (!lambda (o) (!return (!call tostring (!index o "_VALUES")))) ))
(!call (!index p6class "add_method") (p6bool "new" (!lambda (class a)
                (!define bool (!call unpack a))
                (!assign bool (!or (!and (!eq (!call1 type bool) "table") (!index str "_VALUES")) bool))
                (!call checktype "new" 1 bool "boolean")
                (!return (!call setmetatable ("_VALUES": bool "_CLASS": class) (!index (!index class "_VALUES") "mt"))))))
(!call (!index p6class "add_method") (p6bool "WHAT" (!lambda (self)
                (!return p6bool))))
(!call (!index p6class "add_method") (p6bool "Bool" (!lambda (self)
                (!return self))))
(!call (!index p6class "add_method") (p6bool "bool" (!lambda (self)
                (!return (!index self "_VALUES")))))
(!call (!index p6class "add_method") (p6bool "str" (!lambda (self)
                (!return (!callmeth (!index self "_VALUES") str)))))
(!call (!index p6class "add_method") (p6bool "num" (!lambda (self)
                (!return (!callmeth (!index self "_VALUES") num)))))
(!call (!index p6class "add_method") (p6bool "int" (!lambda (self)
                (!return (!callmeth (!index self "_VALUES") int)))))
(!call (!index p6class "add_method") (p6bool "gist" (!lambda (self)
                (!return (!callmeth (!index self "_VALUES") gist)))))
(!call (!index p6class "add_method") (p6bool "perl" (!lambda (self)
                (!return (!callmeth (!index self "_VALUES") perl)))))
)

(!let p6nil (!callmeth1 p6class new ("Nil")))
(!do
(!assign (!index _P6PKG "Nil") p6nil)
(!call (!index p6class "add_parent") (p6nil p6any))
(!assign (!index (!index p6nil "_VALUES") "mt") (
        "__index": (!index (!index p6nil "_VALUES") "proto")
        "__tostring": (!lambda (o) (!return (!call tostring !nil))) ))
(!call (!index p6class "add_method") (p6nil "new" (!lambda (class)
                (!return (!call setmetatable ("_CLASS": class) (!index (!index class "_VALUES") "mt"))))))
(!call (!index p6class "add_method") (p6nil "WHAT" (!lambda ()
                (!return p6nil))))
(!call (!index p6class "add_method") (p6nil "defined" (!lambda ()
                (!return !false))))
(!call (!index p6class "add_method") (p6nil "str" (!lambda ()
                (!return ""))))
(!call (!index p6class "add_method") (p6nil "bool" (!lambda ()
                (!return !false))))
(!call (!index p6class "add_method") (p6nil "num" (!lambda ()
                (!return 0.0))))
(!call (!index p6class "add_method") (p6nil "int" (!lambda ()
                (!return 0))))
(!call (!index p6class "add_method") (p6nil "gist" (!lambda ()
                (!return "Nil"))))
(!call (!index p6class "add_method") (p6nil "perl" (!lambda ()
                (!return "Nil"))))
)

(!let p6num (!callmeth1 p6class new ("Num")))
(!do
(!assign (!index _P6PKG "Num") p6num)
(!call (!index p6class "add_parent") (p6num p6cool))
(!assign (!index (!index p6num "_VALUES") "mt") (
        "__index": (!index (!index p6num "_VALUES") "proto")
        "__tostring": (!lambda (o)
                        (!return (!call tostring (!index o "_VALUES")))) ))
(!call (!index p6class "add_method") (p6num "new" (!lambda (class a)
                (!define num (!call unpack a))
                (!assign num (!or (!and (!eq (!call1 type num) "table") (!index num "_VALUES")) num))
                (!call checktype "new" 1 num "number")
                (!return (!call setmetatable ("_VALUES": num "_CLASS": class) (!index (!index class "_VALUES") "mt"))))))
(!call (!index p6class "add_method") (p6num "WHAT" (!lambda (self)
                (!return p6num))))
(!call (!index p6class "add_method") (p6num "Num" (!lambda (self)
                (!return self))))
(!call (!index p6class "add_method") (p6num "num" (!lambda (self)
                (!return (!index self "_VALUES")))))
(!call (!index p6class "add_method") (p6num "int" (!lambda (self)
                (!return (!callmeth (!index self "_VALUES") int)))))
(!call (!index p6class "add_method") (p6num "str" (!lambda (self)
                (!return (!callmeth (!index self "_VALUES") str)))))
(!call (!index p6class "add_method") (p6num "bool" (!lambda (self)
                (!return (!callmeth (!index self "_VALUES") bool)))))
(!call (!index p6class "add_method") (p6num "gist" (!lambda (self)
                (!return (!callmeth (!index self "_VALUES") gist)))))
(!call (!index p6class "add_method") (p6num "perl" (!lambda (self)
                (!return (!callmeth (!index self "_VALUES") perl)))))
(!call (!index p6class "add_method") (p6num "succ" (!lambda (self)
                (!assign (!index self "_VALUES") (!add (!index self "_VALUES") 1.0))
                (!return self))))
(!call (!index p6class "add_method") (p6num "prec" (!lambda (self)
                (!assign (!index self "_VALUES") (!sub (!index self "_VALUES") 1.0))
                (!return self))))
)

(!let p6array (!callmeth1 p6class new ("Array")))
(!do
(!assign (!index _P6PKG "Array") p6array)
(!call (!index p6class "add_parent") (p6array p6cool))
(!assign (!index (!index p6array "_VALUES") "mt") (
        "__index": (!lambda (t k)
                        (!assign k (!or (!and (!eq (!call1 type k) "table") (!index k "_VALUES")) k))
                        (!if (!eq (!call1 type k) "number")
                             (!do (!if (!lt k 0)
                                       (!assign k (!sub (!index (!index t "_VALUES") "n") k)))
                                  (!return (!call rawget (!index t "_VALUES") k)))
                             (!return (!index (!index (!index (!index t "_CLASS") "_VALUES") "proto") k))))
        "__newindex": (!lambda (t k v)
                        (!assign k (!or (!and (!eq (!call1 type k) "table") (!index k "_VALUES")) k))
                        (!if (!gt k (!index (!index t "_VALUES") "n"))
                             (!assign (!index (!index t "_VALUES") "n") k))
                        (!call rawset (!index t "_VALUES") k v))
        "__tostring": (!lambda (t)
                        (!return (!callmeth t str)))))
(!call (!index p6class "add_method") (p6array "new" (!lambda (class a)
                (!define array (!or (!call unpack a) ()))
                (!assign array (!or (!index array "_VALUES") array))
                (!call checktype "new" 1 array "table")
                (!call assert (!index array "n"))
                (!return (!call setmetatable ("_VALUES": array "_CLASS": class) (!index (!index class "_VALUES") "mt"))))))
(!call (!index p6class "add_method") (p6array "WHAT" (!lambda (self)
                (!return p6array))))
(!call (!index p6class "add_method") (p6array "join" (!lambda (self a)
                (!define sep (!call unpack a))
                (!assign sep (!or (!or (!and (!eq (!call1 type sep) table) (!index table "_VALUES")) sep) " "))
                (!call checktype "join" 1 sep "string")
                (!let t ())
                (!loop i 0 (!sub (!index (!index self "_VALUES") "n") 1) 1
                        (!let e (!index self i))
                        (!assign (!index t (!add (!len t) 1)) (!or (!and e (!callmeth1 e str)) "")))
                (!return (!call tconcat t sep)))))
(!call (!index p6class "add_method") (p6array "str" (!lambda (self)
                (!return (!callmeth self join)))))
(!call (!index p6class "add_method") (p6array "bool" (!lambda (self)
                (!return (!ne (!index (!index self "_VALUES") "n") 0)))))
(!call (!index p6class "add_method") (p6array "num" (!lambda (self)
                (!return (!index (!index self "_VALUES") "n")))))
(!call (!index p6class "add_method") (p6array "int" (!lambda (self)
                (!return (!index (!index self "_VALUES") "n")))))
(!call (!index p6class "add_method") (p6array "gist" (!lambda (self)
                (!let t ())
                (!loop i 0 (!sub (!index (!index self "_VALUES") "n") 1) 1
                        (!let e (!index self i))
                        (!assign (!index t (!add (!len t) 1)) (!or (!and e (!callmeth1 e gist)) "Nil")))
                (!return (!call tconcat t " ")))))
(!call (!index p6class "add_method") (p6array "perl" (!lambda (self)
                (!let t ())
                (!loop i 0 (!sub (!index (!index self "_VALUES") "n") 1) 1
                        (!let e (!index self i))
                        (!assign (!index t (!add (!len t) 1)) (!or (!and e (!callmeth1 e perl)) "Nil")))
                (!return (!concat "Array.new(" (!concat (!call1 tconcat t ", ") ")"))))))
(!call (!index p6class "add_method") (p6array "elems" (!lambda (self)
                (!return (!index (!index self "_VALUES") "n")))))
(!call (!index p6class "add_method") (p6array "push" (!lambda (self a)
                (!let v (!call unpack a))
                (!let n (!index (!index self "_VALUES") "n"))
                (!assign (!index self n) v)
                (!assign (!index (!index self "_VALUES") "n") (!add n 1))
                (!return self))))
(!call (!index p6class "add_method") (p6array "pop" (!lambda (self)
                (!let n (!sub (!index (!index self "_VALUES") "n") 1))
                (!let v (!index self n))
                (!assign (!index (!index self "_VALUES") "n") n)
                (!return v))))
(!call (!index p6class "add_method") (p6array "unshift" (!lambda (self a)
                (!let v (!call unpack a))
                (!let n (!index (!index self "_VALUES") "n"))
                (!loop i n 1 -1
                        (!assign (!index self i) (!index self (!sub i 1))))
                (!assign (!index self 0) v)
                (!assign (!index (!index self "_VALUES") "n") (!add n 1))
                (!return self))))
(!call (!index p6class "add_method") (p6array "shift" (!lambda (self)
                (!let v (!index self 0))
                (!let n (!sub (!index (!index self "_VALUES") "n") 1))
                (!loop i 1 n 1
                        (!assign (!index self (!sub i 1)) (!index self i)))
                (!assign (!index (!index self "_VALUES") "n") n)
                (!return v))))
(!call (!index p6class "add_method") (p6array "delete" (!lambda (self a)
                (!loop i 1 (!len a) 1
                        (!assign (!index self (!index a i)) !nil))
                (!loop i (!sub (!index (!index self "_VALUES") "n") 1) 0 -1
                        (!if (!index self i)
                             (!do (!assign (!index (!index self "_VALUES") "n") i)
                                  (!break))))
                (!return self))))
(!call (!index p6class "add_method") (p6array "exists" (!lambda (self a)
                (!loop i 1 (!len a) 1
                        (!if (!eq (!index self (!index a i)) !nil)
                             (!return !false)))
                (!return !true))))
(!call (!index p6class "add_method") (p6array "hash" (!lambda (self)
                (!let t ())
                (!loop i 0 (!sub (!index (!index self "_VALUES") "n") 1) 2
                        (!assign (!index t (!index self i)) (!index self (!add i 1))))
                (!return (!callmeth (!index _P6PKG "Hash") new (t))))))
(!call (!index p6class "add_method") (p6array "_iter1" (!lambda (self)
                (!define i 0)
                (!return (!lambda ()
                                (!if (!ge i (!index (!index self "_VALUES") "n"))
                                     (!return))
                                (!let v1 (!index (!index self "_VALUES") i))
                                (!assign i (!add i 1))
                                (!return i v1))))))
(!call (!index p6class "add_method") (p6array "_iter2" (!lambda (self)
                (!define i 0)
                (!return (!lambda ()
                                (!if (!ge i (!index (!index self "_VALUES") "n"))
                                     (!do (!return)))
                                (!let v1 (!index (!index self "_VALUES") i))
                                (!assign i (!add i 1))
                                (!let v2 (!index (!index self "_VALUES") i))
                                (!assign i (!add i 1))
                                (!return i v1 v2))))))
(!call (!index p6class "add_method") (p6array "_itern" (!lambda (self a)
                (!let n (!call unpack a))
                (!call assert (!gt n 0))
                (!define i 0)
                (!return (!lambda ()
                                (!if (!ge i (!index (!index self "_VALUES") "n"))
                                     (!return))
                                (!let t ())
                                (!loop _ 1 n 1
                                        (!assign (!index t (!len t)) (!index (!index self "_VALUES") i))
                                        (!assign i (!add i 1)))
                                (!return i (!call unpack t)))))))
)

(!let p6hash (!callmeth1 p6class new ("Hash")))
(!do
(!assign (!index _P6PKG "Hash") p6hash)
(!call (!index p6class "add_parent") (p6hash p6any))
(!let keystr (!lambda (k)
                (!return (!or (!and (!and (!eq (!call1 type k) "table") (!index k "_VALUES")) (!callmeth1 k str)) (!call1 tostring k)))))
(!assign (!index (!index p6hash "_VALUES") "mt") (
        "__index": (!lambda (t k)
                        (!return (!or (!call1 rawget (!index t "_VALUES") (!call1 keystr k)) (!index (!index (!index (!index t "_CLASS") "_VALUES") "proto") k))))
        "__newindex": (!lambda (t k v)
                        (!call rawset (!index t "_VALUES") (!call1 keystr k) v))
        "__tostring": (!lambda (t)
                        (!return (!callmeth t str))) ))
(!call (!index p6class "add_method") (p6hash "new" (!lambda (class a)
                (!define t (!or (!call unpack a) ()))
                (!assign t (!or (!index t "_VALUES") t))
                (!let hash ())
                (!for (k v) ((!call pairs t))
                        (!assign (!index hash (!call1 keystr k)) v))
                (!return (!call setmetatable ("_VALUES": hash "_CLASS": class) (!index (!index class "_VALUES") "mt"))))))
(!call (!index p6class "add_method") (p6hash "WHAT" (!lambda (self)
                (!return p6hash))))
(!call (!index p6class "add_method") (p6hash "str" (!lambda (self)
                (!let t ())
                (!for (k v) ((!call pairs (!index self "_VALUES")))
                        (!assign (!index t (!add (!len t) 1)) k)
                        (!assign (!index t (!add (!len t) 1)) "\t")
                        (!assign (!index t (!add (!len t) 1)) (!callmeth1 v str))
                        (!assign (!index t (!add (!len t) 1)) "\n"))
                (!assign (!index t (!len t)) !nil)
                (!return (!call tconcat t)))))
(!call (!index p6class "add_method") (p6hash "bool" (!lambda (self)
                (!return (!ne (!call1 next self) !nil)))))
(!call (!index p6class "add_method") (p6hash "num" (!lambda (self)
                (!return (!callmeth self elems)))))
(!call (!index p6class "add_method") (p6hash "int" (!lambda (self)
                (!return (!callmeth self elems)))))
(!call (!index p6class "add_method") (p6hash "gist" (!lambda (self)
                (!let t ())
                (!for (k v) ((!call pairs (!index self "_VALUES")))
                        (!assign (!index t (!add (!len t) 1)) k)
                        (!assign (!index t (!add (!len t) 1)) "\t")
                        (!assign (!index t (!add (!len t) 1)) (!callmeth1 v gist))
                        (!assign (!index t (!add (!len t) 1)) "\n"))
                (!assign (!index t (!len t)) !nil)
                (!return (!call tconcat t)))))
(!call (!index p6class "add_method") (p6hash "perl" (!lambda (self)
                (!let t ())
                (!for (k v) ((!call pairs (!index self "_VALUES")))
                        (!assign (!index t (!add (!len t) 1)) (!mconcat k " => " (!callmeth1 v perl))))
                (!return (!mconcat "(" (!call1 tconcat t ", ") ").hash")))))
(!call (!index p6class "add_method") (p6hash "elems" (!lambda (self)
                (!define n 0)
                (!for (_) ((!call pairs (!index self "_VALUES")))
                        (!assign n (!add n 1)))
                (!return n))))
(!call (!index p6class "add_method") (p6hash "keys" (!lambda (self)
                (!let t ())
                (!define n 0)
                (!for (k) ((!call pairs (!index self "_VALUES")))
                        (!assign (!index t n) k)
                        (!assign n (!add n 1)))
                (!assign (!index t "n") n)
                (!return (!callmeth (!index _P6PKG "Array") new (t))))))
(!call (!index p6class "add_method") (p6hash "values" (!lambda (self)
                (!let t ())
                (!define n 0)
                (!for (k v) ((!call pairs (!index self "_VALUES")))
                        (!assign (!index t n) v)
                        (!assign n (!add n 1)))
                (!assign (!index t "n") n)
                (!return (!callmeth (!index _P6PKG "Array") new (t))))))
(!call (!index p6class "add_method") (p6hash "kv" (!lambda (self)
                (!let t ())
                (!define n 0)
                (!for (k v) ((!call pairs (!index self "_VALUES")))
                        (!assign (!index t n) k)
                        (!assign n (!add n 1))
                        (!assign (!index t n) v)
                        (!assign n (!add n 1)))
                (!assign (!index t "n") n)
                (!return (!callmeth (!index _P6PKG "Array") new (t))))))
(!call (!index p6class "add_method") (p6hash "invert" (!lambda (self)
                (!let t ())
                (!for (k v) ((!call pairs (!index self "_VALUES")))
                        (!assign (!index t v) k))
                (!return (!callmeth (!index _P6PKG "Hash") new (t))))))
(!call (!index p6class "add_method") (p6hash "push" (!lambda (self a)
                (!loop i 1 (!len a) 2
                        (!call rawset (!index self "_VALUES") (!call1 keystr (!index a i)) (!index a (!add i 1))))
                (!return self))))
)

(!let main (!callmeth1 p6module new ("MAIN")))
(!do
(!let how (!callmeth1 main HOW))
(!assign (!index _P6PKG "MAIN") main)
(!call setmetatable _G ("__index": main))
(!let stdout (!index io "stdout"))
(!let stderr (!index io "stderr"))
(!assign (!index main "&print") (!lambda (a)
                (!loop i 1 (!len a) 1
                        (!callmeth stdout write (!callmeth1 (!index a i) str)))))
(!assign (!index main "&say") (!lambda (a)
                (!loop i 1 (!len a) 1
                        (!callmeth stdout write (!callmeth1 (!index a i) str)))
                (!callmeth stdout write "\n")))
(!assign (!index main "&note") (!lambda (a)
                (!loop i 1 (!len a) 1
                        (!callmeth stderr write (!callmeth1 (!index a i) str)))
                (!callmeth stderr write "\n")))
(!assign (!index main "&plan") (!lambda (a)
                (!let nb (!call unpack a))
                (!call (!index main "&say") ("1.." nb))))
(!define curr_test 0)
(!assign (!index main "&ok") (!lambda (a)
                (!define (test desc) ((!call unpack a)))
                (!assign test (!callmeth1 test bool))
                (!if (!not test)
                     (!call (!index main "&print") ("not ")))
                (!call (!index main "&print") ("ok "))
                (!assign curr_test (!add curr_test 1))
                (!call (!index main "&print") (curr_test))
                (!if desc
                     (!call (!index main "&print") (" # " desc)))
                (!call (!index main "&print") ("\n"))
                (!return 1)))
)

)

(!let unpack (!index tvm "unpack"))
(!let _PKG (!index _P6PKG "MAIN"))
]]

local termination = [[

(!line "@termination(nqp/compiler.lua)" 1)

(!let tconcat (!index table "concat"))
(!assign uml2dot (!lambda (opt)
                (!assign opt (!or opt ()))
                (!let with_attr (!not (!index opt "no_attr")))
                (!let with_meth (!not (!index opt "no_meth")))
                (!let note (!index opt "note"))
                (!let out ("digraph {\n\n    node [shape=record];\n\n"))
                (!if note
                    (!do (!assign (!index out (!add (!len out) 1)) "    \"__note__\"\n")
                    (!assign (!index out (!add (!len out) 1)) (!mconcat "        [label=\"" note "\" shape=note];\n\n"))))
                (!for (classname class) ((!call pairs _P6PKG))
                        (!if (!and (!eq (!call1 type class) "table") (!eq (!index class "_CLASS") (!index _P6PKG "NQP::Metamodel::ClassHOW")))
                             (!do (!assign (!index out (!add (!len out) 1)) (!mconcat "    \"" classname "\"\n"))
                                  (!assign (!index out (!add (!len out) 1)) "        [label=\"{")
                                  (!assign (!index out (!add (!len out) 1)) "\\N")
                                  (!if with_attr
                                       (!do (!define first !true)
                                            (!for (name) ((!call pairs (!index (!index class "_VALUES") "attributes")))
                                                (!if first
                                                     (!do (!assign (!index out (!add (!len out) 1)) "|")
                                                          (!assign first !false)))
                                                (!assign (!index out (!add (!len out) 1)) (!concat name "\\l")))))
                                  (!if with_meth
                                       (!do (!define first !true)
                                            (!for (name) ((!call pairs (!index (!index class "_VALUES") "methods")))
                                                (!if first
                                                     (!do (!assign (!index out (!add (!len out) 1)) "|")
                                                          (!assign first !false)))
                                                (!assign (!index out (!add (!len out) 1)) (!concat name "()\\l")))))
                                  (!assign (!index out (!add (!len out) 1)) "}\"];\n")
                                  (!let parents (!index (!index class "_VALUES") "parents"))
                                  (!loop i 0 (!sub (!index parents "n") 1) 1
                                        (!let parent (!index parents i))
                                        (!assign (!index out (!add (!len out) 1)) (!mconcat "    \"" classname "\" -> \"" (!index (!index parent "_VALUES") "name") "\" // extends\n"))
                                        (!assign (!index out (!add (!len out) 1)) "        [arrowhead = onormal, arrowtail = none, arrowsize = 2.0];\n"))
                                  (!let roles (!index (!index class "_VALUES") "roles"))
                                  (!loop i 0 (!sub (!index roles "n") 1) 1
                                        (!let role (!index roles i))
                                        (!assign (!index out (!add (!len out) 1)) (!mconcat "    \"" classname "\" -> \"" (!index (!index role "_VALUES") "name") "\" // with\n"))
                                        (!assign (!index out (!add (!len out) 1)) "        [arrowhead = odot, arrowtail = none];\n"))
                                  (!assign (!index out (!add (!len out) 1)) "\n"))))
                (!for (rolename role) ((!call pairs _P6PKG))
                        (!if (!and (!eq (!call1 type role) "table") (!eq (!index role "_CLASS") (!index _P6PKG "NQP::Metamodel::RoleHOW")))
                             (!do (!assign (!index out (!add (!len out) 1)) (!mconcat "    \"" rolename "\"\n"))
                                  (!assign (!index out (!add (!len out) 1)) "        [label=\"{&laquo;role&raquo;\\n\\N")
                                  (!if with_attr
                                      (!do (!define first !true)
                                           (!for (name) ((!call pairs (!index (!index role "_VALUES") "attributes")))
                                                (!if first
                                                     (!do (!assign (!index out (!add (!len out) 1)) "|")
                                                          (!assign first !false)))
                                                (!assign (!index out (!add (!len out) 1)) (!concat name "\\l")))))
                                  (!if with_meth
                                       (!do (!define first !true)
                                            (!for (name) ((!call pairs (!index (!index role "_VALUES") "methods")))
                                                (!if first
                                                     (!do (!assign (!index out (!add (!len out) 1)) "|")
                                                          (!assign first !false)))
                                                (!assign (!index out (!add (!len out) 1)) (!concat name "()\\l")))))
                                  (!assign (!index out (!add (!len out) 1)) "}\"];\n")
                                  (!assign (!index out (!add (!len out) 1)) "\n"))))
                (!for (modname mod) ((!call pairs _P6PKG))
                        (!if (!and (!eq (!call1 type mod) "table") (!eq (!index mod "_CLASS") (!index _P6PKG "NQP::Metamodel::ModuleHOW")))
                             (!do (!assign (!index out (!add (!len out) 1)) (!mconcat "    \"" modname "\"\n"))
                                  (!assign (!index out (!add (!len out) 1)) "        [label=\"{\\N")
                                  (!if with_attr
                                       (!do (!define first !true)
                                            (!for (name v) ((!call pairs (!index mod "_VALUES")))
                                                (!if (!ne (!call1 type v) "function")
                                                     (!do (!if first
                                                               (!do (!assign (!index out (!add (!len out) 1)) "|")
                                                                    (!assign first !false)))
                                                          (!assign (!index out (!add (!len out) 1)) (!concat name "\\l")))))))
                                  (!if with_meth
                                       (!do (!define first !true)
                                            (!for (name v) ((!call pairs (!index mod "_VALUES")))
                                                (!if (!eq (!call1 type v) "function")
                                                     (!do (!if first
                                                               (!do (!assign (!index out (!add (!len out) 1)) "|")
                                                                    (!assign first !false)))
                                                          (!assign (!index out (!add (!len out) 1)) (!concat name "()\\l")))))))
                                  (!assign (!index out (!add (!len out) 1)) "}\"];\n")
                                  (!assign (!index out (!add (!len out) 1)) "\n"))))
                (!assign (!index out (!add (!len out) 1)) "}")
                (!return (!call tconcat out))))

;(!let f (!call assert (!call (!index io "open") "model.dot" "w")))
(!let f (!call assert (!call (!index io "popen") "dot -T png -o model.png" "w")))
(!callmeth f write (!call uml2dot ("note": (!concat "model - by uml2dot\\l" (!call (!index os "date") "%d/%m/%y %H:%M")))))
(!callmeth f close)
]]

how.add_method(parser, 'parse', function (self, s, fname)
                lineno = 1
                self:src(s)
                self:pos((bom * Cp()):match(self:src(), 1) or 1)
                self:init(Stmts:new{})
                local block = Block:new{ blocktype='immediate', self:init(), self:statlist() }
                local unit = CompUnit:new{ filename=fname, prelude=prelude, termination=nil; block }
                if not P(-1):match(self:src(), self:pos()) then
                    syntaxerror("<eof> expected at " .. self:pos())
                end
                return unit
                end)

end -- Parser


local _G = _G
local arg = arg
local open = io.open
local print = print

local function compile (s, fname)
    local parser = _G['TVM::Parser']:new{}
    return parser:parse(s, fname)
end


--assert(io.popen("dot -T png -o model.png", 'w')):write(uml2dot({ note = "model compiler\\lby uml2dot\\l" .. os.date('%d/%m/%y %H:%M') })):close()

local fname = arg and arg[1]
if fname then
    local f, msg = open(fname, 'r')
    if not f then
        error(msg)
    end
    local src = f:read'*a'
    f:close()
    local ast = compile(src, fname)
    print(ast:as_op())
else
    return compile
end

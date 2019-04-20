-- Response

local crc32_short = ngx.crc32_short
local ngx_exit = ngx.exit
local tonumber = tonumber
local tostring = tostring
local setmetatable = setmetatable
local type = type

local _M = { _VERSION = '0.0.1' }
local mt = { __index = _M }

function _M.new(fact)
    return setmetatable({
        fact = fact,
        ctx = {}
    }, mt)
end

function _M.match(self, name)
    self.rulename = name
end

function _M.proxy(self, action)
    if type(action) == "table" then
        self.upstream = tostring(self.fact:get(action.key))
    else
        self.upstream = tostring(action)
    end
end

function _M.crc32(self, action)
    local fact = self.fact
    local key = fact:get(action.hash)
    local hash = crc32_short(tostring(key))

    local selector = action.selector

    self.upstream = tostring(selector[hash % #selector + 1])
end

function _M.refuse(self, action)
    return ngx_exit(tonumber(action))
end

return _M
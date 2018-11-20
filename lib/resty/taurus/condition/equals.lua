-- Equals

local type = type
local tonumber = tonumber
local tostring = tostring
local setmetatable = setmetatable

local _M = { _VERSION = '0.0.1' }
local mt = { __index = _M }

function _M.new(key, value)
    return setmetatable({
        key = key,
        value = value
    }, mt)
end

function _M.execute(self, fact)
    local key = self.key
    local value = self.value
    local search = fact:get(key)
    if not search then
        return false
    end

    if type(value) == "number" then
        return tonumber(search) == value
    else
        return tostring(search) == tostring(value)
    end
end

return _M
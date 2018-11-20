-- InArray

local type = type
local ipairs = ipairs
local tostring = tostring
local setmetatable = setmetatable

local _M = { _VERSION = '0.0.1' }
local mt = { __index = _M }

function _M.new(key, values)
    return setmetatable({
        key = key,
        values = values,
    }, mt)
end

function _M.execute(self, fact)
    local key = self.key
    local values = self.values
    local search = fact:get(key)
    if not search then
        return false
    end

    if type(values) ~= "table" then
        values = fact:get(tostring(values))
    end

    for _, value in ipairs(values) do
        if tostring(search) == tostring(value) then
            return true
        end
    end

    return false
end

return _M
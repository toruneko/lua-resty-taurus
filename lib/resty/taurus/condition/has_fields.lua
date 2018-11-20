-- HasFields

local ipairs = ipairs
local setmetatable = setmetatable

local _M = { _VERSION = '0.0.1' }
local mt = { __index = _M }

function _M.new(keys)
    return setmetatable({
        keys = keys
    }, mt)
end

function _M.execute(self, fact)
    local keys = self.keys
    for _, key in ipairs(keys) do
        if not fact:get(key) then
            return false
        end
    end

    return true
end

return _M
-- Expr

local setmetatable = setmetatable

local _M = { _VERSION = '0.0.1' }
local mt = { __index = _M }

function _M.new(condition)
    return setmetatable({
        conditions = { condition },
    }, mt)
end

function _M.execute(self, fact)
    local conditions = self.conditions
    if #conditions == 0 then
        return false
    end

    local condition = conditions[1]
    return condition:execute(fact)
end

return _M
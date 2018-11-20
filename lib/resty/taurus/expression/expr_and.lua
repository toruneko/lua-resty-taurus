-- Expr_and

local ipairs = ipairs
local setmetatable = setmetatable

local _M = { _VERSION = '0.0.1' }
local mt = { __index = _M }

function _M.new(conditions)
    return setmetatable({
        conditions = conditions
    }, mt)
end

function _M.execute(self, fact)
    local conditions = self.conditions
    for _, condition in ipairs(conditions) do
        -- AND表达式中，只要有一个条件发生false，即整个表达式false
        if not condition:execute(fact) then
            return false
        end
    end
    return true
end

return _M
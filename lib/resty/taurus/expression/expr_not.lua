-- Expr_not

local expr = require "resty.taurus.expression.expr"

local setmetatable = setmetatable

local _M = { _VERSION = '0.0.1' }
local mt = { __index = _M }

function _M.new(conditions)
    return setmetatable({
        expr = expr.new(conditions[1]),
    }, mt)
end

function _M.execute(self, fact)
    return not self.expr:execute(fact)
end

return _M
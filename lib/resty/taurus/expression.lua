-- Expression

local expr = require "resty.taurus.expression.expr"
local expr_not = require "resty.taurus.expression.expr_not"
local expr_and = require "resty.taurus.expression.expr_and"
local expr_or = require "resty.taurus.expression.expr_or"

local _M = { _VERSION = '0.0.1' }

function _M._or(conditions)
    return expr_or.new(conditions)
end

function _M._and(conditions)
    return expr_and.new(conditions)
end

function _M._not(conditions)
    return expr_not.new(conditions)
end

function _M._expr(condition)
    return expr.new(condition)
end

return _M
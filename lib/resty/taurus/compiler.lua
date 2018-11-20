-- Compiler

local condition = require "resty.taurus.condition"
local expression = require "resty.taurus.expression"
local action = require "resty.taurus.action"

local type = type
local error = error
local pairs = pairs
local ipairs = ipairs
local str_lower = string.lower

local _M = { _VERSION = '0.0.1' }

function _M.internal_when_compile(self, name, exprs)
    if not exprs then
        error("syntax error: no expression block for " .. name .. " condition")
    end
    if type(exprs) ~= "table" then
        error("syntax error: bad expression block for " .. name .. " condition")
    end

    -- 特殊处理NOT表达式
    if str_lower(name) == "not" then
        for c_name, c_expr in pairs(exprs) do
            return { self:when_compile(c_name, c_expr) }
        end
        return {}
    end

    local conditions = {}
    for _, expr in ipairs(exprs) do
        for c_name, c_expr in pairs(expr) do
            conditions[#conditions + 1] = self:when_compile(c_name, c_expr)
            break
        end
    end

    return conditions
end

function _M.when_compile(self, name, expr)
    -- 处理 逻辑表达式
    local expname = str_lower("_" .. name)
    if expression[expname] then
        local conditions = self:internal_when_compile(name, expr)
        return expression[expname](conditions)
    end

    -- 处理 运算表达式
    local fn = condition[str_lower(name)]
    if not fn then
        error("syntax error: unknown condition.")
    end

    return expression._expr(fn(expr))
end

function _M.do_compile(self, name, actor)
    return action.new(name, actor)
end

function _M.default_when_block(self)
    return expression._expr(condition.default())
end

return _M

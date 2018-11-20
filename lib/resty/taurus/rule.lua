-- Rule

local compiler = require "resty.taurus.compiler"

local error = error
local pairs = pairs
local setmetatable = setmetatable

local _M = { _VERSION = '0.0.1' }
local mt = { __index = _M }

function _M.compile(rule_name, rule_when_desc, rule_do_desc)
    if not rule_when_desc then
        error("syntax error: no when block")
    end
    if not rule_do_desc then
        error("syntax error: no do block")
    end

    local rule_when_expr = compiler:default_when_block()
    for expr_name, expr_desc in pairs(rule_when_desc) do
        rule_when_expr = compiler:when_compile(expr_name, expr_desc)
        break
    end

    local rule_do_expr
    for expr_name, expr_desc in pairs(rule_do_desc) do
        rule_do_expr = compiler:do_compile(expr_name, expr_desc)
        break
    end
    if not rule_do_expr then
        error("syntax error: no do block")
    end

    return setmetatable({
        name = rule_name,
        expression = rule_when_expr,
        action = rule_do_expr
    }, mt)
end

function _M.match(self, fact, decision)
    local name = self.name
    local expression = self.expression
    local action = self.action

    if expression:execute(fact) then
        action:execute(name, decision)
        return true
    end

    return false
end

return _M
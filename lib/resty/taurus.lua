-- Rule Engine

local rule = require "resty.taurus.rule"

local type = type
local error = error
local ipairs = ipairs
local setmetatable = setmetatable

local _M = { _VERSION = '0.0.2' }
local mt = { __index = _M }

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function(narr, nrec) return {} end
end

function _M.compile(r)
    if not r.rules or type(r.rules) ~= "table" then
        error("bad rule description")
    end

    local rules = new_tab(#r.rules, 0)
    for _, rs in ipairs(r.rules) do
        local rule_name = rs["name"]
        local rule_when_desc = rs["when"]
        local rule_do_desc = rs["do"]

        rules[#rules + 1] = rule.compile(rule_name, rule_when_desc, rule_do_desc)
    end

    return setmetatable({ rules = rules }, mt)
end

function _M.match(self, fact, decision)
    local rules = self.rules

    for _, r in ipairs(rules) do
        if r:match(fact, decision) then
            return true
        end
    end

    return false
end

return _M
-- Action

local setmetatable = setmetatable

local _M = { _VERSION = '0.0.1' }
local mt = { __index = _M }

function _M.new(name, action)
    return setmetatable({
        name = name,
        action = action
    }, mt)
end

function _M.execute(self, rule_name, decision)
    local name = self.name
    local action = self.action
    decision:match(rule_name)

    local fn = decision[name]
    if fn then
        fn(decision, action)
        return
    end
end

return _M
-- Contains

local tostring = tostring
local setmetatable = setmetatable

local re_find = ngx.re.find

local _M = { _VERSION = '0.0.1' }
local mt = { __index = _M }

function _M.new(key, value)
    return setmetatable({
        key = key,
        value = value
    }, mt)
end

function _M.execute(self, fact)
    local key = self.key
    local value = self.value
    local search = fact:get(key)
    if not search then
        return false
    end

    local from, to, err = re_find(tostring(search), tostring(value), "jo")
    if from then
        return true
    else
        return false
    end
end

return _M
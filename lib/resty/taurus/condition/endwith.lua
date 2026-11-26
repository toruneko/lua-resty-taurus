-- Endwith

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

    -- 必须以模式匹配到字符串末尾才算 ends with，
    -- 直接取首个匹配的 to 位置会在后缀在字符串中更早出现时误判
    local from, to, err = re_find(tostring(search), "(?:" .. tostring(value) .. ")$", "jo")
    if from then
        return true
    else
        return false
    end
end

return _M
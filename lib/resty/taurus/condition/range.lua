-- Range

local tonumber = tonumber
local setmetatable = setmetatable

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
    search = tonumber(search)

    if value["gt"] and not (search > tonumber(value["gt"])) then
        return false
    end
    if value["gte"] and not (search >= tonumber(value["gte"])) then
        return false
    end
    if value["lt"] and not (search < tonumber(value["lt"])) then
        return false
    end
    if value["lte"] and not (search <= tonumber(value["lte"])) then
        return false
    end

    return true
end

return _M
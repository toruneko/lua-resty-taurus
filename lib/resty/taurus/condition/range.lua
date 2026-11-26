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
    if not search then
        return false
    end

    local gt = value["gt"]
    if gt ~= nil then
        gt = tonumber(gt)
        if not gt or not (search > gt) then
            return false
        end
    end
    local gte = value["gte"]
    if gte ~= nil then
        gte = tonumber(gte)
        if not gte or not (search >= gte) then
            return false
        end
    end
    local lt = value["lt"]
    if lt ~= nil then
        lt = tonumber(lt)
        if not lt or not (search < lt) then
            return false
        end
    end
    local lte = value["lte"]
    if lte ~= nil then
        lte = tonumber(lte)
        if not lte or not (search <= lte) then
            return false
        end
    end

    return true
end

return _M
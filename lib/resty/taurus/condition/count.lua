-- Count
local limit_count = require "resty.limit.count"

local setmetatable = setmetatable

local _M = { _VERSION = '0.0.1' }
local mt = { __index = _M }

function _M.new(key, opts)
    return setmetatable({
        key = key,
        opts = opts
    }, mt)
end

function _M.execute(self, fact)
    local opts = self.opts
    local search = fact:get(self.key)
    if not search then
        return false
    end

    local limit, _ = limit_count.new(opts.dict_name, opts.total, opts.window)
    if not limit then
        return false
    end
    local delay, err = limit:incoming(search, true)
    if not delay then
        if err == "rejected" then
            return true
        end
        return false
    end

    return false
end

return _M
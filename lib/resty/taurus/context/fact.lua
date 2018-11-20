-- Request

local ngx_re = require "ngx.re"
local ffi = require "ffi"

local ffi_null = ffi.null
local type = type
local tostring = tostring
local setmetatable = setmetatable

local _M = { _VERSION = '0.0.1' }
local mt = { __index = _M }

local function split(str, delimiter)
    if not str or not delimiter then
        return {}
    end
    local res, err = ngx_re.split(str, delimiter, "jo")
    if not res then
        return {}, err
    end
    return res
end

local function get_last_parameter(parameter)
    if parameter and type(parameter) == "table" then
        return parameter[1] and tostring(parameter[#parameter]) or ffi_null
    end

    return parameter and tostring(parameter) or ffi_null
end

function _M.new(header, query, body, ctx)
    return setmetatable({
        header = header,
        query = query,
        body = body,
        ctx = ctx,
        cache = {}
    }, mt)
end

function _M.get_request(self, method, name)
    if method == "header" then
        return get_last_parameter(self.header[name])
    end
    if method == "query" then
        return get_last_parameter(self.query[name])
    end
    if method == "body" then
        return get_last_parameter(self.body[name])
    end

    return ffi_null
end

function _M.get_context(self, method, name)
    local ctx = self.ctx
    if ctx[method] then
        return ctx[method][name] or ffi_null
    end

    return ffi_null
end

function _M.get(self, key)
    local cache = self.cache

    if not cache[key] then

        local keys = split(key, "\\.")
        local namespace = tostring(keys[1])
        local method = tostring(keys[2])
        local name = tostring(keys[3])

        if namespace == "request" then
            cache[key] = self:get_request(method, name)
        end

        if namespace == "context" then
            cache[key] = self:get_context(method, name)
        end

    end

    if cache[key] == ffi_null then
        return nil
    end

    return cache[key]
end

return _M
-- Condition

local equals = require "resty.taurus.condition.equals"
local contains = require "resty.taurus.condition.contains"
local range = require "resty.taurus.condition.range"
local has_fields = require "resty.taurus.condition.has_fields"
local in_array = require "resty.taurus.condition.in_array"

local type = type
local error = error
local pairs = pairs

local _M = { _VERSION = '0.0.1' }

function _M.equals(expr)
    for key, value in pairs(expr) do
        return equals.new(key, value)
    end

    error("syntax error: no action block for equals condition")
end

function _M.contains(expr)
    for key, value in pairs(expr) do
        return contains.new(key, value)
    end

    error("syntax error: no action block for contains condition")
end

function _M.range(expr)
    for key, value in pairs(expr) do
        if type(value) == "table" then
            return range.new(key, value)
        end

        error("syntax error: bad action block for range condition")
    end

    error("syntax error: no action block for range condition")
end

function _M.in_array(expr)
    for key, value in pairs(expr) do
        return in_array.new(key, value)
    end

    error("syntax error: bad action block for in_array condition")
end

function _M.has_fields(expr)
    if type(expr) == "table" then
        return has_fields.new(expr)
    end

    error("syntax error: bad action block for has_fields condition")
end

function _M.default(expr)
    return {
        execute = function(self, fact) return true end
    }
end

return _M
----------------------
-- The lugate module.
-- Lugate is a lua module for building JSON-RPC 2.0 Gateway APIs just inside of your Nginx configuration file.
-- Lugate is meant to be used with [ngx\_http\_lua\_module](https://github.com/openresty/lua-nginx-module) together.
--
-- @classmod lugate.cache.dummy Dummy cache
-- @author Ivan Zinovyev <vanyazin@gmail.com>
-- @license MIT

local Cache = require 'lugate.cache.cache'
local Dummy = setmetatable({}, {__index=Cache})

--- Create new cache instance
-- @params[type=string] name Client name
-- @params ...
-- @return[type=table] Return cache instance
function Dummy:new(...)
  local arg = {...}
  local cache = setmetatable({}, self)
  self.__index = self

  cache.memory = {}
  cache.expire = {}

  return cache
end

--- Set value to cache
function Dummy:set(key, value, ttl)
  ttl = ttl or 3600
  assert(type(key) == "string", "Parameter 'key' is required and should be a string!")
  assert(type(value) == "string", "Parameter 'value' is required and should be a string!")
  assert(type(ttl) == "number", "Parameter 'expire' is required and should be a number!")

  self.memory[key] = value
  self.expire[key] = os.time() + ttl
end

--- Get value from cache
-- @return[type=string]
function Dummy:get(key)
  if self.expire[key] and self.expire[key] > os.time() then
    return self.memory[key]
  end

  return nil
end

return Dummy
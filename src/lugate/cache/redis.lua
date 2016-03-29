----------------------
-- The lugate module.
-- Lugate is a lua module for building JSON-RPC 2.0 Gateway APIs just inside of your Nginx configuration file.
-- Lugate is meant to be used with [ngx\_http\_lua\_module](https://github.com/openresty/lua-nginx-module) together.
--
-- @classmod lugate.cache.redis
-- @author Ivan Zinovyev <vanyazin@gmail.com>
-- @license MIT

local Cache = require 'lugate.cache.cache'

local Redis = setmetatable({}, {__index=Cache})

--- Create new redis instance (wrapper for redis-lua class)
-- @param ...
-- @return[type=table] Return cache instance
function Redis:new(...)
  local arg = {...}
  local redis = setmetatable({}, self)
  self.__index = self

  redis.lredis = require 'redis'
  redis.client = redis.lredis.connect(unpack(arg))

  return redis
end

--- Set value to cache
-- @param[type=string] key
-- @param[type=string] value
-- @param[type=number] ttl
function Redis:set(key, value, ttl)
  ttl = ttl or 3600
  assert(type(key) == "string", "Parameter 'key' is required and should be a string!")
  assert(type(value) == "string", "Parameter 'value' is required and should be a string!")
  assert(type(ttl) == "number", "Parameter 'expire' is required and should be a number!")
  self.client:set(key, value)
  self.client:expire(key, ttl)
end

--- Get value from cache
-- @param[type=string] key
-- @return[type=string]
function Redis:get(key)
  return self.client:get(key)
end

return Redis
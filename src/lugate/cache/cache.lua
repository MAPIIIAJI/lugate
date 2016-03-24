----------------------
-- The lugate module.
-- Lugate is a lua module for building JSON-RPC 2.0 Gateway APIs just inside of your Nginx configuration file.
-- Lugate is meant to be used with [ngx\_http\_lua\_module](https://github.com/openresty/lua-nginx-module) together.
--
-- @classmod lugate.cache
-- @author Ivan Zinovyev <vanyazin@gmail.com>
-- @license MIT

local Cache = {}

--- Create new cache instance
-- @params[type=string] name Client name
-- @params ...
-- @return[type=table] Return cache instance
function Cache:new(name, ...)
  assert(type(config.ngx) == "table", "Parameter 'ngx' is required and should be a table!")

  self.cache = cache

  local cache = setmetatable({}, Cache)
  self.__index = self

  -- Binding for nrk/redis-lua
  if 'redis-lua' == name then
    cache.redis = require "redis"
    cache.client = redis.connect(arg)
  end

  return cache
end

return Cache
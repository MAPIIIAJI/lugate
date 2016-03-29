----------------------
-- The lugate module.
-- Lugate is a lua module for building JSON-RPC 2.0 Gateway APIs just inside of your Nginx configuration file.
-- Lugate is meant to be used with [ngx\_http\_lua\_module](https://github.com/openresty/lua-nginx-module) together.
--
-- @classmod lugate.cache.cache Cache interface
-- @author Ivan Zinovyev <vanyazin@gmail.com>
-- @license MIT

local Cache = {}

--- Create new cache instance
-- @params[type=string] name Client name
-- @params ...
-- @return[type=table] Return cache instance
function Cache:new(...)
end

--- Set value to cache
function Cache:set(key, value, expire)
end

--- Get value from cache
-- @return[type=string]
function Cache:get(key)
end

return Cache
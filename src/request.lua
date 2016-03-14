----------------------
-- The lugate module.
-- Lugate is a lua module for building JSON-RPC 2.0 Gateway APIs just inside of your Nginx configuration file.
-- Lugate is meant to be used with [ngx\_http\_lua\_module](https://github.com/openresty/lua-nginx-module) together.
--
-- @module lugate
-- @author Ivan Zinovyev <vanyazin@gmail.com>
-- @license MIT

local Request = {}

--- Create new request
-- return
function Request:new()
  local request = setmetatable({}, Request)
  self.__index = self

  return request
end

return Request
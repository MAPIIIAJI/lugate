----------------------
-- The lugate module.
-- Lugate is a lua module for building JSON-RPC 2.0 Gateway APIs just inside of your Nginx configuration file.
-- Lugate is meant to be used with [ngx\_http\_lua\_module](https://github.com/openresty/lua-nginx-module) together.
-- @module lugate
-- @author Ivan Zinovyev <vanyazin@gmail.com>
-- @license MIT

-- Json encoder/decoder
local json = require "rapidjson"

--- The lua gateway class
local Lugate = {
  body = nil, -- Request raw body
  routes = {}, -- Routing rules
}

--- Create new Lugate instance
-- @param[type=table] config Table of configuration options: body for raw request body and routes for routing map config
-- @return[type=Lugate] The new instance of Lugate
function Lugate:new(config)
  local lugate = setmetatable({}, Lugate)
  self.__index = self
  lugate:configure(config)

  return lugate
end

--- Configure lugate instance
-- @param[type=table] config Table of configuration options
function Lugate:configure(config)
  self.body = config.body
  self.routes = config.routes or {}
end

--- Parse raw body
-- @return[type=table]
function Lugate:get_data()
  if not self.data then
    self.data = json.decode(self.body)
  end

  return self.data
end

--- Get request collection
-- @return[type=table] The table of requests
function Lugate:get_requests()
  if not self.requests then
    self.requests = {}
    local data = self:get_data()
    if self:is_batch(data) then
      self.requests = data
    elseif self:is_valid(data) then
      self.requests = {data}
    end
  end

  return self.requests
end

--- Check if request is a batch
-- @param[type=table] data Decoded request body
-- @return[type=boolean]
function Lugate:is_batch(data)
  return data and data[1] and ('table' == type(data[1]))
end

--- Check if single request is valid
-- @param[type=table] data Decoded request body
-- @return[type=boolean]
function Lugate:is_valid(data)
  return data and data['jsonrpc'] and data['method'] and data['params'] and data['id'] and true or false
end

return Lugate
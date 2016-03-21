----------------------
-- The lugate module.
-- Lugate is a lua module for building JSON-RPC 2.0 Gateway APIs just inside of your Nginx configuration file.
-- Lugate is meant to be used with [ngx\_http\_lua\_module](https://github.com/openresty/lua-nginx-module) together.
--
-- @classmod lugate
-- @author Ivan Zinovyev <vanyazin@gmail.com>
-- @license MIT

-- Json encoder/decoder
local json = require "rapidjson"

-- Request obeject
local Request = require "lugate.request"

--- The lua gateway class definition
local Lugate = {}

Lugate.HTTP_POST = 8

--- Create new Lugate instance
-- @param[type=table] config Table of configuration options: body for raw request body and routes for routing map config
-- @return[type=Lugate] The new instance of Lugate
function Lugate:new(config)
  local lugate = setmetatable({}, Lugate)
  self.__index = self
  lugate:break_down()
  lugate:configure(config)

  return lugate
end

--- Configure lugate instance
-- @param[type=table] config Table of configuration options
function Lugate:configure(config)
  self.body = config.body
  self.routes = config.routes or {}
end

--- Check if all dependencies are installed or break down on failure
-- @return[type=boolean]
function Lugate:break_down()
  -- Check that mandatory modules are installed
  local modules = {
    'ngx',
    'rapidjson',
  }
  for _, module in ipairs(modules) do
    if not package.loaded[module] then
      error("Module '" .. module .. "' is required!")
    end
  end

  return true
end

--- Parse raw body
-- @return[type=table]
function Lugate:get_data()
  if not self.data then
    self.data = self.body and json.decode(self.body) or {}
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
      for _, rdata in ipairs(data) do
        table.insert(self.requests, Request:new(rdata, self.routes))
      end
    else
      local request = Request:new(data, self.routes)
      if request.is_valid then
        table.insert(self.requests, request)
      end
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

return Lugate
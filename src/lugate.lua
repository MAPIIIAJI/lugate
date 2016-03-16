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
local Request = require "request"

--- The lua gateway class definition
local Lugate = {}

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
      for _, rdata in ipairs(data) do
        table.insert(self.requests, Request:new(rdata))
      end
    else
      local request = Request:new(data)
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

--- Get route for request data
-- @param[type=table] data Decoded requets body
-- @return string
function Lugate:get_route(data)
  if self:is_proxy_call(data) then
    for route, uri in pairs(self.routes) do
      if data.params.route == string.match(data.params.route, route) then
        return uri
      end
    end
  end

  return false
end

--- Normalize data params
function Lugate:normalize_params(data)
  local norm_data = data
  norm_data.params = data.params.params

  return norm_data
end

--- Build a request in format acceptable by nginx
-- @param[type=table] data Decoded requets body
-- @return table
function Lugate:ngx_request(data)
  if not self:is_proxy_call() then
    return false
  end

  local route = self:get_route(data)
  local body = json.encode(self:normalize_params(data))

  return { route, { method = 'POST', body = body } }
end

--- Build all requests in format acceptable by nginx
-- @param[type=table] data Decoded requets body
-- @return table
function Lugate:ngx_requests(data)
  local requests = {}
  for _, req in ipairs(data) do
    if self:is_proxy_call() then
      table.insert(requests, self:ngx_request(req))
    end
  end

  return requests
end

return Lugate
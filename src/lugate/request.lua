----------------------
-- The lugate module.
-- Lugate is a lua module for building JSON-RPC 2.0 Gateway APIs just inside of your Nginx configuration file.
-- Lugate is meant to be used with [ngx\_http\_lua\_module](https://github.com/openresty/lua-nginx-module) together.
--
-- @classmod request
-- @author Ivan Zinovyev <vanyazin@gmail.com>
-- @license MIT

--- Json encoder/decoder
local json = require "rapidjson"

--- Request obeject
local Request = {}

--- Create new request
-- return[type=table] New request instance
function Request:new(data, routes)
  local request = setmetatable({}, Request)
  self.__index = self
  request:configure(data, routes)

  return request
end

--- Configure request instance
-- @param[type=table] data Table of request data
-- @param[type=table] routes Table of routes
function Request:configure(data, routes)
  self.data = data
  self.routes = routes or {}
end

--- Check if request is valid JSON-RPC 2.0
-- @return[type=boolean]
function Request:is_valid()
  if nil == self.valid then
    self.valid = self.data and self.data['jsonrpc'] and self.data['method'] and self.data['params'] and self.data['id'] and true or false
  end

  return self.valid
end

--- Check if request is a valid Lugate proxy call over JSON-RPC 2.0
-- @param[type=table] data Decoded request body
-- @return[type=boolean]
function Request:is_proxy_call()
  if nil == self.proxy_call then
    self.proxy_call = self:is_valid() and self.data.params['route'] and self.data.params['params'] and self.data.params['cache'] and true or false
  end

  return self.proxy_call
end

function Request:get_jsonrpc()
  return self.data.jsonrpc
end

--- Get method name
-- @return[type=string]
function Request:get_method()
  return self.data.method
end

--- Get request params
-- @return[type=table]
function Request:get_params()
  return self:is_proxy_call() and self.data.params.params or self.data.params
end

--- Get request id
-- @return[type=int]
function Request:get_id()
  return self.data.id
end

--- Get request route
-- @return[type=string]
function Request:get_route()
  return self:is_proxy_call() and self.data.params.route or nil
end

--- Get request cache param
-- @return[type=string]
function Request:get_cache()
  return self:is_proxy_call() and self.data.params.cache or false
end

--- Get request data table
-- @return[type=table]
function Request:get_data()
  return {
    jsonrpc = self:get_jsonrpc(),
    id = self:get_id(),
    method = self:get_method(),
    params = self:get_params()
  }
end

--- Get which uri is passing for request data
-- @return[type=string]
function Request:get_uri()
  if self:is_proxy_call() then
    for route, uri in pairs(self.routes) do
      if self:get_route() == string.match(self:get_route(), route) then
        return uri
      end
    end
  end

  return '/'
end

--- Get request body
-- @return[type=string] Json array
function Request:get_body()
  return json.encode(self:get_data())
end

--- Build a request in format acceptable by nginx
-- @param[type=table] data Decoded requets body
-- @return table
function Request:get_ngx_request()
  return { self:get_uri(), { method = 8, body = self:get_body() } }
end

return Request
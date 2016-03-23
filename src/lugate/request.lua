----------------------
-- The lugate module.
-- Lugate is a lua module for building JSON-RPC 2.0 Gateway APIs just inside of your Nginx configuration file.
-- Lugate is meant to be used with [ngx\_http\_lua\_module](https://github.com/openresty/lua-nginx-module) together.
--
-- @classmod lugate.request
-- @author Ivan Zinovyev <vanyazin@gmail.com>
-- @license MIT

--- Json encoder/decoder
local json = require "rapidjson"

--- Request obeject
local Request = {}

--- Create new request
-- param[type=table] data Request data
-- param[type=table] lugate Lugate instance
-- return[type=table] New request instance
function Request:new(data, lugate)
  assert(type(data) == "table", "Parameter 'data' is required and should be a table!")
  assert(type(lugate) == "table", "Parameter 'lugate' is required and should be a table!")

  local request = setmetatable({}, Request)
  self.__index = self
  request.lugate = lugate
  request.data = data

  return request
end

--- Check if request is valid JSON-RPC 2.0
-- @return[type=boolean]
function Request:is_valid()
  if nil == self.valid then
    self.valid = self.data
      and self.data['jsonrpc']
      and self.data['method']
      and true or false
  end

  return self.valid
end

--- Check if request is a valid Lugate proxy call over JSON-RPC 2.0
-- @param[type=table] data Decoded request body
-- @return[type=boolean]
function Request:is_proxy_call()
  if nil == self.proxy_call then
    self.proxy_call = self:is_valid()
      and self.data['params']['route']
      and self.data['params']
      and true or false
  end

  return self.proxy_call
end

--- Get JSON-RPC version
-- @return[type=string]
function Request:get_jsonrpc()
  return self.data.jsonrpc
end

--- Get method name
-- @return[type=string]
function Request:get_method()
  return self.data.method
end

--- Get request params (search for nested params)
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
  return self.lugate:is_proxy_call() and self.data.params.route or nil
end

--- Get request cache time
-- @return[type=string]
function Request:get_cache()
  return self.lugate:is_proxy_call() and self.data.params.cache or false
end

--- Get request cache key
-- @return[type=string]
function Request:get_key()
  return self.lugate:is_proxy_call() and self.data.params.key or false
end

--- Get which uri is passing for request data
-- @return[type=string]
function Request:get_uri()
  if self:is_proxy_call() then
    for route, uri in pairs(self.routes) do
      local uri, matches = string.gsub(self:get_route(), route, uri);
      if matches >= 1 then
        return uri
      end
    end
  end

  return '/'
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
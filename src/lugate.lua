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
local Lugate = {
  ERR_PARSE_ERROR = -32700, -- Error code for "Parse error" error
  ERR_INVALID_REQUEST = -32600, -- Error code for "Invalid request" error
  ERR_METHOD_NOT_FOUND = -32601, -- Error code for "Method not found" error
  ERR_INVALID_PARAMS = -32602, -- Error code for "Invalid params" error
  ERR_INTERNAL_ERROR = -32603, -- Error code for "Internal error" error
  ERR_SERVER_ERROR = -32000, -- Error code for "Server error" error
}

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

--- Create new Lugate instance. Initialize ngx dependent properties
-- @param[type=table] config Table of configuration options: body for raw request body and routes for routing map config
-- @return[type=Lugate] The new instance of Lugate
function Lugate:init(config)
  -- Check request method
  if 'POST' ~= ngx.req.get_method() then
    ngx.say(Lugate.get_json_error(Lugate.ERR_INVALID_REQUEST, 'Only POST requests are allowed'))
    ngx.exit(ngx.HTTP_OK)
  end

  -- Build config
  config = config or {}
  ngx.req.read_body() -- explicitly read the req body
  config['body'] = ngx.req.get_body_data()

  -- Create new lugate instance
  local lugate = self:new(config)

  return lugate
end

--- Get a proper formated json error
-- @param[type=int] code Error code
-- @param[type=string] message Error message
-- @return[type=string]
function Lugate.get_json_error(code, message)
  local messages = {
    [Lugate['ERR_PARSE_ERROR']] = 'Invalid JSON was received by the server. An error occurred on the server while parsing the JSON text.',
    [Lugate['ERR_INVALID_REQUEST']] = 'The JSON sent is not a valid Request object.',
    [Lugate['ERR_METHOD_NOT_FOUND']] = 'The method does not exist / is not available.',
    [Lugate['ERR_INVALID_PARAMS']] = 'Invalid method parameter(s).',
    [Lugate['ERR_INTERNAL_ERROR']] = 'Internal JSON-RPC error.',
    [Lugate['ERR_SERVER_ERROR']] = 'Server error',
  }
  local code = messages[code] and code or Lugate.ERR_SERVER_ERROR
  local message = message or messages[code]

  return '{"jsonrpc":"2.0","error":{"code":' .. tostring(code) .. ',"message":"' .. message .. '","data":[]},"id":null}'
end

--- Configure lugate instance
-- @param[type=table] config Table of configuration options
function Lugate:configure(config)
  self.body = config.body
  self.routes = config.routes or {}
  self.responses = {}
end

--- Check all dependencies are installed or break down on failure
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

--- Get request collection prepared for ngx.location.capture_multi call
-- @return[type=table] The table of requests
function Lugate:run()
  -- Loop requests
  local ngx_requests = {}
  for _, request in ipairs(self:get_requests()) do
    if request:is_valid() then
      table.insert(ngx_requests,request:get_ngx_request())
    else
      ngx.say(self.get_json_error(Lugate.ERR_PARSE_ERROR))
      ngx.exit(ngx.HTTP_OK)
    end
  end

  -- Send multi requst and get multi response
  local responses = {ngx.location.capture_multi(ngx_requests)}
  for _, response in ipairs(responses) do
    self:add_response(response)
  end

  return responses
end

--- Add new response
function Lugate:add_response(response)
  if 200 == response.status then
    local response_body = string.gsub(response.body, '%s$', '')
    response_body = string.gsub(response_body, '^%s', '')
    table.insert(self.responses, response_body)
    
  else
    ngx.say(self.get_json_error(Lugate.ERR_INTERNAL_ERROR))
    ngx.exit(ngx.HTTP_OK)
  end
end

--- Print all responses and exit
function Lugate:print_responses()
  if 1 == #self.responses then
    ngx.say(self.responses[1])
  else
    ngx.print('[' .. table.concat(self.responses, ",") .. ']')
  end

  ngx.exit(ngx.HTTP_OK)
end

--- Check if request is a batch
-- @param[type=table] data Decoded request body
-- @return[type=boolean]
function Lugate:is_batch(data)
  return data and data[1] and ('table' == type(data[1]))
end

return Lugate
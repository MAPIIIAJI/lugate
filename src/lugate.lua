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
  assert(type(config.ngx) == "table", "Parameter 'ngx' is required and should be a table!")
  assert(type(config.json) == "table", "Parameter 'json' is required and should be a table!")

  -- Define metatable
  local lugate = setmetatable({}, Lugate)
  self.__index = self

  -- Define services and configs
  lugate.ngx = config.ngx
  lugate.json = config.json
  lugate.cache = config.cache
  lugate.routes = config.routes or {}
  lugate.request_ids = {}
  lugate.responses = {}

  return lugate
end

--- Create new Lugate instance. Initialize ngx dependent properties
-- @param[type=table] config Table of configuration options: body for raw request body and routes for routing map config
-- @return[type=Lugate] The new instance of Lugate
function Lugate:init(config)
  -- Create new lugate instance
  local lugate = self:new(config)

  -- Check request method
  if 'POST' ~= lugate.ngx.req.get_method() then
    lugate.ngx.say(lugate:get_json_error(Lugate.ERR_INVALID_REQUEST, 'Only POST requests are allowed'))
    lugate.ngx.exit(lugate.ngx.HTTP_OK)
  end

  -- Build config
  lugate.ngx.req.read_body() -- explicitly read the req body

  return lugate
end

--- Get a proper formated json error
-- @param[type=int] code Error code
-- @param[type=string] message Error message
-- @return[type=string]
function Lugate:build_json_error(code, message, data, id)
  local messages = {
    [Lugate.ERR_PARSE_ERROR] = 'Invalid JSON was received by the server. An error occurred on the server while parsing the JSON text.',
    [Lugate.ERR_INVALID_REQUEST] = 'The JSON sent is not a valid Request object.',
    [Lugate.ERR_METHOD_NOT_FOUND] = 'The method does not exist / is not available.',
    [Lugate.ERR_INVALID_PARAMS] = 'Invalid method parameter(s).',
    [Lugate.ERR_INTERNAL_ERROR] = 'Internal JSON-RPC error.',
    [Lugate.ERR_SERVER_ERROR] = 'Server error',
  }
  local code = messages[code] and code or Lugate.ERR_SERVER_ERROR
  local message = message or messages[code]
  local data = data and self.json.encode(data) or 'null'
  local id = id or 'null'

  return '{"jsonrpc":"2.0","error":{"code":' .. tostring(code) .. ',"message":"' .. message .. '","data":' .. data .. '},"id":' .. id .. '}'
end

--- Parse raw body
-- @return[type=table]
function Lugate:get_data()
  if not self.data then
    self.data = self.body and self.json.decode(self.body) or {}
  end

  return self.data
end

--- Get ngx request body
-- @return[type=string]
function Lugate:get_body()
  if not self.body then
    self.body = self.ngx.req and self.ngx.req.get_body_data() or ''
  end
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
  for request_id, request in ipairs(self:get_requests()) do
    if request:is_valid() then
      table.insert(ngx_requests,request:get_ngx_request())
      self.request_ids[#ngx_requests] = request_id
    else
      self:add_response(
        request_id,
        self:get_json_error(Lugate.ERR_PARSE_ERROR, nil, request, request:get_id()),
        true
      )
    end
  end

  -- Send multi requst and get multi response
  local responses = {ngx.location.capture_multi(ngx_requests)}
  for response_id, response in ipairs(responses) do
    local request_id = self.request_ids[response_id]
    self:add_response(request_id, response)
  end

  return responses
end

--- Add new response
function Lugate:add_response(request_id, response, as_is)
  if not as_is then
    local response_body = string.gsub(response.body, '%s$', '')
    response = string.gsub(response_body, '^%s', '')
    if 200 ~= response.status then
      response = self:get_json_error(Lugate.ERR_INTERNAL_ERROR, nil, response, nil)
    end
  end

  self.responses[request_id] = response
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
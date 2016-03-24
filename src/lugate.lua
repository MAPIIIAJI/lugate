----------------------
-- The lugate module.
-- Lugate is a lua module for building JSON-RPC 2.0 Gateway APIs just inside of your Nginx configuration file.
-- Lugate is meant to be used with [ngx\_http\_lua\_module](https://github.com/openresty/lua-nginx-module) together.
--
-- @classmod lugate
-- @author Ivan Zinovyev <vanyazin@gmail.com>
-- @license MIT

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
-- @param [type=table] config Table of configuration options: body for raw request body and routes for routing map config
-- @return [type=table] The new instance of Lugate
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
  lugate.req_num = {}
  lugate.responses = {}

  return lugate
end

--- Create new Lugate instance. Initialize ngx dependent properties
-- @param [type=table] config Table of configuration options: body for raw request body and routes for routing map config
-- @return [type=table] The new instance of Lugate
function Lugate:init(config)
  -- Create new lugate instance
  local lugate = self:new(config)

  -- Check request method
  if 'POST' ~= lugate.ngx.req.get_method() then
    lugate.ngx.say(lugate:build_json_error(Lugate.ERR_INVALID_REQUEST, 'Only POST requests are allowed'))
    lugate.ngx.exit(lugate.ngx.HTTP_OK)
  end

  -- Build config
  lugate.ngx.req.read_body() -- explicitly read the req body

  return lugate
end

--- Get a proper formated json error
-- @param [type=int] code Error code
-- @param [type=string] message Error message
-- @return [type=string]
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

--- Get ngx request body
-- @return [type=string]
function Lugate:get_body()
  if not self.body then
    self.body = self.ngx.req and self.ngx.req.get_body_data() or ''
  end

  return self.body
end

--- Parse raw body
-- @return [type=table]
function Lugate:get_data()
  if not self.data then
    self.data = self:get_body() and self.json.decode(self.body) or {}
  end

  return self.data
end

--- Check if request is a batch
-- @param [type=table] data Decoded request body
-- @return [type=boolean]
function Lugate:is_batch(data)
  return data and data[1] and ('table' == type(data[1])) and true or false
end

--- Get request collection
-- @return [type=table] The table of requests
function Lugate:get_requests()
  if not self.requests then
    self.requests = {}
    local data = self:get_data()
    if self:is_batch(data) then
      for _, rdata in ipairs(data) do
        table.insert(self.requests, Request:new(rdata, self))
      end
    else
      table.insert(self.requests, Request:new(data, self))
    end
  end

  return self.requests
end

--- Get request collection prepared for ngx.location.capture_multi call
-- @return [type=table] The table of requests
function Lugate:run()
  -- Loop requests
  local ngx_requests = {}
  for i, request in ipairs(self:get_requests()) do
    if request:is_valid() then
      local req, err = request:get_ngx_request()
      if req then
        table.insert(ngx_requests, req)
        self.req_num[#ngx_requests] = i
      else
        self.responses[i] = self:build_json_error(Lugate.ERR_SERVER_ERROR, err, request:get_body(), request:get_id())
      end
    else
      self.responses[i] = self:build_json_error(Lugate.ERR_PARSE_ERROR, nil, request:get_body(), request:get_id())
    end
  end

  -- Send multi requst and get multi response
  if #ngx_requests > 0 then
    local responses = { ngx.location.capture_multi(ngx_requests) }
    for n, response in ipairs(responses) do
      self.responses[self.req_num[n]] = response.body
    end
  end

  return self.responses
end

--- Clean response
function Lugate:clean_response(response)
  local response_body = response.body or response
  response_body = string.gsub(response_body, '%s$', '')
  response_body = string.gsub(response_body, '^%s', '')

  return response_body
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

return Lugate
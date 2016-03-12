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
-- @param[type=string] body Request raw body
-- @param[type=table] routes Routing rules
-- @return[type=Lugate] The new instance of Lugate
function Lugate:new(body, routes)
  local lugate = setmetatable({}, Lugate)
  self.__index = self
  self.body = body
  self.routes = routes or {}

  return lugate
end

--- Get the collection of requests
-- @return[type=table] The
function Lugate:get_request()
  if not self.request then
    self.request = {}
    self.data = json.decode(self.body)
    if self.data then
        print(self.data)
    end
  end

  return self.request
end

---- Get table data
--function Lugate:get_data()
--  if self.data == nil then
--    self.data = json.decode(self.raw_body)
--  end
--
--  return self.data
--end
--
---- Check if request is a batch
--function Lugate:is_batch()
--  return (self.data[1] ~= nil)
--    and self:is_valid(self.data[1])
--end
--
---- Check if single request is valid
--function Lugate:is_valid(data)
--  return (type(data) == 'table')
--    and (data.jsonrpc ~= nil)
--    and (data.method ~= nil)
--    and (data.params ~= nil)
--    and (data.id ~= nil)
--end

return Lugate
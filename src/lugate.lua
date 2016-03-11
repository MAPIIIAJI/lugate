--
-- lugate.lua
--

-- Json encoder/decoder
local json = require "rapidjson"

-- Gateway class
local Lugate = {}

-- Class constructor
function Lugate.new(raw_body)
    local self = setmetatable({}, Lugate)
    self.__index = self
    self.raw_body = raw_body

    return self
end

-- Get table data
function Lugate:get_data()
--    if self.data == nil then
--        self.data = json.decode(self.raw_body)
--    end
--
--    return self.data
end

return Lugate
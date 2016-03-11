--
-- lugate.lua
--

-- Json encoder/decoder
local json = require "rapidjson"

-- Gateway class
local Lugate = {}

-- Class constructor
function Lugate:new(raw_body)
    local lugate = setmetatable({}, Lugate)
    self.__index = self
    self.raw_body = raw_body

    return lugate
end

-- Get table data
function Lugate:get_data()
    if self.data == nil then
        self.data = json.decode(self.raw_body)
    end

    return self.data
end

-- Check if request is a batch
function Lugate:is_batch()
    -- todo
end

-- Check if single request is valid
function Lugate:is_valid()    -- todo

    -- todo
end

return Lugate
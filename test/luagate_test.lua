Lugate = dofile("./src/lugate.lua")

describe("parse initial json", function ()
    assert.is_not_nil(Lugate)
    local lugate = Lugate.new('{"jsonrpc":"2.0","method":"service01.say","params":{"foo":"bar"},"id":1}')

--    local data = lugate:get_data()
--    assert.are.equal('table', type(data))
end)
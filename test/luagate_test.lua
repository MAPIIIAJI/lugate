describe("Lugate unit tests", function ()
    local Lugate = dofile("./src/lugate.lua")

    it("should be initialized", function ()
        assert.is_not_nil(Lugate)
    end)

    it("should be a table for correct json", function ()
        local lu1 = Lugate:new('{"jsonrpc":"2.0","method":"service01.say","params":{"foo":"bar"},"id":1}')
        local data1 = lu1:get_data()
        assert.are.equal('table', type(data1))
    end)

    it("should be a nil for invalid json", function ()
        local lu2 = Lugate:new('{"jsonrpc":"2.0",')
        local data2 = lu2:get_data()
        assert.is_nil(data2)
    end)
end)
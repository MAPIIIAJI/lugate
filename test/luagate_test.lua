describe("Check Lugate constructor", function ()
  local Lugate = dofile("./src/lugate.lua")
  it("should be initialized", function()
    assert.is_not_nil(Lugate)
  end)

  it("The new instance of Lugate should be a table", function ()
    local lu1 = Lugate:new('{"jsonrpc":"2.0","method":"service01.say","params":{"foo":"bar"},"id":1}')
    assert:set_parameter("TableFormatLevel", 0)
    assert.are.same(lu1, {})
  end)
end)

describe("Check Lugate request parser", function ()

end)

describe("Check Lugate response builder", function ()

end)

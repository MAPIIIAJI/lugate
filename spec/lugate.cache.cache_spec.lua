-- Load the module
local Cache = dofile("./src/lugate/cache/cache.lua")

describe("Check dummy cache setter and getter", function()
  local cache = Cache:new();
  cache:set('FOO', 'BAR', 3600)

  it("Should set and get values", function()
    assert.equals('BAR', cache:get('FOO'))
  end)
end)
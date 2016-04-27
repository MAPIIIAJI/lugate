-- Load the module
local Dummy = dofile("./src/lugate/cache/dummy.lua")

describe("Check dummy cache setter and getter", function()
  local cache = Dummy:new();
  cache:set('FOO', 'BAR', 0.5)
  math.randomseed(1234)

  it("Should set and get values", function()
    local val1 = cache:get('FOO')
    local val2 = cache:get('FOO')
    assert.equals('BAR', cache:get('FOO'))

    -- emulate sleep
    local time = os.time()
    local time_fn = os.time
    os.time = function() return time + 1 end

    local val3 = cache:get('FOO')
    assert.equals(val1, val2)
    assert.not_equals(val1, val3)
    assert.is_nil(val3)

    -- restore time
    os.time = time_fn
  end)

  it("Should correctly store tags to the set", function()
    cache:sadd('tag1', 'bar1')
    cache:sadd('tag1', 'bar2')
    cache:sadd('tag2', 'bar1')

    assert.same({'bar1', 'bar2'}, cache:get('tag1'))
    assert.same({'bar1'}, cache:get('tag2'))
  end)
end)
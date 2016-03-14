-- Load the module
local Lugate = dofile("./src/lugate.lua")

describe("Check Lugate instance constructor", function()
  it("should be initialized", function()
    assert.is_not_nil(Lugate)
  end)

  it("The new instance of Lugate should be a table", function()
    local lu1 = Lugate:new({
      body = '{"jsonrpc":"2.0","method":"service01.say","params":{"foo":"bar"},"id":1}'
    })
    assert.equal('table', type(lu1))
  end)
end)

describe("Check Lugate request parser", function()
  it("Single request should be packed into array", function()
    local lu1 = Lugate:new({
      body = '{"jsonrpc":"2.0","method":"service01.say","params":{"foo":"bar"},"id":1}'
    })
    local requests = lu1:get_requests()
    assert(requests[1]["method"])
    assert("service01.say", requests[1]["method"])
  end)

  it("Batch request should also be packed into array", function()
    local lu1 = Lugate:new({
      body = '[{"jsonrpc":"2.0","method":"service01.say","params":{"foo":"bar"},"id":1},'
        .. '{"jsonrpc":"2.0","method":"service02.say","params":{"foo":"bar"},"id":2}]'
    })
    local requests = lu1:get_requests()
    assert(requests[1]["method"])
    assert(requests[2]["method"])
    assert("service01.say", requests[1]["method"])
    assert("service02.say", requests[2]["method"])
  end)
end)

describe("Check request validator", function()
  it("Valid single request should be valid", function()
    local lu1 = Lugate:new({
      body = '{"jsonrpc":"2.0","method":"service01.say","params":{"foo":"bar"},"id":1}'
    })
    local res1 = lu1:is_valid(lu1:get_data())
    assert.is_true(res1)
  end)

  it("Invalid single request should not be validated successfully", function()
    local lu2 = Lugate:new({
      body = '{"jsonrpc":"2.0",'
    })
    local res2 = lu2:is_valid(lu2:get_data())
    assert.is_false(res2)
  end)

  it("Valid single request with additional logic should be valid and parsed like proxy call", function()
    local lu1 = Lugate:new({
      body = '{"jsonrpc":"2.0","method":"service01.say","params":{"cache":3600,"route":"v1.service01","params":{"foo":"bar"}},"id":1}'
    })
    local res1 = lu1:is_proxy_call(lu1:get_data())
    assert.is_true(res1)
  end)
end)

describe("Check request router", function()
  it("Bind a route if possible", function()
    local lu1 = Lugate:new({
      body = '{"jsonrpc":"2.0","method":"service01.say","params":{"cache":3600,"route":"v1.service01.say","params":{"foo":"bar"}},"id":1}',
      routes = {
        ["^v2%.service01%s.say"]     = '/v2/service01.loc',
        ["^v2%.service02%s.watch"]   = '/v2/service01.loc',
        ["^v1%..+"]                  = '/v1/json',
      }
    })
    local route = lu1:get_route(lu1:get_data())
    assert.equals(route, '/v1/json')
  end)
end)

describe("Check params normalization", function()
  it("Request should exist and be normalized after normalization", function ()
    local lu1 = Lugate:new({
      body = '{"jsonrpc":"2.0","method":"service01.say","params":{"cache":3600,"route":"v1.service01.say","params":{"foo":"bar"}},"id":1}',
      routes = {
        ["^v2%.service01%s.say"]     = '/v2/service01.loc',
        ["^v2%.service02%s.watch"]   = '/v2/service01.loc',
        ["^v1%..+"]                  = '/v1/json',
      }
    })
    req = lu1:normalize_params(lu1:get_data())
    assert.equals(req.params.foo, 'bar')
  end)
end)

describe("Check Lugate response builder", function()
end)

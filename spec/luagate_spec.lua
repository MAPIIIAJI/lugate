-- Load the module
local Lugate = dofile("./src/lugate.lua")

-- Mock for ngx module
local mock_ngx = loadstring([[
  local ngx = {
    req = {}
  }

  return ngx
]])

describe("Check all mandatory packages are loaded", function()
  it("error should be thrown if ngx is not loaded", function()
    -- Remove ngx if loaded
    package.loaded['ngx'] = nil

    assert.has_error(function() local lu1 = Lugate:new('') end, "Module 'ngx' is required!")

    -- Load ngx after error is caught
    package.loaded['ngx'] = mock_ngx()
  end)
end)

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

describe("Check how requests are parsed to objects", function ()
  it("Requests should be parsed to array from the batch request", function()
    local lu1 = Lugate:new({
      body = '[{"jsonrpc":"2.0","method":"service01.say","params":{"cache":3600,"route":"v1.service01.say","params":{"foo":"bar"}},"id":1},'
      ..'{"jsonrpc":"2.0","method":"service01.say","params":{"cache":3600,"route":"v1.service01.say","params":{"foo":"bar"}},"id":1}]',
      routes = {}
    })
    local req = lu1:get_requests(lu1:get_data())
    assert.is_table(req)
    assert.is_table(req[1])
    assert.is_table(req[2])
    assert.is_equal('service01.say', req[1]:get_method())
    assert.is_equal('service01.say', req[2]:get_method())
  end)
--  local req = lu1:create_request(lu1:get_data())
--  print(req.id)
end)

describe("Check how a single request is parsed to object", function ()
  it("Request should be parsed to array from the single request", function()
    local lu1 = Lugate:new({
      body = '{"jsonrpc":"2.0","method":"service01.say","params":{"cache":3600,"route":"v1.service01.say","params":{"foo":"bar"}},"id":1}',
      routes = {
        ['^v1%..+'] = '/v1'
      }
    })
    local req = lu1:get_requests(lu1:get_data())
    assert.is_table(req)
    assert.is_table(req[1])
    assert.is_equal('2.0', req[1]:get_jsonrpc())
    assert.is_equal('service01.say', req[1]:get_method())
    assert.are.same({foo = "bar"}, req[1]:get_params())
    assert.are.same(3600, req[1]:get_cache())
    assert.are.same('v1.service01.say', req[1]:get_route())
    assert.are.same('/v1', req[1]:get_uri())
    assert.is_equal(1, req[1]:get_id())
  end)
end)

describe("Check how the request body is converted to string", function()
  local lu1 = Lugate:new({
    body = '{"jsonrpc":"2.0","method":"service01.say","params":{"cache":3600,"route":"v1.service01.say","params":{"foo":"bar"}},"id":1}',
    routes = {
      ['^v1%..+'] = '/v1'
    }
  })

  it("Request body should be converted to a valid data array", function()
    assert.equals("2.0", lu1:get_requests()[1]:get_data()['jsonrpc'])
    assert.equals(1, lu1:get_requests()[1]:get_data()['id'])
    assert.equals("service01.say", lu1:get_requests()[1]:get_data()['method'])
    assert.are.same({foo = "bar"}, lu1:get_requests()[1]:get_data()['params'])
  end)

  it("Request body should be converted to a valid json string", function()
    local body = lu1:get_requests()[1]:get_body()
    assert.is_string(body)
    assert.equals('"method":"service01.say"', string.match(body, '"method":"service01.say"'))
  end)

  assert.equals('/v1', lu1:get_requests()[1]:get_ngx_request()[1])
  assert.equals(8, lu1:get_requests()[1]:get_ngx_request()[2]['method'])
  assert.is_string(lu1:get_requests()[1]:get_ngx_request()[2]['body'])
end)

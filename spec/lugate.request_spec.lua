-- Load the module
local Request = dofile("./src/lugate/request.lua")

describe("Check request constructor", function()
  it("Request should be initialized", function()
    assert.is_not_nil(Request)
  end)

  it("Error should be thrown if data is not provided", function()
    assert.has_error(function()
      Request:new(nil, {})
    end, "Parameter 'data' is required and should be a table!")
  end)

  it("Error should be thrown if lugate is not provided", function()
    assert.has_error(function()
      Request:new({}, nil)
    end, "Parameter 'lugate' is required and should be a table!")
  end)

  it("The lugate instance should be a table", function()
    assert.is_table(Request:new({}, {}))
  end)
end)

describe("Check request validation", function()
  it("Request should be valid if jsonrpc version and method are provided", function()
    local request = Request:new({ jsonrpc = '2.0', method = 'foo.bar' }, {})
    assert.is_true(request:is_valid())
  end)

  it("Request should be a valid proxy call if params and route values are provided", function()
    local request = Request:new({
      jsonrpc = '2.0',
      method = 'foo.bar',
      params = {
        params = {},
        route = 'v1.foo.bar'
      }
    }, {})
    assert.is_true(request:is_proxy_call())
  end)

  it("Request should be a invalid proxy call if wrong options are provided", function()
    local request = Request:new({
      jsonrpc = '2.0',
      method = 'foo.bar',
      params = {foo = "bar"}
    }, {})
    assert.is_false(request:is_proxy_call())
  end)
end)

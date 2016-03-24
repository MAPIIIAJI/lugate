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

  it("Request should be invalid if jsonrpc version and method are provided", function()
    local request = Request:new({ method = 'foo.bar' }, {})
    assert.is_false(request:is_valid())
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
      params = { foo = "bar" }
    }, {})
    assert.is_false(request:is_proxy_call())
  end)
end)

describe("Check request params are parsed correctly", function()
  it("Request should contain jsonrpc property if any provided", function()
    local request = Request:new({ jsonrpc = '2.2' }, {})
    assert.equals('2.2', request:get_jsonrpc())
  end)

  it("Request should contain method property if any provided", function()
    local request = Request:new({ method = 'method.name' }, {})
    assert.equals('method.name', request:get_method())
  end)

  it("Request should contain id property if any provided", function()
    local request = Request:new({ id = 2 }, {})
    assert.equals(2, request:get_id())
  end)

  it("Request should contain params property if any provided", function()
    local request = Request:new({ jsonrpc = '2.2', method = 'method.name', params = { one = 1, two = 2 } }, {})
    assert.are_same({ one = 1, two = 2 }, request:get_params())
  end)

  it("Request should contain params property even if they are nested provided", function()
    local request = Request:new({
      jsonrpc = '2.2',
      method = 'method.name',
      params = {
        route = 'v1.method.name',
        params = { one = 1, two = 2 }
      }
    }, {})
    assert.are_same({ one = 1, two = 2 }, request:get_params())
  end)

  it("Request should contain nested proxy params if they are provided", function()
    local request = Request:new({
      jsonrpc = '2.2',
      method = 'method.name',
      params = {
        route = 'v1.method.name',
        cache = false,
        key = 'd88d8ds00-s',
        params = { one = 1, two = 2 }
      }
    }, {})
    assert.equal('v1.method.name', request:get_route())
    assert.equal(false, request:get_cache())
    assert.equal('d88d8ds00-s', request:get_key())
  end)
end)

describe('Check that uri is created correctly', function()
  local lugate = {
    routes = {
      ['^v2%..*'] = '/api/v2/'
    }
  }
  it("Should provide a correct uri if route matches", function()
    local data = {
      jsonrpc = '2.2',
      method = 'method.name',
      params = {
        route = 'v2.method.name',
        cache = false,
        key = 'd88d8ds00-s',
        params = { one = 1, two = 2 }
      },
      id = 1,
    }
    local request = Request:new(data, lugate)
    assert.equal('/api/v2/', request:get_uri())
  end)
  it("Should not provide a correct uri if the route doesn not match", function()
    local data = {
      jsonrpc = '2.2',
      method = 'method.name',
      params = {
        route = 'v1.method.name',
        cache = false,
        key = 'd88d8ds00-s',
        params = { one = 1, two = 2 }
      },
      id = 1,
    }
    local request = Request:new(data, lugate)
    assert.equal('/', request:get_uri())
  end)
end)

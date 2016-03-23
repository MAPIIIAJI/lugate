-- Load the module
local Lugate = dofile("./src/lugate.lua")

describe("Check lugate constructor", function()
  it("Lugate should be initialized", function()
    assert.is_not_nil(Lugate)
  end)

  it("Error should be thrown if ngx is not loaded", function()
    assert.has_error(function()
      Lugate:new({ json = {} })
    end, "Parameter 'ngx' is required and should be a table!")
  end)

  it("Error should be thrown if json is not loaded", function()
    assert.has_error(function()
      Lugate:new({ ngx = {} })
    end, "Parameter 'json' is required and should be a table!")
  end)

  it("The lugate instance should be a table", function()
    assert.is_table(Lugate:new({ ngx = {}, json = {} }))
  end)
end)

describe("Check json rpc error builder", function()
  local lugate = Lugate:new({ ngx = {}, json = require "rapidjson" })
  local data_provider = {
    { { Lugate.ERR_PARSE_ERROR, nil, {}, 1 }, '{"jsonrpc":"2.0","error":{"code":-32700,"message":"Invalid JSON was received by the server. An error occurred on the server while parsing the JSON text.","data":{}},"id":1}', },
    { { Lugate.ERR_INVALID_REQUEST, nil, {}, 1 }, '{"jsonrpc":"2.0","error":{"code":-32600,"message":"The JSON sent is not a valid Request object.","data":{}},"id":1}', },
    { { Lugate.ERR_METHOD_NOT_FOUND, nil, {}, 1 }, '{"jsonrpc":"2.0","error":{"code":-32601,"message":"The method does not exist / is not available.","data":{}},"id":1}', },
    { { Lugate.ERR_INVALID_PARAMS, nil, {}, 1 }, '{"jsonrpc":"2.0","error":{"code":-32602,"message":"Invalid method parameter(s).","data":{}},"id":1}', },
    { { Lugate.ERR_INTERNAL_ERROR, nil, {}, 1 }, '{"jsonrpc":"2.0","error":{"code":-32603,"message":"Internal JSON-RPC error.","data":{}},"id":1}', },
    { { Lugate.ERR_SERVER_ERROR, nil, {}, 1 }, '{"jsonrpc":"2.0","error":{"code":-32000,"message":"Server error","data":{}},"id":1}', },
    { { Lugate.ERR_SERVER_ERROR, nil, {}, 1 }, '{"jsonrpc":"2.0","error":{"code":-32000,"message":"Server error","data":{}},"id":1}', },
  }

  it("Method build_json_error should be able to build a correct error message", function()
    for _, data in ipairs(data_provider) do
      assert.equals(data[2], lugate:build_json_error(data[1][1], data[1][2], data[1][3], data[1][4]))
    end
  end)

  it("Method build_json_error should be able to build an error message with empty input", function()
      assert.equals(
        '{"jsonrpc":"2.0","error":{"code":-32000,"message":"Server error","data":null},"id":null}',
        lugate:build_json_error()
      )
  end)

  it("Method build_json_error should be able to build an error message with a custom input", function()
    assert.equals(
      '{"jsonrpc":"2.0","error":{"code":-32000,"message":"","data":{"foo":"bar"}},"id":100500}',
      lugate:build_json_error(0, "", {foo = "bar"}, 100500)
    )

    assert.equals(
      '{"jsonrpc":"2.0","error":{"code":-32000,"message":"Non-empty message","data":null},"id":null}',
      lugate:build_json_error({}, "Non-empty message", nil, nil)
    )
  end)
end)

--describe("Check how requests are parsed to objects", function()
--  it("Requests should be parsed to array from the batch request", function()
--    local lu1 = Lugate:new({
--      body = '[{"jsonrpc":"2.0","method":"service01.say","params":{"cache":3600,"route":"v1.service01.say","params":{"foo":"bar"}},"id":1},'
--        .. '{"jsonrpc":"2.0","method":"service01.say","params":{"cache":3600,"route":"v1.service01.say","params":{"foo":"bar"}},"id":1}]',
--      routes = {}
--    })
--    local req = lu1:get_requests(lu1:get_data())
--    assert.is_table(req)
--    assert.is_table(req[1])
--    assert.is_table(req[2])
--    assert.is_equal('service01.say', req[1]:get_method())
--    assert.is_equal('service01.say', req[2]:get_method())
--  end)
--  local req = lu1:create_request(lu1:get_data())
--  print(req.id)
--end)

--describe("Check how a single request is parsed to object", function()
--  it("Request should be parsed to array from the single request", function()
--    local lu1 = Lugate:new({
--      body = '{"jsonrpc":"2.0","method":"service01.say","params":{"cache":3600,"key":"baz","route":"v1.service01.say","params":{"foo":"bar"}},"id":1}',
--      routes = {
--        ['^v1%..+'] = '/v1'
--      }
--    })
--    local req = lu1:get_requests(lu1:get_data())
--    assert.is_table(req)
--    assert.is_table(req[1])
--    assert.is_equal('2.0', req[1]:get_jsonrpc())
--    assert.is_equal('service01.say', req[1]:get_method())
--    assert.are.same({ foo = "bar" }, req[1]:get_params())
--    assert.are.same(3600, req[1]:get_cache())
--    assert.are.same('v1.service01.say', req[1]:get_route())
--    assert.are.same('/v1', req[1]:get_uri())
--    assert.is_equal(1, req[1]:get_id())
--  end)
--end)

--describe("Check how the request body is converted to string", function()
--  local lu1 = Lugate:new({
--    body = '{"jsonrpc":"2.0","method":"service01.say","params":{"cache":3600,"key":"baz","route":"v1.service01.say","params":{"foo":"bar"}},"id":1}',
--    routes = {
--      ['^v1%..+'] = '/v1'
--    }
--  })

--  it("Request body should be converted to a valid data array", function()
--    assert.equals("2.0", lu1:get_requests()[1]:get_data()['jsonrpc'])
--    assert.equals(1, lu1:get_requests()[1]:get_data()['id'])
--    assert.equals("service01.say", lu1:get_requests()[1]:get_data()['method'])
--    assert.are.same({ foo = "bar" }, lu1:get_requests()[1]:get_data()['params'])
--  end)

--  it("Request body should be converted to a valid json string", function()
--    local body = lu1:get_requests()[1]:get_body()
--    assert.is_string(body)
--    assert.equals('"method":"service01.say"', string.match(body, '"method":"service01.say"'))
--  end)

--  assert.equals('/v1', lu1:get_requests()[1]:get_ngx_request()[1])
--  assert.equals(8, lu1:get_requests()[1]:get_ngx_request()[2]['method'])
--  assert.is_string(lu1:get_requests()[1]:get_ngx_request()[2]['body'])
--end)

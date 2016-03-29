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

describe("Check how the module is loaded", function()
  it("Should be able to load a module", function()
    local lugate = Lugate:new({ ngx = {}, json = {} })
    local json = lugate:load_module({"dummy"}, { dummy = "lugate.cache.cache", rapidjson = "rapidjson", cjson = "lua-cjson" })
    assert.is_table(json)

    assert.has_error(function()
      lugate:load_module("unknown", { rapidjson = "rapidjson", cjson = "lua-cjson" })
    end)
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
    assert.equals('{"jsonrpc":"2.0","error":{"code":-32000,"message":"Server error","data":null},"id":null}',
      lugate:build_json_error())
  end)

  it("Method build_json_error should be able to build an error message with a custom input", function()
    assert.equals('{"jsonrpc":"2.0","error":{"code":-32000,"message":"","data":{"foo":"bar"}},"id":100500}',
      lugate:build_json_error(0, "", { foo = "bar" }, 100500))

    assert.equals('{"jsonrpc":"2.0","error":{"code":-32000,"message":"Non-empty message","data":null},"id":null}',
      lugate:build_json_error({}, "Non-empty message", nil, nil))
  end)
end)

describe("Check body and data analysis", function()
  it("Method get_body() should return empty string when no body is provided", function()
    local ngx = {}
    local lugate = Lugate:new({ ngx = ngx, json = require "rapidjson" })
    assert.equals('', lugate:get_body())

    ngx.req = {
      get_body_data = function()
        return 'foo'
      end
    }

    assert.equals('', lugate:get_body())
  end)

  it("Method get_body() should always return a raw body", function()
    local ngx = {
      req = {
        get_body_data = function()
          return 'foo'
        end
      }
    }
    local lugate = Lugate:new({ ngx = ngx, json = require "rapidjson" })
    assert.equals('foo', lugate:get_body())
  end)

  it("Method get_data() should return nil if bad json body is provided", function()
    local ngx = {
      req = {
        get_body_data = function()
          return 'foo'
        end
      }
    }
    local lugate = Lugate:new({ ngx = ngx, json = require "rapidjson" })
    assert.is_nil(lugate:get_data())
  end)

  it("Method get_data() should decode a correctly formatted json body", function()
    local ngx = {
      req = {
        get_body_data = function()
          return '{"foo":"bar"}'
        end
      }
    }
    local lugate = Lugate:new({ ngx = ngx, json = require "rapidjson" })
    assert.are_same({ foo = "bar" }, lugate:get_data())
  end)

  it("Method is_batch() should return true if batch is provided and false otherwise", function()
    local lugate = Lugate:new({ ngx = {}, json = {} })
    assert.is_true(lugate:is_batch({ { foo = "bar" } }))
    assert.is_false(lugate:is_batch({ foo = "bar" }))
    assert.is_false(lugate:is_batch(nill))
    assert.is_false(lugate:is_batch("foo"))
  end)
end)

describe("Check request factory", function()
  local ngx = { req = {} }
  it("Should return a single request for a single dimensional table", function()
    local lugate = Lugate:new({ ngx = ngx, json = require "rapidjson" })
    ngx.req.get_body_data = function()
      return '{"foo":"bar"}'
    end
    assert.equal(1, #lugate:get_requests())
  end)

  it("Should return a multi request for the multi dimensional table", function()
    local lugate = Lugate:new({ ngx = ngx, json = require "rapidjson" })
    ngx.req.get_body_data = function()
      return '[{"foo":"bar"},{"foo":"bar"},{"foo":"bar"}]'
    end
    assert.equal(3, #lugate:get_requests())
  end)
end)
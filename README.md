# Lugate
Lugate is a lua module for building JSON-RPC 2.0 Gateway APIs just inside of your Nginx configuration file.

[![Build Status](https://travis-ci.org/zinovyev/lugate.svg?branch=master)](https://travis-ci.org/zinovyev/lugate)

## About
Lugate is a helper set which is meant to be used together with [ngx\_http\_lua\_module](https://github.com/openresty/lua-nginx-module) module.
It provides you several special methods for validating a JSON-RPC 2.0 request, looping a batch call and building a
valid response.

## Lugate proxy call
Lugate brings its own protocol to live for transferring some additional logic over JSON-RPC 2.0 request. It adds
capabilities for routing and caching.
The *params* member of the request object gets some additional mandatory members:

* **route** - fo the routing note
* **cache** - for the caching lifetime
* **params** - the regular array of parameter values

After the request is processed by the Lugate module, the **route** and **cache** values are removed from the
*params* member and the **params** value is expanded on the full *params* field.

## Example
```lua
-- Get request body
body = ngx.req.get_body_data()
-- Get new lugate instance
lugate = Lugate:new({
  body = body,
  routes = {
    "example.com/v1", "^v1%..+",
    "service01.example.com/v2", "^v2%.math%s.+",
    "service02.example.com/v2", "^v2%.string%s.+",
  }
})
-- Get requests collection
if lugate:is_valid() then
  -- Send several parrallel subrequests
  results = {ngx.location.capture_multi(lugate:get_all)}
  -- Attach response values on lugate instance
  lugate:respond(results)
  ngx.say(lugate.get_response)
-- Or print the error response on failure
else
  ngx.say(lugate.err_parse_error)    
end
```
# Lugate
Lugate is a lua module for building JSON-RPC 2.0 Gateway APIs just inside of your Nginx configuration file.

[![Build Status](https://travis-ci.org/zinovyev/lugate.svg?branch=master)](https://travis-ci.org/zinovyev/lugate)

# Example
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
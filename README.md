# Lugate
Lugate is a library for building JSON-RPC 2.0 Gateway API just inside of your NGINX configuration file

[![Build Status](https://travis-ci.org/zinovyev/lugate.svg?branch=master)](https://travis-ci.org/zinovyev/lugate)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/zinovyev/lugate/master/LICENSE)
[![GitHub version](https://badge.fury.io/gh/zinovyev%2Flugate.svg)](https://badge.fury.io/gh/zinovyev%2Flugate)

## Table of Contents  
[Synopsis](#synopsis)

[About](#about)

[API Reference](##api-reference)

[Installation](#installation)

[Usage](#usage)

[Lugate Proxy Call](#lugate-proxy-call)

[Middlewares](#middlewares)

[Testing](#testing)

[Running The Example](#running-the-example)

[Change Log](#change-log)



## Synopsis
```lua
    location / {
          # MIME type determined by default_type:
          default_type 'application/json';

          content_by_lua_block {
              -- Load lugate module
              local Lugate = require "lugate"

              -- Get new lugate instance
              local lugate = Lugate:init({
                json = require "rapidjson",             -- 1. Require wrapper to work with json (should be installed)
                ngx = ngx,                              -- 2. Require nginx instance
                cache = {'redis', '127.0.0.1', 6379},   -- 3. Configure cache wrapper (redis and dummy cache modules are currently available)
                routes = {                              -- 4. Routing rules
                  ['v1%.([^%.]+).*'] = '/v1/%1',        -- 4.1 v1.math.subtract -> /v1/math (for example)
                  ['v2%.([^%.]+).*'] = '/v2/%1',        -- 4.2 v2.math.addition -> /v2/math (for example)
                },
                debug = true,                           -- 5. Enable debug mode (write all requests and responses to the nginx error log)
              })

              -- Send multi requst and get multi response
              lugate:run()

              -- Print responses out
              lugate:print_responses()
          }
    }
```


## About
When we talk about Microservices Architecture pattern there is a thing there called
[API Gateway](http://microservices.io/patterns/apigateway.html) which is the single entry point into the system.

Lugate is a binding over OpenResty's [ngx\_http\_lua\_module](https://github.com/openresty/lua-nginx-module#name) module.
The library provides features for request parsing, validating and routing. Lugate acts like a caching proxy over the
JSON-RPC 2.0 protocol and is meant to be used like an entry point for your application.

![Lugate request processing](doc/images/request_upstream_scheme.png)


## API Reference
The autogenerated API reference is available at: [API reference](http://zinovyev.github.io/lugate).


## Installation
First of all, you have to have nginx compiled with
[ngx\_http\_lua\_module](https://github.com/openresty/lua-nginx-module#installation) module.
Take a look at the `example/provision.sh` file to get a tip on how to do it.

Lugate by itself can be installed via the [luarocks](https://luarocks.org/modules/zinovyev/lugate) package manager.
Just run:
```bash
luarocks install lugate
```

## Usage
in work...


## Lugate Proxy Call
Lugate brings its own protocol to live. It's goal is transferring, routing and distributing cache control logic over
JSON-RPC 2.0 request.

The *params* member of the [request object](http://www.jsonrpc.org/specification#request_object)
is wrapped in additional structure:

* **route** - The routing destination
* **params** - The original parameters member value should be moved here for now
* **cache** - Cache control logic
  * **ttl** - Cache time to life
  * **key** - Cache key
  * **tags** - Cache tags

When the request is processed by the lugate proxy, the **route** and **cache** values are removed from the
*params* member and the nested **params** value is expanded to fill the whole parent *params* field.

The request routing plan:

- Request is preprocessed by the the lugate proxy. Location: gateway.lugate.loc:
```json
{
    "jsonrpc": "2.0",
    "method": "subtract",
    "params": {
        "cache": {
            "ttl": 3600,
            "key": "foobar",
            "tags": ["news_list", "top7"]
        },
        "route": "v2.substract",
        "params": [42, 23]
    },
    "id": 1
}
```

- Request is send to the proper service (deciding of the `route` param). Location: /v2/substract:
```json
{
    "jsonrpc": "2.0",
    "method": "substract",
    "params": [42, 23],
    "id": 1
}
```

- Request is sent back to client:
```json
{
    "jsonrpc": "2.0",
    "result": -19,
    "id": 2
}
```

### Route
  The routing destination. The value is processed by the lua [gsub](http://www.lua.org/pil/20.1.html) function.
  
### Params
  The original params values.
  
### Ttl
  The time-to-life value is used to set cache expiration time. If ttl is false, no cache is set.
  
### Key
  The cache key is calculated by client. This approach gives more flexibility for debugging and development goals.
  
### Tags
  The cache tags. Cache Keys Stored in special Tag sets. Use it for cache invalidation.
  

## Middlewares
You can use the `pre` and `post` hooks to paste additional logic to the `run` method:
* `pre(lugate)` is evaluated before all requests are processed;
* `post(lugate)` - after all requests are processed;
* `cache(lugate, response)` - before cache is stored;

The `lugate` instance is passed to the callback as the only parameter. If `false` is returned the futher evaluation is stopped.

Example on how to define hooks:
```lua
  local lugate = Lugate:init({
    json = require "rapidjson",
    ngx = ngx,
    cache = {'redis', '127.0.0.1', 6379},
    routes = {
      ['v1%.([^%.]+).*'] = '/v1/%1', -- v1.math.subtract -> /v1/math
      ['v2%.([^%.]+).*'] = '/v2/%1', -- v2.math.addition -> /v2/math
    },
    pre = function(lugate)
      ngx.say("Hi there!")
      ngx.exit(ngx.HTTP_OK)
    end
  })
```


## Testing
Use [busted](http://olivinelabs.com/busted/) for running tests (from the root directory of the project).


## Running The Example
The example project uses vagrant provision. So you need to have vagrant and virtualbox installed.

Launch project by running this command from the example directory:
```bash
vagrant up
```
Add this line to your local `/etc/hosts` file:
```
192.168.50.47 gateway.lugate.loc service01.lugate.loc service02.lugate.loc service03.lugate.loc
```


## Change Log


### 6.0.0
* HTTP errors handling ([#4](https://github.com/zinovyev/lugate/issues/4))
* Better request/response factories testing

### 0.5.4
* Invalid JSON detection

### 0.5.3
* Debug log and version header features

### 0.5.2
* Prevent invalid JSON on empty responses in batch

### 0.5.1
* Support for cache tagging

### 0.5.0
* Hooks feature added ([middlewares](#middlewares))
* Redis cache support

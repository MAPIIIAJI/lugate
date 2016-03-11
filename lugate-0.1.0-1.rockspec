package = "LuGate"
version = "0.1.0-1"
source = {
    url = "https://github.com/zinovyev/lugate"
}
description = {
    summary = "Lua module for building JSON-RPC 2.0 Gateway APIs just inside of your Nginx",
    detailed = [[
        Lua module for building JSON-RPC 2.0 Gateway APIs just inside of your Nginx.
        The package is meant to be used with 'openresty/lua-nginx-module' Nginx module.
    ]],
    homepage = "http://github.com/zinovyev/lugate",
    license = "MIT"
}
dependencies = {
    "lua ~> 5.1",
    "rapidjson ~> 0.4"
}
build = {
    type = "builtin",
    modules = {
        lugate = "src/lugate.lua"
    },
    copy_directories = { "test" }
}

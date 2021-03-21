require 'class'
local RPC = require 'rpc'

-- create new client to call functions from server at localhost:12345
client = RPC.client('127.0.0.1', 12345)

-- set actions what to do on success/failure of the remote call.
-- these are the defaults
client.on_success = print
client.on_failure = error

-- queue some functions
client.rpc.print("Hello world!\nHello remote server!")
client.rpc.twice(2)

-- -- you can also define function-specific callbacks.
-- -- prototype is client:call(function_name, on_success, on_failure, ...)
-- client:call('thrice', function(result) print('3 * 2 = ', result) end, function(err) print("RPC error:", err), 3)
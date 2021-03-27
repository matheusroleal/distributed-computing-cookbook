require 'class'
local RPC = require 'base'

-- create new client to call functions from server at localhost:12345
client = RPC.client('127.0.0.1', 12345, 'interface.lua')

-- set actions what to do on success/failure of the remote call.
-- these are the defaults
client.on_success = print
client.on_failure = error

-- queue some functions
local r, s = client.rpc.foo(3, "alo", {nome = "Aaa", idade = 20, peso = 55.0}, 1)

local t, p = client.rpc.boo(20)

t, p = client.rpc.boo('matheus')

require 'class' -- any class commons enabled library
local lrpc = require 'luarpc'

local p1 = lrpc.createProxy('127.0.0.1', 40484, 'interface.lua')
local p2 = lrpc.createProxy('127.0.0.1', 43344, 'interface.lua')

local r, s = p1.rpc.foo(3, "alo", {nome = "Aaa", idade = 20, peso = 55.0}, 1)
print(r)
print(s)

local t, p = p2.rpc.boo(10)
print(t)
print(p)
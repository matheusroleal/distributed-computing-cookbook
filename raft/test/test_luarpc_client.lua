local lrpc = require 'luarpc'

local p1 = lrpc.createProxy('127.0.0.1', 43196, 'interface.lua', true)

local p2 = lrpc.createProxy('127.0.0.1', 43196, 'interface.lua', true)

p1.Snapshot()

p2.Snapshot()
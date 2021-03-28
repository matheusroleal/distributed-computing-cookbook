require 'class' -- any class commons enabled library
local lrpc = require 'luarpc'

local myobj1 = { foo = function (a, s, st, n) return a*2, string.len(s) + st.idade + n end, boo = function (n) return n, { nome = "Bia", idade = 30, peso = 61.0} end }
local myobj2 = { foo = function (a, s, st, n) return 0.0, 1 end, boo = function (n) return 1, { nome = "Teo", idade = 60, peso = 73.0} end }

local address, port = lrpc.createServant(myobj1,'interface.lua')
address, port = lrpc.createServant(myobj2,'interface.lua')

lrpc.waitIncoming()
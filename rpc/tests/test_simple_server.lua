require 'class' -- any class commons enabled library
local RPC = require 'base'

--
-- GLOBAL NAMESPACES
--
myinterface = {}

function interface(iface)
  myinterface = iface
end

mystruct = {}

function struct(strct)
	mystruct = strct
end

dofile('interface.lua')

-- open server at port 12345 on localhost
server = RPC.server(12345, '127.0.0.1')

-- register functions that returns a value
server:register('foo', function (a, s, st, n) return 0.0, 1 end)
server:register('boo', function (n) return n, { nome = "Bia", idade = 30, peso = 61.0} end)

-- run the server
while true do
    server:serve(myinterface)
end
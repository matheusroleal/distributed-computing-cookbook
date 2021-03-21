require 'class' -- any class commons enabled library
local RPC = require 'rpc'

-- open server at port 12345 on localhost
server = RPC.server(12345, '127.0.0.1')

-- register 'print' function as remotely callable
server:register('print', print)

-- register a function that returns a value
server:register('twice', function(x) return 2 * x end)

-- yet another way to define callable functions
function server.registry.thrice(x) return 3 * x end

-- run the server
while true do
    server:serve()
end
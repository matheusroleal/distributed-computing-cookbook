local luarpc = require("luarpc")
local socket = require("socket")
local math = require("math")

-- Reuse code for multiples methods
if #arg < 2 then
    print("Error: missing argument(s).\nUsage: lua test_raft_client.lua [port] [method]")
    os.exit()
end

local port = tonumber(arg[1])
local method = arg[2]

-- Connecting to the client
local raft_node = luarpc.createProxy("127.0.0.1", port, 'interface.lua', false)

-- Defining the method to be called
if method == "InitializeNode" then
    raft_node.InitializeNode()
elseif method == "StopNode" then
    raft_node.StopNode()
elseif method == "ApplyEntry" then
    raft_node.ApplyEntry(math.random(1,20))
elseif method == "Snapshot" then
    raft_node.Snapshot()
end
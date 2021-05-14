local raft = require("raft")
local luarpc = require("luarpc")

-- Reuse code for multiples servers
if #arg < 2 then
    print("Error: missing argument(s).\nUsage: lua test_raft_server.lua [id] [port]")
    os.exit()
end

local id = arg[1]
local port = tonumber(arg[2])

local servers = { { id = 1, port = 1234 }, { id = 2, port = 4321 }, { id = 3, port = 5678 }, { id = 4, port = 4355 } }

-- Create proxies with other nodes
local peers = {}
for _, server in ipairs(servers) do
    raft_node = {}
    raft_node.host = "127.0.0.1"
    raft_node.port = server.port
    raft_node.id = server.id
    raft_node.proxy = luarpc.createProxy(raft_node.host, raft_node.port, "interface.lua", false)
    table.insert(peers, raft_node)
end

-- Setting up a raft node
raft.Configure(peers, id)

-- Starting RPC connection
luarpc.createServant(raft, "interface.lua", port)

luarpc.waitIncoming(false)
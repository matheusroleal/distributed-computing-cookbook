build:
	luarocks install raft-algorithm-0.0.1-1.rockspec

start-nodes:
	lua test_raft_server.lua 1 1234 & lua test_raft_server.lua 2 4321 & lua test_raft_server.lua 3 5678 & lua test_raft_server.lua 4 4355

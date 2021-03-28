build:
	luarocks install lua-rpc-0.0.1-1.rockspec

test_luarpc_client:
	lua test/test_luarpc_client.lua

test_luarpc_server:
	lua test/test_luarpc_server.lua

test_simple:
	@lua test/test_simple_server.lua &
	@lua test/test_simple_client.lua &

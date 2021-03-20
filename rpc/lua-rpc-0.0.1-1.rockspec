package = "lua-rpc"
version = "0.0.1-1"
source = {
  url = "git://github.com/Olivine-Labs/busted",
  branch = "master"
}
description = {
   summary = "A Lua>=5.2 library for generating and processing RPC",
   detailed = "A Lua>=5.2 library for generating and processing RPC",
   homepage = "*** please enter a project homepage ***",
   license = "BSD"
}
dependencies = {
  "lua >= 5.2",
}
build = {
   type = "builtin",
   modules = {
      ["lua-rpc.client"] = "src/client.lua",
      ["lua-rpc.server"] = "src/server.lua"
   }
}

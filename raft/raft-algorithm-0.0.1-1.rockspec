package = "raft-algorithm"
version = "0.0.1-1"
source = {
  url = "git://github.com/matheusroleal/distributed-computing-cookbook/",
  branch = "master"
}
description = {
   summary = "A Lua>=5.2 library for generating and processing RPC",
   detailed = "A Lua>=5.2 library for generating and processing RPC",
   homepage = "github.com/matheusroleal/distributed-computing-cookbook/",
   license = "MIT"
}
dependencies = {
  "lua >= 5.2",
}
build = {
   type = "builtin",
   modules = {
      ["luarpc"] = "raft/src/raft.lua"
   },
   copy_directories = { "raft/src" } 
}

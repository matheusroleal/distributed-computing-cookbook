local lrpc = require 'luarpc'
local raft = require 'raft'

lrpc.createServant(raft,'interface.lua',43196)

lrpc.waitIncoming(true)
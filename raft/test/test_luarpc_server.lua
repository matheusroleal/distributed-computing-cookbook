local lrpc = require 'luarpc'

local myobj1 = { ReceiveMessage = function (st) return 'st.type' end, InitializeNode = function () print('Inicia ai') end, StopNode = function () print('Termina ai') end, ApplyEntry = function (port) return 'Done' end, Snapshot = function () print('Tudo certo aqui') end}

lrpc.createServant(myobj1,'interface.lua',43196)

lrpc.waitIncoming(true)
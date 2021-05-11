local lrpc = require 'luarpc'

local myobj1 = {}

function myobj1.ReceiveMessage(st) 
    return 'st.type' 
end 

function myobj1.InitializeNode() 
    print('Inicia ai')
end

function myobj1.StopNode() 
    print('Termina ai') 
end 

function myobj1.ApplyEntry(port) 
    return 'Done' 
end

function myobj1.Snapshot() 
    print('Tudo certo aqui') 
end


lrpc.createServant(myobj1,'interface.lua',43196)

lrpc.waitIncoming(true)
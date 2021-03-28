require 'class' -- any class commons enabled library
local RPC = require 'base'

local luarpc = {}

--
-- GLOBAL NAMESPACES
--
servant_list = {}

myinterface = {}

function interface(iface)
  myinterface = iface
end

mystruct = {}

function struct(strct)
	mystruct = strct
end

--
-- LOCAL FUNCTIONS  
-- 
local function table_length(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

local function validate_object(object, idl)
	local method_count = 0
	for rpc_method, method in pairs(idl.methods) do
		if object[rpc_method] then
			method_count = method_count + 1
		end
	end
	if not method_count == table_length(object) then
		return false
	end
	return true
end

-- 
-- RPC SERVANT
-- 
function luarpc.createServant(obj, interface_file)
	-- Interface upload
	dofile(interface_file)
    -- Validates received object with IDL
    local ok = validate_object(obj, myinterface) 
    if not ok then
        return nil, nil, "Invalid object received while creating servant"
    end
	-- Creating server values
	address = '127.0.0.1'
	-- Free ports... Ref: https://pt.wikipedia.org/wiki/Lista_de_portas_dos_protocolos_TCP_e_UDP#Portas_49152_a_65535
	port = math.random(40000,43593)
	server = RPC.server(port, address)
	-- Creating a servant unit
	local servant = {
		server = server,
		object = obj,
		idl = myinterface,
	}
	table.insert(servant_list, servant)
	return address, port
end

function luarpc.waitIncoming()
	-- Just to make the IP and port of the servants in a simpler way
	for servant_num, servant in pairs(servant_list) do
		print('Servant ' .. servant_num .. ' running on IP ' .. servant.server.address .. ' and port ' .. servant.server.port)
	end
	-- Recording the methods defined for this servant
	for _, servant in pairs(servant_list) do
		for rpc_method, method in pairs(servant.idl.methods) do
			if servant.object[rpc_method] then
				servant.server:register(rpc_method, servant.object[rpc_method])
			end
		end
	end
	-- Loop between released ports
	while true do
		for _, servant in pairs(servant_list) do
			servant.server:serve(servant.idl)
		end
	end
end

-- 
-- RPC PROXY
-- 
function luarpc.createProxy(ip, port, idl)
	client = RPC.client(ip, port, idl)
	return client
end

--
-- THE MODULE
--
return luarpc
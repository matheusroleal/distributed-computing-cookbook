local socket = require 'socket'
local json = require "json"
assert(common and common.class, "A Class Commons implementation is required")

--
-- GLOBAL NAMESPACES
--
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
local function is_serializable(t,v)
	return t == "number" or
	       t == "boolean" or
	       t == "string" or
	       t == "nil" or
		   t == "table" or
	       (getmetatable(v) or {}).__tostring ~= nil
end

local function serialize(...)
	local args = {n = select('#', ...), ...}
	local serialized = {}
	for i = 1,args.n do
		local t, v = type(args[i]), args[i]
		if not is_serializable(t,v) then
			error(("Cannot serialize values of type `%s'."):format(t))
		end
		if t == "table" then
			serialized[i] = ("%s<%s>"):format(t,json.encode(v))
		else
			serialized[i] = ("%s<%s>"):format(t,tostring(v))
		end
	end
	return table.concat(serialized, ",")
end

local converter = {
	['nil'] = function() return nil end,
	string  = function(v) return v end,
	number  = tonumber,
	boolean = function(v) return v == 'true' end,
	table	= function(v) return json.decode(v) end,
}
local function deserialize_helper(iter)
	local token = iter()
	if not token then return end

	local t,v = token:match('(%w+)(%b<>)')
	return (converter[t] or error)(v:sub(2,-2)), deserialize_helper(iter)
end
local function deserialize(str)
	return deserialize_helper(str:gmatch('%w+%b<>'))
end

local function simplify_args(iter)
	local token = iter()
	local arguments = {}
	while token do
		local t,v = token:match('(%w+)(%b<>)')
		table.insert(arguments, (converter[t] or error)(v:sub(2,-2)) )
		token = iter()
	end
	return arguments
end

local function capabilities(self, pattern)
	pattern = pattern or ".*"
	local ret = {}
	for name, _ in pairs(self.registry) do
		if name:match(pattern) then
			ret[#ret+1] = name
		end
	end
	return table.concat(ret, "\n")
end

local function validate_type(param_type, value)
	if param_type == "char" then
	  if #tostring(value) == 1 then
		return true
	  end
	elseif param_type == "string" then
	  if type(value) == "string" then
		return true
	  end
	elseif param_type == "double" then
	  if tonumber(value) then
		return true
	  end
	elseif param_type == "int" then
		if tonumber(value) then
		  return true
		end
	elseif param_type == "void" then
	  if value == nil then
		return true
	  end
	elseif type(value) == "table" then
		return true
	end
	return false
end

local function validate_args(method, arguments_str, interface_rpc, param_direction)
	local ismethod = 'Method not found'
	local arguments = simplify_args(arguments_str:gmatch('%w+%b<>'))
	for rpc_method, _ in pairs(interface_rpc.methods) do
		if rpc_method == method then
			local agrs_size = 0
			ismethod = nil
			-- Checks for invalid number of arguments
			for count_param, param in pairs(interface_rpc.methods[rpc_method].args) do
				if param.direction == param_direction then 
					agrs_size=count_param
				end
			end
			local same_size = agrs_size == #arguments
			if not same_size then
				return 'Invalid number of arguments'
			end
			-- Checks for invalid argument type
			for count_param, param in pairs(interface_rpc.methods[rpc_method].args) do
				if param.direction == param_direction then 
					if not validate_type(param.type, arguments[count_param]) then
						return 'Unverified format'
					end
				end
			end
		end
	end
	return ismethod
end

local function execute(self, func, args)
	if not self.registry[func] then
		return false, ("Tried to execute unknown function `%s'"):format(func)
	end

	return (function(pcall_ok, ...)
		if pcall_ok then
			return true, serialize(...)
		end
		return false, ...
	end)(pcall(self.registry[func], deserialize(args)))
end

--
-- RPC SERVER
--
local server = {}

function server:init(port, address)
	port = port or 0
	address = address or '*'
	self.socket = assert(socket.bind(address, port))
	self.socket:settimeout(0)
	self.address, self.port = self.socket:getsockname()
	self.registry = {}

	function self.registry.capabilities(...) return capabilities(self, ...) end
end

function server:register(name, func)
	assert(name, "Missing argument: `name'")
	assert(func, "Missing argument: `func'")
	self.registry[name] = func
end

function server:remove(name)
	assert(name, "Missing argument: `name'")
	self.registry[name] = nil
end

function server:defined(name)
	assert(name, "Missing argument: `name'")
	return self.registry[name] ~= nil
end

function server:serve(interface_rpc)
	assert(self.socket, "Server socket not initialized")

	local client,err = self.socket:accept()
	if client then
		local line = client:receive()

		print('I received the following message:', line)

		request_decode = json.decode(line)
		local func = request_decode['method']
		local args = request_decode['params']
 
		local response = {}
		response['method'] = func

		local resp = validate_args(func, args, interface_rpc, "in")
		if resp then
			response['type'] = 'ERROR'
			response['result'] = resp
		else
			local ok, ret = execute(self, func, args)
			response['type'] = 'RESPONSE'
			response['result'] = ret
		end

		local str = json.encode(response) .. "\r\n"
		
		print('Send it back' .. str)
		
		client:send(str)

		client:close()
	elseif not client and err ~= 'timeout' then
		error(err)
	end
end

--
-- RPC CLIENT
--
local client = {}

local function query(self, func, args)
	local client = socket.tcp()
	client:settimeout(10)
	local _, err = client:connect(self.address, self.port)
	if err then
		return false, ("Cannot connect to %s[%s]: %s"):format(self.address, self.port, err)
	end

	local request = {}
	request['type'] = 'REQUEST'
	request['method'] = func
	request['params'] = args

	local str = json.encode(request) .. "\r\n"
	print('Sending it', str)

	_, err = client:send(str)
	if err then
		client:close()
		return false, ("Cannot send query message to %s[%s]: %s"):format(self.address, self.port, err)
	end

	while true do
		local s, status, partial = client:receive('*l')

		local request_decode = json.decode(s)

		local func = request_decode['method']
		local result = request_decode['result']
		
		coroutine.yield(result)
	end
end

function client:init(address, port, interface_file)
	assert(address and port, "Need server address and port")
	dofile(interface_file)

	self.address, self.port = address, port
	self.workers = {}
	self.on_success = print
	self.on_failure = error
	self.idl = myinterface
	self.rpc = setmetatable({}, {__index = function(_,func)
		return function(...) return self:call(func, self.on_success, self.on_failure,...) end
	end})
end

function client:call(func, on_success, on_failure, ...)
	local args = serialize(...)
	local q = coroutine.create(function() return query(self, func, args) end)
	local coroutine_ok, call_ok, returns = coroutine.resume(q)
	if coroutine_ok and call_ok ~= nil then
		return deserialize(call_ok)
	end
	return nil
end

--
-- THE MODULE
--
return {
	server = common.class("RPC.server", server),
	client = common.class("RPC.client", client),
}
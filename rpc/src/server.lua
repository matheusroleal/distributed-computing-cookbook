local socket = require 'socket'

-- TODO: more serializers
local function is_serializable(t,v)
	return t == "number" or
	       t == "boolean" or
	       t == "string" or
	       t == "nil" or
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
		serialized[i] = ("%s<%s>"):format(t,tostring(v))
	end
	return table.concat(serialized, ",")
end

local converter = {
	['nil'] = function() return nil end,
	string  = function(v) return v end,
	number  = tonumber,
	boolean = function(v) return v == 'true' end,
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

--
-- RPC SERVER
--
local server = {}

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

function server:serve()
	assert(self.socket, "Server socket not initialized")

	local client,err = self.socket:accept()
	if client then
		local line = client:receive('*l')
		local bytes = tonumber(line:match('^RPC:(%d+)$'))
		if bytes then
			line = client:receive(bytes)
			local token, func, args = line:match('^([^:]+):([^:]+):(.*)%s*')
			if token and func and args then
				local ok, ret = execute(self, func, args)
				local str = ("RPC:%s:%s:%s\r\n"):format(token, tostring(ok), ret)
				client:send(str)
			end
		end
		client:close()
	elseif not client and err ~= 'timeout' then
		error(err)
	end
end

--
-- THE MODULE
--

return server
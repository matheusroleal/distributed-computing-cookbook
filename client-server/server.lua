local socket = require("socket")

-- create a TCP socket and bind it to the local host, at any port
local server = assert(socket.bind("*", 58041))

-- find out which port the OS chose for us
local ip, port = server:getsockname()
print("Please telnet to localhost on port " .. port)
print("After connecting, you have 10s to enter a line to be echoed")

while 1 do
  -- wait for a connection from any client
  local client = server:accept()

  client:settimeout(10)
  -- receive the line
  local line, err = client:receive()
  
  print('I received the following message:', line)
  
  if not err then client:send(line .. ' from server') end

  client:close()
end

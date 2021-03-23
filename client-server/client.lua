local host, port = "127.0.0.1", 64828
local socket = require("socket")
local tcp = assert(socket.tcp())

tcp:connect(host, port);
--note the newline below
tcp:send("hello world\n");

while true do
    local s, status, partial = tcp:receive()
    
    print('I got back:', s or partial)

    if status == "closed" then break end
end
tcp:close()

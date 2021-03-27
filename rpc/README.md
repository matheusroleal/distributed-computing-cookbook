# Remote Procedure Call 
In distributed computing, a remote procedure call (RPC) is when a computer program causes a procedure (subroutine) to execute in a different address space (commonly on another computer on a shared network), which is coded as if it were a normal (local) procedure call, without the programmer explicitly coding the details for the remote interaction.

## Methods
A system to support remote method calls was built using Lua and LuaSocket. We implemented a luarpc library containing the following methods:
* `lrpc.createServant (myobj, arq_interface)` - Create servers
* `lrpc.waitIncoming` - Responsible for creating passive state waiting for calls
* `lrpc.createProxy (IP, port, arq_interface)` - Responsible for creating a connection to the server

## RPC Protocol
The idea is to start from a specification of the remote object, in our case the `interface.lua` file, which can be read directly by the Lua program. It is used during the connection to check the format of the requests made. If something comes out of the format an error response is sent instead of leaving the request on the air. The communication protocol between client and server is in JSON, containing messages like the ones described below:

```
{
"type": "REQUEST", (optional, to facilitate debugging)
"method": "foo",
"params": [2]
}
```

```
{
"type": "RESPONSE",
"method": "foo",
"result": [4.0]
}
```

```
{
"type": "ERROR",
"method": "foo",
"error": "Error Msg detailing the problem"
}
```
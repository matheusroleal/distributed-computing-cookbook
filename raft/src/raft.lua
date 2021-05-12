luarpc = require("luarpc")
interface = require("interface")
socket = require("socket")
math = require("math")

local raft = {}

-- Internal functions
function check_election_timeout(timeout_limit)
	return os.time() >= timeout_limit
end

function reset_timeout()
    raft.timeoutLimit = os.time() + raft.randomElectionTimeout
end

function table_to_string(tbl)
    local result = "{"
    for k, v in pairs(tbl) do
        -- check the key type (ignore any numerical keys - assume its an array)
        if type(k) == "string" then
            result = result.."[\""..k.."\"]".."="
        end
        -- check the value type
        if type(v) == "table" then
            result = result..table_to_string(v)
        elseif type(v) == "boolean" then
            result = result..tostring(v)
        else
            result = result.."\""..v.."\""
        end
        result = result..","
    end
    -- remove leading commas from the result
    if result ~= "" then
        result = result:sub(1, result:len()-1)
    end
    return result.."}"
end

-- Raft Implementation
function raft.Configure(peers, id)
    -- insert RPC connection to all peers
    raft.remote_peers = peers
    raft.active_peers = 0
    -- initialize state values
    raft.id = id
    raft.state = 'idle'
    raft.running = false
    -- Define Heartbeat variables 
    raft.entries={}
    raft.heartbeatFrequency = 2
    raft.randomElectionTimeout = math.random(10,20)
    raft.timeoutLimit = os.time() + raft.randomElectionTimeout
    print("Heartbeat Timeout Set to " .. tostring(raft.randomElectionTimeout))
	-- initialize election variables 
    raft.votes = 0
    raft.votingMajority = (#peers / 2) + 1
    raft.votedFor = nil
end

function raft.sendHeartbeats()
    raft.active_peers = 0
	for _, peer in ipairs(raft.remote_peers) do
        print('Sending Heartbeat For ' .. peer.id)
        -- create message with heartbeat request
        local message = {}
        message.timeout = raft.timeoutLimit
        message.fromNode = raft.id
        message.toNode = peer.id
        message.type = 'heartbeat'
        message.value = raft.id
        -- send heartbeats
        local p = peer.proxy
        local heartbeatReturn = p.ReceiveMessage(message)
        if heartbeatReturn == 'ok' then
            raft.active_peers = raft.active_peers + 1
        end
    end
end

function raft.startElection()
    raft.votes = 0
	for _, peer in ipairs(raft.remote_peers) do
        print('Asking Vote For ' .. peer.id)
        -- create message with vote request
        local message = {}
        message.timeout = raft.timeoutLimit
        message.fromNode = raft.id
        message.toNode = peer.id
        message.type = 'vote'
        message.value = raft.id
        -- send vote requests
        local p = peer.proxy
        local voteGranted = p.ReceiveMessage(message)
        if voteGranted == 'ok' then
            raft.votes = raft.votes + 1
        end 
    end
    if raft.votes >= raft.votingMajority then
        raft.state = 'leader'
        raft.sendHeartbeats()
        raft.votes=0
    else
        print("Waiting For Heartbeat...")
        luarpc.wait(raft.heartbeatFrequency, false)
    end
end

-- RPC interface methods
function raft.InitializeNode()
    raft.running = true
    raft.state = 'follower'
    while true do
        if raft.running then
            print("Node Running...")
            if raft.state == 'leader' then
                raft.sendHeartbeats()
                luarpc.wait(raft.heartbeatFrequency, false)
            elseif raft.state == 'candidate' then
                raft.startElection()
            elseif raft.state == 'follower' then
				-- check if it is able to become a candidate
                if check_election_timeout(raft.timeoutLimit) then
                    raft.state = 'candidate'
                end
            end
        else
            raft.state = 'idle'
            luarpc.wait(raft.heartbeatFrequency, false)
        end
    end
end

function raft.ReceiveMessage(message) 
    if raft.state == 'idle' then
        return 'out'
    end
    if message.type == 'vote' then
        raft.votedFor = message.fromNode
        raft.reset_timeout()
        return 'ok' 
    end
    if message.type == 'heartbeat' then
        raft.entries = message.value
        raft.votedFor = message.fromNode
        raft.state = 'follower'
        raft.reset_timeout()
        return 'ok' 
    end
    if message.type == 'request' then
        raft.entries = message.value
        raft.votedFor = message.fromNode
        raft.state = 'follower'
        raft.reset_timeout()
        return 'ok' 
    end
    return 'void'
end 

function raft.StopNode()
	raft.running = false
    print("Node Stopped")
end 

function raft.ApplyEntry(data) 
    if raft.state == "leader" then
        for _, peer in ipairs(raft.remote_peers) do
            print('Applying a New Entry For ' .. peer.id)
            -- create message with an entry
            local message = {}
            message.timeout = raft.timeoutLimit
            message.fromNode = raft.id
            message.toNode = peer.id
            message.type = 'request'
            message.value = table.insert(raft.entries, tostring(data))
            -- apply an entry
            local p = peer.proxy
            local voteGranted = p.ReceiveMessage(message)
            if voteGranted == 'ok' then
                raft.votes = raft.votes + 1
            end 
        end
        return 'Done' 
    end
    return 'Not Leader' 
end

function raft.Snapshot()
    print('Entry log: '.. table_to_string(raft.entries))
end

return raft
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
    raft.heartbeatFrequency = 5
    raft.randomElectionTimeout = math.random(15,40)
    raft.timeoutLimit = os.time() + raft.randomElectionTimeout
    print("[Node " .. raft.id .."] Heartbeat Timeout Set to " .. tostring(raft.randomElectionTimeout))
	-- initialize election variables 
    raft.votes = 0
    raft.votingMajority = (#peers / 2) + 1
end

function raft.sendHeartbeats()
    raft.active_peers = 0
	for _, peer in ipairs(raft.remote_peers) do
        if tonumber(peer.id) == tonumber(raft.id) then
            raft.active_peers = raft.active_peers + 1
        else
            print("[Node " .. raft.id .."] Sending Heartbeat For Node" .. peer.id)
            -- create message with heartbeat request
            local message = {}
            message.timeout = raft.timeoutLimit
            message.fromNode = tonumber(raft.id)
            message.toNode = tonumber(peer.id)
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
end

function raft.startElection()
    raft.votes = 0
	for _, peer in ipairs(raft.remote_peers) do
        if tonumber(peer.id) == tonumber(raft.id) then
            -- vote for yourself
            raft.votes = raft.votes + 1
        else
            print("[Node " .. raft.id .."] Asking Vote For Node " .. peer.id)
            -- create message with vote request
            local message = {}
            message.timeout = raft.timeoutLimit
            message.fromNode = tonumber(raft.id)
            message.toNode = tonumber(peer.id)
            message.type = 'vote'
            message.value = raft.id
            -- send vote requests
            local peer_rpc = peer.proxy
            local voteGranted = peer_rpc.ReceiveMessage(message)
            if voteGranted == 'ok' then
                raft.votes = raft.votes + 1
            end 
        end
    end
    print("[Node " .. raft.id .."] got " .. raft.votes .. " votes")
    if tonumber(raft.votes) >= tonumber(raft.votingMajority) then
        print("[Node " .. raft.id .."] I'm the leader")
        raft.state = 'leader'
        -- send to peers the new leader
        raft.sendHeartbeats()
        raft.votes=0
    else
        print("[Node " .. raft.id .."] Waiting For Heartbeat...")
        luarpc.wait(raft.heartbeatFrequency, false)
    end
end

-- RPC interface methods
function raft.InitializeNode()
    raft.running = true
    raft.state = 'follower'
    reset_timeout()
    luarpc.wait(raft.heartbeatFrequency, false)
    while true do
        if raft.running then
            print("[Node " .. raft.id .."] Running...")
            if raft.state == 'leader' then
                -- keeping the followers on your side
                raft.sendHeartbeats()
                luarpc.wait(raft.heartbeatFrequency, false)
            elseif raft.state == 'candidate' then
                -- start election to become leader
                raft.startElection()
            elseif raft.state == 'follower' then
                luarpc.wait(raft.heartbeatFrequency, false)
                -- check if it is able to become a candidate
                if check_election_timeout(raft.timeoutLimit) then
                    raft.state = 'candidate'
                end
            end
        else
            raft.state = 'idle'
            luarpc.wait(raft.heartbeatFrequency, false)
        end
        luarpc.wait(raft.heartbeatFrequency, false)
    end
end

function raft.ReceiveMessage(message) 
    if raft.state == 'idle' then
        return 'out'
    end
    if message.type == 'vote' then
        if raft.state == 'candidate' then
            return 'no'
        end
        print("[Node " .. raft.id .."] Received Vote Request From Node " .. message.fromNode)
        reset_timeout()
        return 'ok' 
    end
    if message.type == 'heartbeat' then
        print("[Node " .. raft.id .."] Timeout Updated")
        raft.state = 'follower'
        reset_timeout()
        return 'ok' 
    end
    if message.type == 'request' then
        print("[Node " .. raft.id .."] Entry Updated")
        table.insert(raft.entries, tostring(data))
        raft.state = 'follower'
        reset_timeout()
        return 'ok' 
    end
    return 'void'
end 

function raft.StopNode()
	raft.running = false
    print("[Node " .. raft.id .."] Stopped")
end 

function raft.ApplyEntry(data) 
    if raft.state == "leader" then
        raft.active_peers = 0
        for _, peer in ipairs(raft.remote_peers) do
            if tonumber(peer.id) == tonumber(raft.id) then
                table.insert(raft.entries, tostring(data))
                print("[Node " .. raft.id .."] Updating Entry For Leader: " .. table_to_string(raft.entries))
            else
                print("[Node " .. raft.id .."] Applying a New Entry For Node " .. peer.id)
                -- create message with an entry
                local message = {}
                message.timeout = raft.timeoutLimit
                message.fromNode = tonumber(raft.id)
                message.toNode = tonumber(peer.id)
                message.type = 'request'
                message.value = tostring(data)
                -- apply an entry
                local p = peer.proxy
                local response = p.ReceiveMessage(message)
                if heartbeatReturn == 'ok' then
                    raft.active_peers = raft.active_peers + 1
                end
            end
        end
        return 'Done' 
    end
    return 'Not Leader' 
end

function raft.Snapshot()
    print("[Node " .. raft.id .."] Entry log: ".. table_to_string(raft.entries))
end

return raft
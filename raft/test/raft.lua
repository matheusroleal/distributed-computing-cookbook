luarpc = require("luarpc")
interface = require("interface")
socket = require("socket")
math = require("math")

-- Raft Implementation
local raft = {}

function raft.SetUp(peers, me, verbose)

    -- Insert RPC connection to all peers in remote_peers table
    raft.remote_peers = peers
    raft.me = me

    -- Initialize state values
    raft.currentTerm = 0
    raft.requestVoteTerm = 0
    raft.receivedRequestVote = false
    raft.votingMajority = (#peers / 2) + 1
    raft.votes = 0
    raft.votedFor = nil
    raft.currentState = "follower"
    raft.running = false
    raft.heartbeatReceived = false
    raft.lastHeartbeatTimestamp = 0
    raft.waitingForVotes = false
    raft.peersToRetryRequestVote = {}
    raft.verbose = verbose
    math.randomseed(me.port * os.time())
    raft.randomElectionTimeout = math.random(10,20)
    raft.heartbeatFrequency = 2
    raft.electionStartTimestamp = nil
    raft.raftStartTimestamp = os.time()
    print("Heartbeat timeout: " .. tostring(raft.randomElectionTimeout))

end

function raft.sendHeartbeats()

end

function raft.sendHeartbeats()

end

-- RPC methods
function raft.InitializeNode()
    raft.printState("InitializingNode received")
    raft.running = true
    while true do
        if raft.running then
            raft.printState("Node Running...")
            if raft.receivedRequestVote then
                raft.ProcessRequestVote()
            end
            -- If it is a leader
            if raft.currentState == 'leader' then
                raft.sendHeartbeats()
                luarpc.wait(raft.heartbeatFrequency, false)
			-- If it is a candidate
            elseif raft.currentState == 'candidate' then
                if raft.waitingForVotes then
                    raft.processReceivedVotes()
                else
                    raft.startElection()
                end
                -- Waits for the votes to arrive
                luarpc.wait(math.max(raft.randomElectionTimeout/5, 1), false)
			-- If it is a follower
            elseif raft.currentState == 'follower' then
                raft.heartbeatReceived = false
                raft.printState("Waiting for heartbeat...")
                luarpc.wait(raft.randomElectionTimeout, false)
                -- Se recebeu um Heartbeat, ignora (lider esta vivo)
                -- if not raft.heartbeatReceived then
                --     raft.currentState = 'candidate'
                -- end
                if not raft.heartbeatReceived or (os.time() - raft.lastHeartbeatTimestamp) > raft.randomElectionTimeout then
                    raft.currentState = 'candidate'
                end
            end
        else
            luarpc.wait(raft.heartbeatFrequency, false)
        end
    end
    raft.printState("Node Stopped")
end

function myobj1.ReceiveMessage(st) 
    return 'st.type' 
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
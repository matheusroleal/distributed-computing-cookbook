local obj = require('obj')
local luarpc = require('luarpc')

-- tick interval
local tick_intval_sec = 0.05
local timeout_interval = 5

-- raft object methods
local raft = {}
local raft_nodes = {}

-- Internal functions
function check_election_timeout(timeout_limit)
	return os.time() >= timeout_limit
end

-- Raft functions
function raft:init()
	self.timeout = os.time() + timeout_interval
	self.state = "idle"
	self.alive = true
	self.nodes = {}
	self.server = nil
	self.thread = {}
	self.election_thread = {}
end

function raft:destroy()
	self.alive = false
	if self.main_thread then
		self.main_thread = nil
	end
	if self.election_thread then
		self.election_thread = nil
	end
	self:fin()
end

function raft:reset_timeout()
	self.timeout = os.time() + timeout_interval
end

function raft:run_election()
	self:reset_timeout()
	print('raft', 'start election', myid)
	while self.state == 'candidate' do
		-- Ask for vote
		-- Check if there is all votes necessary --> state = leader
		-- If not, check if got any vote back
		-- If not, find new leader --> state = follower
	end
end

function raft:launch_election()
	self:run_election()
	self.election_thread = nil
end

function raft:tick()
	if self.state == 'follower' then
		if check_election_timeout(self.timeout_limit) then
			print('follower election timeout', self.timeout, os.time())
			if self.state:has_enough_nodes_for_election() then
				-- if election timeout (and has enough node), become candidate
				self.state = 'candidate'
				self:launch_election()
			else
				print('election timeout but # of nodes not enough')
				self.state = 'follower'
			end
		end
	end
end

function raft:start_thread()
	
end

function raft:start()
	self.state = 'follower'
	self:start_thread()
	self:reset_timeout()
	self.main_thread = nil
	while self.alive do
		clock.sleep(tick_intval_sec)
		self:tick()
	end
end

function raft:stop_replicator(target_actor)
	local machine, thread = uuid.addr(target_actor), uuid.thread_id(target_actor)
	local m = self.replicators[machine]
	if m and m[thread] then
		local r = m[thread]
		self.ev_log:emit('stop', r)
		r:fin()
		m[thread] = nil
	end
end

function raft:propose(logs, timeout)
	local l, timeout = self.state:request_routing_id(timeout or self.opts.proposal_timeout_sec)
	if l then return l:propose(logs, timeout) end
	local msgid = router.regist(tentacle.running(), timeout + clock.get())
	-- ...then write log and kick snapshotter/replicator
	self.state:write_logs(msgid, logs)
	-- wait until logs are committed
	return tentacle.yield(msgid)
end

function raft:add_replica_set(replica_set, timeout)
	local l, timeout = self.state:request_routing_id(timeout or self.opts.proposal_timeout_sec)
	if l then return l:add_replica_set(replica_set, timeout) end
	local msgid = router.regist(tentacle.running(), timeout + clock.get())
	-- ...then write log and kick snapshotter/replicator
	self.state:add_replica_set(msgid, replica_set)
	-- wait until logs are committed
	return tentacle.yield(msgid)
end

function raft:remove_replica_set(replica_set, timeout)
	local l, timeout = self.state:request_routing_id(timeout or self.opts.proposal_timeout_sec)
	if l then return l:remove_replica_set(replica_set, timeout) end
	local msgid = router.regist(tentacle.running(), timeout + clock.get())
	-- ...then write log and kick snapshotter/replicator
	self.state:remove_replica_set(msgid, replica_set)
	-- wait until logs are committed
	return tentacle.yield(msgid)
end

function raft:accepted()
	local a = self.state.proposals.accepted
	local ok, r
	for i=1,#a do
		local log = a[i]
		a[i] = nil
		-- proceed commit log index
		self.state:committed(log.index)
		-- apply log and respond to waiter
		for idx=tonumber(self.state:last_applied_index()) + 1, tonumber(log.index) do
			-- logger.info('apply_log', i)
			self:apply_log(self.state.wal:at(idx))
		end
	end
	self.state:kick_replicator()
end

function raft:apply_log(log)
	local ok, r = self.state:apply(log)
	if log.msgid then
		router.respond_by_msgid(log.msgid, ok, r)
	end
end

--[[--
from https://ramcloud.stanford.edu/raft.pdf
--]]--
--[[
Append Entries RPC
1. Reply false if term < currentTerm (§5.1)
2. Reply false if log doesn’t contain an entry at prevLogIndex
whose term matches prevLogTerm (§5.3)
3. If an existing entry conflicts with a new one (same index
but different terms), delete the existing entry and all that
follow it (§5.3)
4. Append any new entries not already in the log
5. If leaderCommit > commitIndex, set commitIndex = min(leaderCommit, index of last new entry)
]]
function raft:append_entries(term, leader, leader_commit_idx, prev_log_idx, prev_log_term, entries)
	local ok, r
	local last_index, last_term = self.state.wal:last_index_and_term()
	if term < self.state:current_term() then
		-- 1. Reply false if term < currentTerm (§5.1)
		print('raft', 'append_entries', 'receive older term', term, self.state:current_term())
		return self.state:current_term(), false, last_index
	end
	-- (part of 2.) If AppendEntries RPC received from new leader: convert to follower
	if term > self.state:current_term() then
		self.state:become_follower()
		self.state:set_term(term)
	end
	-- Save the current leader
	self.state:set_leader(leader)
	-- if prev_log_idx is not set, means heartbeat. return.
	if prev_log_idx and prev_log_idx > 0 then
		-- verify last index and term. this node's log term at prev_log_idx should be same as which leader sent.
		local tmp_prev_log_term
		if prev_log_idx == last_index then
			-- skip access wal 
			tmp_prev_log_term = last_term
		else
			local log = self.state.wal:at(prev_log_idx)
			if not log then
				print('raft', 'fail to get prev log', prev_log_idx)
				return self.state:current_term(), false, last_index	
			end
			tmp_prev_log_term = log.term
		end
		if tmp_prev_log_term ~= prev_log_term then
			-- 2. Reply false if log doesn’t contain an entry at prevLogIndex whose term matches prevLogTerm (§5.3)
			print('raft', 'last term does not match', tmp_prev_log_term, prev_log_term)
			return self.state:current_term(), false, last_index
		end
	end
	-- 3. If an existing entry conflicts with a new one (same index but different terms), 
	-- delete the existing entry and all that follow it (§5.3)
	if entries and #entries > 0 then
		local first, last = entries[1], entries[#entries]
		-- Delete any conflicting entries
		if first.index <= last_index then
			print('raft', 'Clearing log suffix range', first.index, last_index)
			local wal = self.state.wal
			ok, r = pcall(wal.delete_range, wal, first.index, last_index)
			if not ok then
				print('raft', 'Failed to clear log suffix', r)
				return self.state:current_term(), false, last_index
			end
		end

		-- 4. Append any new entries not already in the log
		if not self.state.wal:copy(entries) then
			print('raft', 'Failed to append logs')
			return self.state:current_term(), false, last_index
		end
	end

	-- 5. If leaderCommit > commitIndex, set commitIndex = min(leaderCommit, index of last new entry)
	-- logger.info('commits', leader_commit_idx, self.state:last_commit_index(), self.state:last_applied_index(), self.state:last_index())
	if leader_commit_idx and (leader_commit_idx > self.state:last_commit_index()) then
		local new_last_commit_idx = math.min(tonumber(leader_commit_idx), tonumber(self.state:last_index()))
		self.state:set_last_commit_index(new_last_commit_idx) -- no error check. force set leader value.
		for idx=tonumber(self.state:last_applied_index()) + 1, new_last_commit_idx do
			-- logger.info('apply_log', idx)
			self:apply_log(self.state.wal:at(idx))
		end
	end
	-- reset timeout to prevent election timeout
	self:reset_timeout()
	-- Everything went well, return success
	return self.state:current_term(), true, self.state:last_index()
end
--[[
Request Vote RPC
1. Reply false if term < currentTerm (§5.1)
2. If votedFor is null or candidateId, and candidate’s log is at
least as up-to-date as receiver’s log, grant vote (§5.2, §5.4)
]]
function raft:request_vote(term, candidate_id, cand_last_log_idx, cand_last_log_term)
	print('request_vote from', candidate_id, term)
	local last_index, last_term = self.state.wal:last_index_and_term()
	if term < self.state:current_term() then
		-- 1. Reply false if term < currentTerm (§5.1)
		print('raft', 'request_vote', 'receive older term', term, self.state:current_term())
		return self.state:current_term(), false
	end
	if term > self.state:current_term() then
		self.state:become_follower()
		self.state:set_term(term)
	end
	-- and candidate’s log is at least as up-to-date as receiver’s log, 
	if cand_last_log_idx < last_index then
		print('raft', 'request_vote', 'log is not up-to-date', cand_last_log_idx, last_index)
		return self.state:current_term(), false		
	end
	if cand_last_log_term < last_term then
		print('raft', 'request_vote', 'term is not up-to-date', cand_last_log_term, last_term)
		return self.state:current_term(), false		
	end
	-- 2. If votedFor is null or candidateId, 
	if not self.state:vote_for(candidate_id, term) then
		print('raft', 'request_vote', 'already vote', v, candidate_id, term)
		return self.state:current_term(), false
	end
	-- grant vote (§5.2, §5.4)
	print('raft', 'request_vote', 'vote for', candidate_id, term)
	return self.state:current_term(), true
end

function raft:install_snapshot(term, leader, last_snapshot_index, fd)
	-- Ignore an older term
	if term < self.state:current_term() then
		print('raft', 'install_snapshot', 'receive older term', term, self.state:current_term())
		return
	end
	-- Increase the term if we see a newer one
	if term > self.state:current_term() then
		self.state:become_follower()
		self.state:set_term(term)
	end
	-- Save the current leader
	self.state:set_leader(leader)
	-- Spill the remote snapshot to disk
	local ok, rb = pcall(self.snapshot.copy, self.snapshot, fd, last_snapshot_index) 
	if not ok then
		self.snapshot:remove_tmp()
		print("raft", 'install_snapshot', "Failed to copy snapshot", rb)
		return
	end
	-- Restore snapshot
	self.state:restore_from_snapshot(rb)
	-- Update the lastApplied so we don't replay old logs
	self.state.last_applied_idx = last_snapshot_index
	-- Compact logs, continue even if this fails
	self.state.wal:compaction(last_snapshot_index)
	-- reset timeout to prevent election timeout
	self:reset_timeout()
	print("raft", 'install_snapshot', "Installed remote snapshot")
	return true
end

return raft
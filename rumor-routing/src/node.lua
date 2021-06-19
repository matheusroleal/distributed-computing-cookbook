local node = {}

math.randomseed(os.time())

function node.create(neighbors_channel)
    my_node = {}
    my_node.id = math.random(0,1000)
    my_node.channels = neighbors_channel
    my_node.neighbors = {}
    my_node.events = {}
    return my_node
end

function node.new_neighbor(neighbors, neighbor)
    local f = true
    for i = 1, #neighbors do
        if type( neighbors[i] ) == "table" then
            f = node.new_neighbor( neighbors[i], neighbor )  --  return value from recursion
            if f then break end  --  if it returned true, break out of loop
        elseif neighbors[i] == neighbor then
            return false
        end
    end
    return f
end

function node.add_neighbor(neighbors, neighbor)
    table.insert(neighbors, neighbor)
end

function node.get_current_distance(events, event)
    local f = true
    for i = 1, #events do
        if type( events[i] ) == "table" then
            f = node.new_neighbor( events[i], event )  --  return value from recursion
            if f then break end  --  if it returned true, break out of loop
        elseif events[i] == event then
            return events[i].distance
        end
    end
    return 0
end

function node.new_event(events, event)
    local f = true
    for i = 1, #events do
        if type( events[i] ) == "table" then
            f = node.new_neighbor( events[i], event )  --  return value from recursion
            if f then break end  --  if it returned true, break out of loop
        elseif events[i] == event then
            return false
        end
    end
    return f
end

function node.event_detected(my_node, event_id, channel, distance)
    event = {}
    event.distance = distance
    event.id = event_id
    event.channel = channel
    table.insert(my_node.events, event)
end

function node.agentReceived(my_node, agent, source)
    agent.num_hops = agent.num_hops + 1
    -- update the node's events table based on the agent's
    for e in pairs(agent.events) do
        if not (my_node.events[e]) or (my_node.events[e].num_hops > agent.events[e]) then
            my_node.events[e].distance = agent.num_hops - agent.events[e].visit_time
            agent.events[e].direction = source
        end
    end
    -- update the agent's events table based on the node's
    for e in pairs(my_node.events) do
        agent.events[e].visit_time = (- my_node.events[e].distance)
    end
    if agent.num_hops < agent_ttl then
        -- destination = pick neighbor based on agent forwarding policy
        forwardAgent(agent, destination)
    end
end

function node.queryReceived(my_node, query, source)
    query.ttl = query.ttl - 1
    -- the query reached a valid destination
    if my_node.events[query.event_name].distance == 0 then
        handleValidQuery(query)
    -- the node has a path to the event
    elseif my_node.events[query.event_name].distance > 0 then
        forwardQuery(query, my_node.events[query.event_name].direction)
    else
        -- destination = pick neighbor based on query forwarding policy
        forwardQuery(query, destination)
    end
end

return node
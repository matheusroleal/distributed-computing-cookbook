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
    for i in pairs(events) do
        e = events[i]
        if e.id == event then
            return events[i].distance
        end
    end
    return nil
end

function node.get_event(events, event)
    for i in pairs(events) do
        e = events[i]
        if e.id == event then
            return events[i]
        end
    end
    return nil
end

function node.new_event(events, event)
    for i in pairs(events) do
        e = events[i]
        if e.id == event then
            return false
        end
    end
    return true
end

function node.generate_next_node(neighbors, track)
    for n in pairs(neighbors) do
        neighbor = neighbors[n]
        if node.new_neighbor(track, neighbor) then
            return neighbor
        end
    end
    return nil
end

function node.add_event_track(track, segment)
    table.insert(track, segment)
end

function node.event_detected(my_node, event_id, channel, distance, ttl, next_node, track)
    my_event = {}
    my_event.distance = distance
    my_event.id = event_id
    my_event.channel = channel
    my_event.ttl = ttl
    my_event.next_node = next_node
    my_event.track = track
    table.insert(my_node.events, my_event)
end

return node
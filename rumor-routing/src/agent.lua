local agent = {}

math.randomseed(os.time())

function agent.add_track(track, node)
    table.insert(track, node)
end

function agent.add_channel(channels, channel)
    table.insert(channels, channel)
end

function agent.new_channel(channels, channel)
    local f = true
    for i = 1, #channels do
        if type( channels[i] ) == "table" then
            f = agent.new_channel( channels[i], channel )  --  return value from recursion
            if f then break end  --  if it returned true, break out of loop
        elseif channels[i] == channel then
            return false
        end
    end
    return f
end

function agent.create(node_id, event, track)
    my_agent = {}
    my_agent.id = node_id
    my_agent.track = {}
    my_agent.channels = {}
    my_agent.event = event
    return my_agent
end

return agent
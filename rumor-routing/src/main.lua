local log = require("log")
local node = require("node")
local json = require ("json")
local agent = require("agent")
local button = require("button")
local mqtt = require("mqtt_library")

math.randomseed(os.time())
first_data_received_search_1 = true
first_data_received_search_2 = true
--
-- LOCAL FUNCTIONS
--
function str_split(inputstr, sep)
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

function splitByChunk(str_text, chunkSize)
  local s = {}
  for i=1, #str_text, chunkSize do
      s[#s+1] = str_text:sub(i,i+chunkSize - 1)
  end
  return s
end

function update_console_log(node_id, message)
  if (logs_size + 1) > 10 then
    logs_size = 0
    text = ""
  end
  if string.len(message) > 40 then
    chunks_log = splitByChunk(message, 45)
    for i,v in ipairs(chunks_log) do
      text = text .. v .. "\n"
      logs_size = logs_size + 1
    end
  else
    text = text .. message .. "\n"
    logs_size = logs_size + 1
  end
  log.write_log_file(node_id, message)
end

function mqtt_request_message(node, id, method)
  local request_message = {}
  request_message['method'] = method
  request_message['node'] = node
  request_message['id'] = id
  return request_message
end

function mqttcb(topic, message)
  local data_received = json.decode(message)
  if not (n.id == data_received['id']) then
    -- message hello for new node
    if data_received['method'] == "hello" and node.new_neighbor(n.neighbors, data_received['id']) then
      -- add neighbor to node
      node.add_neighbor(n.neighbors, data_received['id'])
      -- send hello message back to neighbor
      data = mqtt_request_message(n, n.id, data_received['method'])
      mqtt_client:publish(topic, json.encode(data))
      -- send message to console
      message_log =  "Node " .. data_received['id'] .. " became a neighbor"
      update_console_log(n.id, message_log)
    -- message for event 1
    elseif data_received['method'] == "evento_1" and node.new_event(n.events, data_received['method']) then
      local current_event = node.get_event(data_received['node'].events, data_received['method'])
      if current_event.ttl > 0 and current_event.next_node == n.id then
        -- add new event
        node.add_event_track(current_event.track, current_event.next_node)
        local next_node = node.generate_next_node(n.neighbors, current_event.track)
        if not (next_node == nil) then
          node.event_detected(n, data_received['method'], topic, current_event.distance + 1, current_event.ttl - 1, next_node, current_event.track)
          -- send message to other channels
          for c in pairs(n.channels) do
            channel = n.channels[c]
            if not (channel == topic) then
              data = mqtt_request_message(n, n.id, data_received['method'])
              mqtt_client:publish(channel, json.encode(data))
            end
          end
          -- send message to console
          message_log =  "Node " .. data_received['id'] .. " sent " .. data_received['method']
          update_console_log(n.id, message_log)
        end
      end
    -- message for event 2
    elseif data_received['method'] == "evento_2" and node.new_event(n.events, data_received['method']) then
      local current_event = node.get_event(data_received['node'].events, data_received['method'])
      if current_event.ttl > 0 and current_event.next_node == n.id then
        -- add new event
        node.add_event_track(current_event.track, current_event.next_node)
        local next_node = node.generate_next_node(n.neighbors, current_event.track)
        if not (next_node == nil) then
          node.event_detected(n, data_received['method'], topic, current_event.distance + 1, current_event.ttl - 1, next_node, current_event.track)
          -- send message to other channels
          for c in pairs(n.channels) do
            channel = n.channels[c]
            if not (channel == topic) then
              data = mqtt_request_message(n, n.id, data_received['method'])
              mqtt_client:publish(channel, json.encode(data))
            end
          end
          -- send message to console
          message_log =  "Node " .. data_received['id'] .. " sent " .. data_received['method']
          update_console_log(n.id, message_log)
        end
      end
    -- event 1 query message
    elseif data_received['method'] == "consulta_1" and agent.new_channel(data_received['node'].channels, topic) and node.get_current_distance(n.events, data_received['node'].event) then
      if node.get_current_distance(n.events, data_received['node'].event) > 0 then
        for c in pairs(n.channels) do
          channel = n.channels[c]
          if not (channel == topic) then
            agent.add_channel(data_received['node'].channels, topic)
            agent.add_track(data_received['node'].track, n.id)
            data = mqtt_request_message(data_received['node'], n.id, data_received['method'])
            mqtt_client:publish(channel, json.encode(data))
          end
        end
      else
        print("cheguei")
        agent.add_channel(data_received['node'].channels, topic)
        agent.add_track(data_received['node'].track, n.id)
        -- send message to console
        message_log =  "Returning request for event 1"
        update_console_log(n.id, message_log)
        -- returning query request
        data_received['node'].channels = {}
        data = mqtt_request_message(data_received['node'], n.id, "resposta_consulta_1")
        for c in pairs(n.channels) do
          channel = n.channels[c]
          mqtt_client:publish(channel, json.encode(data))
        end
      end
    -- event 2 query message
    elseif data_received['method'] == "consulta_2" and agent.new_channel(data_received['node'].channels, topic) and node.get_current_distance(n.events, data_received['node'].event) then
      if node.get_current_distance(n.events, data_received['node'].event) > 0 then
        for c in pairs(n.channels) do
          channel = n.channels[c]
          if not (channel == topic) then
            agent.add_channel(data_received['node'].channels, topic)
            agent.add_track(data_received['node'].track, n.id)
            data = mqtt_request_message(data_received['node'], n.id, data_received['method'])
            mqtt_client:publish(channel, json.encode(data))
          end
        end
      else
        print("cheguei")
        agent.add_channel(data_received['node'].channels, topic)
        agent.add_track(data_received['node'].track, n.id)
        -- send message to console
        message_log =  "Returning request for event 2"
        update_console_log(n.id, message_log)
        -- returning query request
        data_received['node'].channels = {}
        data = mqtt_request_message(data_received['node'], n.id, "resposta_consulta_2")
        for c in pairs(n.channels) do
          channel = n.channels[c]
          mqtt_client:publish(channel, json.encode(data))
        end
      end
    -- event 1 query return message
    elseif data_received['method'] == "resposta_consulta_1" and agent.new_channel(data_received['node'].channels, topic) then
      if n.id == data_received['node'].id and first_data_received_search_1 then
        first_data_received_search_1 = false
        -- send message to console
        message_log =  "Got the following track for event 1 " .. json.encode(data_received['node'].track)
        update_console_log(n.id, message_log)
      else
        for c in pairs(n.channels) do
          channel = n.channels[c]
          if not (channel == topic) and agent.new_channel(data_received['node'].channels, topic) and node.get_current_distance(n.events, data_received['node'].event) then
            agent.add_channel(data_received['node'].channels, topic)
            data = mqtt_request_message(data_received['node'], n.id, data_received['method'])
            mqtt_client:publish(channel, json.encode(data))
          end
        end
      end
    -- event 2 query return message
    elseif data_received['method'] == "resposta_consulta_2" and agent.new_channel(data_received['node'].channels, topic) then
      if n.id == data_received['node'].id and first_data_received_search_2 then
        first_data_received_search_2 = false
        -- send message to console
        message_log =  "Got the following track for event 2 " .. json.encode(data_received['node'].track)
        update_console_log(n.id, message_log)
      else
        for c in pairs(n.channels) do
          channel = n.channels[c]
          if not (channel == topic) and agent.new_channel(data_received['node'].channels, topic) and node.get_current_distance(n.events, data_received['node'].event) then
            agent.add_channel(data_received['node'].channels, topic)
            data = mqtt_request_message(data_received['node'], n.id, data_received['method'])
            mqtt_client:publish(channel, json.encode(data))
          end
        end
      end
    end
  end
end

-- reuse code for multiples servers
if #arg < 1 then
  print("Error: missing argument(s).\nUsage: love src [channels]")
  os.exit()
end

channels = str_split(arg[2], ",")

--
-- LOVE ENVIROMENT
--
function love.mousepressed(x, y)
  if button.click(x, y, bt1) then
    local next_node = node.generate_next_node(n.neighbors, {})
    node.event_detected(n, "evento_1", n.channels, 0, 3, next_node, {n.id})
    -- send event message to neighbors
    data = mqtt_request_message(n, n.id, "evento_1")
    for c in pairs(n.channels) do
      channel = n.channels[c]
      mqtt_client:publish(channel, json.encode(data))
    end
  elseif button.click(x, y, bt2) then
    local next_node = node.generate_next_node(n.neighbors, {})
    node.event_detected(n, "evento_2", n.channels, 0, 3, next_node, {n.id})
    -- send event message to neighbors
    data = mqtt_request_message(n, n.id, "evento_2")
    for c in pairs(n.channels) do
      channel = n.channels[c]
      mqtt_client:publish(channel, json.encode(data))
    end
  elseif button.click(x, y, bt3) then
    -- create agent to search for event 1
    a = agent.create(n.id, "evento_1", {})
    -- send message to all neighbors
    data = mqtt_request_message(a, n.id, "consulta_1")
    for c in pairs(n.channels) do
      channel = n.channels[c]
      agent.add_track(a.track, n.id)
      mqtt_client:publish(channel, json.encode(data))
    end
    -- send message to console
    message_log =  "Checking for the event 1"
    update_console_log(n.id, message_log)
  elseif button.click(x, y, bt4) then
    -- create agent to search for event 2
    a = agent.create(n.id, "evento_2", {})
    -- send message to all neighbors
    data = mqtt_request_message(a, n.id, "consulta_2")
    for c in pairs(n.channels) do
      channel = n.channels[c]
      agent.add_track(a.track, n.id)
      mqtt_client:publish(channel, json.encode(data))
    end
    -- send message to console
    message_log =  "Checking for the event 2"
    update_console_log(n.id, message_log)
  elseif button.click(x, y, bt5) then
    -- send message to console
    message_log = json.encode(n)
    update_console_log(n.id, message_log)
  end
end

function love.load()
  -- initialize buttons
  bt1 = button.create("evento 1", 5, 35, 75, 60)
  bt2 = button.create("evento 2", 83.5, 35, 75, 60)
  bt3 = button.create("consulta 1", 162.5, 35, 75, 60)
  bt4 = button.create("consulta 2", 241, 35, 75, 60)
  bt5 = button.create("estado", 320, 35, 75, 60)
  -- initialize node
  n = node.create(channels)
  -- setup mqtt connection
  client_id = "cliente_mqtt_" .. n.id
  mqtt_client = mqtt.client.create("localhost", 1883, mqttcb)
  -- initialize logs
  text = ""
  logs_size = 0
  log.initialize_log(n.id)
  -- initialize mqtt connection
  for c in pairs(n.channels) do
    channel = n.channels[c]
    mqtt_client:connect(client_id)
    mqtt_client:subscribe({channel})
    -- send hello message to neighbors
    data = mqtt_request_message(n, n.id, "hello")
    mqtt_client:publish(channel, json.encode(data))
    print(client_id .. " started on " .. channel)
  end
end

function love.draw()
  -- draw Background
  love.graphics.setColor(0.92,0.93,0.93)
  love.graphics.rectangle("fill", 4, 4, 392, 292)
  -- draw buttons
  button.draw(0.18, 0.8, 0.443, bt1.x, bt1.y, bt1.width, bt1.height, bt1.text)
  button.draw(0.18, 0.8, 0.443, bt2.x, bt2.y, bt2.width, bt2.height, bt2.text)
  button.draw(0.2, 0.596, 0.86, bt3.x, bt3.y, bt3.width, bt3.height, bt3.text)
  button.draw(0.2, 0.596, 0.86, bt4.x, bt4.y, bt4.width, bt4.height, bt4.text)
  button.draw(0.96, 0.69, 0.255, bt5.x, bt5.y, bt5.width, bt5.height, bt5.text)
  -- draw console
  love.graphics.print("log", 20, 110)
  love.graphics.setColor(0.337,0.396,0.45)
  love.graphics.rectangle("fill", 20, 130, 360, 150)
  -- draw logs
  love.graphics.setColor(0.92,0.93,0.93)
  love.graphics.print(text, 20, 130)
end

function love.update(dt)
  mqtt_client:handler()
end

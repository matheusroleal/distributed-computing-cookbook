local log = require("log")
local node = require("node")
local json = require ("json")
local button = require("button")
local mqtt = require("mqtt_library")

math.randomseed(os.time())

function update_console_log(node_id, message)
  if (logs_size + 1) > 10 then
    logs_size = 0
    text = ""
  end
  text = text .. message .. "\n"
  logs_size = logs_size + 1
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
    if data_received['method'] == "hello" and node.new_neighbor(n.neighbors, data_received['id']) then
      node.add_neighbor(n.neighbors, data_received['id'])
      message_log =  "Node " .. data_received['id'] .. " became a neighbor"
      -- Envia mensagem hello de volta para o vizinho
      data = mqtt_request_message(n, n.id, data_received['method'])
      mqtt_client:publish(topic, json.encode(data))
      update_console_log(n.id, message_log)
    elseif data_received['method'] == "evento_1" then
      node.event_detected(n, data_received['method'], topic)
      message_log =  "Node " .. data_received['id'] .. " sent " .. data_received['method']
      update_console_log(n.id, message_log)
    elseif data_received['method'] == "evento_2" then
      node.event_detected(n, data_received['method'], topic)
      message_log =  "Node " .. data_received['id'] .. " sent " .. data_received['method']
      update_console_log(n.id, message_log)
    end
  end
end

function love.mousepressed(x, y)
  if button.click(x, y, bt1) then
    data = mqtt_request_message(n, n.id, "evento_1")
    for c in pairs(n.channels) do
      channel = n.channels[c]
      mqtt_client:publish(channel, json.encode(data))
    end
  elseif button.click(x, y, bt2) then
    data = mqtt_request_message(n, n.id, "evento_2")
    for c in pairs(n.channels) do
      channel = n.channels[c]
      mqtt_client:publish(channel, json.encode(data))
    end
  elseif button.click(x, y, bt3) then
    message_log =  "Checking for the event"
    update_console_log(n.id, message_log)
  elseif button.click(x, y, bt4) then
    message_log = json.encode(data)
    update_console_log(n.id, message_log)
  end
end

function love.load()
  channels = {"controle"}
  -- Inicializa botões
  bt1 = button.create("evento 1", 20, 35, 75, 60)
  bt2 = button.create("evento 2", 115, 35, 75, 60)
  bt3 = button.create("consulta", 210, 35, 75, 60)
  bt4 = button.create("estado", 305, 35, 75, 60)
  -- Inicia nó
  n = node.create(channels)
  -- Setup conexão mqtt
  client_id = "cliente_mqtt_" .. n.id
  mqtt_client = mqtt.client.create("localhost", 1883, mqttcb)
  -- Inicializa logs
  text = ""
  logs_size = 0
  log.initialize_log(n.id)
  for c in pairs(n.channels) do
    channel = n.channels[c]
    mqtt_client:connect(client_id)
    -- Inicia conexão mqtt
    mqtt_client:subscribe({channel})
    -- Envia mensagem de hello para os vizinhos
    data = mqtt_request_message(n, n.id, "hello")
    mqtt_client:publish(channel, json.encode(data))
    print(client_id .. " started on " .. channel)
  end
end

function love.draw()
  -- Desenha Fundo
  love.graphics.setColor(0.92,0.93,0.93)
  love.graphics.rectangle("fill", 4, 4, 392, 292)
  -- Desenha Botões
  button.draw(0.18, 0.8, 0.443, bt1.x, bt1.y, bt1.width, bt1.height, bt1.text)
  button.draw(0.18, 0.8, 0.443, bt2.x, bt2.y, bt2.width, bt2.height, bt2.text)
  button.draw(0.2, 0.596, 0.86, bt3.x, bt3.y, bt3.width, bt3.height, bt3.text)
  button.draw(0.96, 0.69, 0.255, bt4.x, bt4.y, bt4.width, bt4.height, bt4.text)
  -- Desenha Caixa de Log 
  love.graphics.print("log", 20, 110)
  love.graphics.setColor(0.337,0.396,0.45)
  love.graphics.rectangle("fill", 20, 130, 360, 150)
  -- Desenha Logs
  love.graphics.setColor(0.92,0.93,0.93)
  love.graphics.print(text, 20, 130)
end

function love.update(dt)
  mqtt_client:handler()
end

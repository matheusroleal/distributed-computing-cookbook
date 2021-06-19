local json = require "json"
local mqtt = require("mqtt_library")
local button = require("button")
local node = require("node")

math.randomseed(os.time())

function exibe_no_log(message)
  if (logs_size + 1) > 10 then
    logs_size = 0
    text = ""
  end
  text = text .. message
  logs_size = logs_size + 1
end

function mqttcb(topic, message)
  local data_received = json.decode(message)
  if not (n.id == data_received['id']) then
    if data_received['method'] == "hello" then
      node.addNeighbor(n.neighbors, data_received['id'])
      message_log =  "Node " .. data_received['id'] .. " became a neighbor\n"
    elseif data_received['method'] == "evento_1" then
      node.eventDetected(n, data_received['method'], topic)
      message_log =  "Node " .. data_received['id'] .. " sent " .. data_received['method'] .. "\n"
    elseif data_received['method'] == "evento_2" then
      node.eventDetected(n, data_received['method'], topic)
      message_log =  "Node " .. data_received['id'] .. " sent " .. data_received['method'] .. "\n"
    end
    -- Imprime mensagem no log
    exibe_no_log(message_log)
  end
end

function love.mousepressed(x, y)
  data = {}
  data['node'] = n
  data['id'] = n.id
  if button.click(x, y, bt1) then
    data['method'] = "evento_1"
    mqtt_client:publish("controle", json.encode(data))
  elseif button.click(x, y, bt2) then
    data['method'] = "evento_2"
    mqtt_client:publish("controle", json.encode(data))
  elseif button.click(x, y, bt3) then
    message_log =  "Checking for the event\n"
    exibe_no_log(message_log)
  elseif button.click(x, y, bt4) then
    message_log = json.encode(data)
    exibe_no_log(message_log)
  end
end

function love.load()
  channels = {"controle"}
  -- Inicializa botões
  bt1 = button.create("evento 1", 20, 35, 75, 60)
  bt2 = button.create("evento 2", 115, 35, 75, 60)
  bt3 = button.create("consulta", 210, 35, 75, 60)
  bt4 = button.create("estado", 305, 35, 75, 60)
  -- Inicializa logs
  text = ""
  logs_size = 0
  -- Inicia nó
  n = node.create(channels)
  -- Setup conexão mqtt
  client_id = "cliente_mqtt_" .. n.id
  mqtt_client = mqtt.client.create("localhost", 1883, mqttcb)
  for c in pairs(n.channels) do
    channel = n.channels[c]
    print(channel)
    mqtt_client:connect(client_id)
    -- Inicia conexão mqtt
    mqtt_client:subscribe({channel})
    -- Envia mensagem de hello para os vizinhos
    data = {}
    data['method'] = "hello"
    data['node'] = n
    data['id'] = n.id
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

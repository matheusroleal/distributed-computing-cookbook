local mqtt = require("mqtt_library")
local button = require("button")

math.randomseed(os.time())

function mqttcb(topic, message)
  if (logs_size + 1) > 10 then
    logs_size = 0
    text = ""
  end
  text = text .. message
  logs_size = logs_size + 1
  if message == "a" then 
    controle = not controle
  end
end

function love.mousepressed(x, y)
  if (logs_size + 1) > 10 then
    logs_size = 0
    text = ""
  end
  if button.click(x, y, bt1) then
    mqtt_client:publish("controle", "pressionou botao evento 1 \n")
  end
  if button.click(x, y, bt2) then
    mqtt_client:publish("controle", "pressionou botao evento 2 \n")
  end
  if button.click(x, y, bt3) then
    mqtt_client:publish("controle", "pressionou botao consulta \n")
  end
  if button.click(x, y, bt4) then
    mqtt_client:publish("controle", "pressionou botao evento \n")
  end
end

function love.load()
  -- Inicializa botões
  bt1 = button.create("evento 1", 20, 35, 75, 60)
  bt2 = button.create("evento 2", 115, 35, 75, 60)
  bt3 = button.create("consulta", 210, 35, 75, 60)
  bt4 = button.create("evento", 305, 35, 75, 60)
  -- Inicializa logs
  text = ""
  logs_size = 0
  -- Inicia conexão mqtt
  client_id = "cliente_mqtt_" .. math.random()
  mqtt_client = mqtt.client.create("localhost", 1883, mqttcb) 
  mqtt_client:connect(client_id)
  mqtt_client:subscribe({"controle"})
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

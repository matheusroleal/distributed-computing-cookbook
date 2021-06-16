button = require("button")

function love.mousepressed(x, y)
  if (logs_size + 1) > 10 then
    logs_size = 0
    text = ""
  end
  if button.click(x, y, bt1) then
    text = text .. "pressionou botao evento 1 \n"
    logs_size = logs_size + 1
  end
  if button.click(x, y, bt2) then
    text = text .. "pressionou botao evento 2 \n"
    logs_size = logs_size + 1
  end
  if button.click(x, y, bt3) then
    text = text .. "pressionou botao consulta \n"
    logs_size = logs_size + 1
  end
  if button.click(x, y, bt4) then
    text = text .. "pressionou botao evento \n"
    logs_size = logs_size + 1
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
end

function love.draw()
  -- Desenha Fundo
  love.graphics.setColor(0.92,0.93,0.93)
  love.graphics.rectangle("fill", 4, 4, 392, 292)
  -- Desenha Botão de Evento 1
  button.draw(0.18, 0.8, 0.443, bt1.x, bt1.y, bt1.width, bt1.height, bt1.text)
  -- Desenha Botão de Evento 2
  button.draw(0.18, 0.8, 0.443, bt2.x, bt2.y, bt2.width, bt2.height, bt2.text)
  -- Desenha Botão de Consulta
  button.draw(0.2, 0.596, 0.86, bt3.x, bt3.y, bt3.width, bt3.height, bt3.text)
  -- Desenha Botão de Estado
  button.draw(0.96, 0.69, 0.255, bt4.x, bt4.y, bt4.width, bt4.height, bt4.text)
  -- Desenha Caixa de Log 
  love.graphics.print("log", 20, 110)
  love.graphics.setColor(0.337,0.396,0.45)
  love.graphics.rectangle("fill", 20, 130, 360, 150)
  -- Desenha Logs
  love.graphics.setColor(0, 0, 0)
  love.graphics.print(text, 20, 130)

end

function love.update(dt)

end

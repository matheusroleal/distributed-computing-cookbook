local button = {}

function button.create(text, x, y, width, height)
	my_button = {}
	my_button.text = text
	my_button.x = x
	my_button.y = y
	my_button.width = width
	my_button.height = height
	return my_button
end

function button.draw(r, g, b, x, y, width, height, text)
    love.graphics.setColor(r, g, b)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(text, x + 10, y + 5)
end

function button.click(x, y, my_button)
	if x > my_button.x and x < my_button.x + my_button.width and y > my_button.y and y < my_button.y + my_button.height then
		return true
	end
	return false
end

return button
require "game.classes.text"

MenuText = Class{__includes = Text}
local BIRD = love.graphics.newImage("data/graphics/resources/menu_bird.png")

local FONT = love.graphics.newFont("data/graphics/resources/Adobe_Heiti.otf",35)

function MenuText:init(text,x,y,bx,length)
	self.text = text
	self.len = length
	self.x = x
	self.y = y
	self.bx = bx 	-- x-coord for bird position
	self.alpha = 0
	self.visible = false
end

function MenuText:draw()
	if self.visible then
		love.graphics.setFont(FONT)

		if self:on(love.mouse.getPosition()) then
			love.graphics.setColor(1,130/255,7/255,self.alpha)
			love.graphics.printf(self.text, self.x, self.y, self.len, "right")
			love.graphics.setColor(1,1,1,self.alpha)
			love.graphics.draw(BIRD, self.bx, self.y)
		else
			love.graphics.setColor(1,1,1,self.alpha)
			love.graphics.printf(self.text, self.x, self.y, self.len, "right")
		end

		love.graphics.setColor(1,1,1,1)
		love.graphics.setNewFont(10)
	end
end

return MenuText
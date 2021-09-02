require "game.classes.scorebutton"

ScoreButtonBig = Class{__includes = ScoreButton}
local FONT = love.graphics.newFont("data/graphics/resources/Adobe_Heiti.otf",30)

function ScoreButtonBig:init(x,y,width,height,text)
	self.x = x
	self.y = y
	self.width = width
	self.height = height
	self.text = text and text or "Button"
	self.visible = false
end

function ScoreButtonBig:draw()
	if self.visible then
		if self:on(love.mouse.getPosition()) then
			love.graphics.setColor(180/255,180/255,180/255,0.5)
		else
			love.graphics.setColor(150/255,150/255,150/255,0.5)
		end
		love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

		love.graphics.setFont(FONT)
		love.graphics.setColor(1,1,1,1)
		love.graphics.print(self.text, self.x+30, self.y + 70)
		love.graphics.setNewFont(10)
	end
end

return ScoreButtonBig
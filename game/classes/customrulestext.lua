require "game.classes.text"

CustomRulesText = Class{__includes = Text}
local FONT = love.graphics.newFont("data/graphics/resources/Adobe_Heiti.otf",35)

function CustomRulesText:init(text,x,y)
	self.text = text
	self.len = (#text + 1) * 16
	self.x = x
	self.y = y
	self.alpha = 0
	self.gray = true
	self.visible = false
end

function CustomRulesText:draw()
	if self.visible then
		love.graphics.setFont(FONT)

		if self.gray then
			love.graphics.setColor(149/255,149/255,149/255,self.alpha)
			love.graphics.print(self.text, self.x, self.y)
		else
			love.graphics.setColor(1,1,1,self.alpha)
			love.graphics.print(self.text, self.x, self.y)
		end

		love.graphics.setColor(1,1,1,1)
		love.graphics.setNewFont(10)
	end
end

function CustomRulesText:toDefault()
	self.alpha = 0
	self.gray = true
	self.visible = false
end

return CustomRulesText
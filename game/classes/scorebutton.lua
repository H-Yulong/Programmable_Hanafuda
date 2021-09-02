ScoreButton = Class{}

local FONT = love.graphics.newFont("data/graphics/resources/Adobe_Heiti.otf",30)

function ScoreButton:init(x,y,width,height,text1,text2)
	self.x = x
	self.y = y
	self.width = width
	self.height = height
	self.text1 = text1 and text1 or "Button"
	self.text2 = text2 and text2 or " "
	self.visible = false
end

function ScoreButton:draw()
	if self.visible then
		if self:on(love.mouse.getPosition()) then
			love.graphics.setColor(180/255,180/255,180/255,0.5)
		else
			love.graphics.setColor(150/255,150/255,150/255,0.5)
		end
		love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

		love.graphics.setFont(FONT)
		love.graphics.setColor(1,1,1,1)
		love.graphics.print(self.text1, self.x+7, self.y+5)
		love.graphics.print(self.text2, self.x+7, self.y+40)
		love.graphics.setNewFont(10)
	end
end

function ScoreButton:on(x,y)
	return (x >= self.x) and (y >= self.y) and 
		(x <= self.x+self.width) and (y <= self.y+self.height)
end

function ScoreButton:update(dt)
end	

return ScoreButton



Text = Class{}

local timer = Timer.new()

local FONT = love.graphics.newFont("data/graphics/resources/Adobe_Heiti.otf",35)

function Text:init(text,x,y,length)
	self.text = text
	self.len = length and length or (#text + 1) * 16
	self.x = x
	self.y = y
	self.alpha = 0
	self.visible = false
end

function Text:draw()
	if self.visible then
		love.graphics.setFont(FONT)
		love.graphics.setColor(1,1,1,self.alpha)
		love.graphics.print(self.text, self.x, self.y)
		love.graphics.setColor(1,1,1,1)
		love.graphics.setNewFont(10)
	end
end

function Text:update(dt)
	timer:update(dt)
end

function Text:on(x,y)
	return (x > self.x - 10) and (x <= self.x + self.len) and (y > self.y) and (y <= self.y + 42)
end

function Text:fadeIn(duration)
	self.alpha = 0
	timer:tween(duration,self,{alpha = 1})
end

function Text:fadeOut(duration)
	self.alpha = 1
	timer:tween(duration,self,{alpha = 0}, "linear")
end

function Text:toDefault()
	self.alpha = 0
	self.visible = false
end
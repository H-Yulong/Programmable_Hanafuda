Avatar = Class{}

local timer = Timer.new()

function  Avatar:init(x,y,path)
	self.x = x
	self.y = y
	self.img = love.graphics.newImage(path)
end

function Avatar:draw()
	love.graphics.draw(self.img, self.x, self.y)
end

function Avatar:on(x,y)
	return (x >= self.x - 5) and (y >= self.y - 5)
			and (x <= self.x + 135) and (y <= self.y + 225)
end

function Avatar:update(dt)
	timer.update(dt)
end

return Avatar
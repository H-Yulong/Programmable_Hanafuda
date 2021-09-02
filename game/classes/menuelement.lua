MenuElement = Class{}
local timer = Timer.new()

function MenuElement:init(path,x,y,isGround)
	self.img = love.graphics.newImage(path)
	self.x, self.y = x,y
	self.width, self.height = self.img:getPixelDimensions()
	
	self.alpha = 1

	self.visible = false
	
	self.bouncy = false
	self.bouncing = true
	self.bounce_vertical = false

	if isGround then self:groundInit() end
end

function MenuElement:draw()
	if self.visible then
		love.graphics.setColor(1,1,1,self.alpha)
		love.graphics.draw(self.img, self.x, self.y)
		love.graphics.setColor(1,1,1,1)
	end
end

function MenuElement:update(dt)
	timer:update(dt)
	if self.bouncy then
		if (not self.bouncing) and self:on(love.mouse.getPosition()) then
			self:bounce(self.bounce_vertical)
		elseif self.bouncing and not(self:on(love.mouse.getPosition())) then
			self.bouncing = false
		end
	end
end

function MenuElement:fadeIn(duration)
	self.visible = true
	self.alpha = 0
	timer:tween(duration, self,{alpha = 1}, "out-quart")
end

function MenuElement:on(x,y)
	return (x > self.x) and (x <= self.x + self.width) and (y > self.y) and (y <= self.y + self.height)
end

function MenuElement:bounce(vertical)
	self.bouncing = true
	if vertical then
		timer:tween(1, self, {y = self.y-5}, "in-back", 
			function() 
				timer:tween(1, self, {y = self.y+5}, "out-back")
			end
		)
	else
		timer:tween(1, self, {x = self.x+10}, "in-back", 
			function() 
				timer:tween(1, self, {x = self.x-10}, "out-back")
			end
		)
	end
end

function MenuElement:groundOn(x,y)
	if (x <= 1014) then
		return (x > self.x) and (x <= self.x + self.width) and (y > self.y) and (y <= self.y + self.height)
	else
		return (x > self.x) and (x <= self.x + self.width) and (y > 600) and (y <= 720)
 	end
end


function MenuElement:groundInit()
	self.bounce_vertical = true
	self.on = self.groundOn
end


function MenuElement:toDefault()
	self.alpha = 1
	self.visible = false
	self.bouncy = false
	self.bouncing = true
end

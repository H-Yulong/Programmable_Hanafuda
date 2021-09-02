Card = Class{}
local SHINE = love.graphics.newImage("data/graphics/cards/shine.png")
local timer = Timer.new()

function Card:init(path)
	self.img = love.graphics.newImage(path)
	self.x = 0
	self.y = 0	
	self.sx = 1
	self.sy = 1
	self.ox = 0
	self.oy = 0
	self.scale = 1
	self.visible = false
	self.grey = false
	self.respond = false
	self.highlight = false
	self.alpha = 1
end


function Card:draw()
	if self.visible then 
		if self.respond then
			if self:on(love.mouse.getPosition()) then
				love.graphics.setColor(72/255,244/255,255/255)
	      		love.graphics.rectangle("fill",self.x-4,self.y-4,80*self.sx,135*self.sy,self.ox,self.oy)
	      	end
	      	if self.grey then love.graphics.setColor(0.7,0.7,0.7,self.alpha) else love.graphics.setColor(1,1,1,self.alpha) end
      		love.graphics.draw(self.img,self.x,self.y,0,self.sx*self.scale,self.sy*self.scale,self.ox,self.oy)
      	elseif self.highlight then
			love.graphics.setColor(1,1,1)
			love.graphics.draw(SHINE,self.x-5,self.y-5)
	      	if self.grey then love.graphics.setColor(0.7,0.7,0.7,self.alpha) else love.graphics.setColor(1,1,1,self.alpha) end
      		love.graphics.draw(self.img,self.x,self.y,0,self.sx,self.sy,self.ox,self.oy)
		else
			if self.grey then love.graphics.setColor(0.7,0.7,0.7,self.alpha) else love.graphics.setColor(1,1,1,self.alpha) end	
			love.graphics.draw(self.img,self.x,self.y,0,self.sx*self.scale,self.sy*self.scale,self.ox,self.oy)
		end

		love.graphics.setColor(1,1,1,1)
	end
end

function Card:on(x,y)
	return (x > self.x) and (x <= self.x + self.sx*70) and (y > self.y) and (y <= self.y + self.sy*120)
end

function Card:update(dt,x,y)
	timer:update(dt)
	if self.respond then
		if self:on(x,y) then self.scale = 1.05
		else self.scale = 1 end
	else
		self.scale = 1
	end
end


-- @param cardback: the image that is used as a cardback
-- @param duration: the time it takes to flip halfway around
function Card:flipAnimation(cardback,duration)
	local image = self.img
	self.img = cardback
	self.ox = 35
	self.x = self.x + 35
	timer:tween(duration,self,{sx = 0},"in-out-quad",
		function()
			self.img = image
			timer:tween(duration,self,{sx = 1},"in-out-quad",
				function() 
					self.ox = 0
					self.x = self.x - 35 
				end)
		end)
end

-- Simple animations for folding and expanding cards
function Card:foldUp(duration)
	timer:tween(duration,self,{sy = 0},"in-out-quad")
end

function Card:expandUp(duration)
	local y = self.y
	self.oy = 120
	self.y = y - 120
	timer:tween(duration,self,{sy = 1},"in-out-quad",function() self.oy = 0 self.y = y end)
end

function Card:foldDown(duration)
	self.oy = -120
	timer:tween(duration,self,{sy = 0},"in-out-quad", function() self.oy = 0 end)
end

--ok
function Card:expandDown(duration)
	timer:tween(duration,self,{sy = 1},"in-out-quad")
end

function Card:fadeOut(duration)
	timer:tween(duration,self,{alpha = 0})
end

function Card:fadeIn(duration)
	timer:tween(duration,self,{alpha = 1})
end


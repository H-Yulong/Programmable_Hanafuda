NameBox = Class{}

local FONT = love.graphics.newFont("data/graphics/resources/Adobe_Heiti.otf",20)
local WIDTH = 20
local timer = Timer.new()

function NameBox:init(x,y,name)
	self.x = x
	self.y = y
	self.name = name
	self.index = 1
end

function NameBox:draw()
	love.graphics.setFont(FONT)
	if #self.name > WIDTH then
		love.graphics.print(self.name:sub(self.index,self.index + WIDTH), 
				self.x+12, self.y+12)
	else
		love.graphics.print(self.name, 
				self.x+110, self.y+12, 0,1,1,
				#self.name*5)
	end
	love.graphics.setNewFont(10)

	if self.index < (#self.name - WIDTH) then
		love.graphics.polygon("fill",
						self.x + 204, self.y + 35,
						self.x + 204, self.y + 39,
						self.x + 211, self.y + 37)
	end

	if self.index > 1 then
		love.graphics.polygon("fill",
				self.x + 14, self.y + 35,
				self.x + 14, self.y + 39,
				self.x + 7, self.y + 37)
	end
end


function NameBox:wheelmoved(dx,dy)
	if self:on(love.mouse.getPosition()) then
		if dy > 0 then self:indexDown()
		elseif dy < 0 then self:indexUp()
		end
	end
end

function NameBox:indexUp()
	if self.index < (#self.name - WIDTH) then self.index = self.index + 1 end
	
end

function NameBox:indexDown()
	if self.index > 1 then self.index = self.index - 1 end
end

function NameBox:on(x,y)
	return (x >= self.x - 5 ) and (y >= self.y - 5) 
	and (x <= self.x + 223) and (y <= self.y + 51)
end

return NameBox





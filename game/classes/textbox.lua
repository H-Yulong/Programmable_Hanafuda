TextBox = Class{}

local FONT = love.graphics.newFont("data/graphics/resources/Adobe_Heiti.otf",20)
local timer = Timer.new()

function TextBox:init(x,y,text)
	self.x = x
	self.y = y
	self.textlines = {}
	self.index = 0

	self:updateText(text)

	self.loc_y = {}
	for i = 1,5 do
		self.loc_y[i] = self.y + (i-1)*25 + 12
	end
end

function TextBox:draw()
	love.graphics.setFont(FONT)
	for i = 1,5 do
		if self.textlines[self.index + i] then
			love.graphics.print(self.textlines[self.index + i], self.x + 9, self.loc_y[i])
		end
	end
	love.graphics.setNewFont(10)

	if self.index < (#self.textlines - 5) then
		love.graphics.polygon("fill",
						self.x + 200, self.y + 147,
						self.x + 208, self.y + 147,
						self.x + 204, self.y + 154)
	end

	if self.index > 0 then
		love.graphics.polygon("fill",
				self.x + 200, self.y + 14,
				self.x + 208, self.y + 14,
				self.x + 204, self.y + 7)
	end

end

function TextBox:updateText(text)
	self.textlines = {}
	-- 20 letters per line => 18 per line
	local i = 1
	for sub in string.gmatch(text,"[^\n]+\n") do
		sub = sub:sub(1, #sub-1)
	    self.textlines[i] = sub
	    while #sub >= 20 do
			self.textlines[i] = sub:sub(1,19).."-"
			i = i + 1
			sub = sub:sub(20)
		end
		self.textlines[i] = sub
	    i = i + 1
	end
end

function TextBox:wheelmoved(dx,dy)
	if self:on(love.mouse.getPosition()) then
		if dy > 0 then self:indexDown()
		elseif dy < 0 then self:indexUp()
		end
	end
end

function TextBox:indexUp()
	if self.index < (#self.textlines - 5) then self.index = self.index + 1 end
	
end

function TextBox:indexDown()
	if self.index > 0 then self.index = self.index - 1 end
end

function TextBox:on(x,y)
	return (x >= self.x - 5 ) and (y >= self.y - 5) 
	and (x <= self.x + 300) and (y <= self.y + 165)
end

return TextBox





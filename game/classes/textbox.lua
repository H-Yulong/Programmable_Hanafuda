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
	--[[
		20 letters per line

		Do not write words that across two lines,
		unless this word is longer than 20 letters.

		Do not show punctuations at the beginning of a line.
	]]
	local i = 0

	for sub in string.gmatch(text,"[^\n]+\n") do
		i = i + 1
		self.textlines[i] = ""
		local capacity = 20
		-- Remove "\n" at the end, add a space at the end
		sub = sub:sub(1, #sub-1).." "
	
		for word in string.gmatch(sub, "[^ ]+ ") do

	    	if capacity + 1 >= #word then
	    		self.textlines[i] = self.textlines[i]..word

	    		capacity = capacity - #word
	    	elseif #word <= 20 then
	    		-- Write in the next line if space is not enough
	    		self.textlines[i+1] = word
	    		capacity = 20 - #word
	    		i = i + 1
	    	else
	    		-- Write multi-line text, using "-"
	    		-- Some condition testing to make pretty textlines.

	    		if capacity >= 3 then
		    		self.textlines[i] = self.textlines[i]..word:sub(1,capacity-1).."-"
		    		word = word:sub(capacity)
		    	end

	    		i = i + 1

	    		while #word >= 20 do
	    			self.textlines[i] = word:sub(1,19).."-"
	    			word = word:sub(20)
	    			i = i + 1
	    		end
	    		
	    		if #word == 2 then
	    			self.textlines[i-1] = self.textlines[i-1]:sub(1,19)..word
	    			i = i - 1
	    			capacity = 20
	    		else
		    		self.textlines[i] = word
		    		capacity = 20 - #word
	    		end
	    	end
	    end
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





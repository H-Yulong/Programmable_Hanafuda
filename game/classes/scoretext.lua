ScoreText = Class{}

local FONT = love.graphics.newFont("data/graphics/resources/Adobe_Heiti.otf",30)
local FONT_SMALL = love.graphics.newFont("data/graphics/resources/Adobe_Heiti.otf",20)

function ScoreText:init(list,x,y,text_top, text_bottom, score)
	self.x = x
	self.y = y
	self.text_top = text_top
	self.text_bottom = text_bottom
	
	self.loc_y = {}
	for i = 1,6 do
		self.loc_y[i] = y + 45*i - 5
	end

	self.page = 0

	self.textlines = {}
	self.score = score

	if not self.score then
		self.score = 0
		for i,v in ipairs(list) do
			if type(v[2]) == "number" then
				self.score = self.score + v[2]
			end
		end
	end

	for i,v in ipairs(list) do
		local text = v[1] .. "  " .. v[2]
		if #text <= 24 then
			self.textlines[#self.textlines + 1] = {text,false}
		elseif #text <= 34 then
			self.textlines[#self.textlines + 1] = {text,true}
		else
			while #text >=34 do
				self.textlines[#self.textlines + 1] = {text:sub(1,33).."-",true}
				text = text:sub(34)
			end
			self.textlines[#self.textlines + 1] = {text,true}
		end
	end
end

function ScoreText:draw()
	love.graphics.setFont(FONT)

	-- Draw the top and the bottom text
	if self.text_top then 
		love.graphics.print(self.text_top, self.x + 210, self.y+5, 0,1,1,
			#self.text_top * 11, 10)
	else
		love.graphics.print("List", self.x + 210, self.y+5, 0,1,1, 44,10)
	end

	if self.text_bottom then 
		love.graphics.print(self.text_bottom..self.score, self.x, self.y+330, 0,1,1,0, 10)
	else
		love.graphics.print("Total:  "..self.score, self.x, self.y+330, 0,1,1,0, 10)
	end

	-- Draw the list items
	for i = 1,6 do
		if self.textlines[i + 6*self.page] then
			local text = self.textlines[i + 6*self.page][1]
			local small = self.textlines[i + 6*self.page][2]
			if small then
				love.graphics.setFont(FONT_SMALL)
				love.graphics.print(text, self.x, self.loc_y[i], 0,1,1)
			else
				love.graphics.setFont(FONT)
				love.graphics.print(text, self.x, self.loc_y[i], 0,1,1)
			end
		end
	end

	-- Draw buttons for turning pages
	if self:hasPreviousPage() then
		love.graphics.polygon("fill", self.x+200,self.y+30, self.x+195,self.y+37, self.x+205,self.y+37 )
	end
	if self:hasNextPage() then
		love.graphics.polygon("fill", self.x+200,self.y+307, self.x+195,self.y+300, self.x+205,self.y+300)
	end

	love.graphics.setNewFont(10)
end

function ScoreText:hasPreviousPage()
	return self.page > 0
end

function ScoreText:hasNextPage()
	return #self.textlines > ((self.page + 1) * 6)
end

function ScoreText:mousepressed(x,y,button)
	if (button == 1) then
		if self:hasPreviousPage() then
			if (x >= self.x) and (x <= self.x + 220) and (y >= self.y) and (y < self.y+175) then
				self.page = self.page - 1
			end
		end

		if self:hasNextPage() then
			if (x >= self.x) and (x <= self.x + 220) and (y >= self.y+175) and (y <= self.y+350) then
				self.page = self.page + 1
			end
		end
	end
end

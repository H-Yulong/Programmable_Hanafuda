ScoreList =  Class{}

local FONT = love.graphics.newFont("data/graphics/resources/Adobe_Heiti.otf",30)


function ScoreList:init(gamedata,x,y)
	self.x = x
	self.y = y
	self.y2 = y + 40
	
	self.loc_x = {}
	for i = 1,12 do 
		self.loc_x[i] = self.x + 80 + 58*i
	end

	self.index = 1
	self.hasScoreRight = false
	self.textline_player = {}
	self.textline_com = {}

	for i,v in ipairs(gamedata.env.score) do
		local ps,cs = tostring(v[1]), tostring(v[2])
		local pl = (#ps % 3 == 0) and (#ps - #ps % 3) / 3 or ((#ps - #ps % 3)) / 3 + 1
		local cl = (#cs % 3 == 0) and (#cs - #cs % 3) / 3 or ((#cs - #cs % 3)) / 3 + 1


		self.textline_player[#self.textline_player + 1] = {ps,pl}
		self.textline_com[#self.textline_com + 1] = {cs,cl}
	end

end

function ScoreList:draw()
	love.graphics.setFont(FONT)
	love.graphics.print("Player", self.x, self.y)
	love.graphics.print("AI", self.x, self.y2)

	if self.index > 1 then
		love.graphics.polygon("fill", self.x+110,self.y+40, self.x+115,self.y+47, self.x+115,self.y+33)
	end
	if self.hasScoreRight then
		love.graphics.polygon("fill", self.x+815,self.y+40, self.x+810,self.y+47, self.x+810,self.y+33)
	end

	---[[
	local space = 12
	local hasSpace = true
	local i = self.index
	while hasSpace do
		if self.textline_player[i] then
			local length = 0
			
			if self.textline_player[i][2] > self.textline_com[i][2] then
				length = self.textline_player[i][2]
			else
				length = self.textline_com[i][2]
			end
			
			if length <= space then
				love.graphics.print(self.textline_player[i][1],self.loc_x[12 - space + 1], self.y)
				love.graphics.print(self.textline_com[i][1],self.loc_x[12 - space + 1], self.y2)
				space = space - length
				i = i + 1
			else
				hasSpace = false
				self.hasScoreRight = true
			end
		else
			hasSpace = false
			self.hasScoreRight = false
		end
	end


	love.graphics.setNewFont(10)
end

function ScoreList:update(dt)
	-- body
end

function ScoreList:mousepressed(x,y,button)
	if button == 1 then
		if (y >= self.y - 10) and (y <= self.y + 90) then
			if (x >= self.x + 100) and (x <= self.x + 150) then
				if self.index > 1 then
					self.index = self.index - 1
				end
			elseif (x >= self.x + 780) and (x <= self.x + 830) then
				if self.hasScoreRight then
					self.index = self.index + 1
				end
			end
		end
	end
end
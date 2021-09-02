GameLog = Class{}

local FONT = love.graphics.newFont("data/graphics/resources/Adobe_Heiti.otf",30)
local FONT_SMALL = love.graphics.newFont("data/graphics/resources/Adobe_Heiti.otf",20)
local LINE = "--------------------------------------------------"
function GameLog:init(log,x,y,width,height)
	self.x = x
	self.y = y
	self.width = width
	self.height = height
	self.LOC_Y = {}

	self.textlines = {}
	self.index = 0

	for i = 1,5 do
		self.LOC_Y[i] = self.y + (i-1)*30 + 35
	end

	self:initRefine(self:initRaw(log))
end

function GameLog:draw()
	love.graphics.setColor(150/255,150/255,150/255,0.5)
	love.graphics.rectangle("fill",self.x,self.y,self.width,self.height)
	love.graphics.setColor(1,1,1,1)

	love.graphics.setFont(FONT)
	love.graphics.print("Game Log", self.x+213, self.y)
	love.graphics.setFont(FONT_SMALL)
	for i = 1,5 do
		if self.textlines[self.index + i] then
			love.graphics.print(self.textlines[self.index + i], self.x + 18, self.LOC_Y[i])
		end
	end

	if self.index > 0 then
		love.graphics.polygon("fill",
							  self.x + 2, self.y+35,
							  self.x + 12, self.y+35,
							  self.x + 7, self.y+28)
	end

	if self.index < (#self.textlines - 5) then
		love.graphics.polygon("fill",
							  self.x + 2, self.y+172,
							  self.x + 12, self.y+172,
							  self.x + 7, self.y+178)
	end 

	love.graphics.setNewFont(10)
end

function GameLog:initRaw(log)
	local round = 0
	local ply = 2
	local result = {}
	local playerfirst
	for i,v in ipairs(log) do
		local l = #result
		if v.type == "gamestarts" then
			playerfirst = v.playerfirst
			result[l+1] = "The game begins."
			if playerfirst then
				result[l+2] = "The player is the oya."
			else
				result[l+2] = "AI is the oya."
			end
			result[l+3] = LINE
		elseif v.type == "precheck" then
			if v.op == "continue" then
				if playerfirst then
					result[l+1] = "Prechecks(player): none."
					result[l+2] = "Prechecks(AI): none."
				else
					result[l+1] = "Prechecks(AI): none."
					result[l+2] = "Prechecks(player): none."
				end
			elseif v.op == "gameover" then
				local text1,text2
				if v.isPlayer then
					text1 = "Prechecks(player): "
					text2 = "The player wins the game with prechecks!"
				else
					text1 = "Prechecks(AI): "
					text2 = "AI wins the game with prechecks!"
				end

				for j,w in ipairs(v.precheck_list) do
					text1 = text1 .. w[1]..", "
				end
				text1 = text1:sub(1,#text1-2)
				text1 = text1.."."
				result[l+1] = text1
				result[l+2] = text2
			elseif v.op == "restart" then
				if v.isPlayer then
					result[l+1] = "Prechecks(player): restart the game!"
				else
					result[l+1] = "Prechecks(AI): restart the game!"
				end
			end
		elseif v.type == "played" then
			local text
			
			if v.isPlayer then text = "The player played card "
			else text = "AI played card "
			end

			text = text .. v.card..", it matched"
			if #v.matched == 1 then
				text = text.." card "..v.matched[1].."."
			elseif #v.matched == 3 then
				text = text.." cards "..v.matched[1]..", "..
					v.matched[2]..", and"..v.matched[3].."."
			else
				text = text.." no card."
			end
			
			if ply == 2 then
				ply = 1
				round = round + 1
				result[l+1] = LINE
				result[l+2] = "Round "..round.."."
				result[l+3] = text
			else
				ply = ply + 1
				result[l+1] = text
			end

		elseif v.type == "flipped" then
			local text
			
			if v.isPlayer then text = "The player flipped card "
			else text = "AI flipped card "
			end

			text = text .. v.card..", it matched"
			if #v.matched == 1 then
				text = text.." card "..v.matched[1].."."
			elseif #v.matched == 3 then
				text = text.." cards "..v.matched[1]..", "..
					v.matched[2]..", and"..v.matched[3].."."
			else
				text = text.." no card."
			end

			result[l+1] = text

		elseif v.type == "yaku" then
			result[l+1] = "Yaku: "..v.name.." scored "..v.score.."."
		elseif v.type == "koikoi" then
			if v.isPlayer then
				result[l+1] = "The player chose to koi-koi!"
			else
				result[l+1] = "AI chose to koi-koi!"
			end
		end
	end
	result[#result + 1] = LINE
	result[#result + 1] = "Gameover!"
	return result
end

function GameLog:initRefine(lines)
	for i,v in ipairs(lines) do
		while #v >= 60 do
			self.textlines[#self.textlines + 1] = v:sub(1,59).."-"
			v = v:sub(60)
		end
		self.textlines[#self.textlines + 1] = v
	end
end

function GameLog:mousepressed(x,y,button)
	if self:on(x,y) then
		if y >= self.y + 0.5 * self.height then
			self:indexUp()
		else
			self:indexDown()
		end
	end
end

function GameLog:on(x,y)
	return (x >= self.x) and (y >= self.y) and (x <= self.x + self.width) and (y <= self.y + self.height)
end

function GameLog:wheelmoved(dx,dy)
	if self:on(love.mouse.getPosition()) then
		if dy > 0 then self:indexDown()
		elseif dy < 0 then self:indexUp()
		end
	end
end

function GameLog:indexUp()
	if self.index < (#self.textlines - 5) then self.index = self.index + 1 end
	
end

function  GameLog:indexDown()
	if self.index > 0 then self.index = self.index - 1 end
end


return GameLog
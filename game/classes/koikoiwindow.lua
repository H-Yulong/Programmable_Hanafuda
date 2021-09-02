KoiKoiWindow = Class{}

local FONT = love.graphics.newFont("data/graphics/resources/Adobe_Heiti.otf",30)
local BACKGROUND = love.graphics.newImage("data/graphics/resources/battle_koikoi.png")
local WIDTH = BACKGROUND:getWidth()
local HEIGHT = BACKGROUND:getHeight()

function KoiKoiWindow:init(x,y)
	self.x = x
	self.y = y
	self.visible = false
end

function KoiKoiWindow:draw()
	if self.visible then 
		-- Background
		love.graphics.draw(BACKGROUND, self.x, self.y)

		-- Yes Button
		if self:onYes(love.mouse.getPosition()) then
			love.graphics.setColor(180/255,180/255,180/255,0.5)
		else
			love.graphics.setColor(150/255,150/255,150/255,0.5)
		end

		love.graphics.rectangle("fill", self.x + 5, self.y + 50, WIDTH - 10, 50)

		-- No Button
		if self:onNo(love.mouse.getPosition()) then
			love.graphics.setColor(180/255,180/255,180/255,0.5)
		else
			love.graphics.setColor(150/255,150/255,150/255,0.5)
		end

		love.graphics.rectangle("fill", self.x + 5, self.y + 110, WIDTH - 10, 50)

		love.graphics.setColor(1,1,1,1)

		--Texts on buttons
		love.graphics.setFont(FONT)

		love.graphics.print("Yes", self.x+60, self.y + 60)
		love.graphics.print("No", self.x+65, self.y + 120)

		love.graphics.setNewFont(10)
	end
end

function KoiKoiWindow:update(dt)
end

function KoiKoiWindow:on(x,y)
	return (x >= self.x - 5) and (y >= self.y - 5)
		and (x < self.x + WIDTH + 5) and (y < self.y + HEIGHT + 5)
end

function KoiKoiWindow:onYes(x,y)
	return (x >= self.x) and (x < self.x + WIDTH)
		and (y >= self.y + 45) and (y < self.y + 100)
end

function KoiKoiWindow:onNo(x,y)
	return (x >= self.x) and (x < self.x + WIDTH)
	and (y >= self.y + 105) and (y < self.y + 155)
end



return KoiKoiWindow
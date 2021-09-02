local plot = {}

local timer = Timer.new()
local scenes = {}
local gamedata = nil
local channel = love.thread.getChannel("message")
local current

function plot:start(game)
	gamedata = game
	current = 0
end

function plot:draw()
	scenes[current]:draw()
end

function plot:update(dt)
	timer:update(dt)
	scenes[current]:update(dt)
end

function plot:mousepressed()
end

scenes[0] = {
	text = "",
	draw = function(self) 
		--love.graphics.print(self.text,100,100)
	end,
	update = function(self,dt) 
		local message = channel:peek()
		if message then
			if message.type == "yaku" then 
				self.text = message.name
				timer:after(2,function() self.text = "" end)
				return true 
			end
		end
	end,
	mousepressed = function() end,
}

scenes[1] = {
	draw = function() end,
	update = function(dt) end,
	mousepressed = function() end,
}




return plot
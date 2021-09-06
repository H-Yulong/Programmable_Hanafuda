
---------------------------------------------------------------------
-----						DECLAREATIONS						-----
---------------------------------------------------------------------
local visualEffects = require "data.graphics.effects"
require "game.utils.utilFunctions"
require "game.classes.menuelement"
require "game.classes.menutext"

local timer

local menu = {}

local BACKGROUND = MenuElement("data/graphics/resources/menu_background.png",0,0)
local GROUND = MenuElement("data/graphics/resources/menu_ground.png",0,444,true)
local MOON = MenuElement("data/graphics/resources/menu_moon.png",90,28)
local TITLE = MenuElement("data/graphics/resources/menu_title.png",595,28)
local TEXTS = {
	MenuText("Custom Game", 1017, 310, 960, 225),
	MenuText("Scenario", 1017, 352, 1050, 225),
	MenuText("Tutorial", 1017, 394, 1060, 225),
	MenuText("Settings", 1017, 436, 1050, 225),
	MenuText("Quit", 1017, 478, 1110, 225),
}

local CUSTOM = {
	MenuText("Start Now", 1017, 310, 1025, 225),
	MenuText("Continue", 1017, 352, 1030, 225),
	MenuText("Custom Rules", 1017, 394, 970, 225),
	MenuText("Back", 1017, 436, 1108, 225),
}

local text = "Type here! --"

---------------------------------------------------------------------
-----					CALLBACK FUNCTIONS						-----
---------------------------------------------------------------------
function menu:enter(previous)
	timer = Timer.new()

	BACKGROUND:toDefault()
	GROUND:toDefault()
	MOON:toDefault()
	TITLE:toDefault()
	for i,v in ipairs(TEXTS) do
		v:toDefault()
	end
	for i,v in ipairs(CUSTOM) do
		v:toDefault()
	end

	self.state = ("animate")
	BACKGROUND.visible = true
	BACKGROUND:fadeIn(5)

	timer:after(1.5, function() 
		GROUND.visible = true
		GROUND:fadeIn(5) 
	end)

	timer:after(3, function() 
		MOON.visible = true
		MOON:fadeIn(5) 
	end)

	timer:after(4.5, function() 
		TITLE.visible = true
		TITLE:fadeIn(5) 
	end)

	timer:after(5.5, function()
		for i,v in ipairs(TEXTS) do v.visible = true end 
		self:arrFadeIn(TEXTS) 
	end)

	timer:after(7, 
		function()  
			GROUND.bouncy = true
			MOON.bouncy = true
			TITLE.bouncy = true
			self.state = "normal"
		end)

end

function menu:draw()
	BACKGROUND:draw()
	GROUND:draw()
	MOON:draw()
	TITLE:draw()
	for _,v in ipairs(TEXTS) do
		v:draw()
	end
	for _,v in ipairs(CUSTOM) do
		v:draw()
	end
	--love.graphics.printf(text, 200, 200, love.graphics.getWidth())
end

function menu:update(dt)
	timer:update(dt)
	BACKGROUND:update(dt)
	GROUND:update(dt)
	MOON:update(dt)
	TITLE:update(dt)
	for _,v in ipairs(TEXTS) do
		v:update(dt)
	end
	for _,v in ipairs(CUSTOM) do
		v:update(dt)
	end
end

function menu:mousepressed(x,y,button)
	if button == 1 then
		if self.state == "normal" then
			if TEXTS[1].visible and TEXTS[1]:on(x,y) then 
				self.state = "animate"
				self:arrFadeOut(TEXTS)
				if love.filesystem.getInfo("saved/gamedata.lua") then
					timer:after(2, function()
						for i,v in ipairs(CUSTOM) do v.visible = true end
						for i = 3,#CUSTOM do CUSTOM[i].y = TEXTS[i].y end
					end)
				else
					timer:after(2, function()
						for i,v in ipairs(CUSTOM) do v.visible = true end
						CUSTOM[2].visible = false
						for i = 3,#CUSTOM do CUSTOM[i].y = TEXTS[i-1].y end
 					end)
				end
				
				timer:after(2, function() 
					for i,v in ipairs(TEXTS) do v.visible = false end
					self:arrFadeIn(CUSTOM) 
				end)

				timer:after(2.5, function() self.state = "custom" end)	

			elseif TEXTS[1].visible and TEXTS[5]:on(x,y) then love.event.quit()
			end
		elseif self.state == "custom" then
			if CUSTOM[1].visible and CUSTOM[1]:on(x,y) then
				self:startNow()
			elseif CUSTOM[2].visible and CUSTOM[2]:on(x,y) then self:continueGame()
			elseif CUSTOM[3].visible and CUSTOM[3]:on(x,y) then self:toCustomRules()
			elseif CUSTOM[4].visible and CUSTOM[4]:on(x,y) then
				self.state = "animate"
				self:arrFadeOut(CUSTOM)
				timer:after(2, function() 
					for i,v in ipairs(TEXTS) do v.visible = true end
					for i,v in ipairs(CUSTOM) do v.visible = false end
					self:arrFadeIn(TEXTS) 
				end)
				timer:after(3, function() self.state = "normal" end)
			end
		end
	elseif button == 2 then
		--self:startNow()
	end
end

function love.textinput(t)
    text = text .. t
end

function love.keypressed(key)
    if key == "backspace" then
	    -- get the byte offset to the last UTF-8 character in the string.
	    local byteoffset = utf8.offset(text, -1)

	    if byteoffset then
	        -- remove the last UTF-8 character.
	        -- string.sub operates on bytes rather than UTF-8 characters, so we couldn't do string.sub(text, 1, -2).
	        text = string.sub(text, 1, byteoffset - 1)
	    end
	elseif key == "return" then
		text = text.."\n"
	end
end

---------------------------------------------------------------------
-----					UTILITY FUNCTIONS						-----
---------------------------------------------------------------------

function menu:arrFadeIn(arr)
	for i,v in ipairs(arr) do
		timer:after((i-1)*0.2, function() v:fadeIn(1.5) end)
	end
end

function menu:arrFadeOut(arr)
	local len = #arr
	for i=1,len do
		timer:after((i-1)*0.2, function() arr[len-i+1]:fadeOut(0.5) end)
		timer:after((len-1)*0.2+0.5, function() arr[len-i+1].visible = false end)
	end
end

function menu:startNow()
	local gui_resource = {
		graphic_path = "data/graphics/cards",
		background = "data/graphics/backgrounds/GaifuKaisei.png",
		cardback = "data/graphics/cardbacks/plain.png"
	}
	local def = require "data.yakus.default"
	local env = {
		-- Basic settings
		total_rounds = 2,
		scoring = "adding",
		difficulty = "easy",	
		next_oya = "alter",

		-- Advanced Settings
		player_def = def,
		com_def = def,
		current_round = 1,
		months = {1,2,3,4,5,6,7,8,9,10,11,12},
		score = {},
		initial_scores = {0,0},
		types = {
	    8,2,1,1,4,2,1,1,8,2,1,1,4,2,1,1,
	    4,2,1,1,4,2,1,1,4,2,1,1,8,4,1,1,
	    5,2,1,1,4,2,1,1,8,4,2,1,8,1,1,1,
		},
		card_range = 48,
		month_range = 12,
		names = {"You", "Computer (easy)"}		
	}
	local board = {
		playerfirst = true,
		seed = nil --11111111
	}
	newgame(board,env)
	gamestate.switch(states.battle,gui_resource,"bgm-here-do-it-later",{board = board,env = env} --[[The gamedata]],"data.plots.default")
end

function menu:toCustomRules()
	gamestate.switch(states.customrules)
end

function menu:continueGame()
	local gamedata = Tserial.unpack(love.filesystem.load("saved/gamedata.lua")())
	local message = Tserial.unpack(love.filesystem.load("saved/message.lua")())
	local img = love.image.newImageData("saved/background.png")
	local gui_resource = Tserial.unpack(love.filesystem.load("saved/gui_resource.lua")())
	local log = Tserial.unpack(love.filesystem.load("saved/log.lua")())
	gamestate.switch(states.afterbattle,gamedata,message,img,gui_resource,log) 
end

return menu
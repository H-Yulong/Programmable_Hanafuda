require "game.classes.scoretext"
require "game.classes.scorelist"
require "game.classes.scorebutton"
require "game.classes.gamelog"
require "game.classes.scorebuttonbig"

local afterbattle = {}

-- Tables for game data and GUI resources
local gamedata
local message
local image
local gui_resource
local log

-- Local variables for components to draw
local background
local yaku_text,bonus_text
local scorelist
local winner
local font = love.graphics.newFont("data/graphics/resources/Adobe_Heiti.otf",30)
local button_save = ScoreButton(1133,520,115,78, "Save &", "Quit")
local button_next = ScoreButton(1133,620,115,78, "Next", "Round")
local button_quit = ScoreButtonBig(1133,520,115,180, "Quit")
local gamelog



---------------------------------------------------------------------
-----					CALLBACK FUNCTIONS						-----
---------------------------------------------------------------------
function afterbattle:enter(previous,game,msg,img,gui,l)
	
	-- Initialization
	gamedata = game
	message = msg
	image = img
	gui_resource = gui
	log = l

	background = love.graphics.newImage(image)
	
	self:initText(message)
	
	scorelist = ScoreList(gamedata,430,410)

	-- Show "next round" and "save & quit" buttons if the game is not over
	-- Show "quit" otherwise
	if gamedata.env.total_rounds == "endless" or (gamedata.env.current_round <= gamedata.env.total_rounds) then
		button_next.visible = true
		button_save.visible = true
		button_quit.visible = false
	else
		button_next.visible = false
		button_save.visible = false
		button_quit.visible = true
	end

	gamelog = GameLog(log,570,520,555,180)

end

function afterbattle:draw()
	self:drawRegions()
	yaku_text:draw()
	bonus_text:draw()
	scorelist:draw()

	-- Buttons at the right
	button_save:draw()
	button_next:draw()
	button_quit:draw()

	gamelog:draw()
end

function afterbattle:update(dt)
end

function afterbattle:drawRegions()
	--Background, regions and lines

	-- Background
	love.graphics.draw(background,0,0)

	-- Black retangles
	love.graphics.setColor(0,0,0,0.6)
	love.graphics.rectangle("fill",420,20,840,370)
	love.graphics.rectangle("fill",420,400,840,100)
	love.graphics.rectangle("fill",420,510,840,200)
	
	-- White line
	love.graphics.setColor(1,1,1,1)
	love.graphics.rectangle("fill",839,40, 3,340)

	-- Gray Rectangle at the left
	love.graphics.setColor(150/255,150/255,150/255,0.5)
	love.graphics.rectangle("fill",430,520,130,180)
	love.graphics.setColor(1,1,1,1)

	-- The winner message
	self:drawWinner()
end

function afterbattle:mousepressed(x,y,button)
	yaku_text:mousepressed(x,y,button)
	bonus_text:mousepressed(x,y,button)
	scorelist:mousepressed(x,y,button)
	gamelog:mousepressed(x,y,button)

	--[[
	for i,v in pairs(log) do
		print(i,v.type,v.isPlayer)
	end
	--]]

	if button == 1 then
		if button_next.visible and button_next:on(x,y) then
			self:nextRound()
		elseif button_save.visible and button_save:on(x,y) then
			self:saveQuit()
			gamestate.switch(states.menu)
		elseif button_quit.visible and button_quit:on(x,y) then
			self:noSaveQuit()
			gamestate.switch(states.menu)
		end
	end
end

function afterbattle:wheelmoved(dx,dy)
	gamelog:wheelmoved(dx,dy)
end

function afterbattle:initText(message)
	-- Initialization of texts on this page
	if message.yakus then
		yaku_text = ScoreText(message.yakus,430,30, "Yakus", "Sum of all yakus:  ")
	elseif message.prechecks then
		if message.restart then
			yaku_text = ScoreText(message.prechecks,430,30, "Prechecks", "Need to restart this game!", " ")
		elseif message.winner == "player" then
			yaku_text = ScoreText(message.prechecks,430,30, "Prechecks", "Sum of your prechecks:  ")
		elseif message.winner == "com" then
			yaku_text = ScoreText(message.prechecks,430,30, "Prechecks", "Sum of AI's prechecks:  ")
		end
	end
	bonus_text = ScoreText(message.bonus,850,30, "Bonus", "Final score:  ", message.score)
	winner = message.winner
end

function afterbattle:drawWinner()
	love.graphics.setFont(font)
	if not message.restart then
		if winner == "player" then
			love.graphics.print("You", 465, 575)
			love.graphics.print("Win!", 465, 610)
		elseif winner == "com" then
			love.graphics.print("AI", 460, 575)
			love.graphics.print("Wins!", 460, 610)
		elseif winner == "none" then
			love.graphics.print("Draw!", 460, 590)
		end
	else
		love.graphics.print("Wait...", 455, 590)
	end
end

function afterbattle:nextRound()
	-- Start a new game, transit to the battle state
	if gamedata.board.seed then
		gamedata.board.seed = gamedata.board.seed + 1
	end
	newgame(gamedata.board,gamedata.env)
	gamestate.switch(states.battle,gui_resource,"bgm-here-do-it-later",gamedata --[[The gamedata]],"data.plots.default")

end

function afterbattle:saveQuit()
	-- Save player's gamedata on disk
	if not love.filesystem.getInfo("/saved") then
		love.filesystem.createDirectory("/saved")
	end
	love.filesystem.write("saved/gamedata.lua", "return [["..Tserial.pack(gamedata).."]]")
	love.filesystem.write("saved/message.lua", "return [["..Tserial.pack(message).."]]")	
	image:encode("png", "saved/background.png")
	love.filesystem.write("saved/gui_resource.lua", "return [["..Tserial.pack(gui_resource).."]]")
	love.filesystem.write("saved/log.lua", "return [["..Tserial.pack(log).."]]")
end

function afterbattle:noSaveQuit()
	-- Remove saved files if the game is finished
	if love.filesystem.getInfo("/saved") then
		love.filesystem.remove("saved/gamedata.lua")
		love.filesystem.remove("saved/message.lua")
		love.filesystem.remove("saved/background.png")
		love.filesystem.remove("saved/gui_resource.lua")
		love.filesystem.remove("saved/log.lua")
	end
end

return afterbattle
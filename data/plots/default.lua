require "game.classes.textbox"

local plot = {}

local timer = Timer.new()
local scenes = {}
local gamedata = nil
local channel = love.thread.getChannel("message")

-- Avatar size: 121x212
local avatar_player
local avatar_com

local text_player
local text_com

local name_player
local name_com

local ids

local PLAYER_DIALOGS = {
	waiting_input = "Please play a card.\n",
	waiting_choice = "Please choose a card on board to match with.\n",
	waiting = "Please wait...\n",
	gameover_win = "Gameover!\n",
	gameover_lose = "Gameover!\n",
	gameover_draw = "Gameover!\n",
	yakulist = {score = 0},
	yaku = function(self, message)
		if not contains(ids, message.id)then
				self.yakulist[#self.yakulist + 1] = message.name
				self.yakulist.score = self.yakulist.score + message.score
		end
	end,
	koikoi = function(self)
		local text = "You got these yakus:\n"
		for i,v in ipairs(self.yakulist) do
			text = text..v..", "
		end
		text = text:sub(1,#text-2).."\nwith total score "
		text = text..tostring(self.yakulist.score)..".\n \nKoikoi?\n"
		return text
		
	end,
}

local COM_DIALOGS = {
	waiting = "It's your turn now.\n",
	thinking = "Let me think...\n",
	yakulist = {score = 0},
	gameover_win = "I win this time!\n",
	gameover_lose = "You win...\n",
	gameover_draw = "A draw is not bad.\n",
	yaku = function(self, message)
		if not contains(ids, message.id)then
				self.yakulist[#self.yakulist + 1] = message.name
				self.yakulist.score = self.yakulist.score + message.score
		end
	end,
	koikoi = function(self)
		local text = "Now I have "
		for i,v in ipairs(self.yakulist) do
			text = text..v..","
		end
		text = text:sub(1,#text-1).." that worth "
		text = text..self.yakulist.score.." scores!\nKoi-koi!\n"
		return text
	end,
}


function plot:start(game,gui)
	-- Initialization
	gamedata = game
	ids = {}

	text_player = TextBox(166,497,"Please wait...\n")
	text_com = TextBox(166,11,"Nice to meet you.\n")
	
	--name_player
	--name_com

	PLAYER_DIALOGS.yakulist = {score = 0}
	PLAYER_DIALOGS.ids = {}
	COM_DIALOGS.yakulist = {score = 0}
	COM_DIALOGS.ids = {}

	if gui.player_avatar_path then
		avatar_player = love.graphics.newImage(gui.player_avatar_path)
	else
		avatar_player = love.graphics.newImage("data/graphics/avatars/player-1.png")
	end

	if gui.com_avatar_path then
		avatar_com = love.graphics.newImage(gui.com_avatar_path)
	else
		avatar_com = love.graphics.newImage("data/graphics/avatars/com-1.png")
	end
end

function plot:draw()
	love.graphics.draw(avatar_com,24,14)
	love.graphics.draw(avatar_player,24,494)

	text_player:draw()
	text_com:draw()
end

local com_yaku = false
function plot:update(dt)
	timer:update(dt)

	message = channel:peek()
	if message and (not contains(ids, message.id)) then
		
		if message.type == "waiting input" then
			text_player:updateText(PLAYER_DIALOGS.waiting_input)
			if com_yaku then
				text_com:updateText(COM_DIALOGS:koikoi())
			else
				text_com:updateText(COM_DIALOGS.waiting)
			end
		elseif message.type == "waiting choice" then
			text_player:updateText(PLAYER_DIALOGS.waiting_choice)
			text_com:updateText(COM_DIALOGS.waiting)
		elseif message.type == "gamestarts" then
		elseif message.type == "precheck" then
		elseif message.type == "revealed" then
		elseif message.type == "flipped" then
		elseif message.type == "com_think" then
			text_com:updateText(COM_DIALOGS.thinking)
			channel:pop()
		elseif message.type == "played" then
			text_player:updateText(PLAYER_DIALOGS.waiting)
			com_yaku = false
			PLAYER_DIALOGS.yakulist = {score = 0}
			COM_DIALOGS.yakulist = {score = 0}
		elseif message.type == "yaku" then
			if message.isPlayer then
				PLAYER_DIALOGS:yaku(message)
			else
				COM_DIALOGS:yaku(message)
				com_yaku = true
			end
		elseif message.type == "waiting koikoi" then
			text_player:updateText(PLAYER_DIALOGS:koikoi())
		elseif message.type == "koikoi" then
			if message.isPlayer then
				text_player:updateText(PLAYER_DIALOGS.waiting)
			else
				
			end
		elseif message.type == "gameover" then
			if message.winner == "player" then
				text_player:updateText(PLAYER_DIALOGS.gameover_win)
				text_com:updateText(COM_DIALOGS.gameover_lose)
			elseif message.winner == "com" then
				text_player:updateText(PLAYER_DIALOGS.gameover_lose)
				text_com:updateText(COM_DIALOGS.gameover_win)
			elseif message.winner == "none" then
				text_player:updateText(PLAYER_DIALOGS.gameover_draw)
				text_com:updateText(COM_DIALOGS.gameover_draw)
			end
		end

		ids[#ids + 1] = message.id
	end
end

function plot:mousepressed()
end

function plot:wheelmoved(dx,dy)
	text_com:wheelmoved(dx,dy)
	text_player:wheelmoved(dx,dy)
end

return plot
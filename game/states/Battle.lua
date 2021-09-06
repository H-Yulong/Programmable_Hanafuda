


---------------------------------------------------------------------
-----						DECLAREATIONS						-----
---------------------------------------------------------------------

local visualEffects = require "data.graphics.effects"
require "game.classes.card"
require "game.classes.namebox"
require "game.classes.koikoiwindow"
require "game.utils.utilFunctions"


-- Game data
local battle = {}
local gamethread
local plot
local timer
local gamedata,cards,topcards
local graphic_resourses
local initial_state
local player_channel,message_channel
local gameover
local log
local PTypes,CTypes

--GUI-realted stuffs
local PX,PY = 490,580	-- Player's hand positions
local BX = {683,683,760,760,837,837,914,914,606,606,991,991,1068,1068,1145,1145} -- Board card positions
local BY = {235,360,235,360,235,360,235,360,235,360,235,360,235,360,235,360}
local CX,CY = 490,20	-- Computer cards positions 
local DX,DY = 500,300	-- Deck cards positions
local GotX = {1045,850,655,460}
local PGY,CGY = 500,155 -- Player, Computer's got card positions
local SHOW_UPPER_HANDS
local TypesText = {"Kasu","Tan","Tane","Ko"}
local playername,comname

local battle_background = love.graphics.newImage("data/graphics/resources/battle_background.png")
local graphic_path,background
local cardback
local got_region = love.graphics.newImage("data/graphics/resources/battle_got_region.png")
local got_bg = {
	img = love.graphics.newImage("data/graphics/resources/battle_got_bg.png"), 
	visible = false, x = 400, y = 215,
	color = {1,1,1}, cardX = 490, cardY = {230,365}
}
local koikoi_window = KoiKoiWindow(1070,275)



---------------------------------------------------------------------
-----					CALLBACK FUNCTIONS						-----
---------------------------------------------------------------------

function battle:enter(previous,gui,bgms,game,plotpath)	

	-- Initialize local variables in this state	
	timer = Timer.new()
	gamethread = love.thread.newThread("game/utils/gamethread.lua")
	PTypes,CTypes = {},{}
	for i = 1,4 do
		PTypes[i],CTypes[i] = {},{}
	end
	SHOW_UPPER_HANDS = false
	self:initializeStack()

	--game = Tserial.unpack(love.filesystem.load("gamedata.hana")())

	--Set up the constants etc etc...
	gamethread:start(Tserial.pack(game))
	plot = require(plotpath)
	plot:start(game,gui)
	graphic_resourses = gui
	graphic_path = graphic_resourses.graphic_path
	background = love.graphics.newImage(graphic_resourses.background)
	cardback = love.graphics.newImage(graphic_resourses.cardback)

	gamedata = game

	playername = NameBox(166,664,gamedata.env.names[1])
	comname = NameBox(166,177,gamedata.env.names[2])
	
	cards,topcards = {},{}
	for i=1,game.env.card_range do
		cards[i] = Card(graphic_path.."/"..i..".png")
	end

	self.state = "animate"
	initial_state = Tserial.pack(gamedata.board,nil,true)

	player_channel = love.thread.getChannel("player")
	message_channel = love.thread.getChannel("message")

	log = {}
	local x,y = CX,CY

	-- Handle gui card data
	for _,v in ipairs(gamedata.board.PGot) do
		cards[v].x,cards[v].y = DX,DY
		self:updateType(v,true)
	end

	for _,v in ipairs(gamedata.board.CGot) do
		cards[v].x,cards[v].y = DX,DY
		self:updateType(v,false)
	end
	
	timer:after(0.8, function()

		-- Deal animation
		for i,v in ipairs(gamedata.board.PHand) do
			cards[v].x,cards[v].y = DX,DY
			timer:after(0.5, function()
				cards[v].visible = true
				timer:tween(1+0.05*i,cards[v],{x = PX + (i-1)*90, y = PY},"in-out-quad")
				timer:after(1.5,function() cards[v].respond = true end)
				end
			)	
		end

		for i,v in ipairs(gamedata.board.onboard) do
			if v ~= -1 then
				cards[v].x,cards[v].y = DX,DY
				timer:after(0.5, function()
					cards[v].visible = true
					timer:tween(1+0.05*i,cards[v],{x = BX[i], y = BY[i]},"in-out-quad")
					end
				)
			end
		end

		for i=1,#gamedata.board.CHand do
			local c = Card(graphic_resourses.cardback)
			c.visible = true
			c.x,c.y = DX,DY
			timer:tween(1+0.05*i,c,{x = PX + (i-1)*90,y = CY},"in-out-quad", 
				function () SHOW_UPPER_HANDS = true end)
			cards[#cards+1] = c
		end

		--Got regions
		for i=1,4 do
			local fold = (#PTypes[i] > 5)
			table.sort(PTypes[i])
			for j,v in ipairs(PTypes[i]) do
				cards[v].visible = true
				cards[v].respond = false
				cards[v].highlight = false
				if fold then
					timer:tween(1+0.02*i+0.03*j,cards[v],{x = GotX[i] + (j-1)*(145/(#PTypes[i]-1)), y = PGY,sx = 0.5, sy = 0.5},"in-out-quad")
				else
					timer:tween(1+0.02*i+0.03*j,cards[v],{x = GotX[i] + (j-1)*35, y = PGY,sx = 0.5, sy = 0.5},"in-out-quad")
				end
				if v > gamedata.env.card_range then cards[v].grey = true end
			end
			fold = (#CTypes[i] > 5)	
			table.sort(CTypes[i])
			for j,v in ipairs(CTypes[i]) do
				cards[v].visible = true
				cards[v].respond = false
				cards[v].highlight = false
				if fold then
					timer:tween(1+0.02*i+0.03*j,cards[v],{x = GotX[i] + (j-1)*(145/(#CTypes[i]-1)), y = CGY,sx = 0.5, sy = 0.5},"in-out-quad")
				else
					timer:tween(1+0.02*i+0.03*j,cards[v],{x = GotX[i] + (j-1)*35, y = CGY,sx = 0.5, sy = 0.5},"in-out-quad")				
				end
				if v > gamedata.env.card_range then cards[v].grey = true end
			end
		end 

		--Some finishing up works
		CX,CY = -1000,-1000

		timer:after(3,function() 
			self.state = "normal"
			CX,CY = x,y
			for i=1,#gamedata.board.CHand do cards[#cards] = nil end
		end)
	end)
end

function battle:draw()

	love.graphics.draw(battle_background,0,0)
	love.graphics.draw(background,400,0)

	--Dynamicly show deck depth
	local count = #gamedata.board.CFlip + #gamedata.board.PFlip + 8
	for i=count,1,-1 do
		love.graphics.draw(cardback,DX+i,DY+i)
	end

	--Fake opponent hands
	if SHOW_UPPER_HANDS then
		for i=1,#gamedata.board.CHand do
			love.graphics.draw(cardback,CX + (i-1)*90, CY)
		end
	end

	--Cards
	for i=1,#cards do
		cards[i]:draw()
	end

	--Koi-koi window
	if self.state == "koikoi" then
		koikoi_window:draw()
	end

	--Special case: got_bg
	if got_bg.visible then 
		love.graphics.setColor(unpack(got_bg.color))
		love.graphics.draw(got_bg.img,got_bg.x,got_bg.y)
		love.graphics.setColor(1,1,1)
	end

	--Some cards needs to be painted on the top of others
	for _,v in ipairs(topcards) do
		cards[v]:draw()
	end

	--The got region
	love.graphics.setNewFont(15)
	for i=1,4 do
		if gamedata.board.PCount[i] > 0 then 
			love.graphics.draw(got_region,GotX[i],PGY+40) 
			love.graphics.print(TypesText[i]..gamedata.board.PCount[i],GotX[i],PGY+40) 
		end
		if gamedata.board.CCount[i] > 0 then 
			love.graphics.draw(got_region,GotX[i],CGY+40) 
			love.graphics.print(TypesText[i]..gamedata.board.CCount[i],GotX[i],CGY+40)
		end
	end
	love.graphics.setNewFont(10)

	--Players' names
	playername:draw()
	comname:draw()

	--Plot, obviously
	plot:draw()

	if self.state == "paused" then
		-- White background
		love.graphics.setColor(1,1,1,0.4)
		love.graphics.rectangle("fill",400,0,880,720)

		-- Black text
		love.graphics.setColor(0,0,0,1)
		love.graphics.setNewFont(30)
		love.graphics.print("Paused...", 1050, 330)

		love.graphics.setNewFont(10)
		love.graphics.setColor(1,1,1,1)
	end
end

function battle:update(dt)
	-- Watching the message channel, handle messages if any.
	local plotting = plot:update(dt)
	if not plotting then
		if self.state == "normal" then
			
			local message = message_channel:peek()

			if message then
				if message.type == "gamestarts" then
					log[message.id] = message
					message_channel:pop()
				elseif message.type == "precheck" then
					log[message.id] = message
					message_channel:pop()
				elseif message.type == "played" then
					self:updateBoard(message)
					log[message.id] = message
					message_channel:pop()
				elseif message.type == "waiting input" then
					for _,v in ipairs(gamedata.board.PHand) do
						if v ~= -1 then 
							local matching = match(gamedata.board.onboard,v)
							if #matching > 0 then
								cards[v].grey = false
								if cards[v]:on(love.mouse.getPosition()) then
									for _,w in ipairs(matching) do
										cards[w].highlight = v
									end
								else
									for _,w in ipairs(matching) do
										if (cards[w].highlight == v) then
											cards[w].highlight = false
										end
									end
								end
							else
								cards[v].grey = true
							end
						end
					end
					for _,v in ipairs(gamedata.board.onboard) do
						if v ~= -1 then cards[v].grey = (#(match(gamedata.board.PHand,v)) == 0) end
					end
				elseif message.type == "waiting choice" then
					for _,v in ipairs(gamedata.board.onboard) do
						if v ~= -1 then 
							local isChoice = (v == message[1] or v == message[2])
							cards[v].grey = not isChoice
							if isChoice and cards[v]:on(love.mouse.getPosition()) then
								cards[v].highlight = true
							else cards[v].highlight = false end
						end
					end
				elseif message.type == "waiting koikoi" then
					self.state = "koikoi"
					message_channel:pop()
					koikoi_window.visible = true
					for i,v in ipairs(gamedata.board.PHand) do
						cards[v].respond = false
					end
				elseif message.type == "revealed" then
					-- More complicated than this...
					cards[message.card].visible = true
					if message.ai then
						removeFill(gamedata.board.CHand,message.card)
						cards[message.card].x,cards[message.card].y = CX + (#gamedata.board.CHand)*90, CY
					else
						cards[message.card].x,cards[message.card].y = DX,DY
					end
					cards[message.card]:flipAnimation(cardback,10)
					self.state = "animate"
					timer:after(2,function () self.state = "normal" end)
					message_channel:pop()
				elseif message.type == "flipped" then
					self:updateBoard(message)
					log[message.id] = message
					message_channel:pop()
				elseif message.type == "yaku" then
					log[message.id] = message
					message_channel:pop()
				elseif message.type == "koikoi" then
					log[message.id] = message
					message_channel:pop()
				elseif message.type == "gameover" then
					self:gameover(message)
				end
			end

			timer:update(dt)
			x,y = love.mouse.getPosition()
			for i=1,48 do
				if cards[i].visible then cards[i]:update(dt,x,y) end
			end
		elseif self.state == "paused" then
			--Todo: what to do...
		elseif self.state == "lookgot" then
			-- Nothing really to do here.
		elseif self.state == "animate" then
			timer:update(dt)
			x,y = love.mouse.getPosition()
			for i=1,48 do
				if cards[i].visible then cards[i]:update(dt,x,y) end
			end
		elseif self.state == "koikoi" then
			koikoi_window:update(dt)
		end
	end
end

function battle:mousepressed(x,y,button)
	-- Again, clear and self-explaning codes
	if self.state == "normal" then

		if self:showGotRegion(x,y,button) then return end

		local message = message_channel:peek()
		if message and message.type then
			if message.type == "waiting input" then
				for _,v in ipairs(gamedata.board.PHand) do
					if cards[v]:on(x,y) then 
						player_channel:push(v) 
						message_channel:pop()
						break 
					end
				end
			elseif message.type == "waiting choice" then
				for _,v in ipairs(message) do
					if cards[v]:on(x,y) then 
						player_channel:push(v)
						message_channel:pop() 
						break 
					end
				end
			end			
		end
	elseif self.state == "lookgot" then
		if x >= 460 and x <= 1280 and ( (y >= 0 and y <= 215) or (y >= 500 and y <= 720) ) then
			self.state = "animate"
			got_bg.visible = false
			self:posAnimation()
			timer:after(1,function() 
				self.state = self:popStack()
				regiontb = nil
				row = 1 
				for _,v in ipairs(gamedata.board.PHand) do
					cards[v].respond = true
				end
				for i = 1,#topcards do
					topcards[i] = nil
				end
			end)
		elseif button == 1 and x >= 460 and x <= 1280 and y >= 215 and y <= 245 then
			self:showNextRow(false)
		elseif button == 1 and x >= 460 and x <= 1280 and y >= 470 and y <= 500 then
			self:showNextRow(true)
		end
	elseif self.state == "koikoi" and (button == 1) then 
		if self:showGotRegion(x,y,button) then return end
		if koikoi_window:onYes(x,y) then 
			player_channel:push(true)
			self.state = "normal"
			koikoi_window.visible = false
			for i,v in ipairs(gamedata.board.PHand) do
				cards[v].respond = true
			end
		elseif koikoi_window:onNo(x,y) then
			player_channel:push(false)
			self.state = "normal"
			self.visible = false
		end
	end
end

function battle:keypressed(key)
	if key == "escape" then
		if self.state == "paused" then
			for i,v in ipairs(gamedata.board.PHand) do
				cards[v].respond = true
			end
			self.state = self:popStack()
		else	
			for i,v in ipairs(gamedata.board.PHand) do
				cards[v].respond = false
			end
			self:pushStack(self.state)
			self.state = "paused"
		end
	end
end

function battle:wheelmoved(dx,dy)
	playername:wheelmoved(dx,dy)
	comname:wheelmoved(dx,dy)
	plot:wheelmoved(dx,dy)
end

function battle:quit()
	-- Autosave for testing, or for player to restart
	love.filesystem.write("gamedata.hana", "return [["..Tserial.pack(gamedata,nil,false).."]]")
end

---------------------------------------------------------------------
-----					UTILITY FUNCTIONS						-----
---------------------------------------------------------------------

function battle:updateBoard(message)
	
	--[[
		Basically, handle the message. Let the state be "animate" to avoid weird interaction behavior
		for a while.
		1. handle the internal representation(gamedata.board) correctly
		2. handle the gui, which involves tap the card and move all the cards to the correct position,
		   done with posAnimation()
		3. finally, some finish up works.
	]]

	local matched = message.matched
	local delay = 0
	self.state = "animate"

	if message.isPlayer then
		if #matched > 0 then
			addSpace(gamedata.board.PGot,message.card)
			if message.type == "played" then 
				removeFill(gamedata.board.PHand,message.card)
			else 
				removeFill(gamedata.board.PFlip,message.card) 
			end
			updateCount(gamedata.board.PCount,gamedata.env.types,message.card)
			cards[message.card].respond = false
			timer:tween(0.5,cards[message.card],{x = cards[matched[1]].x,y = cards[matched[1]].y},
				"in-quad",function() self:updateType(message.card,true) end)
			for _,v in ipairs(message.matched) do 
				addSpace(gamedata.board.PGot,v) 
				removeSpace(gamedata.board.onboard,v)
				updateCount(gamedata.board.PCount,gamedata.env.types,v)
				self:updateType(v,true)
			end
			if #message.matched == 3 then
				for _,v in ipairs(message.matched) do
					timer:tween(0.5,cards[v],{x = cards[matched[1]].x,y = cards[matched[1]].y})
				end
			end
			delay = 1.5
		else
			addSpace(gamedata.board.onboard,message.card)
			if message.type == "played" then 
				removeFill(gamedata.board.PHand,message.card)
			else 
				removeFill(gamedata.board.PFlip,message.card) 
			end
		end
	else
		if #matched > 0 then
			addSpace(gamedata.board.CGot,message.card)
			if message.type == "played" then 
				removeFill(gamedata.board.CHand,message.card)
			else 
				removeFill(gamedata.board.CFlip,message.card) 
			end
			updateCount(gamedata.board.CCount,gamedata.env.types,message.card)
			timer:tween(0.5,cards[message.card],{x = cards[matched[1]].x,y = cards[matched[1]].y},
				"in-quad",function() self:updateType(message.card,false) end)			
			for _,v in ipairs(message.matched) do 
				addSpace(gamedata.board.CGot,v) 
				removeSpace(gamedata.board.onboard,v)
				updateCount(gamedata.board.CCount,gamedata.env.types,v)	
				self:updateType(v,false)		 
			end
			if #message.matched == 3 then
				for _,v in ipairs(message.matched) do
					timer:tween(0.5,cards[v],{x = cards[matched[1]].x,y = cards[matched[1]].y})
				end
			end
			delay = 1.5
		else
			addSpace(gamedata.board.onboard,message.card)
			if message.type == "played" then 
				removeFill(gamedata.board.CHand,message.card)
			else 
				removeFill(gamedata.board.CFlip,message.card) 
			end
			delay = 0.5
		end
	end

	for _,v in ipairs(matched) do
		topcards[#topcards+1] = v
	end
	topcards[#topcards+1] = message.card

	timer:after(delay, function()
		self.posAnimation()
		timer:after(1,function ()
			for i,_ in ipairs(topcards) do
				topcards[i] = nil
			end
			self.state = "normal"
		end)
	end)

end

function battle:posAnimation()
	-- For each card in each region, work out where they should be,
	-- then we have some juicy tweening!

	for i,v in ipairs(gamedata.board.PHand) do
		if v ~= -1 then
			cards[v].visible = true
			timer:tween(1,cards[v],{x = PX + (i-1)*90, y = PY},"in-out-quad")
			cards[v].grey = false
		end
	end

	for i,v in ipairs(gamedata.board.onboard) do
		if v ~= -1 then
			cards[v].visible = true
			cards[v].respond = false
			cards[v].highlight = false
			timer:tween(1,cards[v],{x = BX[i], y = BY[i]},"in-out-quad")
			cards[v].grey = false
		end
	end
	
	for i=1,4 do
		local fold = (#PTypes[i] > 5)
		table.sort(PTypes[i])
		for j,v in ipairs(PTypes[i]) do
			cards[v].visible = true
			cards[v].respond = false
			cards[v].highlight = false
			if fold then
				timer:tween(1,cards[v],{x = GotX[i] + (j-1)*(145/(#PTypes[i]-1)), y = PGY,sx = 0.5, sy = 0.5},"in-out-quad")
			else
				timer:tween(1,cards[v],{x = GotX[i] + (j-1)*35, y = PGY,sx = 0.5, sy = 0.5},"in-out-quad")
			end
			if v > gamedata.env.card_range then cards[v].grey = true end
		end
		fold = (#CTypes[i] > 5)	
		table.sort(CTypes[i])
		for j,v in ipairs(CTypes[i]) do
			cards[v].visible = true
			cards[v].respond = false
			cards[v].highlight = false
			if fold then
				timer:tween(1,cards[v],{x = GotX[i] + (j-1)*(145/(#CTypes[i]-1)), y = CGY,sx = 0.5, sy = 0.5},"in-out-quad")
			else
				timer:tween(1,cards[v],{x = GotX[i] + (j-1)*35, y = CGY,sx = 0.5, sy = 0.5},"in-out-quad")				
			end
			if v > gamedata.env.card_range then cards[v].grey = true end
		end
	end
end

function battle:updateType(card,isPlayer)
	--[[
		This deals with the tricky problem of type alienation: when one card has more than one types.
		Ideally, our gui should draw normally for the biggest type and draw "shadows" for smaller types.
		This is done by adding shadow card objects to cards table.
		In standard rules only sake has this properity, but in custom rules lots of things could happen.  
	]]
	local t = gamedata.env.types[card]
	local first = true
	local tb
	if isPlayer then tb = PTypes else tb = CTypes end
	if t >= 8 then
		tb[4][#tb[4]+1] = card
		first = false
		t = t - 8
	end
	if t >= 4 then
		if first then tb[3][#tb[3]+1] = card first = false
		else
			tb[3][#tb[3]+1] = #cards + 1
			cards[#cards+1] = Card(graphic_path.."/"..card..".png")
			cards[#cards].grey = true
			cards[#cards].x,cards[#cards].y = cards[card].x,cards[card].y
		end
		t = t - 4
	end
	if t >= 2 then
		if first then tb[2][#tb[2]+1] = card first = false
		else
			tb[2][#tb[2]+1] = #cards + 1
			cards[#cards+1] = Card(graphic_path.."/"..card..".png")
			cards[#cards].grey = true
			cards[#cards].x,cards[#cards].y = cards[card].x,cards[card].y
		end
		t = t - 2
	end
	if t >= 1 then
		if first then tb[1][#tb[1]+1] = card
		else
			tb[1][#tb[1]+1] = #cards + 1
			cards[#cards+1] = Card(graphic_path.."/"..card..".png")
			cards[#cards].grey = true
			cards[#cards].x,cards[#cards].y = cards[card].x,cards[card].y
		end
	end
end

local regiontb
function battle:showGotRegion(x,y,button)
	--[[
		This is the function handling the click on got region. Fairly easy.
		Determine the position clicked, then play the animation. Also manage the states.
	]]
	if (button == 1) then

		-- Push the current state in the stack
		self:pushStack(self.state)

		-- Determine which region the player clicked
		local isPlayer
		if (y >= PGY) and (y <= PGY + 60) then isPlayer = true
		elseif (y >= CGY) and (y <= CGY + 60) then isPlayer = false
		else return end
		
		local index
		local tb = isPlayer and gamedata.board.PCount or gamedata.board.CCount
		for i=1,4 do
			if (x >= GotX[i]) and (x <= GotX[i] + 175) and (tb[i] > 0) then index = i break end
		end

		if not index then return end

		-- Change the states, show the animation
		regiontb = isPlayer and PTypes[index] or CTypes[index]
		got_bg.visible = true
		self.state = "animate"
		for i,v in ipairs(regiontb) do
			topcards[#topcards + 1] = v
			if i >=1 and i <= 8 then
				timer:tween(1,cards[v],{x = got_bg.cardX + (i-1)*90, y = got_bg.cardY[1], sx = 1, sy = 1})
			elseif i >=9 and i <= 16 then
				timer:tween(1,cards[v],{x = got_bg.cardX + (i-8-1)*90, y = got_bg.cardY[2], sx = 1, sy = 1})
			else
				local j = i - math.floor(i/8)
				timer:tween(1,cards[v],{x = got_bg.cardX + (j-1)*90, y = got_bg.cardY[2], sx = 0, sy = 0},"linear",
					function() cards[v].sx,cards[v].sy,cards[v].visible = 1,1,false end)
			end
		end
		for _,v in ipairs(gamedata.board.PHand) do
			cards[v].respond = false
		end
		timer:after(1,function() self.state = "lookgot" end)
	end
end

local row = 1
function battle:showNextRow(isDown)
	--[[
		This is the function handling the animation of turning pages of examining got cards.
		Local variables row, regiontb are used.
		A card in row x and column y is the {(x-1)*8+y}th element in regiontb.
	]]
	if isDown and (#regiontb > 8*(row+1)) then
		self.state = "animate"
		for i = 1,8 do
			--The current row: fold it
			cards[regiontb[(row-1)*8 + i]].visible = false
			--cards[regiontb[(row-1)*2 + i]]:foldUp(10)
			--The row below: move it up
			timer:tween(1,cards[regiontb[row*8 +i]],{x = got_bg.cardX + (i-1)*90, y = got_bg.cardY[1]})
			--The row that's 2 rows below: show it
			local next_card = cards[regiontb[(row+1)*8 + i]]
			if next_card then 
				next_card.x,next_card.y = got_bg.cardX + (i-1)*90, got_bg.cardY[2]
				next_card.visible = true
				--next_card:expandUp(10) 
			end
		end
		timer:after(2,function() self.state = "lookgot" end)
		row = row + 1
	elseif isDown == false and row > 1 then
		self.state = "animate"
		for i = 1,8 do
			--The row above: show it
			cards[regiontb[(row-2)*8 + i]].visible = true
			cards[regiontb[(row-2)*8 + i]]:expandDown(10)
			--The current row: move it down
			timer:tween(1,cards[regiontb[(row-1)*8 + i]],{x = got_bg.cardX + (i-1)*90, y = got_bg.cardY[2]})
			--The next row: fold it
			local next_card = cards[regiontb[row*8 + i]]
			if next_card then 
				--next_card.x,next_card.y = got_bg.cardX + (i-1)*90, got_bg.cardY[2]
				next_card.visible = false
				--next_card:foldDown(10) 
			end
		end
		timer:after(1,function() self.state = "lookgot" end)
		row = row - 1
	end
end

function battle:yaku(message)
	--[[
		This function handles the yaku message, which has two cases:
		1. the player got a yaku. Show the yaku's name and score, and ask for koi-koi decisions.
		2. the computer got a yaku. Show yaku name and score, and show computer's decision.
	]]
end

function battle:initializeStack()
	self.state_stack = {}
end

function battle:popStack()
	local state = self.state_stack[#self.state_stack]
	self.state_stack[#self.state_stack] = nil
	return state
end

function battle:pushStack(state)
	self.state_stack[#self.state_stack + 1] = state
end

function battle:gameover(message)
	--[[
		This function handles the gameover message. It does the following things:
		- Reveal opponent's hand, if any left.
		- Prepare data for the AfterGame state.
		- Update gamedata for later use
		-- Finally transit to AfterGame state.
	]]

	message_channel:pop()
	-- Do the animation thing here
	SHOW_UPPER_HANDS = false
	for i,v in ipairs(gamedata.board.CHand) do
		cards[v].visible = true
		cards[v].x,cards[v].y = CX + (i-1)*90, CY 
		cards[v]:flipAnimation(cardback,10)
	end

	for _,v in ipairs(gamedata.board.PHand) do
		cards[v].respond = false
	end

	self.state = "animate"

	if message.type == "gameover" then
		koikoi_window.visible = false
		if not message.restart then
			-- Handle score
			local l = gamedata.env.score[1] and #gamedata.env.score or 0
			local pl_score = (l > 0) and gamedata.env.score[l][1] or gamedata.env.initial_scores[1]
			local com_score = (l > 0) and gamedata.env.score[l][2] or gamedata.env.initial_scores[2]

			if gamedata.env.scoring == "adding" then
				if message.winner == "player" then
					gamedata.env.score[l+1] = {pl_score + message.score, com_score}
				elseif message.winner == "com" then
					gamedata.env.score[l+1] = {pl_score, com_score + message.score}
				elseif message.winner == "none" then
					if gamedata.board.playerfirst then
						gamedata.env.score[l+1] = {pl_score + message.score, com_score}
					else
						gamedata.env.score[l+1] = {pl_score, com_score + message.score}
					end
				end
			elseif gamedata.env.scoring == "taking" then
				if message.winner == "player" then
					gamedata.env.score[l+1] = {pl_score + message.score, com_score - message.score}
				elseif message.winner == "com" then
					gamedata.env.score[l+1] = {pl_score - message.score, com_score + message.score}
				elseif message.winner == "none" then
					if gamedata.board.playerfirst then
						gamedata.env.score[l+1] = {pl_score + message.score, com_score - message.score}
					else
						gamedata.env.score[l+1] = {pl_score - message.score, com_score + message.score}
					end
				end
			end

			-- Handle rounds
			if gamedata.env.total_rounds == "endless" then
				if (gamedata.env.score[l+1][1] >= 0) and (gamedata.env.score[l+1][2] >= 0) then 
					gamedata.env.current_round = gamedata.env.current_round + 1
				else
					gamedata.env.total_rounds = 0
				end
			elseif gamedata.env.current_round <= gamedata.env.total_rounds then
				gamedata.env.current_round = gamedata.env.current_round + 1
			end

			-- Handle Next oya
			if gamedata.env.next_oya == "alter" then
				gamedata.board.playerfirst = not gamedata.board.playerfirst
			elseif gamedata.env.next_oya == "winner" then
				if message.winner == "player" then gamedata.board.playerfirst = true
				elseif message.winner == "com" then gamedata.board.playerfirst = false
				elseif message.winner == "none" then gamedata.board.playerfirst = not gamedata.board.playerfirst
				end
			elseif gamedata.env.next_oya == "random" then
				math.randomseed(gamedata.board.seed or os.time())
				local i = math.random(0,1)
				gamedata.board.playerfirst = (i == 1)
			end
		else
			if gamedata.env.next_oya == "random" then
				math.randomseed(gamedata.board.seed or os.time())
				local i = math.random(0,1)
				gamedata.board.playerfirst = (i == 1)
			end
		end
		timer:after(2, function() 
			love.graphics.captureScreenshot(function(img)
				gamestate.switch(states.afterbattle,gamedata,message,img,graphic_resourses,log) 
			end)
		end)
	end

end


---------------------------------------------------------------------
-----					RETURN STATEMENT						-----
---------------------------------------------------------------------
return battle
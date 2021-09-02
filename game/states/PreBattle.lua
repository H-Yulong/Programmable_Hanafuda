local prebattle = {}

---[[

function prebattle:draw()
	love.graphics.print("click LEFT to go FIRST, click RIGHT to go SECOND\n right click to load testgame",300,300)
end

function prebattle:update(dt)
end

function prebattle:mousepressed(x,y,button)
	local gui_resource = {
		graphic_path = "data/graphics/cards",
		background = "data/graphics/backgrounds/GaifuKaisei.png",
		cardback = "data/graphics/cardbacks/plain.png"
	}
	if button == 1 then
		local def = require "test"
		local def2 = require "test2"
		--local def = require "tests.parseline_test"
		local env = {
			player_def = def,
			com_def = def2,
			current_round = 1,
			total_rounds = 12,
			months = {1,2,3,4,5,6,7,8,9,10,11,12},
			score = {},
			types = {
		    8,2,1,1,4,2,1,1,8,2,1,1,4,2,1,1,
		    4,2,1,1,4,2,1,1,4,2,1,1,8,4,1,1,
		    5,2,1,1,4,2,1,1,8,4,2,1,8,1,1,1,
			},
			next_oya = "function (oya) return not oya end",
			card_range = 48,
			month_range = 12,
			difficulty = "easy"
		}
		local board = {
			playerfirst = (x<=640)
		}
		self:newgame(board,env)
		gamestate.switch(states.battle,gui_resource,"bgm-here-do-it-later",{board = board,env = env} --[[The gamedata]],"data.plots.default")
	elseif button == 2 then
		local gamedata = require "testgame"
		gamestate.switch(states.battle,gui_resource,"bgm-here-do-it-later",gamedata,"data.plots.default")
	end
end


function prebattle:newgame(board,env)
	math.randomseed(board.seed or os.time())
	
	local deck = {}
	for i=1,env.card_range do
		deck[i] = i 
	end

	-- Fisher-Yates Shuffle --
  	for i = #deck, 2, -1 do
		local j = math.random(i)
		deck[i], deck[j] = deck[j], deck[i]
	end

	board.PHand,board.PFlip,board.CHand,board.CFlip,board.onboard = {},{},{},{},{}

	for i = 1,8 do
		board.PHand[i] = deck[i]
		board.PFlip[i] = deck[i+8]
		board.CHand[i] = deck[i+16]
		board.CFlip[i] = deck[i+24]
		board.onboard[i] = deck[i+32]
	end

	board.PGot,board.CGot = {},{}
	board.PCount,board.CCount = {0,0,0,0,0},{0,0,0,0,0}
	board.now = env.months[env.current_round]
end

--]]

return prebattle
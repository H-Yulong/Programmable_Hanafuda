
---------------------------------------------------------------------
-----						DECLAREATIONS						-----
---------------------------------------------------------------------
local visualEffects = require "data.graphics.effects"
require "game.utils.utilFunctions"
require "game.classes.menuelement"
require "game.classes.menutext"
require "game.classes.customrulestext"

local timer = Timer.new()

local customrules = {}

-- Elements for custom settings
local BACKGROUND = MenuElement("data/graphics/resources/customrules_background.png",0,0)

local MENUS = {
	CustomRulesText("Total rounds",190,77),
	CustomRulesText("Scoring",190,150),
	CustomRulesText("Difficulty",190,223),
	CustomRulesText("Oya",190,296),
	CustomRulesText("Oya (first round)",190,369),
}

local ROUNDS = {
	CustomRulesText("1",480,77),CustomRulesText("2",512,77),CustomRulesText("3",545,77),
	CustomRulesText("4",580,77),CustomRulesText("5",615,77),CustomRulesText("6",650,77),
	CustomRulesText("7",685,77),CustomRulesText("8",720,77),CustomRulesText("9",754,77),
	CustomRulesText("10",785,77),CustomRulesText("11",835,77),CustomRulesText("12",880,77),
	CustomRulesText("Endless",945,77)
}

local SCORING = { CustomRulesText("Adding",480,150), CustomRulesText("Taking",650,150) }

local DIFFICULTY = { 
	CustomRulesText("Easy",480,223), 
	CustomRulesText("Normal",650,223), 
	CustomRulesText("Hard",833,223) 
}

local OYA = { 
	CustomRulesText("Alter",480,296), 
	CustomRulesText("Winner",650,296), 
	CustomRulesText("Random",833,296) 
}

local OYA_FIRST_TURN = { 
	CustomRulesText("Player",480,369), 
	CustomRulesText("AI",650,369), 
	CustomRulesText("Random",833,369) 
}

local START_BUTTON = MenuText("Start Now", 865, 538, 870, 225)
local BACK_BUTTON = MenuText("Back", 865, 580, 955, 225)

local MENU_OPTIONS = {ROUNDS, SCORING, DIFFICULTY, OYA, OYA_FIRST_TURN}

-- Tables that keeps the user's settings
local gui_resource = {
	graphic_path = "data/graphics/cards",
	background = "data/graphics/backgrounds/GaifuKaisei.png",
	cardback = "data/graphics/cardbacks/plain.png"
}

local env = {
	-- Basic settings
	total_rounds = 1,
	scoring = "adding",
	difficulty = "easy",	
	next_oya = "alter",
	-- Advanced Settings
	player_def = nil,
	com_def = nil,
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
	names = {"Player", "Computer (easy)"}		
}

local board = {
	playerfirst = true,
	seed = nil
}

---------------------------------------------------------------------
-----					UTILITY FUNCTIONS						-----
---------------------------------------------------------------------
function customrules:drawElements()
	
	-- Total rounds
	for i,v in ipairs(ROUNDS) do
		if i == env.total_rounds then
			v.gray = false
		else
			v.gray = true
		end
	end

	if env.total_rounds == "endless" then
		ROUNDS[13].gray = false
	end

	-- Scoring
	for _,v in ipairs(SCORING) do
		v.gray = true
	end
	
	if env.scoring == "adding" then
		SCORING[1].gray = false
	elseif env.scoring == "taking" then
		SCORING[2].gray = false
	end

	-- Difficulty
	for _,v in ipairs(DIFFICULTY) do
		v.gray = true
	end
	
	if env.difficulty == "easy" then
		DIFFICULTY[1].gray = false
	elseif env.difficulty == "normal" then
		DIFFICULTY[2].gray = false
	elseif env.difficulty == "hard" then
		DIFFICULTY[3].gray = false
	end

	-- Oya
	for _,v in ipairs(OYA) do
		v.gray = true
	end
	
	if env.next_oya == "alter" then
		OYA[1].gray = false
	elseif env.next_oya == "winner" then
		OYA[2].gray = false
	elseif env.next_oya == "random" then
		OYA[3].gray = false
	end

	-- Oya first turn
	for _,v in ipairs(OYA_FIRST_TURN) do
		v.gray = true
	end
	
	if board.playerfirst == true then
		OYA_FIRST_TURN[1].gray = false
	elseif board.playerfirst == false then
		OYA_FIRST_TURN[2].gray = false
	elseif board.playerfirst == "random" then
		OYA_FIRST_TURN[3].gray = false
	end

	for _,v in ipairs(MENU_OPTIONS) do
		for _,w in ipairs(v) do
			w:draw()
		end
	end

	START_BUTTON:draw()
	BACK_BUTTON:draw()
end


---------------------------------------------------------------------
-----					CALLBACK FUNCTIONS						-----
---------------------------------------------------------------------
function customrules:enter(previous)
	-- Animation: everything fades in
	BACKGROUND:toDefault()
	for _,v in ipairs(MENUS) do
		v:toDefault()
	end
	for _,v in ipairs(MENU_OPTIONS) do
		for _,w in ipairs(v) do
			w:toDefault()
		end
	end


	BACKGROUND:fadeIn(4)
	
	for _,v in ipairs(MENUS) do
		v.gray = false
		v.visible = true
		v:fadeIn(6)
	end

	for _,v in ipairs(MENU_OPTIONS) do
		for _,w in ipairs(v) do
			w.visible = true
			w:fadeIn(6)
		end
	end

	START_BUTTON.visible = true
	START_BUTTON:fadeIn(6)

	BACK_BUTTON.visible = true
	BACK_BUTTON:fadeIn(6)

end

function customrules:draw()
	BACKGROUND:draw()

	for _,v in ipairs(MENUS) do
		v:draw()
	end

	self:drawElements()
end

function customrules:update(dt)
	timer:update(dt)
	BACKGROUND:update(dt)

	for _,v in ipairs(MENUS) do
		v:update(dt)
	end

	for _,v in ipairs(MENU_OPTIONS) do
		for _,w in ipairs(v) do
			w:update(dt)
		end
	end

	START_BUTTON:update(dt)
end

function customrules:mousepressed(x,y,button)
	if button == 1 then
		-- Total rounds
		for i,v in ipairs(ROUNDS) do
			if v:on(x,y) and v.gray then
				env.total_rounds = i
			end
		end
		if env.total_rounds == 13 then
			-- Only score-taking is allowed in endless mode 
			env.total_rounds = "endless" 
			env.scoring = "taking"
		end

		-- Scoring
		if START_BUTTON:on(x,y) then
			-- In case of random...
			if board.playerfirst == "random" then
				math.randomseed(board.seed or os.time())
				local i = math.random(0,1)
				board.playerfirst = (i == 1)
			end

			-- Fill-in initial scores
			if env.scoring == "adding" then
				env.initial_scores = {0,0}
			elseif env.scoring == "taking" then
				env.initial_scores = {10,10}
			end

			-- Default yaku definitions if none provided
			local def = require "data.yakus.default"
			env.player_def = def
			env.com_def = def


			-- Generate new game
			newgame(board,env)
			gamestate.switch(states.battle,gui_resource,"bgm-here-do-it-later",{board = board,env = env} --[[The gamedata]],"data.plots.default")
		
    elseif SCORING[1]:on(x,y) and SCORING[1].gray then 
      env.scoring = "adding"
      -- Cannot play endless games in the adding mode
      if env.total_rounds == "endless" then env.total_rounds = 12 end
      
		elseif SCORING[2]:on(x,y) and SCORING[2].gray then env.scoring = "taking"

		elseif DIFFICULTY[1]:on(x,y) and DIFFICULTY[1].gray then env.difficulty = "easy" 
		elseif DIFFICULTY[2]:on(x,y) and DIFFICULTY[2].gray then env.difficulty = "normal" 
		elseif DIFFICULTY[3]:on(x,y) and DIFFICULTY[3].gray then env.difficulty = "hard" 

		elseif OYA[1]:on(x,y) and OYA[1].gray then env.next_oya = "alter" 
		elseif OYA[2]:on(x,y) and OYA[2].gray then env.next_oya = "winner" 
		elseif OYA[3]:on(x,y) and OYA[3].gray then env.next_oya = "random" 

		elseif OYA_FIRST_TURN[1]:on(x,y) and OYA_FIRST_TURN[1].gray then board.playerfirst = true 
		elseif OYA_FIRST_TURN[2]:on(x,y) and OYA_FIRST_TURN[2].gray then board.playerfirst = false 
		elseif OYA_FIRST_TURN[3]:on(x,y) and OYA_FIRST_TURN[3].gray then board.playerfirst = "random" 

		elseif BACK_BUTTON:on(x,y) then
			gamestate.switch(states.menu)
		end
	end
end

function love.textinput(t)
end

return customrules
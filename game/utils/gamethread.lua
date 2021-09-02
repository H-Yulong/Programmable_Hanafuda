require ("love.timer")
require ("love.math")

require ("lib.Tserial")
require ("game.utils.utilFunctions")
require ("game.utils.compiler")


--[[
	Paradiam: 
		This thread processes a single round of hanafuda game. 
		It uses channel:demand() to halt and wait for player inputs from the main thread.
		It uses channel:push() to pass information to the main thread.
		The main thread will handle messages according to their types.
		Available types:
			- precheck
			- waiting input
			- waiting choice
			- waiting koikoi
			- revealed
			- flipped
			- yaku
			- gameover

]]


---------------------------------------------------------------------
-----					CONSTANTS								-----
---------------------------------------------------------------------
-- Global variables are OK because this is a new thread.

gamedata = Tserial.unpack(...)
board = gamedata.board
env = gamedata.env


-- Set up channels
channels = {}
channels.player = love.thread.getChannel("player")
channels.com = love.thread.getChannel("com")
channels.message = love.thread.getChannel("message")

delay = 1	 --seconds
gameover = false
player_turn = false
player_win = false
com_win = false
id = 1

ptb,Ppre,Pbonus,board.PNamelist,board.PRecord,board.PAcculist = compile(env.player_def)
ctb,Cpre,Cbonus,board.CNamelist,board.CRecord,board.CAcculist = compile(env.com_def)

-- Fix here: load the correct Ai difficulty
com = love.thread.newThread("game/ai/easy.lua")





---------------------------------------------------------------------
-----					PRECHECK						        -----
---------------------------------------------------------------------

function precheck()
	-- Checking: is any precheck conditions satisfied?
	for _,v in pairs(board.PNamelist.precheck) do
		local score = Ppre[v](board, env.types, true)
		if score then 
			gameover = true 
			board.PRecord.precheck[v] = score
		end
	end

	for _,v in pairs(board.CNamelist.precheck) do
		local score = Cpre[v](board, env.types, false)
		if score then 
			gameover = true 
			board.CRecord.precheck[v] = score
		end
	end

	-- If no, continue the game as usual
	if not gameover then 
		channels.message:push({type = "precheck", op = "continue", id = id})
		id = id + 1
		return false
	end
	
	-- If yes, handle them. 
	local found = false
	local found_restart = false
	local list = {}
	--The oya has higher priority
	if board.playerfirst then
		--player precheck:
		for _,v in pairs(board.PNamelist.precheck) do
			local val = board.PRecord.precheck[v]
			if val then
				found = true
				list[#list + 1] = {v,val}

				if val == "restart" then 
					found_restart = true
				end
			end
		end

		if found then
			local message = {type = "precheck", op = "gameover", id = id, isPlayer = true, precheck_list = list}
			if found_restart then message.op = "restart" end
			channels.message:push(message)
			return message
		end

		--com precheck:
		for _,v in pairs(board.CNamelist.precheck) do
			local val = board.CRecord.precheck[v]
			if val then
				found = true
				list[#list + 1] = {v,val}

				if val == "restart" then 
					found_restart = true
				end
			end
		end

		if found then
			local message = {type = "precheck", op = "gameover", id = id, isPlayer = false, precheck_list = list}
			if found_restart then message.op = "restart" end
			channels.message:push(message)
			return message
		end
	else
		--com precheck:
		for _,v in pairs(board.CNamelist.precheck) do
			local val = board.CRecord.precheck[v]
			if val then
				found = true
				list[#list + 1] = {v,val}

				if val == "restart" then 
					found_restart = true
				end
			end
		end

		if found then
			local message = {type = "precheck", op = "gameover", id = id, isPlayer = false, precheck_list = list}
			if found_restart then message.op = "restart" end
			channels.message:push(message)
			return message
		end

		--player precheck:
		for _,v in pairs(board.PNamelist.precheck) do
			local val = board.PRecord.precheck[v]
			if val then
				found = true
				list[#list + 1] = {v,val}

				if val == "restart" then 
					found_restart = true
				end
			end
		end

		if found then
			local message = {type = "precheck", op = "gameover", id = id, isPlayer = true, precheck_list = list}
			if found_restart then message.op = "restart" end
			channels.message:push(message)
			return message
		end
	end
end
---------------------------------------------------------------------
-----							MAIN							-----
---------------------------------------------------------------------

-- for starting animation to play
love.timer.sleep(1)

if #board.PHand > #board.CHand then
	player_turn = true
elseif #board.PHand < #board.CHand then
	player_turn = false
else -- #board.PHand == #board.CHand
	player_turn = board.playerfirst
end

precheck_message = nil
if #board.PHand == 8 and #board.CHand == 8 then
	channels.message:push({type = "gamestarts", playerfirst = board.playerfirst, id = id})
	id = id + 1
	precheck_message =  precheck()
end

if not precheck_message then
	while not(gameover) do
		if player_turn then
			-------------------------------------------------
			-- user plays a card
			-------------------------------------------------
			-- Obtain user input
			channels.message:push({type = "waiting input"})	--Means waiting for input
			local card = channels.player:demand()
			removeFill(board.PHand,card)

			-- Processing: a card is played
			-- Requires player to choose when 2 cards matches
			-- Otherwise, process automatically
			local matches = match(board.onboard,card)
			if #matches == 2 then
				channels.message:push({matches[1],matches[2],type = "waiting choice"}) --Means waiting for a choice
				local chosen = channels.player:demand()
				matches = {chosen}
			end
			if #matches == 0 then 
				addSpace(board.onboard,card) 
			else 
				addSpace(board.PGot,card) 
				updateCount(board.PCount,env.types,card) 
			end
			for _,v in ipairs(matches) do
				addSpace(board.PGot,v)
				removeSpace(board.onboard,v)
				updateCount(board.PCount,env.types,v)
			end

			local message = {
				id = id,
				type = "played",
				isPlayer = true,
				card = card,
				matched = matches
			}
			id = id + 1

			channels.message:supply(message)
			love.timer.sleep(1)
			

			-------------------------------------------------
			--Flip
			-------------------------------------------------
			local card = board.PFlip[1]
			removeFill(board.PFlip,card)
			channels.message:supply({type = "revealed", card = card})	--Means that a new card has showed up
			local matches = match(board.onboard,card)
			if #matches ~= 2 then love.timer.sleep(delay) end
			if #matches == 2 then
				channels.message:push({matches[1],matches[2],type = "waiting choice"}) --Means waiting for a choice
				local chosen = channels.player:demand()
				matches = {chosen}
			end
			if #matches == 0 then 
				addSpace(board.onboard,card) 
			else 
				addSpace(board.PGot,card) 
				updateCount(board.PCount,env.types,card) 
			end
			for _,v in ipairs(matches) do
				addSpace(board.PGot,v)
				removeSpace(board.onboard,v)
				updateCount(board.PCount,env.types,v)
			end

			local message = {
				id = id,
				type = "flipped",
				isPlayer = true,
				card = card,
				matched = matches
			}
			id = id + 1

			channels.message:push(message)

			-------------------------------------------------
			--yaku check
			-------------------------------------------------
			---[[
			local yaku = false
			for _,name in pairs(board.PNamelist.yakus) do
				local score, isAccu = ptb[name](board, true)
				if ((board.PRecord.yakus[name] == false) or (type(board.PRecord.yakus[name]) == "number")) and score then
					if isAccu then board.PRecord.yakus[name] = score 
					else board.PRecord.yakus[name] = true
					end
					yaku = true
					print("player yaku: ",name,score)
					local message = {
						type = "yaku",
						name = name,
						score = score,
						id = id,
						isPlayer = true,
						seen = false,
					}
					id = id + 1
					channels.message:push(message)
				end
			end
			if yaku and #board.PHand ~= 0 then 
				print("koikoi?")
				channels.message:push({type = "waiting koikoi"})
				local koi = channels.player:demand()
				if koi then 
					board.PCount[5] = board.PCount[5] + 1
					player_turn = not player_turn
					local message = {
						type = "koikoi",
						id = id,
						isPlayer = true,
					}
					id = id + 1
					channels.message:push(message)
				else 
					gameover = true
					player_win = true
				end
			elseif yaku and #board.PHand == 0 then
				--Force ending
				gameover = true
				player_win = true
			elseif not yaku and not board.playerfirst and #board.PHand == 0 then
				--Draw
				gameover = true
			else
				player_turn = not player_turn
			end
		else
			-------------------------------------------------
			-- Doing the ai thing...
			-------------------------------------------------
			---[[
			com:start(Tserial.pack(gamedata))
			channels.message:push({type = "com_think"})
			love.timer.sleep(1)
			-- AI plays a card
			local move = Tserial.unpack(channels.com:demand())
			channels.message:push({type = "revealed", card = move.card, ai = true})

			
			move.type = "played"
			move.isPlayer = false
			move.id = id
			id = id + 1
			
			removeFill(board.CHand,move.card)
			if #move.matched == 0 then 
				addSpace(board.onboard,move.card)
			else 
				addSpace(board.CGot,move.card) 
				updateCount(board.CCount,env.types,move.card) 
			end
			channels.message:push(move)

			for _,v in ipairs(move.matched) do
				addSpace(board.CGot,v)
				removeSpace(board.onboard,v)
				updateCount(board.CCount,env.types,v)
			end
			

			-- AI flips
			love.timer.sleep(1)
			local move = Tserial.unpack(channels.com:demand())
			channels.message:push({type = "revealed", card = move.card, ai = false})

			

			move.type = "flipped"
			move.isPlayer = false
			move.id = id
			id = id + 1
			
			if #move.matched == 0 then 
				addSpace(board.onboard,move.card) 
			else 
				addSpace(board.CGot,move.card) 
				updateCount(board.CCount,env.types,move.card) 
			end
			channels.message:push(move)
			removeFill(board.CFlip,move.card)
			for _,v in ipairs(move.matched) do
				addSpace(board.CGot,v)
				removeSpace(board.onboard,v)
				updateCount(board.CCount,env.types,v)
			end

			-- AI yaku check
			local yaku = false
			for _,name in pairs(board.CNamelist.yakus) do
				local score, isAccu = ctb[name](board, false)
				if ((board.CRecord.yakus[name] == false) or (type(board.CRecord.yakus[name]) == "number")) and score then
					if isAccu then board.CRecord.yakus[name] = score 
					else board.CRecord.yakus[name] = true
					end
					yaku = true
					print("ai yaku: ",name,score)
					local message = {
						type = "yaku",
						name = name,
						score = score,
						id = id
					}
					id = id + 1
					channels.message:push(message)
				end
			end

			if yaku and #board.CHand ~= 0 then 
				local koi = channels.com:demand()
				print("ai koikoi? --",koi)
				if koi then 
					board.CCount[5] = board.CCount[5] + 1
					player_turn = not player_turn
					local message = {
						type = "koikoi",
						id = id
					}
					id = id + 1
					channels.message:push(message)
				else 
					gameover = true
					com_win = true
				end
			elseif yaku and #board.CHand == 0 then
				--Force ending
				gameover = true
				com_win = true
			elseif not yaku and board.playerfirst and #board.CHand == 0 then
				--Draw
				gameover = true
			else
				player_turn = not player_turn
			end		
			channels.com:clear()
		end
	end

	print("gameover!")

	-- Do the aftercheck
	if ( player_win or (board.playerfirst and (not player_win) and (not com_win))) then

		local yaku_list = {}
		local score = 0
		for _,v in pairs(board.PNamelist.yakus) do
			local s = board.PRecord.yakus[v]
			if s then
				if type(s) == "number" then yaku_list[v] = s
				else yaku_list[v] = ptb[v](board, true)
				end
			end
		end

		local yaku_list_order = {}
		if player_win then
			print("Player wins!")
			print("Final yakus:")
			for i,v in pairs(yaku_list) do
				print(i,v)
				yaku_list_order[#yaku_list_order + 1] = {i,v}
				score = score + v
			end
		else
			print("draw! Player is the oya.")
		end

		print("Total: "..score)

		print("Adding bonus:")

		-- Do the player's aftercheck

		-- Handle overwrites
		for _,name in pairs(board.PNamelist.bonus) do
			local bonus = Pbonus[name](board, env.types, player_win, com_win, score, true)
		end

		local bonus_list = {{"base",score}}
		for _,name in pairs(board.PNamelist.bonus) do
			local bonus = Pbonus[name](board, env.types, player_win, com_win, score, true)
			if bonus then 
				score = bonus
				bonus_list[#bonus_list + 1] = {name, score}
				print(name, score)
			end
		end

		print("Final score: "..score)

		local winner = player_win and "player" or "none"

		channels.message:push({
			type = "gameover", 
			winner = winner, 
			yakus = yaku_list_order, 
			bonus = bonus_list, 
			id = id, 
			score = score})
	elseif ( com_win or ((not board.playerfirst) and (not player_win) and (not com_win))) then

		local yaku_list = {}
		local score = 0
		for _,v in pairs(board.CNamelist.yakus) do
			local s = board.CRecord.yakus[v]
			if s then
				if type(s) == "number" then yaku_list[v] = s
				else yaku_list[v] = ctb[v](board, false)
				end
			end
		end

		local yaku_list_order = {}
		if com_win then
			print("Computer wins!")
			print("Final yakus:")
			for i,v in pairs(yaku_list) do
				print(i,v)
				yaku_list_order[#yaku_list_order + 1] = {i,v}
				score = score + v
			end
		else
			print("draw! Computer is the oya.")
		end
		
		print("Total: "..score)

		print("Adding bonus:")

		-- Do the computer's aftercheck

		-- Handle overwrites
		for _,name in pairs(board.CNamelist.bonus) do
			local bonus = Cbonus[name](board, env.types, player_win, com_win, score, false)
		end

		local bonus_list = {{"base",score}}
		for _,name in pairs(board.CNamelist.bonus) do
			local bonus = Cbonus[name](board, env.types, player_win, com_win, score, false)
			if bonus then 
				score = bonus
				bonus_list[#bonus_list + 1] = {name, score}
				print(name, score)
			end
		end

		print("Final score: "..score)

		local winner = com_win and "com" or "none"

		channels.message:push({
			type = "gameover", 
			winner = winner, 
			yakus = yaku_list_order, 
			bonus = bonus_list, 
			id = id, 
			score = score})
	end
else
	if precheck_message.op == "gameover" then

		local score = 0
		for _,v in ipairs(precheck_message.precheck_list) do
			score = score + v[2]
		end

		local winner
		if precheck_message.isPlayer then
			winner = "player"
		else
			winner = "com"
		end

		channels.message:push({
			type = "gameover",
			winner = winner,
			prechecks = precheck_message.precheck_list,
			bonus = {{"base (precheck)", score}},
			id = id,
			score = score
		})

	elseif precheck_message.op == "restart" then

		local winner
		if precheck_message.isPlayer then
			winner = "player"
		else
			winner = "com"
		end

		channels.message:push({
			type = "gameover",
			winner = winner,
			prechecks = precheck_message.precheck_list,
			bonus = {{"Restart the current game", " "}},
			id = id,
			score = 0,
			restart = true
		})
	end
end
--]]

--[[		channels.message:push({
			type = "gameover", 
			winner = winner, 
			yakus = yaku_list_order, 
			bonus = bonus_list, 
			id = id, 
			score = score})]]

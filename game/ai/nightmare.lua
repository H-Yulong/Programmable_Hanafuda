----------------------------------------------------
-- Some initialization
----------------------------------------------------
require ("lib.Tserial")

require ("game.utils.utilFunctions")
require ("game.utils.compiler")

--For testing only
--gamedata = require ("testgame")
gamedata = Tserial.unpack(...)
board = gamedata.board
env = gamedata.env
channel = love.thread.getChannel("com")

ptb,Ppre,Pbonus,board.PNamelist,board.PRecord,board.PAcculist = compile(env.player_def)
ctb,Cpre,Cbonus,board.CNamelist,board.CRecord,board.CAcculist = compile(env.com_def)

local tree = {}

----------------------------------------------------
-- Some util functions
----------------------------------------------------
function empty(tb)
	for _,v in ipairs(tb) do
		if v ~= -1 then return false end
	end
	return true
end

function copyBoard(b)
	local result = {}
	for i,v in pairs(b) do
		if type(v) == "table" then result[i] = copyBoard(v)
		else result[i] = v end
	end
  return result
end

function draw(board,playerfirst)
	printtree()
	print("draw")
	if playerfirst then
		local score = 0
		for _,v in pairs(board.PNamelist.bonus) do
			local bonus = Pbonus[v](Pbonus,board.PHand,board.PGot,board.onboard,board.PCount,board.now,
									board.playerfirst,board.PNamelist.bonus,
									board.PNamelist.yakus,board.PRecord.yakus)
			if bonus then
				loadstring("function f (score) return "..bonus.." end")()
				score = score - f(score)
				f = nil
			end
		end
		print("player ",score)
		return score
	else
		local score = 0
		for _,v in pairs(board.CNamelist.bonus) do
			local bonus = Cbonus[v](Cbonus,board.CHand,board.CGot,board.onboard,board.CCount,board.now,
									(not board.playerfirst),board.CNamelist.bonus,
									board.CNamelist.yakus,board.CRecord.yakus)
			if bonus then
				loadstring("function f (score) return "..bonus.." end")()
				score = score + f(score)
				f = nil
			end
		end
		print("ai ",score)
		return score
	end
end

function order(board,isPlayer)
	local have_match,no_match = {},{}
	local mark = {}
	local hand
	if isPlayer then hand = board.PHand else hand = board.CHand end
	for i=1,#hand do 
		mark[i] = (hand[i] == -1)
	end

	--If there is a match, we prefer the one with higher type rank
	local target_type = 8
	for i=1,4 do
		for j,v in ipairs(hand) do
			if v ~= -1 then
				if (not mark[j]) and (#(match(board.onboard,v)) > 0) and (env.types[v] >= target_type) then
					have_match[#have_match+1] = v
					mark[j] = true
				end
			end
		end
		target_type = target_type / 2
	end



	--If there is no match, we prefer the one with lower type rank
	target_type = 8
	for i=1,4 do
		for j,v in ipairs(hand) do
			if v ~= -1 then
				if (not mark[j]) and (#(match(board.onboard,v)) == 0) and (env.types[v] >= target_type) then
					no_match[#no_match+1] = v
					mark[j] = true
				end
			end
		end
		target_type = target_type / 2
	end

	for i=(#no_match),1,-1 do
		have_match[#have_match+1] = no_match[i]
	end

	return have_match

end

----------------------------------------------------
-- The min-max algorithm
----------------------------------------------------
function max(a,b,board,level)
	--Max is the ai, who wants to maximize his gain

	--Determine draw
	if ((not board.playerfirst) and empty(board.CHand)) then return draw(board,false) end
	
	local val = -999	--Negative infinity, sort of...
	local playmsg
	local flipmsg
	local koi

	--Apply heuristics here, we prefer the card that has higher type and matches
	local orderHand = order(board,false)

	--Iterate through all possible states
	--1. Determine the card we wanna play...
	for _,card in ipairs(orderHand) do
		if card ~= -1 then

			--2. Any choice needed when we play this card?
			local matched = match(board.onboard,card)
			if #matched == 2 then
				matched = {{matched[1]},{matched[2]}}
			else matched = {matched} end

			for _,m in ipairs(matched) do
				--We create a copy and update
				local board_temp = copyBoard(board)
				
				for _,got in ipairs(m) do 
					addSpace(board_temp.CGot,got) 
					removeSpace(board_temp.onboard,got)
					updateCount(board_temp.CCount,env.types,got) 
				end

				removeFill(board_temp.CHand,card)
				if #m == 0 then 
					addSpace(board_temp.onboard,card) 
				else 
					addSpace(board_temp.CGot,card) 
					updateCount(board_temp.CCount,env.types,card)
				end

				--We flip
				local flip = board_temp.CFlip[1]

				--3. Any choice needed when we flip?
				local fmatched = match(board_temp.onboard,flip)
				if #fmatched == 2 then
					fmatched = {{fmatched[1]},{fmatched[2]}}
				else fmatched = {fmatched} end

				for _,fm in ipairs(fmatched) do
					--We create a copy and update, again
					local board_new = copyBoard(board_temp)
				
					for _,got in ipairs(fm) do 
						addSpace(board_new.CGot,got) 
						removeSpace(board_new.onboard,got)
						updateCount(board_new.CCount,env.types,got) 
					end

					removeFill(board_new.CFlip,flip)
					if #fm == 0 then 
						addSpace(board_new.onboard,flip) 
					else 
						addSpace(board_new.CGot,flip) 
						updateCount(board_new.CCount,env.types,flip)
					end

					--4. Any yakus? If so, shall we koikoi?
					--First, check for yakus
					tree[level] = card
					if #tree > level then for i=level+1,#tree do tree[i] = nil end end
					local yaku = false
					for _,name in pairs(board_new.CNamelist.yakus) do
						local score,isAccu = ctb[name](ctb,board_new.CGot,board_new.CCount[1],board_new.CCount[2],
									board_new.CCount[3],board_new.CCount[4],board_new.CCount[5],board_new.now,
									(not board_new.playerfirst),board_new.CAcculist,board_new.CNamelist.yakus,board_new.CRecord.yakus)
						if ((board.CRecord.yakus[name] == false) or (type(board.CRecord.yakus[name]) == "number")) and score then
							if isAccu then board_new.CRecord.yakus[name] = score 
							else board_new.CRecord.yakus[name] = true
							end
							yaku = true
						end
					end

					--If yaku, calculate the score, do the branch
					--Use the minus sign here for ai wins equals to player loses
					if yaku then
						local score = 0
						for _,v in pairs(board_new.CNamelist.yakus) do
							if type(board_new.CRecord.yakus[v]) == "number" then score = score + board_new.CRecord.yakus[v]
							elseif board_new.CRecord.yakus[v] then
								score = score + ctb[v](ctb,board_new.CGot,board_new.CCount[1],board_new.CCount[2],
									board_new.CCount[3],board_new.CCount[4],board_new.CCount[5],board_new.now,
									(not board_new.playerfirst),board_new.CAcculist,board_new.CNamelist.yakus,board_new.CRecord.yakus)
							end
						end

						for _,v in pairs(board_new.CNamelist.bonus) do
							local bonus = Cbonus[v](Cbonus,board_new.CHand,board_new.CGot,board_new.onboard,board_new.CCount,board_new.now,
									(not board_new.playerfirst),board_new.CNamelist.bonus,
									board_new.CNamelist.yakus,board_new.CRecord.yakus)
							if bonus then 
								loadstring("function f (score) return "..bonus.." end")()
								score = f(score)
								f = nil
							end
						end

						

						--Do the classic min-max thing
						val = (val > score) and val or score
						printtree()
						print("ai stops.")
						print(val,a,b)
						tree[level] = tree[level].." ai koikoi"
						print("score: ",score)

						if val > b then return val end
						if val > a then 
							a = val 
							playmsg = {card = card, matched = m}
							flipmsg = {card = flip, matched = fm}
							koi = false
							--tree[level] = playmsg
						end
						

						--We can only koikoi if there're cards left in hand
						if (not empty(board_new.CHand)) then board_new.CCount[5] = board_new.CCount[5] + 1
						else return val,playmsg,flipmsg,koi end
					end

					--Do the classic min-max thing
					local minval = min(a,b,copyBoard(board_new),level + 1)
					val = (val > minval) and val or minval
					if val > b then return val end
					if val > a then 
						a = val 
						playmsg = {card = card, matched = m}
						flipmsg = {card = flip, matched = fm}
						koi = yaku
						--tree[level] = playmsg
					end
				end
			end
		end
	end

	return val,playmsg,flipmsg,koi,a,b
end

function min(a,b,board,level)
	--min is the player, who wants to minimize his gain

	--Determine draw
	if ((board.playerfirst) and empty(board.PHand)) then return draw(board,true) end
	
	local val = 999	--Positive infinity, sort of...
	local playmsg
	local flipmsg
	local koi

	--Apply heuristics here, we prefer the card that has higher type and matches
	local orderHand = order(board,true)

	--Iterate through all possible states
	--1. Determine the card we wanna play...
	for _,card in ipairs(orderHand) do
		if card ~= -1 then

			--2. Any choice needed when we play this card?
			local matched = match(board.onboard,card)
			if #matched == 2 then
				matched = {{matched[1]},{matched[2]}}
			else matched = {matched} end

			for _,m in ipairs(matched) do
				--We create a copy and update
				local board_temp = copyBoard(board)
				
				for _,got in ipairs(m) do 
					addSpace(board_temp.PGot,got) 
					removeSpace(board_temp.onboard,got)
					updateCount(board_temp.PCount,env.types,got) 
				end

				removeFill(board_temp.PHand,card)
				if #m == 0 then 
					addSpace(board_temp.onboard,card) 
				else 
					addSpace(board_temp.PGot,card) 
					updateCount(board_temp.PCount,env.types,card)
				end

				--We flip
				local flip = board_temp.PFlip[1]

				--3. Any choice needed when we flip?
				local fmatched = match(board_temp.onboard,flip)
				if #fmatched == 2 then
					fmatched = {{fmatched[1]},{fmatched[2]}}
				else fmatched = {fmatched} end

				for _,fm in ipairs(fmatched) do
					--We create a copy and update, again
					local board_new = copyBoard(board_temp)
				
					for _,got in ipairs(fm) do 
						addSpace(board_new.PGot,got) 
						removeSpace(board_new.onboard,got)
						updateCount(board_new.PCount,env.types,got) 
					end

					removeFill(board_new.PFlip,flip)
					if #fm == 0 then 
						addSpace(board_new.onboard,flip) 
					else 
						addSpace(board_new.PGot,flip) 
						updateCount(board_new.PCount,env.types,flip)
					end

					--4. Any yakus? If so, shall we koikoi?
					--First, check for yakus
					tree[level] = card
					if #tree > level then for i=level+1,#tree do tree[i] = nil end end
					local yaku = false
					for _,name in pairs(board_new.PNamelist.yakus) do
						local score,isAccu = ptb[name](ptb,board_new.PGot,board_new.PCount[1],board_new.PCount[2],
									board_new.PCount[3],board_new.PCount[4],board_new.PCount[5],board_new.now,
									board_new.playerfirst,board_new.PAcculist,board_new.PNamelist.yakus,board_new.PRecord.yakus)
						if ((board.PRecord.yakus[name] == false) or (type(board.PRecord.yakus[name]) == "number")) and score then
							if isAccu then board_new.PRecord.yakus[name] = score 
							else board_new.PRecord.yakus[name] = true
							end
							yaku = true
						end
					end

					--If yaku, calculate the score, do the branch
					--Use the minus sign here for player wins equals to ai loses
					if yaku then
						local score = 0
						for _,v in pairs(board_new.PNamelist.yakus) do
							if type(board_new.PRecord.yakus[v]) == "number" then score = score - board_new.PRecord.yakus[v]
                  			elseif board_new.PRecord.yakus[v] then
								score = score - ptb[v](ptb,board_new.PGot,board_new.PCount[1],board_new.PCount[2],
									board_new.PCount[3],board_new.PCount[4],board_new.PCount[5],board_new.now,
									board_new.playerfirst,board_new.PAcculist,board_new.PNamelist.yakus,board_new.PRecord.yakus)
							end
						end

						for _,v in pairs(board_new.PNamelist.bonus) do
							local bonus = Pbonus[v](Pbonus,board_new.PHand,board_new.PGot,board_new.onboard,board_new.PCount,board_new.now,
									board_new.playerfirst,board_new.PNamelist.bonus,
									board_new.PNamelist.yakus,board_new.PRecord.yakus)
							if bonus then 
								loadstring("function f (score) return "..bonus.." end")()
								score = -1 * f(score)
								f = nil
							end
						end



						--Do the classic min-max thing
						val = (val < score) and val or score

						printtree()
						print("human stop.")
						print(val,a,b)
						tree[level] = tree[level].." human koikoi"
						print("score: ",score)

						if val < a then return val end
						if val < b then 
							b = val 
							playmsg = {card = card, matched = m}
							flipmsg = {card = flip, matched = fm}
							koi = false
							--tree[level] = playmsg
						end
						
						--We can only koikoi if there're cards left in hand
						if (not empty(board_new.PHand)) then board_new.PCount[5] = board_new.PCount[5] + 1
						else return val,playmsg,flipmsg,koi end
					end

					--Do the classic min-max thing
					local maxval = max(a,b,copyBoard(board_new),level + 1)
					val = (val < maxval) and val or maxval
					if val < a then return val end
					if val < b then 
						b = val 
						playmsg = {card = card, matched = m}
						flipmsg = {card = flip, matched = fm}
						koi = yaku
						--tree[level] = playmsg
					end

				end
			end
		end
	end

	return val,playmsg,flipmsg,koi
end

function printtree()
	local now = "ai"
	for i,v in ipairs(tree) do
	print(i,now," played: ",v)
	now = (now == "ai") and "human" or "ai"
	end
end

val,playmsg,flipmsg,koi,a,b = max(-999,999,board,1)
print(a,b)
print("val: ",val)

---[[
channel:push(Tserial.pack(playmsg))
channel:push(Tserial.pack(flipmsg))
channel:push(koi)
--]]
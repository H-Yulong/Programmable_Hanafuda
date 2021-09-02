-- This... is so obvious.
function contains(tb,element)
	for _,v in ipairs(tb) do
		if v == element then return true end
	end
	return false
end

-- This counts the number of cards from the given month in the given table.
function monthcount(tb,month,now)
	local count = 0
	local i
	if tonumber(month) then
		i = tonumber(month)
	elseif month == "now" then
		i = now
	end

	for _,v in ipairs(tb) do
		if math.floor((v-1)/4)+1 == i then count = count + 1 end
	end

	return count 

end

-- This counts the number of different groups of cards from the same month
-- with more than <size> cards in the given table.
function groupcount(tb,size)
	local size = tonumber(size)
	local list = {0,0,0,0,0,0,0,0,0,0,0,0,}
	local count = 0

	for _,v in ipairs(tb) do
		local i = math.floor((v-1)/4)+1
		list[i] = list[i] + 1
	end

	for _,v in ipairs(list) do
		if v >=size then count = count + 1 end
	end

	return count
end

function typecount(tb,typetable,t)
	local i = 0
	local count = 0

	if t == "kasu" then i = 1
	elseif t == "tan" then i = 2
	elseif t == "tane" then i = 3
	elseif t == "ko" then i = 4 end

	for _,v in ipairs(tb) do
		if typetable[v] > i then count = count + 1 end
	end

	return count
end

-- This finds out how many cards in the table matches the card played, and return them as a table.
function match(tb,played)
	local i = 0
	local month = math.floor((played-1)/4) -- No need to +1 as we are only comparing here.
	local result = {}
	for _,v in ipairs(tb) do
		if math.floor((v-1)/4) == month then
			i = i + 1
			result[i] = v
		end
	end
	return result
end

-- This finds a space in table (represented by value -1) and places the card in it.
-- addFill is easy, just do table[#table+1] = card.
function addSpace(tb,card)
	for i,v in ipairs(tb) do
		if v == -1 then tb[i] = card return end
	end
	tb[#tb+1] = card
	return
end

-- This removes a card in table and every card behind fills in the space.
function removeFill(tb,card)
	local found = false
	for i,v in ipairs(tb) do
		if not found then
			if v == card then found = true tb[i] = tb[i+1] end
		else tb[i] = tb[i+1] end
	end
	return
end

-- Removes a card in table, leaves a space behind
function removeSpace(tb,card)
	for i,v in ipairs(tb) do
		if v == card then tb[i] = -1 return end
	end
end

function flip(tb)
	for i,v in ipairs(tb) do
		if v ~= -1 then
			tb[i] = -1
			return v
		end
	end
end

function updateCount(tb,index,card)
	local cardtype = index[card]
	if not cardtype then print(card) end
	if cardtype >= 8 then 
		tb[4] = tb[4] + 1 
		cardtype = cardtype - 8 
	end
	if cardtype >= 4 then 
		tb[3] = tb[3] + 1 
		cardtype = cardtype - 4 
	end
	if cardtype >= 2 then 
		tb[2] = tb[2] + 1 
		cardtype = cardtype - 2 
	end
	if cardtype >= 1 then 
		tb[1] = tb[1] + 1 
	end
end

function copy(tb)
	local cp = {}
	for i,v in pairs(tb) do
		cp[i] = v
	end
	return cp
end

function newgame(board,env)
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
	board.now = env.months[env.current_round % #env.months]
end
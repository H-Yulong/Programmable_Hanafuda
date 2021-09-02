require ("lib.Tserial")
require ("game.utils.utilFunctions")

gamedata = Tserial.unpack(...)
board = gamedata.board
env = gamedata.env
channel = love.thread.getChannel("com")

----------------------------------------------------
-- Play a card, it always plays the left-most one
-- If choice needed, always chooses the first one
----------------------------------------------------

card = board.CHand[1]

removeFill(board.CHand,card)

matches = match(board.onboard,card)
if #matches == 2 then matches[2] = nil end
if #matches == 0 then 
	addSpace(board.onboard,card) 
else 
	addSpace(board.CGot,card)
	updateCount(board.CCount,env.types,card) 
end
for _,v in ipairs(matches) do
	removeSpace(board.onboard,v)
	addSpace(board.CGot,v)
	updateCount(board.CCount,env.types,v) 
end

channel:push(Tserial.pack({card = card,matched = matches}))

----------------------------------------------------
-- Flip a card, always chooses the first one
----------------------------------------------------

flip = board.CFlip[1]
removeFill(board.CFlip,flip)

fmatches = match(board.onboard,flip)
if #fmatches == 2 then fmatches[2] = nil end
if #fmatches == 0 then 
	addSpace(board.onboard,flip) 
else 
	addSpace(board.CGot,flip)
	updateCount(board.CCount,env.types,flip) 
end
for _,v in ipairs(fmatches) do
	removeSpace(board.onboard,v)
	addSpace(board.CGot,v)
	updateCount(board.CCount,env.types,v)
end

channel:push(Tserial.pack({card = flip,matched = fmatches}))

----------------------------------------------------
-- If opponent has yaku then stop
-- Otherwize, koi koi!
----------------------------------------------------
channel:push(gamedata.board.PCount[5] == 0)
--channel:push(true)




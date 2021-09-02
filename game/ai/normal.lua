require ("lib.Tserial")
require ("game.utils.utilFunctions")

gamedata = Tserial.unpack(...)
board = gamedata.board
env = gamedata.env
channel = love.thread.getChannel("com")

----------------------------------------------------
--[[ 
Computer in Normal difficulty follows this logic:
	1. If playing a card leads to a yaku, then it plays it.
	2. Otherwise, if playing a card matches some cards on board, then it plays it.
	3. Otherwise, play a card in hand.

Normal computer is aware a little bit of cards' values.
It tends to play cards with the highest value first if there are matches,
and it play cards with the least value if there is no match.

A card's value depends on:
	- scores of the yaku that this card leads to
	- cardtype
	- special meanings in hanadufa-koikoi
	- other cards in hand/onboard/opponent's got region

Only koi-koi if it is losing.
]]
----------------------------------------------------



local function isTerminate(s,terminate)
	if type(terminate) == "table" then
		for _,v in ipairs(terminate) do
			if s == v then return true end
		end
		return false
	else return s == terminate end
end


--[[
  Procedure that parses conditions with the following definition:
  <conditions> ::= <number> <loc> | <cardname> <loc> 
                  | win | draw | oya
                  | #<cardtype> op <number> <loc>
                  | #month <month> op <number> <loc>
                  | #groupof <number> <op> <number> <loc>
                  | <conditions> and <conditions>
                  | <conditions> or <conditions>
                  | not <conditions>
                  | (<conditions>)
  <month> ::= <number> | any
  <number> ::= any non-negative integer
  <cardname> ::= any defined cardname
  <op> ::= > | < | >= | <= | <> | ==
  <loc> ::= hand | got | ophand | opgot | onboard
  <cardtype> ::= kasu | tan | tane | ko | koi

  Note: all <loc> are optional with default value "got".
  E.g. "sake got" and "sake" have the same meaning.
]]--
local function parseCondition(s,name,sugar,terminate,free_list)
  local foundWith = false
  local waitingExpr = true
  local condition = ""
  local bracket_counter = 0

  while not foundWith do

    local token = s:match("%S+")

    if token:match("%d+") == token then
    --[1-card_range]
      if not waitingExpr then return "Error in bonus "..name..": unexpected token "..token.." found." end
      waitingExpr = false
      local i = tonumber(token)
      if i < 1 or i > 256 then return "Error in bonus "..name..": invalid card number "..token.." found." end
      s = s:sub(#token+2)
      if s:match("%S+") == "onboard" then
        condition = condition .. "contains(onboard,"..i..")"
        s = s:sub(9)
      elseif s:match("%S+") == "hand" then
        condition = condition .. "contains(hand,"..i..")"
        s = s:sub(6)
      elseif s:match("%S+") == "got" then
        condition = condition .. "contains(got,"..i..")"
        s = s:sub(5)
      elseif s:match("%S+") == "ophand" then
        condition = condition .. "contains(opponent_hand,"..i..")"
        s = s:sub(8)
      elseif s:match("%S+") == "opgot" then
        condition = condition .. "contains(opponent_got,"..i..")"
        s = s:sub(7)
      else
        condition = condition .. "contains(got,"..i..")"
      end
    elseif sugar[token] then
    -- <sugar words>
      if not waitingExpr then return "Error in bonus "..name..": unexpected token "..token.." found." end
      waitingExpr = false
      local i = tonumber(sugar[token])
      s = s:sub(#token+2)
      if s:match("%S+") == "onboard" then
        condition = condition .. "contains(onboard,"..i..")"
        s = s:sub(9)
      elseif s:match("%S+") == "hand" then
        condition = condition .. "contains(hand,"..i..")"
        s = s:sub(6)
      elseif s:match("%S+") == "got" then
        condition = condition .. "contains(got,"..i..")"
        s = s:sub(5)
      elseif s:match("%S+") == "ophand" then
        condition = condition .. "contains(opponent_hand,"..i..")"
        s = s:sub(8)
      elseif s:match("%S+") == "opgot" then
        condition = condition .. "contains(opponent_got,"..i..")"
        s = s:sub(7)
      else
        condition = condition .. "contains(got,"..i..")"
      end
    elseif token == "oya" then
      if not waitingExpr then return "Error in bonus "..name..": unexpected token "..token.." found." end
      waitingExpr = false
      condition = condition .. " oya "
      s = s:sub(5)
    elseif token == "win" then
      if not waitingExpr then return "Error in bonus "..name..": unexpected token "..token.." found." end
      waitingExpr = false
      condition = condition .. " win "
      s = s:sub(5)
    elseif token == "draw" then
      if not waitingExpr then return "Error in bonus "..name..": unexpected token "..token.." found." end
      waitingExpr = false
      condition = condition .. " draw "
      s = s:sub(6)
    elseif token:sub(1,1) == "#" then
      if not waitingExpr then return "Error in bonus "..name..": unexpected token "..token.." found." end
        waitingExpr = false
    -- #type op number onboard
      if token == "#month" then
        --#month <month>
        s = s:sub(8)

        local month = s:match("%S+")
        local i = tonumber(month)

        --Match month: [1-12,now]
        if (month == "now") or (i and (i >= 1) ) then

          s = s:sub(#month + 2)

          --Match op
          local op = s:match("%S+")
          if (op == "==") or (op == ">=") or (op == "<=") or (op == ">") or (op == "<") or (op == "<>") then
            s = s:sub(#op + 2)
            if op == "<>" then op = "~=" end

            --Match number
            local num = s:match("%S+")
            if (tonumber(num)) and (num == num:match("%d+"))then
              s = s:sub(#num + 2)

            --Match onboard (optional)
            if s:match("%S+") == "onboard" then
              condition = condition .. "(monthcount(onboard,\""..month.."\",now)".." "..op.." "..num..")"
              s = s:sub(9)
            elseif s:match("%S+") == "hand" then
              condition = condition .. "(monthcount(hand,\""..month.."\",now)".." "..op.." "..num..")"
              s = s:sub(6)
            elseif s:match("%S+") == "got" then
              condition = condition .. "(monthcount(got,\""..month.."\",now)".." "..op.." "..num..")"
              s = s:sub(5)
            elseif s:match("%S+") == "ophand" then
              condition = condition .. "(monthcount(opponent_hand,\""..month.."\",now)".." "..op.." "..num..")"
              s = s:sub(8)
            elseif s:match("%S+") == "opgot" then
              condition = condition .. "(monthcount(opponent_got,\""..month.."\",now)".." "..op.." "..num..")"
              s = s:sub(7)
            else
              condition = condition .. "(monthcount(hand,\""..month.."\",now)".." "..op.." "..num..")"
            end
              else return "Error in bonus "..name..": an non-negative integer is expected but '" .. num .. "' is found." end
            else return "Error in bonus "..name..": unexpected operator " .. op .. " found." end
          else return "Error in bonus "..name..": "..month.." found, but month must be 'now' or a number greater than 1." end

        elseif token == "#groupof" then
        --#groupof <group size>
        s = s:sub(10)

        local size = s:match("%S+")
        local i = tonumber(size)

        if (i and (i >= 1) )then

          s = s:sub(#size + 2)

          --Match op
          local op = s:match("%S+")
          if (op == "==") or (op == ">=") or (op == "<=") or (op == ">") or (op == "<") or (op == "<>") then
            s = s:sub(#op + 2)
            if op == "<>" then op = "~=" end

            --Match number
            local num = s:match("%S+")
            if (tonumber(num)) and (num == num:match("%d+"))then
              s = s:sub(#num + 2)

            --Match loc
            if s:match("%S+") == "onboard" then
              condition = condition .. "(groupcount(onboard,\""..size.."\")".." "..op.." "..num..")"
              s = s:sub(9)
            elseif s:match("%S+") == "hand" then
              condition = condition .. "(groupcount(hand,\""..size.."\")".." "..op.." "..num..")"
              s = s:sub(6)
            elseif s:match("%S+") == "got" then
              condition = condition .. "(groupcount(got,\""..size.."\")".." "..op.." "..num..")"
              s = s:sub(5)
            elseif s:match("%S+") == "ophand" then
              condition = condition .. "(groupcount(opponent_hand,\""..size.."\")".." "..op.." "..num..")"
              s = s:sub(8)
            elseif s:match("%S+") == "opgot" then
              condition = condition .. "(groupcount(opponent_got,\""..size.."\")".." "..op.." "..num..")"
              s = s:sub(7)
            else
              condition = condition .. "(groupcount(hand,\""..size.."\")".." "..op.." "..num..")"
            end
              else return "Error in bonus "..name..": an non-negative integer is expected but '" .. num .. "' is found." end
            else return "Error in bonus "..name..": unexpected operator " .. op .. " found." end
          else return "Error in bonus "..name..": "..size.." found, but group size must be a number greater than 1." end

        elseif (token == "#kasu") or (token == "#tan") or (token == "#tane") or (token == "#ko") or (token == "#koi") then

        s = s:sub(#token + 2)

        local op = s:match("%S+")
        if (op == "==") or (op == ">=") or (op == "<=") or (op == ">") or (op == "<") or (op == "<>") then
        s = s:sub(#op + 2)

        if op == "<>" then op = "~=" end

        local num = s:match("%S+")
        if (tonumber(num)) and (num == num:match("%d+"))then
          s = s:sub(#num + 2)

          local index
          if token == "#kasu" then index = 1
          elseif token == "#tan" then index = 2
          elseif token == "#tane" then index = 3
          elseif token == "#ko" then index = 4
          elseif token == "#koi" then index = 5
          end

          if s:match("%S+") == "onboard" then 
          	if (index == 5) then return "Error in bonus "..name..": cannot count #koi onboard." end
            s = s:sub(9)
            condition = condition .. "(typecount(onboard,types,\""..token:sub(2).."\") "..op.." "..num..") "
          elseif s:match("%S+") == "hand" then
            if (index == 5) then return "Error in bonus "..name..": cannot count #koi in hand." end
            condition = condition .. "(typecount(hand,types,\""..token:sub(2).."\") "..op.." "..num..") "
            s = s:sub(6)
          elseif s:match("%S+") == "got" then
            condition = condition.."(count["..index.."] "..op.." "..num..") "
            s = s:sub(5)
          elseif s:match("%S+") == "ophand" then
            if (index == 5) then return "Error in bonus "..name..": cannot count #koi in opponent's hand." end
            condition = condition .. "(typecount(opponent_hand,types,\""..token:sub(2).."\") "..op.." "..num..") "
            s = s:sub(8)
          elseif s:match("%S+") == "opgot" then
            condition = condition.."(opponent_count["..index.."] "..op.." "..num..") "
            s = s:sub(7)
          else 
          	condition = condition.."(count["..index.."] "..op.." "..num..") "
          end



        else return "Error in bonus "..name..": an non-negative integer is expected but '" .. num .. "' is found." end
      else return "Error in bonus "..name..": unexpected operator " .. op .. " found." end

      else return "Error in bonus "..name..": unexpected token " .. token:sub(2).. " found after #." end
    elseif token == "and" then
    -- AND
      if waitingExpr then return "Error in bonus "..name..": expression expected but 'and' found." end
      waitingExpr = true
      condition = condition .. " and "
      s = s:sub(5)
    elseif token == "or" then
    -- OR
      if waitingExpr then return "Error in bonus "..name..": expression expected but 'or' found." end
      waitingExpr = true
      condition = condition .. " or "
      s = s:sub(4)
    elseif token == "not" then
    -- NOT
      s = s:sub(5)
      if not waitingExpr then return "Error in bonus "..name..": unexpected token 'not' found." end
      condition = condition.. "not "
    elseif token == "(" then
    -- Left Bracket
      if not waitingExpr then return "Error in bonus "..name..": unexpected token '(' found." end
      bracket_counter = bracket_counter + 1
      condition = condition .. "("
      s = s:sub(3)
    elseif token == ")" then
    -- Right Bracket
      bracket_counter = bracket_counter - 1
      if bracket_counter < 0 then return "Error in bonus "..name..": single right-bracket found." end
      if waitingExpr then return "Error in bonus "..name..": unexpected token ')' found." end
      waitingExpr = false
      condition = condition ..")" 
      s = s:sub(3)
    elseif isTerminate(token,terminate) then
    -- With, termination indication
      foundWith = true
      if bracket_counter > 0 then return "Error in bonus "..name..": "..bracket_counter.." open brackets found." end
      s = s:sub(#terminate+2)
    elseif token == token:match("[%w][%w_]*") then
    -- Yaku name
    	if not waitingExpr then return "Error in bonus "..name..": unexpected token '"..token.."' found." end
    	waitingExpr = false
    	free_list[#free_list+1] = token
    	condition = condition.."(contains(yaku_list,'"..token.."') and yaku_record['"..token.."'])"
    	s = s:sub(#token + 2)
    else return "Error in bonus "..name..": unexpected token '"..token.."' found." end
  end
  return s,condition
end


--[[
  Procedure that parses scores with the following definition:
  <score> ::= <number> | #<cardtype> <loc>
              | #month <month> <loc>
              | #groupof <number> <loc>
              | <score> <op> <score> | (<score>)
  <number> ::= any non-negative integer
  <cardtype> ::= kasu | tan | tane | ko | koi
  <loc> ::= hand | got | ophand | opgot | onboard
  <op> ::= + | - | * | / | ^
  <month> ::= <number> | any

  Note: all <loc> are optional with default value "got".
  Division results are rounded down to the nearest integer (floor).
]]--
local function parseScore(s,name,sugar,terminate)
  local score = ""
  if s:match("%S+") == "restart" then 
      score = "restart"
      s = s:sub(9)
      if s:sub(1,1) ~= terminate then return "Error in bonus "..name..": '"..terminate.."' expected but '" .. s:match("%S+") .. "' found." end
  else
      local waitingNumber = true
      local foundEnd = false
      local bracket_counter = 0

      while not foundEnd do
        local token = s:match("%S+")
        
        if tonumber(token) and token == token:match("%d+") then
        --integer
          if not waitingNumber then return "Error in bonus "..name..": operator expected but "..token.." found." end
          waitingNumber = false
          s = s:sub(#token + 2)
          score = score..token.." "
        elseif (token == "#kasu") or (token == "#tan") or (token == "#tane") or (token == "#ko") then
        --#<cardtype>
          if not waitingNumber then return "Error in bonus "..name..": operator expected but "..token.." found." end
          waitingNumber = false

          s = s:sub(#token + 2)
          if s:match("%S+") == "onboard" then
            score = score.."typecount(onboard,types,\""..token:sub(2).."\") "
            s = s:sub(9)
          elseif s:match("%S+") == "hand" then
            score = score.."typecount(hand,types,\""..token:sub(2).."\") "
            s = s:sub(6)
          elseif s:match("%S+") == "got" then
            score = score.."typecount(got,types,\""..token:sub(2).."\") "
            s = s:sub(5)
          elseif s:match("%S+") == "ophand" then
            score = score.."typecount(opponent_hand,types,\""..token:sub(2).."\") "
            s = s:sub(8)
          elseif s:match("%S+") == "opgot" then
            score = score.."typecount(opponent_got,types,\""..token:sub(2).."\") "
            s = s:sub(7)
          else
            score = score.."typecount(got,types,\""..token:sub(2).."\") "
           end
        elseif (token == "#koi") then
          if not waitingNumber then return "Error in bonus "..name..": operator expected but "..token.." found." end
          waitingNumber = false

          s = s:sub(#token + 2)
          if s:match("%S+") == "onboard" then
            return "Error in bonus "..name..": cannot count koi-koi on board!"
          elseif s:match("%S+") == "hand" then
            return "Error in bonus "..name..": cannot count koi-koi in hand!"
          elseif s:match("%S+") == "got" then
            score = score.." count[5] "
            s = s:sub(5)
          elseif s:match("%S+") == "ophand" then
            return "Error in bonus "..name..": cannot count koi-koi in opponent's hand!"
          elseif s:match("%S+") == "opgot" then
            score = score.." opponent_count[5] "
            s = s:sub(7)
          else
            score = score.." count[5] "
          end

        elseif (token == "#month") then
        --#month
          s = s:sub(#token + 2)
          if not waitingNumber then return "Error in bonus "..name..": operator expected but "..token.." "..s:match("%S+").." found." end

          local month = s:match("%S+")
          local i = tonumber(month)

          --Match month: [1-month_range,now]
          if (month == "now") or (i and (i >= 1) )then
            waitingNumber = false
            s = s:sub(#month + 2)
            if s:match("%S+") == "onboard" then
                score = score.."monthcount(onboard,\""..month.."\") "
              s = s:sub(9)
            elseif s:match("%S+") == "hand" then
              score = score.."monthcount(hand,\""..month.."\") "
              s = s:sub(6)
            elseif s:match("%S+") == "got" then
              score = score.."monthcount(got,\""..month.."\") "
              s = s:sub(5)
            elseif s:match("%S+") == "ophand" then
              score = score.."monthcount(opponent_hand,\""..month.."\") "
              s = s:sub(8)
            elseif s:match("%S+") == "opgot" then
              score = score.."monthcount(opponent_got,\""..month.."\") "
              s = s:sub(7)
            else
              score = score.."monthcount(got,\""..month.."\") "
            end
          else return "Error in bonus "..name..": "..month.." found, but month must be between 1 and month_range or 'now'." end 
          
        elseif token == "#groupof" then 
          s = s:sub(#token + 2)
          if not waitingNumber then return "Error in bonus "..name..": operator expected but "..token.." "..s:match("%S+").." found." end

          local size = s:match("%S+")
          local i = tonumber(size)

          --Match month: [1-month_range,now]
          if (i and (i >= 1) )then
            waitingNumber = false
            s = s:sub(#size + 2)
            if s:match("%S+") == "onboard" then
              score = score.."groupcount(onboard,\""..size.."\") "
              s = s:sub(9)
            elseif s:match("%S+") == "hand" then
              score = score.."groupcount(hand,\""..size.."\") "
              s = s:sub(6)
            elseif s:match("%S+") == "got" then
              score = score.."groupcount(got,\""..size.."\") "
              s = s:sub(5)
            elseif s:match("%S+") == "ophand" then
              score = score.."groupcount(opponent_hand,\""..size.."\") "
              s = s:sub(8)
            elseif s:match("%S+") == "opgot" then
              score = score.."groupcount(opponent_got,\""..size.."\") "
              s = s:sub(7)
            else
              score = score.."groupcount(got,\""..size.."\") "
            end
          else return "Error in bonus "..name..": "..size.." found, but but group size must be a number greater than 1." end 

        elseif (token == "+") or (token == "-") or (token == "*") or (token == "/") or (token == "^") then
        --Operators
          if waitingNumber then return "Error in bonus "..name..": number expected but "..token.." found." end
          waitingNumber = true
          s = s:sub(3)
          score = score..token.." "
        elseif token == "(" then
          if not waitingNumber then return "Error in bonus "..name..": unexpected token '(' found." end
          s = s:sub(3)
          bracket_counter = bracket_counter + 1
          score = score.."("
        elseif token == ")" then 
          bracket_counter = bracket_counter - 1
          if waitingNumber then return "Error in bonus "..name..": unexpected token ')' found." end
          if bracket_counter < 0 then return "Error in bonus "..name..": single right-bracket found." end
          waitingNumber = false
          s = s:sub(3)
          score = score..")"
        elseif token == "score" then
        	if not waitingNumber then return "Error in bonus "..name..": unexpected token 'score' found." end
        	waitingNumber = false
        	score = score.."score "
        	s = s:sub(7)
        elseif isTerminate(token,terminate) then
          if waitingNumber then return "Error in bonus "..name..": number expected." end
          if bracket_counter > 0 then return "Error in bonus "..name..": "..bracket_counter.." open brackets found." end
          foundEnd = true
        else return "Error in bonus "..name..": unexpected token "..token.." found." end
        end
      end
  return s,score
end

local function parseBonus(s,line,sugar,isOutput)

  local result = "return function(board, types, player_win, com_win, score, isPlayer) \n"
  result = result..[[
      local hand,got,count
      local opponent_hand,opponent_got,opponent_count
      local oya,namelist,yaku_list,yaku_record,win

      if isPlayer then
        hand = board.PHand
        got = board.PGot
        count = board.PCount

        opponent_hand = board.CHand
        opponent_got = board.CGot
        opponent_count = board.CCount

        oya = board.playerfirst
        win = player_win
        namelist = board.PNamelist.bonus
        yaku_list = board.PNamelist.yakus
        yaku_record = board.PRecord.yakus
      else
        hand = board.CHand
        got = board.CGot
        count = board.CCount

        opponent_hand = board.PHand
        opponent_got = board.PGot
        opponent_count = board.PCount
        
        oya = not board.playerfirst
        win = com_win
        namelist = board.CNamelist.bonus
        yaku_list = board.CNamelist.yakus
        yaku_record = board.CRecord.yakus
      end

      local now = board.now
      local draw = (not player_win) and (not com_win)
      local onboard = board.onboard
      local satisfied = false
  ]]


  --Match name, with sanity check
  local name = s:match("%S+") 
  if name ~= name:match("[%w][%w_]*") then return "bonus",nil,nil,nil,nil,"Error in bonus "..line..": illegal name '"..name.."' found." end
  s = s:sub(#name+2)

  local free_list = {}

  if name ~= "order" then
	  --Match overwrites
	  local over_list = {}
	  local over_all = false
	  local waitingName = true
	  if s:sub(1,11) == "overwrites " then
	    s = s:sub(12)
	    while s:sub(1,2) ~= "= " do
	      local token = s:match("%S+")
	      if token == "all" then
	        over_all = true
	        waitingName = false
	        s = s:sub(5)
	      elseif token == token:match("[%w][%w_]*") then
	        waitingName = false
	        over_list[#over_list+1] = token
	        s = s:sub(#token+2)
	      elseif token == "," then
	        if waitingName then return "bonus",nil,nil,nil,nil,"Error in bonus "..name..": comma expected but '"..token.."' found." end
	        waitingName = true
	        s = s:sub(3)
	      else return "bonus",nil,nil,nil,nil,"Error in bonus "..name..": illegal name '"..token.."' found." end
	    end
	    if waitingName then return "bonus",nil,nil,nil,nil,"Error in bonus "..name..": overwritten bonus name expected." end
	  end

	  --Match =
	  if s:sub(1,2) ~= "= " then return "bonus",nil,nil,nil,nil,"Error in bonus "..name..": '=' expected but '" .. s:match("%S+") .. "' found." end
	  s = s:sub(3)

	  --Match if
	  if s:sub(1,3) ~= "if " then return "bonus",nil,nil,nil,nil,"Error in bonus "..name..": 'if' expected but '" .. s:match("%S+") .. "' found." end
	  s = s:sub(4)

	  --Match conditions
	  local condition = ""
	  s,condition = parseCondition(s,name,sugar,"then",free_list)
	  if not condition then return "bonus",nil,nil,nil,nil,s end
	  result = result .. "if "..condition.." then "

	  local score = ""
	  s,score = parseScore(s,name,sugar,{"elseif","else",";"})
	  if not score then return "bonus",nil,nil,nil,nil,s end
	  result = result.."score = "..score.." \n satisfied = true\n"



	  local token_n
	  token_n = s:match("%S+")
	  while not ((token_n == "else") or (token_n == ";")) do
	  	
	  	if token_n == "elseif" then
	  		s = s:sub(#token_n+2)

	  		s,condition = parseCondition(s,name,sugar,"then",free_list)
	  		if not condition then return "bonus",nil,nil,nil,nil,s end
	  		result = result .. "elseif "..condition.." then "

	  		s,score = parseScore(s,name,sugar,{"elseif","else",";"})
	  		if not score then return "bonus",nil,nil,nil,nil,s end
	  		result = result.."score = "..score.." \n satisfied = true\n"

	  		token_n = s:match("%S+")
	  	else return "bonus",nil,nil,nil,nil,"Error in bonus "..name..": 'elseif','else' or ';' expected but '" .. token_n .. "' found." end
	  end

	  if token_n == "else" then
	  	s = s:sub(6)
	  	s,score = parseScore(s,name,sugar,";")
	  	if not score then return "bonus",nil,nil,nil,nil,s end
	  	result = result.."else score = "..score.." \n satisfied = true\n"
	  end

	  --End for the if clause
	  result = result.."end\n"
	  
	  --Handle overwrites and return
    result = result.."if satisfied then\n"
	  if over_all then
	  	result = result..
      	[[
        for i,v in pairs(namelist) do 
          if v ~= "]]..name..[[" then namelist[i] = nil end
        end
        ]]
    else
    	result = result.. "for i,v in pairs(namelist) do\n"
    	for _,v in ipairs(over_list) do
      	result = result .. "if v == \""..v.."\" then namelist[i] = nil end\n"
    	end
    	result = result.."end\n"
     end

    result = result.."return score\n end\n"

    result = result.."end\n"

	   --print(result)

	  return "bonus",result,name,over_list,nil,nil,free_list

  else

    --Match =
    if s:sub(1,2) ~= "= " then return "bonus",nil,nil,nil,nil,"Error in bonus "..name..": '=' expected but '" .. s:match("%S+") .. "' found." end
    s = s:sub(3)

    local foundEnd = false
    local namelist = {}
    local waitingName = true
    while not foundEnd do
      local token = s:match("%S+")
      if token == token:match("[%w][%w_]*") then
        if not waitingName then return "bonus",nil,nil,nil,nil,"Error in bonus "..name..": unexpected symbol '" .. token .. "' found." end
        waitingName = false
        namelist[#namelist + 1] = token
        s = s:sub(#token + 2)
      elseif token == "," then
        if waitingName then return "bonus",nil,nil,nil,nil,"Error in bonus "..name..": name expected, but unexpected symbol ',' found." end
        waitingName = true
        s = s:sub(3)
      elseif token == ";" then
        if waitingName then return "bonus",nil,nil,nil,nil,"Error in bonus "..name..": name expected, but unexpected symbol ';' found." end
        foundEnd = true
      else return "bonus",nil,nil,nil,nil,"Error in bonus "..name..": name expected, but unexpected symbol '" .. token .. "' found." end
    end

    return "bonus_order",nil,namelist
  end
end

return parseBonus
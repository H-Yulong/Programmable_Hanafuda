--[[
  Procedure that parses conditions with the following definition:
  <conditions> ::= <number> <loc> | <cardname> <loc> | oya
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
  <loc> ::= hand | ophand | onboard
  <cardtype> ::= kasu | tan | tane | ko

  Note: all <loc> are optional with default value "hand".
  E.g. "sake hand" and "sake" have the same meaning.
]]--
local function parseCondition(s,name,sugar,terminate)
  local foundWith = false
  local waitingExpr = true
  local condition = ""
  local bracket_counter = 0

  while not foundWith do

    local token = s:match("%S+")

    if token:match("%d+") == token then
    --[1-card_range]
      if not waitingExpr then return "Error in precheck "..name..": unexpected token "..token.." found." end
      waitingExpr = false
      local i = tonumber(token)
      if i < 1 or i > 256 then return "Error in precheck "..name..": invalid card number "..token.." found." end
      s = s:sub(#token+2)
      if s:match("%S+") == "onboard" then
        condition = condition .. "contains(onboard,"..i..")"
        s = s:sub(9)
      elseif s:match("%S+") == "ophand" then
        condition = condition .. "contains(opponent_hand,"..i.." )"
        s = s:sub(10)
      elseif s:match("%S+") == "hand" then
        condition = condition .. "contains(hand,"..i..")"
        s = s:sub(6)
      else
        condition = condition .. "contains(hand,"..i..")"
      end
    elseif sugar[token] then
    -- <sugar words>
      if not waitingExpr then return "Error in precheck "..name..": unexpected token "..token.." found." end
      waitingExpr = false
      local i = tonumber(sugar[token])
      s = s:sub(#token+2)
      if s:match("%S+") == "onboard" then
        condition = condition .. "contains(onboard,"..i..")"
        s = s:sub(9)
      elseif s:match("%S+") == "ophand" then
        condition = condition .. "contains(opponent_hand,"..i.." )"
        s = s:sub(10)
      elseif s:match("%S+") == "hand" then
        condition = condition .. "contains(hand,"..i..")"
        s = s:sub(6)
      else
        condition = condition .. "contains(hand,"..i..")"
      end
    elseif token == "oya" then
      if not waitingExpr then return "Error in precheck "..name..": unexpected token "..token.." found." end
      waitingExpr = false
      condition = condition .. " oya "
      s = s:sub(5)
    elseif token:sub(1,1) == "#" then
      if not waitingExpr then return "Error in precheck "..name..": unexpected token "..token.." found." end
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
              s = s:sub(9)
              condition = condition .. "(monthcount(onboard,\""..month.."\",now)".." "..op.." "..num..")"
            elseif s:match("%S+") == "ophand" then
              condition = condition .. "(monthcount(opponent_hand,\""..month.."\",now)".." "..op.." "..num..")"
              s = s:sub(10)
            elseif s:match("%S+") == "hand" then
              condition = condition .. "(monthcount(hand,\""..month.."\",now)".." "..op.." "..num..")"
              s = s:sub(6)
            else 
              condition = condition .. "(monthcount(hand,\""..month.."\",now)".." "..op.." "..num..")"
            end
              else return "Error in precheck "..name..": an non-negative integer is expected but '" .. num .. "' is found." end
            else return "Error in precheck "..name..": unexpected operator " .. op .. " found." end
          else return "Error in precheck "..name..": "..month.." found, but month must be 'now' or a number greater than 1." end

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

            --Match accu (optional)
            if s:match("%S+") == "onboard" then
              s = s:sub(9)
              condition = condition .. "(groupcount(onboard,\""..size.."\")".." "..op.." "..num..")"
            elseif s:match("%S+") == "ophand" then
              condition = condition .. "(groupcount(opponent_hand,\""..size.."\")".." "..op.." "..num..")"
              s = s:sub(10)
            elseif s:match("%S+") == "hand" then
              condition = condition .. "(groupcount(hand,\""..size.."\")".." "..op.." "..num..")"
              s = s:sub(6)
            else 
              condition = condition .. "(groupcount(hand,\""..size.."\")".." "..op.." "..num..")"
            end
              else return "Error in precheck "..name..": an non-negative integer is expected but '" .. num .. "' is found." end
            else return "Error in precheck "..name..": unexpected operator " .. op .. " found." end
          else return "Error in precheck "..name..": "..size.." found, but group size must be a number greater than 1." end

        elseif (token == "#kasu") or (token == "#tan") or (token == "#tane") or (token == "#ko") then

        s = s:sub(#token + 2)

        local op = s:match("%S+")
        if (op == "==") or (op == ">=") or (op == "<=") or (op == ">") or (op == "<") or (op == "<>") then
        s = s:sub(#op + 2)

        if op == "<>" then op = "~=" end

        local num = s:match("%S+")
        if (tonumber(num)) and (num == num:match("%d+"))then
          s = s:sub(#num + 2)

          if s:match("%S+") == "onboard" then
            condition = condition .. "(typecount(onboard,types,\""..token:sub(2).."\") "..op.." "..num..") "
            s = s:sub(9)
          elseif s:match("%S+") == "ophand" then
            condition = condition .. "(typecount(opponent_hand,types,\""..token:sub(2).."\") "..op.." "..num..") "
            s = s:sub(10)
          elseif s:match("%S+") == "hand" then
            condition = condition .. "(typecount(hand,types,\""..token:sub(2).."\") "..op.." "..num..") "
            s = s:sub(6)
          else 
            condition = condition .. "(typecount(hand,types,\""..token:sub(2).."\") "..op.." "..num..") "
          end

        else return "Error in precheck "..name..": an non-negative integer is expected but '" .. num .. "' is found." end
      else return "Error in precheck "..name..": unexpected operator " .. op .. " found." end

      else return "Error in precheck "..name..": unexpected token " .. token:sub(2).. " found after #." end
    elseif token == "and" then
    -- AND
      if waitingExpr then return "Error in precheck "..name..": expression expected but 'and' found." end
      waitingExpr = true
      condition = condition .. " and "
      s = s:sub(5)
    elseif token == "or" then
    -- OR
      if waitingExpr then return "Error in precheck "..name..": expression expected but 'or' found." end
      waitingExpr = true
      condition = condition .. " or "
      s = s:sub(4)
    elseif token == "not" then
    -- NOT
      s = s:sub(5)
      if not waitingExpr then return "Error in precheck "..name..": unexpected token 'not' found." end
      condition = condition.. "not "
    elseif token == "(" then
    -- Left Bracket
      if not waitingExpr then return "Error in precheck "..name..": unexpected token '(' found." end
      bracket_counter = bracket_counter + 1
      condition = condition .. "("
      s = s:sub(3)
    elseif token == ")" then
    -- Right Bracket
      bracket_counter = bracket_counter - 1
      if bracket_counter < 0 then return "Error in precheck "..name..": single right-bracket found." end
      if waitingExpr then return "Error in precheck "..name..": unexpected token ')' found." end
      waitingExpr = false
      condition = condition ..")" 
      s = s:sub(3)
    elseif token == terminate then
    -- With, termination indication
      foundWith = true
      if bracket_counter > 0 then return "Error in precheck "..name..": "..bracket_counter.." open brackets found." end
      s = s:sub(#terminate+2)
    else return "Error in precheck "..name..": unexpected token '"..token.."' found." end
  end
  return s,condition
end


--[[
  Procedure that parses scores with the following definition:
  <score> ::= <number> | restart | #<cardtype> <loc>
              | #month <month> <loc>
              | #groupof <number> <loc>
              | <score> <op> <score> | (<score>)
  <number> ::= any non-negative integer
  <cardtype> ::= kasu | tan | tane | ko | koi
  <loc> ::= hand | ophand | onboard
  <op> ::= + | - | * | /
  <month> ::= <number> | any

  Note: all <loc> are optional with default value "hand".
  Division results are rounded down to the nearest integer (floor).
]]--
local function parseScore(s,name,sugar,terminate)
  local score = ""
  if s:match("%S+") == "restart" then 
      score = "restart"
      s = s:sub(9)
      if s:sub(1,1) ~= terminate then return "Error in precheck "..name..": '"..terminate.."' expected but '" .. s:match("%S+") .. "' found." end
  else
      local waitingNumber = true
      local foundEnd = false
      local bracket_counter = 0

      while not foundEnd do
        local token = s:match("%S+")
        
        if tonumber(token) and token == token:match("%d+") then
        --integer
          if not waitingNumber then return "Error in precheck "..name..": operator expected but "..token.." found." end
          waitingNumber = false
          s = s:sub(#token + 2)
          score = score..token.." "
        elseif (token == "#kasu") or (token == "#tan") or (token == "#tane") or (token == "#ko") or (token == "#koi") then
        --#<cardtype>
          if not waitingNumber then return "Error in precheck "..name..": operator expected but "..token.." found." end
          waitingNumber = false

          s = s:sub(#token + 2)
          if s:match("%S+") == "onboard" then
            s = s:sub(9)
            score = score.."typecount(onboard,types,\""..token:sub(2).."\") "
          elseif s:match("%S+") == "ophand" then
            score = score.."typecount(opponent_hand,types,\""..token:sub(2).."\") "
            s = s:sub(10)
          elseif s:match("%S+") == "hand" then
            score = score.."typecount(hand,types,\""..token:sub(2).."\") "
            s = s:sub(6)
          else 
            score = score.."typecount(hand,types,\""..token:sub(2).."\") "
          end
        elseif (token == "#month") then
        --#month
          s = s:sub(#token + 2)
          if not waitingNumber then return "Error in precheck "..name..": operator expected but "..token.." "..s:match("%S+").." found." end

          local month = s:match("%S+")
          local i = tonumber(month)

          --Match month: [1-month_range,now]
          if (month == "now") or (i and (i >= 1) )then
            waitingNumber = false
            s = s:sub(#month + 2)
            if s:match("%S+") == "onboard" then
              s = s:sub(9)
              score = score.."monthcount(onboard,\""..month.."\") "
            elseif s:match("%S+") == "ophand" then
              score = score.."monthcount(opponent_hand,\""..month.."\") "
              s = s:sub(10)
            elseif s:match("%S+") == "hand" then
              score = score.."monthcount(onboard,\""..month.."\") "
              s = s:sub(6)
            else 
              score = score.."monthcount(hand,\""..month.."\") "
            end
          else return "Error in precheck "..name..": "..month.." found, but month must be between 1 and month_range or 'now'." end 
          
        elseif token == "#groupof" then 
          s = s:sub(#token + 2)
          if not waitingNumber then return "Error in precheck "..name..": operator expected but "..token.." "..s:match("%S+").." found." end

          local size = s:match("%S+")
          local i = tonumber(size)

          --Match group
          if (i and (i >= 1) )then
            waitingNumber = false
            s = s:sub(#size + 2)
            if s:match("%S+") == "onboard" then
              s = s:sub(9)
              score = score.."groupcount(onboard,\""..size.."\") "
            elseif s:match("%S+") == "ophand" then
              score = score.."groupcount(opponent_hand,\""..size.."\") "
              s = s:sub(10)
            elseif s:match("%S+") == "hand" then
              score = score.."groupcount(hand,\""..size.."\") "
              s = s:sub(6)
            else 
              score = score.."groupcount(hand,\""..size.."\") "
            end
          else return "Error in precheck "..name..": "..size.." found, but group size must be a number greater than 1." end 

        elseif (token == "+") or (token == "-") or (token == "*") or (token == "/") then
        --Operators
          if waitingNumber then return "Error in precheck "..name..": number expected but "..token.." found." end
          waitingNumber = true
          s = s:sub(3)
          score = score..token.." "
        elseif token == "(" then
          if not waitingNumber then return "Error in precheck "..name..": unexpected token '(' found." end
          s = s:sub(3)
          bracket_counter = bracket_counter + 1
          score = score.."("
        elseif token == ")" then 
          bracket_counter = bracket_counter - 1
          if waitingNumber then return "Error in precheck "..name..": unexpected token ')' found." end
          if bracket_counter < 0 then return "Error in precheck "..name..": single right-bracket found." end
          waitingNumber = false
          s = s:sub(3)
          score = score..")"
        elseif token == terminate then
          if waitingNumber then return "Error in precheck "..name..": number expected." end
          if bracket_counter > 0 then return "Error in precheck "..name..": "..bracket_counter.." open brackets found." end
          foundEnd = true
        else return "Error in precheck "..name..": unexpected token "..token.." found." end
        end
      end
  return s,score
end



--[[
  Parse precheck definitions in this format:
  precheck <name> overwrites <name>* = <conditions> with score <score>;
  overwrites <name>* part is optional.
]]--
local function parsePrecheck(s,line,sugar,isOutput)

  local result = ""

  --Match name, with sanity check
  local name = s:match("%S+") 
  if name ~= name:match("[%w][%w_]*") then return "precheck",nil,nil,nil,nil,"Error in precheck "..line..": illegal name '"..name.."' found." end
  s = s:sub(#name+2)

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
          if waitingName then return "precheck",nil,nil,nil,nil,"Error in precheck "..name..": comma expected but '"..token.."' found." end
          waitingName = true
          s = s:sub(3)
        else return "precheck",nil,nil,nil,nil,"Error in precheck "..name..": illegal name '"..token.."' found." end
      end
      if waitingName then return "precheck",nil,nil,nil,nil,"Error in precheck "..name..": overwritten precheck name expected." end
    end

     --Match =
    if s:sub(1,2) ~= "= " then return "precheck",nil,nil,nil,nil,"Error in precheck "..name..": '=' expected but '" .. s:match("%S+") .. "' found." end
    s = s:sub(3)



    local condition = ""

    s,condition = parseCondition(s,name,sugar,"with")
    if not condition then return "precheck",nil,nil,nil,nil,s end

    --Match score
    if s:sub(1,6) ~= "score " then return "precheck",nil,nil,nil,nil,"Error in precheck "..name..": 'score' expected but '" .. s:match("%S+") .. "' found." end
    s = s:sub(7)

    local score = ""
    s,score = parseScore(s,name,sugar,";")
    if not score then return "precheck",nil,nil,nil,nil,s end

    if score == "restart" then
      score = "return \"restart\""
    else
      score = "return math.floor( "..score.." )"
    end
    
    result = "return function(board, types, isPlayer)\n"
    result = result..
    [[local hand,opponent_hand,namelist
      if isPlayer then
        hand = board.PHand
        opponent_hand = board.CHand
        oya = board.playerfirst
        namelist = board.PNamelist.precheck
      else
        hand = board.CHand
        opponent_hand = board.PHand
        oya = not board.playerfirst
        namelist = board.CNamelist.precheck
      end
      local now = board.now
      local onboard = board.onboard
    ]]
    result = result .. "if "..condition.." then \n"

    if over_all then
        result = result..
        [[for i,v in pairs(namelist) do 
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
    
    result = result..score.."\n"
    result = result.."end\nend\n"
    
    return "precheck",result,name,over_list
  
  else

    --Match =
    if s:sub(1,2) ~= "= " then return "precheck",nil,nil,nil,nil,"Error in precheck "..name..": '=' expected but '" .. s:match("%S+") .. "' found." end
    s = s:sub(3)

    local foundEnd = false
    local namelist = {}
    local waitingName = true
    while not foundEnd do
      local token = s:match("%S+")
      if token == token:match("[%w][%w_]*") then
        if not waitingName then return "precheck",nil,nil,nil,nil,"Error in precheck "..name..": unexpected symbol '" .. token .. "' found." end
        waitingName = false
        namelist[#namelist + 1] = token
        s = s:sub(#token + 2)
      elseif token == "," then
        if waitingName then return "precheck",nil,nil,nil,nil,"Error in precheck "..name..": name expected, but unexpected symbol ',' found." end
        waitingName = true
        s = s:sub(3)
      elseif token == ";" then
        if waitingName then return "precheck",nil,nil,nil,nil,"Error in precheck "..name..": name expected, but unexpected symbol ';' found." end
        foundEnd = true
      else return "precheck",nil,nil,nil,nil,"Error in precheck "..name..": name expected, but unexpected symbol '" .. token .. "' found." end
    end

    return "precheck_order",nil,namelist
  end

end

return parsePrecheck
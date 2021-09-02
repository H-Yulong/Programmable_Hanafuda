


--[[
  This function extracts the name and rejects illegal names.
  Yaku names must:
    - only contain numbers, letters and "_"
    - not begin with "_"
    - be one of the preserved keywords: "all"
  Inputs: s, line, from inputs of parseYaku()
  Outputs:
    - s : processed definition string
    - name : the extracted name of the yaku
    - err : error message; is nil if none.
]]--
local function matchName(s, line)
  local name = s:match("%S+") 
  if (name ~= name:match("[%w][%w_]*")) and (name ~= "all") then return nil,"Error in yaku "..line..": illegal name '"..name.."' found." end
  s = s:sub(#name+2)
  return s, name, nil
end


--[[
  This function processes the "overwrites <name>* =" part of yaku definition.
  
  "all" is a preserved keyword for <name>. 
  "overwrites all" means ???
  In the case of circular reference, the latter definition has higher priority.
  E.g. yaku def1 overwrites def2 ...
       yaku def2 overwrites def1 ...
    In this case, def1 will be overwritten by def2.

  Inputs: s, line from inputs of parseYaku()
  Outputs:
    - s : processed definition string
    - over_list : an array of yakus to be overwritten
    - over_all : bool, whether this yaku overwrites all
    - err : error message; is nil if none
]]--
local function matchOverwrites(s, line)
  -- Initialization
  local over_list = {}
  local over_all = false

  local waitingName = true

  -- Match keyword "overwrites", skip if not found one
  if s:sub(1,11) == "overwrites " then
    s = s:sub(12)
    -- Match yaku names until "=" is found
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
        if waitingName then return nil,nil, "Error in yaku "..name..": comma expected but '"..token.."' found." end
        waitingName = true
        s = s:sub(3)
      else return nil,nil, "Error in yaku "..name..": illegal name '"..token.."' found." end
    end
    if waitingName then return nil,nil, "Error in yaku "..name..": overwritten yaku name expected." end
  end

  -- Match =
  if s:sub(1,2) ~= "= " then return nil,nil, "Error in yaku "..name..": '=' expected but '" .. s:match("%S+") .. "' found." end
  s = s:sub(3)

  return s, over_list, over_all, err
end


--[[
  This function processes <yaku_expr>.

  <yaku_expr> ::= <card> | #<cardtype> op number accu(optional)| oya | not <yaku_expr>
                 | (<yaku_expr>) | <yaku_expr> and <yaku_expr> | <yaku_expr> or <yaku_expr>
  <card> ::= [1-card_range]| one of the self-defined cardnames
  <cardtype> ::= kasu | tan | tane | ko | koi | month number/now | groupof number
  
  "accu" means that you are comparing with an accumulator instead of a constant, like standard yaku "kasu",
  the accumulator is updated everytime when this yaku is achieved.

  "month now" means the current month.

  Inputs: 
    - s, line, cardnames from inputs of parseYaku()
    - name : this yaku's name

  Outputs:
    -s : processed definition string
    -condition : lua expression that describes this yaku
    -accu_list ： an array of yakus that need accumulators; is {} if none
    -accu_init : a table of <yaku name, initial value> pairs for yakus that need accumulators; is {} if none
    -err : error message; is nil if none
]]--
local function matchYakuexpr(s, line, cardnames, name)


  -- Initialization
  local condition = ""
  local accu_init = {}
  local accu_list = {}

  local foundWith = false
  local waitingExpr = true
  local bracket_counter = 0

  while not foundWith do

    local token = s:match("%S+")

    if token:match("%d+") == token then

    -- [1-card_range]
      if not waitingExpr then return nil,nil,nil,nil, "Error in yaku "..name..": unexpected token "..token.." found." end
      
      waitingExpr = false
      
      local i = tonumber(token)
      if i < 1 or i > 256 then return nil,nil,nil,nil, "Error in yaku "..name..": invalid card number "..token.." found." end
      condition = condition .. "contains(got,"..i..")"
      
      s = s:sub(#token+2)

    elseif cardnames[token] then

    -- self-defined cardnames
      if not waitingExpr then return nil,nil,nil,nil, "Error in yaku "..name..": unexpected token "..token.." found." end
      
      waitingExpr = false

      local i = tonumber(cardnames[token])
      condition = condition .. "contains(got,"..i..")" 

      s = s:sub(#token+2)

    elseif token == "oya" then

    -- oya
      if not waitingExpr then return nil,nil,nil,nil,"Error in yaku "..name..": unexpected token "..token.." found." end
      
      waitingExpr = false
      
      condition = condition .. " oya "
      
      s = s:sub(5)

    elseif token:sub(1,1) == "#" then
    -- #<cardtype> op number accu(optional)
      
      if not waitingExpr then return nil,nil,nil,nil,"Error in yaku "..name..": unexpected token "..token.." found." end
      waitingExpr = false

    -- #type op number accu
      if token == "#month" then
        --#month number
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

              --Match accu (optional)
              if s:match("%S+") == "accu" then

                  if (op == "==") or (op == "~=") then return nil,nil,nil,nil,"Error in yaku "..name..": accu is not allowed after this operator ." end
                    s = s:sub(6)
                  if (op == ">=") or (op == "<=") then 
                    accu_list[#accu_list+1] = "acculist."..name.."_accu_"..(#accu_list+1).." = monthcount(got,\""..month.."\",now) + 1" 
                  else
                    accu_list[#accu_list+1] = "acculist."..name.."_accu_"..(#accu_list+1).." = monthcount(got,\""..month.."\",now)"
                  end

                  accu_init[name.."_accu_"..#accu_list] = tonumber(num)
                  condition = condition .. "(monthcount(got,\""..month.."\",now)".." "..op.." acculist."..name.."_accu_"..#accu_list..")"
              else 
                  condition = condition .. "(monthcount(got,\""..month.."\",now)".." "..op.." "..num..")"
                end

            else return nil,nil,nil,nil,"Error in yaku "..name..": an non-negative integer is expected but '" .. num .. "' is found." end
          
          else return nil,nil,nil,nil,"Error in yaku "..name..": unexpected operator " .. op .. " found." end
      
      else return nil,nil,nil,nil,"Error in yaku "..name..": "..month.." found, but month must be 'now' or a number greater than 1." end

      elseif token == "#groupof" then
        -- #groupof number
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
              if s:match("%S+") == "accu" then
                  if (op == "==") or (op == "~=") then return nil,nil,nil,nil,"Error in yaku "..name..": accu is not allowed after this operator ." end
                  
                  s = s:sub(6)
                  
                  if (op == ">=") or (op == "<=") then 
                    accu_list[#accu_list+1] = "acculist."..name.."_accu_"..(#accu_list+1).." = groupcount(got,\""..size.."\") + 1" 
                  else
                    accu_list[#accu_list+1] = "acculist."..name.."_accu_"..(#accu_list+1).." = groupcount(got,\""..size.."\")"
                  end
                  
                  accu_init[name.."_accu_"..#accu_list] = tonumber(num)
                  condition = condition .. "(groupcount(got,\""..size.."\")".." "..op.." acculist."..name.."_accu_"..#accu_list..")"
              else 
                  condition = condition .. "(groupcount(got,\""..size.."\")".." "..op.." "..num..")"
                end
            else return nil,nil,nil,nil,"Error in yaku "..name..": an non-negative integer is expected but '" .. num .. "' is found." end
            
          else return nil,nil,nil,nil,"Error in yaku "..name..": unexpected operator " .. op .. " found." end
        
        else return nil,nil,nil,nil,"Error in yaku "..name..": "..size.." found, but group size must be a number greater than 1." end

      elseif (token == "#kasu") or (token == "#tan") or (token == "#tane") or (token == "#ko") or (token == "#koi") then
        -- Default types: kasu, tan, tane, ko, koi
        s = s:sub(#token + 2)

        -- Match op
        local op = s:match("%S+")
        if (op == "==") or (op == ">=") or (op == "<=") or (op == ">") or (op == "<") or (op == "<>") then
          s = s:sub(#op + 2)

          if op == "<>" then op = "~=" end

          local num = s:match("%S+")
          
          -- Match number
          if (tonumber(num)) and (num == num:match("%d+"))then

              s = s:sub(#num + 2)

              if s:match("%S+") == "accu" then
                if (op == "==") or (op == "~=") then return nil,nil,nil,nil,"Error in yaku "..name..": accu is not allowed after operator == and <>." end
                s = s:sub(6)
                
                if (op == ">=") or (op == "<=") then 
                    accu_list[#accu_list+1] = "acculist."..name.."_accu_"..(#accu_list+1).." = "..token:sub(2).." + 1 "
                else
                    accu_list[#accu_list+1] = "acculist."..name.."_accu_"..(#accu_list+1).." = "..token:sub(2)
                end

                accu_init[name.."_accu_"..#accu_list] = tonumber(num)
                condition = condition .. "("..token:sub(2).." "..op.." acculist."..name.."_accu_"..#accu_list..")"
              else 
                condition = condition .. "("..token:sub(2).." "..op.." "..num..") "
              end

          else return nil,nil,nil,nil,"Error in yaku "..name..": an non-negative integer is expected but '" .. num .. "' is found." end
        else return nil,nil,nil,nil,"Error in yaku "..name..": unexpected operator " .. op .. " found." end

      else return nil,nil,nil,nil,"Error in yaku "..name..": unexpected token " .. token:sub(2).. " found after #." end
    elseif token == "and" then

    -- AND
      if waitingExpr then return nil,nil,nil,nil,"Error in yaku "..name..": expression expected but 'and' found." end
      waitingExpr = true
      condition = condition .. " and "
      s = s:sub(5)

    elseif token == "or" then

    -- OR
      if waitingExpr then return nil,nil,nil,nil,"Error in yaku "..name..": expression expected but 'or' found." end
      waitingExpr = true
      condition = condition .. " or "
      s = s:sub(4)

    elseif token == "not" then

    -- NOT
      s = s:sub(5)
      if not waitingExpr then return nil,nil,nil,nil,"Error in yaku "..name..": unexpected token 'not' found." end
      condition = condition.. "not "

    elseif token == "(" then

    -- Left Bracket
      if not waitingExpr then return nil,nil,nil,nil,"Error in yaku "..name..": unexpected token '(' found." end
      bracket_counter = bracket_counter + 1
      condition = condition .. "("
      s = s:sub(3)

    elseif token == ")" then

    -- Right Bracket
      bracket_counter = bracket_counter - 1
      if bracket_counter < 0 then return nil,nil,nil,nil,"Error in yaku "..name..": single right-bracket found." end
      if waitingExpr then return nil,nil,nil,nil,"Error in yaku "..name..": unexpected token ')' found." end
      waitingExpr = false
      condition = condition ..")" 
      s = s:sub(3)

    elseif token == "with" then

    -- With
      foundWith = true
      if bracket_counter > 0 then return nil,nil,nil,nil,"Error in yaku "..name..": "..bracket_counter.." open brackets found." end
      s = s:sub(6)

    else return nil,nil,nil,nil,"Error in yaku "..name..": unexpected token '"..token.."' found." end
  end

  return s, condition, accu_list, accu_init, nil
end


--[[
  This function processes <score_expr>.

  <score_expr> ::= number | #<cardtype> | (<score_expr>) | <score_expr> <arith_op> <score_expr> | 
  <cardtype> ::= kasu | tan | tane | ko | koi | month number/now | groupof number
  <arith_op> ::= + | - | * | /

  Results of divisions are rounded down to the nearest integer, i.e. takes the floor value.
  E.g. 3 / 2 is rounded down to 1.

  Inputs: s, line from inputs of parseYaku()
  Outputs: 
    -s : processed definition string
    -score : lua expression for evaluating the this yaku's score
    -err : error message; is nil if none
]]--

local function matchScoreexpr(s, line)

  -- Initialization
    local score = ""

    local waitingNumber = true
    local foundEnd = false
    local bracket_counter = 0

    -- Match keyword "score"
    if s:sub(1,6) ~= "score " then 
      return "yaku",nil,nil,nil,nil,"Error in yaku "..name..": 'score' expected but '" .. s:match("%S+") .. "' found." 
    end
    s = s:sub(7)

    while not foundEnd do
      local token = s:match("%S+")
      
      if tonumber(token) and token == token:match("%d+") then

        --number
        if not waitingNumber then return nil,nil,"Error in yaku "..name..": operator expected but "..token.." found." end
        waitingNumber = false
        s = s:sub(#token + 2)
        score = score..token.." "

      elseif (token == "#kasu") or (token == "#tan") or (token == "#tane") or (token == "#ko") or (token == "#koi") then

        --#<cardtype>
        if not waitingNumber then return nil,nil,"Error in yaku "..name..": operator expected but "..token.." found." end
        waitingNumber = false

        s = s:sub(#token + 2)
        score = score..token:sub(2).." "

      elseif (token == "#month") then
      
        --#month
        s = s:sub(#token + 2)
        if not waitingNumber then return nil,nil,"Error in yaku "..name..": operator expected but "..token.." "..s:match("%S+").." found." end

        local month = s:match("%S+")
        local i = tonumber(month)

        --Match month: [1-month_range,now,any,types]
        if (month == "now") or (i and (i >= 1) ) then
          waitingNumber = false
          s = s:sub(#month + 2)
          score = score.."monthcount(got,\""..month.."\") "
        else return nil,nil,"Error in yaku "..name..": "..month.." found, but month must be between 1 and month_range or 'now' or 'any'." end 
        

      elseif (token == "+") or (token == "-") or (token == "*") or (token == "/") then
        
        --Arithmetic operators: + - * /
        if waitingNumber then return nil,nil,"Error in yaku "..name..": number expected but "..token.." found." end
        waitingNumber = true
        s = s:sub(3)
        
        score = score..token.." "
      elseif token == "(" then
        
        -- Left bracket
        if not waitingNumber then return nil,nil,"Error in yaku "..name..": unexpected token '(' found." end
        s = s:sub(3)
        bracket_counter = bracket_counter + 1
        score = score.."("

      elseif token == ")" then 

        -- Right bracket
        bracket_counter = bracket_counter - 1
        if waitingNumber then return nil,nil,"Error in yaku "..name..": unexpected token ')' found." end
        if bracket_counter < 0 then return nil,nil,"Error in yaku "..name..": single right-bracket found." end
        waitingNumber = false
        s = s:sub(3)
        score = score..")"

      elseif token == ";" then

        -- Semi-colon
        if waitingNumber then return nil,nil,"Error in yaku "..name..": number expected." end
        if bracket_counter > 0 then return nil,nil,"Error in yaku "..name..": "..bracket_counter.." open brackets found." end
        foundEnd = true

      else return nil,nil,"Error in yaku "..name..": unexpected token "..token.." found." end
    end

  score = "return math.floor( "..score.." )"

  return s, score, nil 

end


--[[
  The body of compiling yaku definition types.
  
  Yaku definition: yaku <name> overwrites <name>* = <yaku_expr> with score <score_expr> 
  (overwrites <name>* is optional)

  Inputs: 
    - s : definition code
    - cardnames : a table of defined English names for cards
    - line : line count, used for output error message
    - isTestMode : bool, for enable/disable test mode

  Outputs:
    - line_type : type of the definition, here it is "yaku"
        - code : ???
        - name : name of the definition

        - overwrites : a table of other definitions that this one overwrites; is nil if none.
        - accu_init : ???
        - err : error message produced when parsing this line; is nil if none.
]]--

local function parseYaku(s,line,cardnames, isTestMode)

  -- Initialization
  local result = ""

  -- Match yaku name
  local s, name, err = matchName(s, line)
  if err then return nil,nil,nil,nil,nil,err end

  -- Match overwrite
  local s, over_list, over_all, err = matchOverwrites(s, line)
  if err then return nil,nil,nil,nil,nil,err end

  -- Match yaku_expr
  local s, condition, accu_list, accu_init, err = matchYakuexpr(s, line, cardnames, name)
  if err then return nil,nil,nil,nil,nil,err end

  -- Match score_expr
  local s, score, err = matchScoreexpr(s, line)
  if err then return nil,nil,nil,nil,nil,err end


  --[[
    Filling in result in such a format:
      return function (board, isPlayer)
            -- Initialize local variables
            if (condition) then
              -- Update accumulators
              -- Overwrite yakus
              -- Calculates final score and rounded down
              -- Returns final score and a bool value, indicates whether this yaku has accumulators
            end
          end
    This string will be loaded to the game engine as the yaku's function

  ]]--

  -- Indicates whether this yaku has accumulators
  if #accu_list > 0 then 
    score = score..", true"
  end

  if isTestMode then
    return true
  else
    result = result.."return function(board, isPlayer)\n"
    result = result..
    [[local got,count,oya,acculist,namelist,record
      if isPlayer then
        got = board.PGot
        count = board.PCount
        oya = board.playerfirst
        acculist = board.PAcculist
        namelist = board.PNamelist.yakus
        record = board.PRecord.yakus
      else
        got = board.CGot
        count = board.CCount
        oya = not board.playerfirst
        acculist = board.CAcculist
        namelist = board.CNamelist.yakus
        record = board.CRecord.yakus
      end
      local now = board.now
      local kasu = count[1]
      local tan = count[2]
      local tane = count[3]
      local ko = count[4]
      local koi = count[5]
    ]]
    result = result .. "if "..condition.." then \n"

    for i,v in ipairs(accu_list) do
      result = result..v.."\n"
    end

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

    return "yaku",result,name,over_list,accu_init,nil
    
  end

end

return parseYaku
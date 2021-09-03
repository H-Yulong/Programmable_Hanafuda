local parseYaku = require "game.utils.parseYaku"

local parsePrecheck = require "game.utils.parsePrecheck"

local parseBonus = require "game.utils.parseBonus"

--[[
  This function turns input code s to a standard format for later processing.
  To be specific, it:
    - removes comments
    - add one space in front of and after these symbols: , ; ( )
    - replace multiple spaces with a single space
    - each definition is put in to a single line
  Returns an array of one-line definitions  
]]--
local function toLine(s)

  local result = {}

  local i = 1

  local remove_comments = string.gsub(s,"[/][/][^\n]+\n","")
  
  local seperate_symbols = string.gsub(string.gsub(string.gsub(string.gsub(remove_comments,"[,]"," , "),"[;]"," ; "),"[)]"," ) "),"[(]"," ( ")
  
  local sanitise_spaces = string.gsub(seperate_symbols,"%s+"," ")
  
  for sub in string.gmatch(sanitise_spaces,"[^;]+;") do
    result[i] = sub
    i = i + 1
  end

  if i == 1 then error("Error: ';' expected but none found!") end

  return result
end

--[[
  name <name> = number
  <name> must:
    - only contain numbers, letters and "_"
    - not begin with "_"
]]
local function parseName(s, line, cardnames)

  -- Match <name>
  local name = s:match("%S+")
  if (name ~= name:match("[%w][%w_]*")) and (name ~= "all") then error("Error in name "..line..": illegal name '"..name.."' found.") end
  if cardnames[name] then error("Error in name "..line..": "..name.." has been used before.") end
  s = s:sub(#name+2)

  -- Match "="
  if s:sub(1,2) ~= "= " then error("Error in name "..name..": '=' expected but '" .. s:match("%S+") .. "' found.") end
  s = s:sub(3)

  -- Match card number
  local token = s:match("%S+")
  if token:match("%d+") == token then
    local i = tonumber(token)
    
    if i < 1 or i > 256 then error("Error in name "..name..": invalid card number "..token.." found.") end

    s = s:sub(#token+2)

    cardnames[name] = i
    return "name"
  else 
    error("Error in name "..name..": unexpected token '"..token.."' found.") 
  end
end


--[[
  This function parses an one-line definition according to its type.
]]--
local function parseLine(s,line,cardnames,isOutput)
  --Eliminate starting space, if any
  if s:sub(1,1) == " " then s = s:sub(2) end

  --Match yaku
  if s:sub(1,5) == "yaku " then return parseYaku(s:sub(6),line, cardnames, isOutput)
  elseif s:sub(1,9) == "precheck " then return parsePrecheck(s:sub(10),line, cardnames, isOutput)
  elseif s:sub(1,6) == "bonus " then return parseBonus(s:sub(7),line, cardnames, isOutput)
  elseif s:sub(1,5) == "name " then return parseName(s:sub(6), line, cardnames)
  else error("Error in definition "..line..": unexpected token '" .. s:match("%S+") .. "' found.")
  end
end


local function exist(element,tb)
  for _,v in ipairs(tb) do
    if element == v then return true end
  end
  return false
end


--[[
  This function is the body of the yaku-compiler.
  Input:
    -s : a multiline definition string
  Outputs:
    -yakus : <yaku name, yaku-determing function> (a table of key-value pairs in such form)
    -precheck : <precheck name, precheck-determing function>
                has an extra field "order" that keeps the order of executing prechecks
    -bonus : <bonus name, bonus-determing function>
              has an extra field "order"
    -namelist : 
    -yakus,precheck,bonus,namelist,records,acculist
]]--
function compile(s)


  -- Initialization
  local yakus,precheck,bonus,namelist,records,acculist,overlist,freelist = {},{},{},{},{},{},{},{}
  
  namelist.yakus,namelist.precheck,namelist.bonus = {},{},{}
  records.yakus,records.precheck,records.bonus = {},{},{}
  overlist.yakus,overlist.precheck,overlist.bonus = {},{},{}
  freelist.yakus,freelist.precheck,freelist.bonus = {},{},{}

  local precheck_order, bonus_order = {},{}
  local cardnames = {}


  -- Parse and process each line of the code according to its type.
  for i,v in ipairs(toLine(s)) do
    --[[
      List of local variables returned by parseLine:
        - line_type : type of the definition, e.g. "yaku"
        - code : lua code for the game engine to run with
        - name : name of the definition / a list of ordered bonus names
        - overwrites : a table of other definitions that this one overwrites; is nil if none.
        - accus : a list of accumulators to initialize by the game engine
        - err : error message produced when parsing this line; is nil if none.
        - freenames : a table of unbounded names mentioned in this definition; is nil if none.
    ]]--

    local line_type,code,name,overwrites,accus,err,freenames = parseLine(v,i,cardnames,false)

    if not err then

      if line_type == "yaku" then

        -- Check repeating definitions
        if exist(name,namelist.yakus) then error("Error: "..name.." has already existed in previous definitions.") return end
        
        -- Add yaku name, definition to the tables
        yakus[name] = loadstring(code)()
        --print(code)
        namelist.yakus[#namelist.yakus+1] = name
        records.yakus[name] = false 
        
        -- Recording free-variables
        for _,v in ipairs(overwrites) do
          if not exist(v,overlist.yakus) then
            overlist.yakus[#overlist.yakus+1] = v
          end
        end

        -- Recording accumulators
        for i,v in pairs(accus) do
          acculist[i] = v
        end


      elseif line_type == "precheck" then

        -- Check repeating definitions
        if exist(name,namelist.precheck) then error("Error: "..name.." has already existed in previous definitions.") return end
        
        -- Add precheck name, definition to the tables
        precheck[name] = loadstring(code)()
        namelist.precheck[#namelist.precheck+1] = name
        records.precheck[name] = false

        -- Recording free-variable
        for _,v in ipairs(overwrites) do
          if not exist(v,overlist.precheck) then
            overlist.precheck[#overlist.precheck+1] = v
          end
        end

      elseif line_type == "precheck_order" then
        precheck_order = name


      elseif line_type == "bonus" then
        
        -- Check repeating definitions
        if exist(name,namelist.bonus) then error("Error: "..name.." has already existed in previous definitions.") return end
        
        -- Add yaku name, definition to the tables
        bonus[name] = loadstring(code)()
        namelist.bonus[#namelist.bonus + 1] = name
        records.bonus[name] = false
        
        -- Recording free-variable
        for _,v in ipairs(overwrites) do 
            if not exist(v,overlist.bonus) then
              overlist.bonus[#overlist.bonus+1] = v
            end
        end

        for _,v in ipairs(freenames) do
          if not exist(v,freelist.bonus) then
             freelist.bonus[#freelist.bonus+1] = v
          end
        end


      elseif line_type == "bonus_order" then
        bonus_order = name
      end

    else
      error(err)
    end 

  end
    
  --[[
    Completing precheck and bonus order.
    If no order provided, the first one appears in the code is evaluated firstly by default.
    If the order is provided for some of the definitions, 
    those definitions are evaluated by the provided order first, then the rest is evaluated by default order. 
    If non-defined names appear, throw an error.
  ]]

  if #precheck_order == 0 then
    precheck_order = namelist.precheck
  end

  if #precheck_order < #namelist.precheck then
    for _,v in ipairs(namelist.precheck) do
      if not exist(v,precheck_order) then
        precheck_order[#precheck_order + 1] = v
      end
    end
    namelist.precheck = precheck_order
  elseif #precheck_order > #namelist.precheck then
    for _,v in ipairs(precheck_order) do
      if not exist(v, namelist.precheck) then error("Error: '"..v.."' is in the precheck order list but not defined.") return end 
    end
  end

  if #bonus_order == 0 then 
    bonus_order = namelist.bonus
  end

  if #bonus_order < #namelist.bonus then
    for _,v in ipairs(namelist.bonus) do
      if not exist(v,bonus_order) then 
        bonus_order[#bonus_order + 1] = v
      end
    end
    namelist.bonus = bonus_order
  elseif #bonus_order > #namelist.bonus then
    for _,v in ipairs(bonus_order) do
        if not exist(v,namelist.bonus) then error("Error: '"..v.."' is in the bonus order list but not defined.") return end
    end
  end

  -- Check for any non-defined definitions
  for i,v in pairs(overlist) do
    for _,w in ipairs(v) do
      if not exist(w,namelist[i]) then error("Error: '"..w.."' is not defined.") return end
    end
  end

  for i,v in pairs(freelist.bonus) do
    if not exist(v,namelist.yakus) then error("Error: '"..v.."' is not defined.") return end
  end

  -- table.sort(namelist.yakus)

  return yakus,precheck,bonus,namelist,records,acculist
end
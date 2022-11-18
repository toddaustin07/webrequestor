local log = require "log"
local xml2lua = require "xml2lua"
local xml_handler = require "xmlhandler.tree"
local json = require "dkjson"


local function is_array(t)
  if type(t) ~= "table" then return false end
  local i = 0
  for _ in pairs(t) do
    i = i + 1
    if t[i] == nil then return false end
  end
  return true
end

local function getTableElement(key, input_table)

  if not key or type(key) ~= 'string' then
    log.error ('Invalid key string')
    return
  end

  if not input_table or type(input_table) ~= 'table' then
    log.error ('Missing or invalid table object')
    return
  end
  
  local compound = input_table

  local found = false
  local elementslist = {}

  for element in string.gmatch(key, "[^%.]+") do
    table.insert(elementslist, element)
  end
  
  for el_idx=1, #elementslist do
    local element = elementslist[el_idx]
    local key = element:match('^([^%[]+)')
    local array_index = element:match('%[(%d+)%]$')
    if array_index then; array_index = tonumber(array_index) + 1; end	-- adjust for Lua indexes starting at 1
    compound = compound[key]
    if compound == nil then; break; end
    
    if array_index then
      if is_array(compound) then
	if compound[array_index] then
	  compound = compound[array_index]
	else
	  break
	end
      else
	break
      end
    end
    
    if type(compound) ~= 'table' then
      if el_idx == #elementslist then; return compound; end
    end
  end
  
end


-- Deprecated
local function searchtable(table, searchkey, maxlevels, currlevel)

  if not currlevel then; currlevel = 0; end
  currlevel = currlevel + 1
  local result
  
  for key, value in pairs(table) do
    if type(value) ~= 'table' then
      if key == searchkey then
				-- Boolean value will be converted to string!!
        if type(value) == 'boolean' then
          if value == true then
            value = 'true'
          elseif value == false then
            value = 'false'
          end
        end
	      return value
      end
    end
    if (type(value) == 'table') and (currlevel < maxlevels) then
      result = searchtable(value, searchkey, maxlevels, currlevel)
      if result then; break; end
    end
  end
  return result
end


local function findkeyvalue(response, key)

  local rtable, pos, err
  
  log.debug ('Parsing response for key', key)

  if response:find('<?xml', 1, 'plaintext') == 1 then

    local handler = xml_handler:new()
    local xml_parser = xml2lua.parser(handler)

    xml_parser:parse(response)

    if not handler.root then
      log.error ("XML parse error - no root")
      return nil
    end

    rtable = handler.root

  elseif response:find('{', 1, 'plaintext') == 1 then
    
    rtable, pos, err = json.decode (response, 1, nil)
    if err then
      log.error ("JSON decode error:", err)
      return nil
    end
  else
    log.warn ('Response format not XML or JSON - cannot parse key')
  end
  
  if rtable then
    local result = getTableElement(key, rtable)
    if result ~= nil then
      return result
    else
      log.warn ('Configured Key value was not found')
      return nil
    end
  end
end


return {
	findkeyvalue = findkeyvalue,
}

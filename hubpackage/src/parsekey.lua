local log = require "log"
local xml2lua = require "xml2lua"
local xml_handler = require "xmlhandler.tree"
local json = require "dkjson"


local function searchtable(table, searchkey, maxlevels, currlevel)

  if not currlevel then; currlevel = 0; end
  currlevel = currlevel + 1
  local result
  
  for key, value in pairs(table) do
    if type(value) ~= 'table' then
      if key == searchkey then
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
    local result = searchtable(rtable, key, 5)
    if result then
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

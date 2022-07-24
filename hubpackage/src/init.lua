--[[
  Copyright 2021 Todd Austin

  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file
  except in compliance with the License. You may obtain a copy of the License at:

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software distributed under the
  License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
  either express or implied. See the License for the specific language governing permissions
  and limitations under the License.


  DESCRIPTION
  
  Web requests: execute web requests via mobile app or device command; supports http and https

--]]

-- Edge libraries
local capabilities = require "st.capabilities"
local Driver = require "st.driver"
local cosock = require "cosock"                 -- just for time
local socket = require "cosock.socket"          -- just for time
local https = cosock.asyncify "ssl.https"
local http = cosock.asyncify "socket.http"
http.TIMEOUT = 15
https.TIMEOUT = 15
local ltn12 = require "ltn12"
local log = require "log"

-- Driver modules
local parser = require "parsekey"

-- Global variables
local devcounter = 1

-- Module variables
local webreqDriver
local initialized = false
local lastinfochange = socket.gettime()
local webreq_commands = {}
local cleardevice = {}

-- Custom Capabilities
local capdefs = require "capabilitydefs"

local cap_select = capabilities.build_cap_from_json_string(capdefs.select_cap)
capabilities["partyvoice23922.webrequestselect"] = cap_select

local cap_requestcmd = capabilities.build_cap_from_json_string(capdefs.requestcmd_cap)
capabilities["partyvoice23922.webrequest"] = cap_requestcmd

local cap_httpcode = capabilities.build_cap_from_json_string(capdefs.httpcode_cap)
capabilities["partyvoice23922.httpcode"] = cap_httpcode

local cap_response = capabilities.build_cap_from_json_string(capdefs.response_cap)
capabilities["partyvoice23922.httpresponse"] = cap_response

local cap_keyvalue = capabilities.build_cap_from_json_string(capdefs.keyvalue_cap)
capabilities["partyvoice23922.keyvalue"] = cap_keyvalue

local cap_createdev = capabilities.build_cap_from_json_string(capdefs.createdev_cap)
capabilities["partyvoice23922.createanother"] = cap_createdev


local displevels = 0

-- For debugging only
local function disptable(table, tab, maxlevels)

  displevels = displevels + 1
  for key, value in pairs(table) do
    log.debug (tab .. key, value)
    if (type(value) == 'table') and (displevels < maxlevels) then
      disptable(value, '  ' .. tab, maxlevels)
    end
  end
end


local function validate_address(lanAddress)

  local valid = true
  
  local ip = lanAddress:match('^(%d.+):')
  local port = tonumber(lanAddress:match(':(%d+)$'))
  
  if ip then
    local chunks = {ip:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")}
    if #chunks == 4 then
      for i, v in pairs(chunks) do
        if tonumber(v) > 255 then 
          valid = false
          break
        end
      end
    else
      valid = false
    end
  else
    valid = false
  end
  
  if port then
    if type(port) == 'number' then
      if (port < 1) or (port > 65535) then 
        valid = false
      end
    else
      valid = false
    end
  else
    valid = false
  end
  
  if valid then
    return ip, port
  else
    return nil
  end
      
end


local function validate(input, silent)

  local msg
  local method = string.upper(input:match('(%a+):'))
  local url = input:match(':(.+)')
  
  if (method == 'GET') or (method == 'POST') then

    local protocol = url:match('^(%a+):')
    if (protocol == 'http') or (protocol == 'https') then
    
      local skiplen
      if protocol == 'http' then; skiplen = 8; end
      if protocol == 'https' then; skiplen = 9; end
      
      local startpath = url:find('/', skiplen+1)
      local urladdr
      
      if startpath ~= nil then
        urladdr = url:sub(skiplen, startpath-1)
      else
        urladdr = url:sub(skiplen)
      end
      
      if validate_address(urladdr) then
        return method, url
      else
        msg = 'Invalid IP:Port address provided'
      end

    else
      msg = "URL does not start with 'http://' or 'https://'"
    end
  else
    msg = "Request string does not start with valid method ('GET:' or 'POST:')"
  end
  
  if not silent then; log.warn (msg); end
  return nil
  
end


local function issue_request(device, req_method, req_url)

  local responsechunks = {}
  
  local protocol = req_url:match('^(%a+):')
  local body, code, headers, status
  
  if protocol == 'https' then
  
    body, code, headers, status = https.request{
      method = req_method,
      url = req_url,
      protocol = "any",
      options =  {"all"},
      verify = "none",
      sink = ltn12.sink.table(responsechunks)
     }

  else
    body, code, headers, status = http.request{
      method = req_method,
      url = req_url,
      sink = ltn12.sink.table(responsechunks)
     }
  end

  local response = table.concat(responsechunks)
  
  log.info(string.format("response code=<%s>, status=<%s>", code, status))
  
  local returnstatus = 'unknown'
  local old_driver = device.device_network_id:find('webrequest', 1, 'plaintext')
  local httpcode_str
  local httpcode_num
  protocol = string.upper(protocol)
  
  if type(code) == 'number' then
    httpcode_num = code
  else
    httpcode_str = code
  end
  
  if httpcode_num then
    if old_driver and ((httpcode_num < 200) or (httpcode_num >= 300)) then
      device:emit_event(cap_response.response(string.format('**%s error %s', protocol, tostring(httpcode_num))))
    else
      device:emit_event(cap_httpcode.httpcode(tostring(httpcode_num)))
    end
  end

  if httpcode_num then
    if (httpcode_num >= 200) and (httpcode_num < 300) then
      returnstatus = 'OK'
      log.debug (string.format('Response:\n>>>%s<<<', response))
      
      if response ~= '' then
        device:emit_event(cap_response.response(response))
        
        if device.preferences.valuekey then
          if device.preferences.valuekey ~= 'x1x' then
            local kvalue = parser.findkeyvalue(response, device.preferences.valuekey)
            
            if kvalue then
              device:emit_event(cap_keyvalue.keyvalue(kvalue))
            end
          end
        end
      end
      
    else
      log.warn (string.format("HTTP %s request to %s failed with http code %s, status: %s", req_method, req_url, tostring(httpcode_num), status))
      returnstatus = 'Failed'
    end
  
  else

    if httpcode_str then
      if string.find(httpcode_str, "closed") then
        log.warn ("Socket closed unexpectedly")
        returnstatus = "No response"
      elseif string.find(httpcode_str, "refused") then
        log.warn("Connection refused: ", req_url)
        returnstatus = "Refused"
      elseif string.find(httpcode_str, "timeout") then
        log.warn("HTTP request timed out: ", req_url)
        returnstatus = "Timeout"
      else
        log.error (string.format("HTTP %s request to %s failed with code: %s, status: %s", req_method, req_url, httpcode_str, status))
        returnstatus = 'Failed'
      end
    else
      log.warn ("No response code returned")
      returnstatus = "No response code"
    end

    
    if old_driver then
      device:emit_event(cap_response.response('**'..returnstatus))
    else
      device:emit_event(cap_httpcode.httpcode('**'..returnstatus))
    end
    
  end

  return returnstatus
  
end


local function create_another_device(driver, counter)

  log.info("Creating additioal Web Request device")
  
  local MFG_NAME = 'SmartThings Community'
  local VEND_LABEL = string.format('Web Req Multi #%d', counter)
  local MODEL = 'webrequestormv1'
  local ID = 'webreqm' .. '_' .. socket.gettime()
  local PROFILE = 'webrequestm_addl.v1'

  log.debug (string.format('Creating additional device: label=<%s>, id=<%s>', VEND_LABEL, ID))

  -- Create master device

  local create_device_msg = {
                              type = "LAN",
                              device_network_id = ID,
                              label = VEND_LABEL,
                              profile = PROFILE,
                              manufacturer = MFG_NAME,
                              model = MODEL,
                              vendor_provided_label = VEND_LABEL,
                            }
                      
  assert (driver:try_create_device(create_device_msg), "failed to create additional webreq device")

end


local function clearmsg ()

  if cleardevice then
    cleardevice:emit_event(cap_select.selection(' '))
    cleardevice = nil
  end

end

-----------------------------------------------------------------------
--										COMMAND HANDLERS
-----------------------------------------------------------------------


local function handle_selection(driver, device, command)

  log.debug("Web request selection = " .. command.command, command.args.value)
  
	local reqnumber = tonumber(command.args.value)
  
  if type(reqnumber) == 'number' then

    device:emit_event(cap_httpcode.httpcode(' '))
    device:emit_event(cap_response.response(' '))
    device:emit_event(cap_keyvalue.keyvalue('--'))
    if type(webreq_commands[device.id][reqnumber]) == 'table' then
      device:emit_event(cap_select.selection(command.args.value))
      log.info (string.format('SEND %s COMMAND: %s', webreq_commands[device.id][reqnumber].method, webreq_commands[device.id][reqnumber].url))
      local status = issue_request(device, webreq_commands[device.id][reqnumber].method, webreq_commands[device.id][reqnumber].url)
      
    else
      log.debug (string.format('Web request #%d not configured', reqnumber))
      device:emit_event(cap_select.selection('Not configured'))
    end
    
    cleardevice = device
    driver:call_with_delay(3, clearmsg)
  end
end


local function handle_requestcmd(_, device, command)

  log.debug (string.format('%s command Received; url = %s', command.command, command.args.url))
  
  if (command.command == 'GET') or (command.command == 'POST') then
  
    if command.args.url ~= nil then
      device:emit_event(cap_response.response('--'))
      device:emit_event(cap_keyvalue.keyvalue('--'))
      issue_request(device, command.command, command.args.url)
    else
      log.error ('\tURL command argument missing')
    end
  else
    log.error ('\tUnrecognized command (method)')
  end

end

local function handle_createdev(driver, device, command)

  log.debug ('Createdev handler- command received:', command.command)
  
  devcounter = devcounter + 1
  
  create_another_device(driver, devcounter)

end

------------------------------------------------------------------------
--                REQUIRED EDGE DRIVER HANDLERS
------------------------------------------------------------------------

-- Lifecycle handler to initialize existing devices AND newly discovered devices
local function device_init(driver, device)
  
  log.debug(device.id .. ": " .. device.device_network_id .. "> INITIALIZING")

  webreq_commands[device.id] = {}

  for key, value in pairs(device.preferences) do
    
    local pnum = tonumber(key:match('request(%d+)'))
    if pnum then
      local method, url = validate(value, true)
            
      if url ~= nil then
        log.debug (string.format('Web request string #%d initialized', pnum))
        webreq_commands[device.id][pnum] = {}
        webreq_commands[device.id][pnum].method = method
        webreq_commands[device.id][pnum].url = url
       end
     end
  end

  initialized = true
  device:emit_event(cap_select.selection(' '))
  device:online()
  
end


-- Called when device was just created in SmartThings
local function device_added (driver, device)

  log.info(device.id .. ": " .. device.device_network_id .. "> ADDED")
  
end


-- Called when SmartThings thinks the device needs provisioning
local function device_doconfigure (_, device)

  -- Nothing to do here!

end


-- Called when device was deleted via mobile app
local function device_removed(_, device)
  
  log.warn(device.id .. ": " .. device.device_network_id .. "> removed")
  
  --initialized = false
  
end


local function handler_driverchanged(driver, device, event, args)

  log.debug ('*** Driver changed handler invoked ***')

end


local function handler_infochanged (driver, device, event, args)

  log.debug ('Info changed handler invoked')

  local timenow = socket.gettime()
  local timesincelast = timenow - lastinfochange

  log.debug('Time since last info_changed:', timesincelast)
  
  lastinfochange = timenow
  
  if timesincelast > 10 then

    -- Did preferences change?
    if args.old_st_store.preferences then
    
      --[[
      log.debug ('OLD preference settings:')
      for key, value in pairs(args.old_st_store.preferences) do
        log.debug ('\t' .. key, value)
      end
      log.debug ('NEW preference settings:')
      for key, value in pairs(device.preferences) do
        log.debug ('\t' .. key, value)
      end
      --]]
      
       -- Examine each preference setting to see if it changed 
      
      for key, value in pairs(device.preferences) do
      
        local pnum = tonumber(key:match('request(%d+)'))
        
        if pnum then 
        
          if args.old_st_store.preferences[key] ~= device.preferences[key] then
          
            log.info (string.format('Request #%d string changed to: %s', pnum, value))
            
            -- parse & validate the string
            local method, url = validate(value, false)
            
            if url ~= nil then
              log.info (string.format('\tRequest string #%d is valid', pnum))
              webreq_commands[device.id][pnum] = {}
              webreq_commands[device.id][pnum].method = method
              webreq_commands[device.id][pnum].url = url
            else
              log.warn (string.format('\tInvalid Request string #%d -- ignored', pnum))
              webreq_commands[device.id][pnum] = nil
            end
          end
        else
          if args.old_st_store.preferences.valuekey ~= device.preferences.valuekey then
            log.info (string.format('Value key changed to %s', device.preferences.valuekey))
          end
        end
      end
       
    else
      log.warn ('Old preferences missing')
    end  
     
  else
    log.error ('Duplicate info_changed - IGNORED')
  end
end


-- Create Primary Creator Device
local function discovery_handler(driver, _, should_continue)
  
  if not initialized then
  
    log.info("Creating Web Request device")
    
    local MFG_NAME = 'SmartThings Community'
    local VEND_LABEL = 'Web Req Multi Master'
    local MODEL = 'webrequestormv1'
    local ID = 'webreqm' .. '_' .. socket.gettime()
    local PROFILE = 'webrequestm.v1'

    -- Create master device
	
		local create_device_msg = {
																type = "LAN",
																device_network_id = ID,
																label = VEND_LABEL,
																profile = PROFILE,
																manufacturer = MFG_NAME,
																model = MODEL,
																vendor_provided_label = VEND_LABEL,
															}
												
		assert (driver:try_create_device(create_device_msg), "failed to create web request device")
    
    log.debug("Exiting device creation")
    
  else
    log.info ('Web request device already created')
  end
end


-----------------------------------------------------------------------
--        DRIVER MAINLINE: Build driver context table
-----------------------------------------------------------------------
webreqDriver = Driver("webreqDriver", {
  discovery = discovery_handler,
  lifecycle_handlers = {
    init = device_init,
    added = device_added,
    driverSwitched = handler_driverchanged,
    infoChanged = handler_infochanged,
    doConfigure = device_doconfigure,
    removed = device_removed
  },
  
  capability_handlers = {
  
    [cap_select.ID] = {
      [cap_select.commands.setSelection.NAME] = handle_selection,
    },
    [cap_requestcmd.ID] = {
      [cap_requestcmd.commands.POST.NAME] = handle_requestcmd,
      [cap_requestcmd.commands.GET.NAME] = handle_requestcmd,
    },
    [cap_createdev.ID] = {
      [cap_createdev.commands.push.NAME] = handle_createdev,
    },
  }
})

log.info ('Web Requestor Multi Driver v1.0b Started')

webreqDriver:run()

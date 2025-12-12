--[[
#### Example for a Location message !!!!!
]]
local other_private_message_module = {}
--JSON = assert(loadfile "_G.JSON.lua")() -- one-time load of the routines

function other_private_message_module.handler(parsed_cli)
  Print_to_Log(1, "Start processing other_private_messages.")
  local response = "Done"
  local status
  local total_response = ""
  -- Merge all possible parameters back into one string
  for i, t in ipairs(parsed_cli) do
    if i > 2 then
      total_response = total_response .. " " .. t
    end
    Print_to_Log(3, i, t)
  end
  Print_to_Log(3, "Step1: total_response:", total_response)
  local lastupdate = ''
  local decoded_response = JSON.decode(total_response) or {}
  if type(decoded_response) == "table" then
    Print_to_Log(1, "Step2: Decoded response is JSON ")
    -- ### Example for using Location message from Telegram to update a Domoticz text device
    -- process the received message
    if (decoded_response.location) then
      local didx = 499 -- Domoticz text device IDX
      Print_to_Log(1, "Step3: This is a location message. ")
      Print_to_Log(1, "Location latitude:", decoded_response.location.latitude)
      Print_to_Log(1, "Location longitude:", decoded_response.location.longitude)
      -- set domoticz text device to location
      if decoded_response and decoded_response.edit_date then
        lastupdate = tostring(os.date("%X", decoded_response.edit_date) or '')
      end
      local dtxt = decoded_response.location.latitude .. ":" .. decoded_response.location.longitude
      local dUrl = "type=command&param=udevice&idx=" .. didx .. "&nvalue=0&svalue=" .. dtxt
      Print_to_Log(3, "JSON request <" .. dUrl .. ">")
      local decoded_response, status = PerformDomoticzRequest(dUrl, 2)
      Print_to_Log(3, "Status:", status)
      if status == 200 then
        if decoded_response then
          response = "Set " .. didx .. " to " .. dtxt
        else
          response = "Failed to Set " .. didx .. " to " .. dtxt
        end
      else
        response = "HTTP RC:" .. status .. "  Failed to Set " .. didx .. " to " .. dtxt
      end
    end
  end
  return status, lastupdate .. '->' .. response
end

local other_private_message_commands = {
  ["other_private_message"] = {handler = other_private_message_module.handler, description = "other_private_message ...."}
}

function other_private_message_module.get_commands()
  return other_private_message_commands
end

return other_private_message_module

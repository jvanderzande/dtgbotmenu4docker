_G.dtgbot_inlineaction_version = '1.0 202512181633'

--[[
	Script to support the Inline Menu options for any telegram message DTGBOT
	Developer: jvdzande
	GNU GENERAL PUBLIC LICENSE
]]

--[[
-----------------------------------------------------------------------
--This script handles inline-keyboard responses when replies are send to dtgbot
	on messages coded like the below examples (send by any process):

	Basic example on/off switch:
		https://api.telegram.org/bot123456890:aaa...xxx/sendMessage?
			chat_id=123456789
			&text=actions for DeviceName
			&reply_markup={"inline_keyboard":[[
				{"text":"On","callback_data":"ia DeviceName on"},
				{"text":"Off","callback_data":"ia DeviceName off"},
				{"text":"exit","callback_data":"ia DeviceName exit"},
			] ] }

	Example for a dimmer
		https://api.telegram.org/bot123456890:aaa...xxx/sendMessage?
			chat_id=123456789
			&text=actions for DeviceName
			&reply_markup={"inline_keyboard":[ [
				{"text":"Aan",   "callback_data":"ia DeviceName on"},
				{"text":"25%",   "callback_data":"ia DeviceName set level 25"},
				{"text":"50%",   "callback_data":"ia DeviceName set level 50"},
				{"text":"75%",   "callback_data":"ia DeviceName set level 75"},
				{"text":"Uit",   "callback_data":"ia DeviceName off"},
				{"text":"exit",  "callback_data":"ia exit"},
				{"text":"remove","callback_data":"ia remove"}
				] ] }

	Example for a Setpoint with event trigger:
		https://api.telegram.org/bot123456890:aaa...xxx/sendMessage?
			chat_id=123456789
			&text=actions for DeviceName
			&reply_markup={"inline_keyboard":[ [
				{"text":"18.0c", "callback_data":"ia DeviceName3 udevice 18 -t"},
				{"text":"18.5c", "callback_data":"ia DeviceName3 udevice 18.5 -t"},
				{"text":"19.0c", "callback_data":"ia DeviceName3 udevice 19 -t"},
				{"text":"exit",  "callback_data":"ia exit"},
				] ] }

	Callback_Data format: inlineaction DeviceName Action [-st]
		DeviceName -> Domoticz DeviceName to perform the action for. Optional
		Action On/Off/Set level xx -> Action to perform on DeviceName
		Action udevice "x[;y;z]"   -> Action to perform an udevice on DeviceName
				-t parameter to trigger event when udevice is used. default is no event triggered
		Action exit   -> remove the inline menu with closing message
		Action remove -> remove the whole message with keyboard.
		-s parameter to perform the action Silent without any response text
]]
local inlineaction = {}
--JSON = assert(loadfile "_G.JSON.lua")() -- one-time load of the routines

-- process the received command by DTGBOT
local function perform_action(parsed_cli, SendTo, MessageId, org_replymarkup)
	Print_to_Log(2, 'Inlineaction start: ' .. tostring(#parsed_cli))
	local DeviceName = ''
	local action = ''
	local status, response, replymarkup
	local switchtype
	local udevtrigger = false
	local silent = false

	for x, param in pairs(parsed_cli) do
		Print_to_Log(2, 'command parameter ' .. x .. '=' .. param)
		if x == 1 then
			-- "stuff" Used for other purposes
		elseif x == 2 then
			-- the "inlineaction"/"ia" command
		else
			if param:sub(1, 1) == '-' then
				if param:find('t', 2) then
					udevtrigger = true
				end
				if param:find('s', 2) then
					silent = true
				end
			elseif param == '/silent' then
				-- backwards compatibility previvous versions
				silent = true
			elseif DeviceName == '' then
				-- assume this param is the action when that is the last parameter
				if #parsed_cli == x then
					action = param
				else
					DeviceName = param
				end
			else
				if action == '' then
					action = param
				else
					action = action .. ' ' .. param
				end
			end
		end
	end
	-- strip leading/trailing spaces
	action = StrTrim(action)

	-- remove keyboard when exit is defined as action and
	if action == 'exit' then
		response = 'exit ' .. DeviceName
		replymarkup = 'remove'
		if silent then
			response = ''
		end
		return 1, response, replymarkup
	end
	-- remove message and keyboard when remove is defined as action
	if action == 'remove' then
		response = 'remove'
		replymarkup = 'remove'
		return 1, response, replymarkup
	end
	-- process the action
	response = ''
	replymarkup = org_replymarkup -- set markup to the same as the original
	status = 1
	Print_to_Log(3, 'SendTo:' .. SendTo)
	Print_to_Log(3, 'MessageId:' .. MessageId)
	Print_to_Log(3, 'DeviceName:' .. DeviceName)
	Print_to_Log(3, 'action:' .. action)

	-- Check if DeviceName is a known domoticz device
	switchtype = 'device'
	DeviceID = Domo_Idx_From_Name(DeviceName, 'devices')
	if DeviceID == nil then
		-- Its not a device so check if a scene
		DeviceID = Domo_Idx_From_Name(DeviceName, 'scenes')
		switchtype = 'scenes'
	end
	-- process the action when either a device or a scene
	if DeviceID == nil then
		response = '' .. DeviceName .. ' is unknown.'
	else
		if switchtype == 'device' and action:sub(1, 7):lower() == 'udevice' then
			local sValue = action:gsub('udevice ', '')
			local dUrl = 'type=command&param=udevice&idx=' .. DeviceID .. '&nvalue=0&svalue=' .. sValue .. '&parsetrigger=' .. tostring(udevtrigger)
			Print_to_Log(3, ' update url:' .. dUrl)
			local decoded_response, status = PerformDomoticzRequest(dUrl, 2)
			if decoded_response then
				response = 'Udevice: Set ' .. DeviceName .. ' to ' .. sValue .. ' trigger=' .. tostring(udevtrigger)
			else
				response = 'Udevice: ' .. (status or '??') .. ' Failed to Set ' .. DeviceName .. ' to ' .. sValue
			end
		else
			if action:sub(1, 9):lower() == 'set level' then
				local sValue = action:sub(11)
				Print_to_Log(3, '1. updated Set Level:' .. sValue .. '=' .. sValue:gsub('[%s%%]', ''))
				-- Set the proper level to set the dimmer
				action = string.format('Set Level %.0f', sValue:gsub('[%s%%]', '')) -- remove % & decimals
				Print_to_Log(3, ' updated Set Level:' .. action)
			end
			-- Now switch the device or scene
			response = Domo_sSwitchName(DeviceName, switchtype, switchtype, DeviceID, action)
		end
	end
	-- remove info when /silent is provided as parameter > 3
	if silent then
		Print_to_Log(3, '/silent active')
		response = ''
		replymarkup = ''
	end
	--
	return status, response, replymarkup
end

function inlineaction.handler(parsed_cli, SendTo, MessageId)
	return perform_action(parsed_cli, SendTo, MessageId)
end

local inlineaction_commands = {
	['inlineaction'] = { handler = inlineaction.handler, description = 'inline action - handle actions from inline-keyboard' },
	['ia'] = { handler = inlineaction.handler, description = 'inline action - handle actions from inline-keyboard' }
}

function inlineaction.get_commands()
	return inlineaction_commands
end

return inlineaction

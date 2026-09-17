_G.dtgbot_inlineaction_version = '1.0 202609171415'

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
				{"text":"exit","callback_data":"ia exit"},
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

	Example for a variable update:
		https://api.telegram.org/bot123456890:aaa...xxx/sendMessage?
			chat_id=123456789
			&text=actions for DeviceName
			&reply_markup={"inline_keyboard":[ [
					{"text":"Reset uservar to value","callback_data":"ia -v varname value"},
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

-- Process Device/Scene actions
local function process_device_action(DeviceName, action, isdevice, switchtype, udevtrigger, silent)
	-- process the action as Device or Scene
	local response = ''
	local replymarkup = ''
	local status

	if isdevice and DeviceName == nil or DeviceName == '' then
		response = 'DeviceName is missing! format is: ia -v devicename value'
		status = 0
		Print_to_Log(2, response)
		return status, response, replymarkup
	end

	-- Check if DeviceName is a known domoticz device
	switchtype = 'devices'
	DeviceID = Domo_Idx_From_Name(DeviceName, 'devices')
	if DeviceID == nil then
		-- Its not a device so check if a scene
		DeviceID = Domo_Idx_From_Name(DeviceName, 'scenes')
		switchtype = 'scenes'
		-- if device name could be a variable when not explicitly defined as device command with -d ??
		if DeviceID == nil then
			if isdevice then
				Print_to_Log(2, 'DeviceName:"' .. DeviceName .. '" is not a device or scene and explicit -d device.')
			else
				Print_to_Log(2, 'DeviceName:"' .. DeviceName .. '" is not a device or scene -> try UserVariable.')
			end
			response = '' .. DeviceName .. ' is unknown Device/Scene'
			return 0, response, replymarkup
		end
	end

	if action == '' then
		-- Get device/scene current status
		local sSwitchType=''
		local sSwitchStatus=''
		local sLevelNames=''
		local sLevelInt=''
		local DResult = Domo_Retrieve_Status(DeviceID, switchtype)
		if DResult and DResult['result'] then
			local record = DResult['result'][1]
			if type(record) == 'table' then
				DeviceName = record.Name or DeviceName
				sSwitchType = record.SwitchType or '??'
				sSwitchStatus = record.Status or '??'
				sLevelNames = _G.Base64_Decode(record.LevelNames or '')
				sLevelInt = record.LevelInt or '??'
			end
		end
		-- Print_to_Log(3, 'DResult:' .. tostring(JSON.encode(DResult, { indent = true })))
		-- Print_to_Log(3, 'DeviceID:' .. DeviceID .. ' sSwitchType:' .. sSwitchType .. ' sSwitchStatus:' .. sSwitchStatus .. ' sLevelNames:' .. sLevelNames .. ' sLevelInt:' .. sLevelInt)
		-- local _, _, _, _, sSwitchType, _, sSwitchStatus, sLevelNames, sLevelInt = Domo_Devinfo_From_Name(0, DeviceName, switchtype)
		sSwitchStatus = sSwitchStatus or ''
		local oswst
		if sSwitchStatus ~= '' then
			if sSwitchType == 'Selector' then
				oswst = tostring(sLevelInt) .. '->' .. getSelectorStatusLabel(sLevelNames, sLevelInt)
			else
				oswst = tostring(sSwitchStatus)
				-- oswst = sSwitchStatus:gsub('Set Level: ', '')
			end
		end
		replymarkup = ''
		response = switchtype ..' "' .. DeviceName .. '" = ' .. (oswst or '??')
		return 1, response, replymarkup
	end

	-- process the action when either a device or a scene
	if switchtype == 'devices' and action:sub(1, 7):lower() == 'udevice' then
		local sValue = action:gsub('udevice ', '')
		local dUrl = 'type=command&param=udevice&idx=' .. DeviceID .. '&nvalue=0&svalue=' .. sValue .. '&parsetrigger=' .. tostring(udevtrigger)
		Print_to_Log(3, ' update url:' .. dUrl)
		local decoded_response, dstatus = PerformDomoticzRequest(dUrl, 2)
		if decoded_response then
			response = 'Udevice: Set "' .. DeviceName .. '" to ' .. sValue .. ' trigger=' .. tostring(udevtrigger)
		else
			response = 'Udevice: ' .. (dstatus or '??') .. ' Failed to Set ' .. DeviceName .. ' to ' .. sValue
		end
	else
		if action:sub(1, 9):lower() == 'set level' then
			local sValue = action:sub(11)
			-- Set the proper level to set the dimmer
			action = string.format('Set Level %.0f', sValue:gsub('[%s%%]', '')) -- remove % & decimals
			Print_to_Log(3, ' 1. action Set Level:' .. action)
		elseif action:match('^%d+%s*%%?$') then
			local sValue = action
			-- Set the proper level to set the dimmer
			action = string.format('Set Level %.0f', sValue:gsub('[%s%%]', '')) -- remove % & decimals
			Print_to_Log(3, ' 2. action Set Level:' .. action)
		end
		-- Now switch the device or scene
		response, status = Domo_sSwitchName(DeviceName, switchtype, switchtype, DeviceID, action)
		Print_to_Log(2, 'DeviceName:"' .. DeviceName .. '" updated Set Level:' .. action)
	end
	-- remove info when /silent is provided as parameter > 3
	if silent then
		Print_to_Log(3, '/silent active')
		response = ''
		replymarkup = ''
	end
		--
	return 1, response, replymarkup
end

-- Process User Variables actions
local function process_variable_action(UservarName, action)
		-- Update UserList table
		_G.Variablelist = Domo_Variable_List_Names_IDXs()
		local status = 0
		local response = ''
		local replymarkup = ''
		local UservarValue = action
		if UservarName == nil or UservarName == '' then
			response = 'UserVariable name is missing! format is: ia -v varname value'
			status = 0
			Print_to_Log(2, response)
			return status, response, replymarkup
		end
		UservarName = UservarName:match('%s*(.*)%s*') -- trim spaces
		UservarValue = (UservarValue or ''):match('%s*(.*)%s*') -- trim spaces

		local uidx
		local utype
		if _G.Variablelist[UservarName] then
			uidx = _G.Variablelist[UservarName].idx
			utype = _G.Variablelist[UservarName].type
		elseif _G.Variablelist[UservarName:lower()] then
			uidx = _G.Variablelist[UservarName:lower()].idx
			utype = _G.Variablelist[UservarName:lower()].type
			UservarName = _G.Variablelist[UservarName:lower()].name
			Print_to_Log(2, ' propercase username:' .. UservarName)
		end
		if not uidx or UservarName == '' then
			replymarkup = ''
			response = 'Unknown uservar ' .. UservarName
			return 0, response, replymarkup
		end
		if uidx == 0 then
			replymarkup = ''
			response = 'Unknown uservar ' .. UservarName
			return 0, response, replymarkup
		end
		if UservarValue == '' then
			-- Get user variable DevicesWithTemperature
			UservarValue = Domo_Get_Variable_Value(uidx)
			replymarkup = ''
			response = 'Uservariable "' .. UservarName .. '" = ' .. UservarValue
			status = 1
		else
			-- set the value of the uservar
			Print_to_Log(3, 'uidx:' .. uidx)
			Print_to_Log(3, 'UservarName:' .. UservarName)
			Print_to_Log(3, 'utype:' .. (utype or '?'))
			Print_to_Log(3, 'UservarValue:' .. tostring(UservarValue))
			local urlresponse, dstatus = Domo_Set_Variable_Value(uidx, UservarName, utype, tostring(UservarValue))
			if dstatus == 200 then
				response = 'Uservariable "' .. UservarName .. '" set to ' .. UservarValue
				status = 1
			else
				response = 'Uservariable "' .. UservarName  .. '" not set to ' .. UservarValue .. " Status:" .. status .. '  Response:' .. ((urlresponse or {}).message or '')
				status = 0
			end
		end
		return status, response, replymarkup
end

-- process the received command by DTGBOT
local function perform_action(parsed_cli, SendTo, MessageId)
	Print_to_Log(2, 'Inlineaction start: ' .. tostring(#parsed_cli))
	local InputName = ''
	local action = ''
	local status, response, replymarkup
	local switchtype
	local udevtrigger = false
	local silent = false
	local isdevice = false
	local isvariable = false

	for x, param in pairs(parsed_cli) do
		Print_to_Log(3, 'command parameter ' .. x .. '=' .. param)
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
				if param:find('d', 2) then
					isdevice = true
				end
				if param:find('v', 2) then
					isvariable = true
				end
			-- start backwards compatibility previous versions
			elseif param == 'uservar' then
					isdevice = false
					isvariable = true
			elseif param == '/silent' then
				silent = true
			-- end backwards compatibility previous versions
			elseif InputName == '' then
				-- assume this param is the action when that is the last parameter
				InputName = param
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
	Print_to_Log(2, 'SendTo:' .. SendTo)
	Print_to_Log(2, 'MessageId:' .. MessageId)
	Print_to_Log(2, 'InputName:' .. (InputName or ' no Name provided'))
	Print_to_Log(2, 'Action:' .. action)
	Print_to_Log(2, 'isdevice:' .. tostring(isdevice))
	Print_to_Log(2, 'isvariable:' .. tostring(isvariable))

	-- remove keyboard when exit is defined as action and
	if action == 'exit' then
		response = 'exit ' .. InputName
		replymarkup = 'remove'
		if silent then
			response = ''
		end
	elseif action == 'remove' then
	-- remove message and keyboard when remove is defined as action
		response = 'remove'
		replymarkup = 'remove'
	else
		-- process the action for  device when type is -d or not defined
		if isdevice or not isvariable then
			status, response, replymarkup = process_device_action(InputName, action, isdevice, switchtype, udevtrigger, silent)
			if status == 1 then
				isdevice = true
			end
		end
		-- process the action for  uservariable when type is -v or not defined and device process failed
		if isvariable or not isdevice then
			status, response, replymarkup = process_variable_action(InputName, action)
		end
	end
	Print_to_Log(2, '<- response:' .. tostring(response))
	--
	return 1, response, replymarkup
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

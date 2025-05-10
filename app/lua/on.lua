local on_module = {};
--JSON = assert(loadfile "_G.JSON.lua")() -- one-time load of the routines

local function switch(parsed_cli)
	local response
	local len_DeviceNames
	local switchtype
	local command = parsed_cli[2]
	DeviceNames = Form_Device_names(parsed_cli)
	response = ''
	if DeviceNames ~= nil then
		len_DeviceNames = #DeviceNames
		for j = 1, len_DeviceNames do
			DeviceName = DeviceNames[j]
			-- DeviceName can either be a device / group / scene name or a number refering to list previously generated
			if tonumber(DeviceName) ~= nil then
				NewDeviceName = _G.StoredList[tonumber(DeviceName)]
				if NewDeviceName == nil then
					response = response .. 'No ' .. _G.StoredType .. ' with number ' .. DeviceName .. ' was found - please execute devices or scenes command with qualifier to generate list' .. '\n'
					return response
				else
					DeviceName = NewDeviceName
				end
			end
			-- Update the list of device names and ids to be checked later
			-- Check if DeviceName is a device
			DeviceID = Domo_Idx_From_Name(DeviceName, 'devices')
			switchtype = 'light'
			-- Its not a device so check if a scene
			if DeviceID == nil then
				DeviceID = Domo_Idx_From_Name(DeviceName, 'scenes')
				switchtype = 'scene'
			end
			if DeviceID ~= nil then
				-- Now switch the device
				response = response .. Domo_SwitchID(DeviceName, DeviceID, switchtype, command) .. '\n'
			else
				response = response .. 'Device ' .. DeviceName .. ' was not found on Domoticz - please check spelling and capitalisation' .. '\n'
			end
		end
	else
		response = 'No device specified'
	end
	return response
end

function on_module.handler(parsed_cli)
	local response = ''
	response = switch(parsed_cli)
	return nil, response;
end

local on_commands = {
	['on'] = { handler = on_module.handler, description = 'on - on devicename - switches devicename on' },
	['off'] = { handler = on_module.handler, description = 'off - off devicename - switches devicename off' }
}

function on_module.get_commands()
	return on_commands;
end

return on_module;

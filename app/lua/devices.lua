local devices_module = {};
--JSON = assert(loadfile "_G.JSON.lua")() -- one-time load of the routines

function DevicesScenes(parsed_cli)
	local DeviceType = parsed_cli[2]:lower()
	local qualifier = nil
	local getDevStatus = false
	local devcontains = false
	for index, value in ipairs(parsed_cli) do
		if index > 2 then
			if value:sub(1,1) == '-' then
				if value:find('s', 2) then
					getDevStatus = true
				end
				if value:find('c', 2) then
					devcontains = true
				end
			else
				qualifier = value
			end
		end
	end
	local response = ''
	local ItemNumber, result, decoded_response
	if qualifier then
		if devcontains then
			response = 'All ' .. DeviceType .. ' containing ' .. qualifier
		else
			response = 'All ' .. DeviceType .. ' starting with ' .. qualifier
		end
		qualifier = string.lower(qualifier)
	else
		response = 'All available ' .. DeviceType
	end

	decoded_response = Domo_Device_List(DeviceType)
	result = decoded_response['result']
	_G.StoredType = DeviceType
	_G.StoredList = {}
	ItemNumber = 0
	if type(result) == 'table' then
		for k, record in pairs(result) do
			if type(record) == 'table' then
				DeviceName = record['Name']
				-- Don't bother to store Unknown devices
				if DeviceName ~= 'Unknown' then
					if qualifier then
						if (devcontains and DeviceName:lower():find(qualifier, 1, true))
						or ((not devcontains) and qualifier == string.lower(string.sub(DeviceName, 1, qualifier:len()))) then
							ItemNumber = ItemNumber + 1
							local oswst = ''
							if getDevStatus then
								-- get dev status
								local _, _, _, _, dSwitchType, _, switchstatus, LevelNames, LevelInt = Domo_Devinfo_From_Name(0, DeviceName)
								switchstatus = switchstatus or ''
								if switchstatus ~= '' then
									if dSwitchType == 'Selector' then
										oswst = ' - ' .. getSelectorStatusLabel(LevelNames, LevelInt)
									else
										--~ 							Print_to_Log(0,switchstatus)
										oswst = tostring(switchstatus)
										oswst = switchstatus:gsub('Set Level: ', '')
										oswst = '->' .. oswst
									end
								end
							end
							table.insert(_G.StoredList, DeviceName .. oswst)
						end
					else
						ItemNumber = ItemNumber + 1
						table.insert(_G.StoredList, DeviceName)
					end
				end
			end
		end
	end
	table.sort(_G.StoredList)
	if #_G.StoredList ~= 0 then
		for ItemNumber, DeviceName in ipairs(_G.StoredList) do
			response = response .. '\n' .. ItemNumber .. ' - ' .. _G.StoredList[ItemNumber]
		end
	else
		response = response .. ' none found'
	end
	return response
end

function devices_module.handler(parsed_cli)
	local response = ''
	response = DevicesScenes(parsed_cli)
	return nil, response;
end

local devices_commands = {
	['devices'] = { handler = devices_module.handler, description = 'devices - return list of all devices\n>devices Room - all devices that start with Room\n Options\n  -c = contains instead of start with\n  -s = Also show current status' },
	['scenes'] = { handler = devices_module.handler, description = 'scenes - scenes - return list of all scenes\n>scenes down - all scenes that start with down' }
}

function devices_module.get_commands()
	return devices_commands;
end

return devices_module;

local devices_module = {};
--JSON = assert(loadfile "_G.JSON.lua")() -- one-time load of the routines

function DevicesScenes(DeviceType, qualifier, state)
	state = state or ''
	local switchstatus = ''
	local quallength = 0
	local response = ''
	local ItemNumber, result, decoded_response
	if qualifier ~= nil then
		response = 'All ' .. DeviceType .. ' starting with ' .. qualifier
		qualifier = string.lower(qualifier)
		quallength = string.len(qualifier)
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
					if qualifier and qualifier == string.lower(string.sub(DeviceName, 1, quallength)) then
						ItemNumber = ItemNumber + 1
						if state ~= '' then
							-- get dev status
							local _, _, _, _, dSwitchType, _, switchstatus, LevelNames, LevelInt = Domo_Devinfo_From_Name(0, DeviceName)
              switchstatus = switchstatus or ''
              if switchstatus ~= '' then
								if dSwitchType == 'Selector' then
									switchstatus = ' - ' .. getSelectorStatusLabel(LevelNames, LevelInt)
								else
									--~ 							Print_to_Log(0,switchstatus)
									switchstatus = tostring(switchstatus)
									switchstatus = switchstatus:gsub('Set Level: ', '')
									switchstatus = '->' .. switchstatus
								end
							end
						end
						table.insert(_G.StoredList, DeviceName .. switchstatus)
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
	response = DevicesScenes(string.lower(parsed_cli[2]), parsed_cli[3], parsed_cli[4])
	return nil, response;
end

local devices_commands = {
	['devices'] = { handler = devices_module.handler, description = 'devices - devices - return list of all devices\ndevices - devices qualifier - all that start with qualifier i.e.\n devices St - all devices that start with St' },
	['scenes'] = { handler = devices_module.handler, description = 'scenes - scenes - return list of all scenes\ndevices - devices qualifier - all that start with qualifier i.e.\n scenes down - all scenes that start with down' }
}

function devices_module.get_commands()
	return devices_commands;
end

return devices_module;

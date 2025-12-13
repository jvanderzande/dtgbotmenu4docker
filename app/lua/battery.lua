local battery_module = {}
--JSON = assert(loadfile "_G.JSON.lua")() -- one-time load of the routines

local function get_battery_level(DeviceName)
	local idx = Domo_Idx_From_Name(DeviceName, 'devices')
	if idx == nil then
		return DeviceName, -999, 0
	end
	-- Determine battery level
	local t
	if (_G.DomoticzBuildDate or 0) > 20230601 then
		t = _G.DomoticzUrl .. '/json.htm?type=command&param=getdevices&rid=' .. idx
	else
		t = _G.DomoticzUrl .. '/json.htm?type=devices&rid=' .. idx
	end

	Print_to_Log(0, 'JSON request <' .. t .. '>')
	local jresponse, status = _G.HTTP.request(t)
	local decoded_response = _G.JSON.decode(jresponse) or {}
	local result = decoded_response['result']
	local record = result[1]
	BattLevel = record['BatteryLevel']
	LastUpdate = record['LastUpdate']
	DeviceName = record['Name']
	return DeviceName, BattLevel, LastUpdate
end

local function battery(DeviceName)
	local response = ''
	DeviceName, BattLevel, LastUpdate = get_battery_level(DeviceName)
	if BattLevel == -999 then
		Print_to_Log(DeviceName .. ' does not exist')
		return 1, DeviceName .. ' does not exist'
	end
	Print_to_Log(DeviceName .. ' batterylevel is ' .. BattLevel .. '%')
	response = DeviceName .. ' battery level was ' .. BattLevel .. '% when last seen ' .. LastUpdate
	return nil, response
end

function battery_module.handler(parsed_cli)
	local t, jresponse, status, decoded_response, result, idx, record
	local response = ''
	if string.lower(parsed_cli[2]) == 'battery' then
		DeviceName = Form_Device_name(parsed_cli)
		if DeviceName == nil then
			Print_to_Log(0, 'No Battery Device Name given')
			return 1, 'No Battery Device Name given'
		end
		status, response = battery(DeviceName)
	else
		-- Get list of all user variables
		t = _G.DomoticzUrl .. '/json.htm?type=command&param=getuservariables'
		Print_to_Log(0, 'JSON request <' .. t .. '>')
		jresponse, status = _G.HTTP.request(t)
		decoded_response = _G.JSON.decode(jresponse) or {}
		result = decoded_response['result']
		idx = 0
		for k, record in pairs(result) do
			if type(record) == 'table' then
				if record['Name'] == 'DevicesWithBatteries' then
					Print_to_Log(record['idx'])
					idx = record['idx']
				end
			end
		end
		if idx == 0 then
			Print_to_Log(0, 'User Variable DevicesWithBatteries not set in Domoticz')
			return 1, 'User Variable DevicesWithBatteries not set in Domoticz'
		end
		-- Get user variable DevicesWithBatteries
		t = _G.DomoticzUrl .. '/json.htm?type=command&param=getuservariable&idx=' .. idx
		Print_to_Log(0, 'JSON request <' .. t .. '>')
		jresponse, status = _G.HTTP.request(t)
		decoded_response = _G.JSON.decode(jresponse) or {}
		result = decoded_response['result']
		record = result[1]
		DevicesWithBatteries = record['Value']
		DeviceNames = {}
		Print_to_Log(DevicesWithBatteries)
		for DeviceName in string.gmatch(DevicesWithBatteries, '[^|]+') do
			DeviceNames[#DeviceNames + 1] = DeviceName
		end
		-- Loop round each of the devices with batteries
		local r
		for i, DeviceName in ipairs(DeviceNames) do
			status, r = battery(DeviceName)
			response = response .. r .. '\n'
		end
	end
	return status, response
end

local battery_commands = {
	['battery'] = { handler = battery_module.handler, description = 'battery - battery devicename - returns battery level of devicename and when last updated' },
	['batteries'] = { handler = battery_module.handler, description = 'batteries - batteries - returns battery level of DevicesWithBatteries and when last updated' }
}

function battery_module.get_commands()
	return battery_commands
end

return battery_module

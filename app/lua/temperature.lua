local temperature_module = {};
--JSON = assert(loadfile "_G.JSON.lua")() -- one-time load of the routines

local function get_temperature(DeviceName)
	local idx = Domo_Idx_From_Name(DeviceName, 'devices')
	if idx == nil then
		return DeviceName, -999, -999, -999, 0
	end
	Temperature = -999
	Humidity = -999
	Pressure = -999
	-- Determine temperature
	local t
	if (_G.DomoticzBuildDate or 0) > 20230601 then
		t = _G.DomoticzUrl .. '/json.htm?type=command&param=getdevices&rid=' .. idx
	else
		t = _G.DomoticzUrl .. '/json.htm?type=devices&rid=' .. idx
	end

	print('JSON request <' .. t .. '>');
	local jresponse, status = _G.HTTP.request(t)
	local decoded_response = _G.JSON.decode(jresponse) or {}
	local result = decoded_response['result']
	local record = result[1]
	DeviceType = record['Type']
	if DeviceType == 'Temp' then
		Temperature = record['Temp']
	else
		if DeviceType == 'Humidity' then
			Humidity = record['Humidity']
		else
			if DeviceType == 'Temp + Humidity' then
				Temperature = record['Temp']
				Humidity = record['Humidity']
			else
				if DeviceType == 'Temp + Humidity + Baro' then
					Temperature = record['Temp']
					Humidity = record['Humidity']
					Pressure = record['Barometer']
				end
			end
		end
	end
	LastUpdate = record['LastUpdate']
	DeviceName = record['Name']
	return DeviceName, Temperature, Humidity, Pressure, LastUpdate;
end

local function temperature(DeviceName)
	local response = ''
	DeviceName, Temperature, Humidity, Pressure, LastUpdate = get_temperature(DeviceName)
	if Temperature == -999 and Humidity == -999 and Pressure == -999 then
		Print_to_Log(1, DeviceName .. ' does not exist')
		return 1, 'Devicename ' .. DeviceName .. ' not found in Domoticz'
	else
		if Temperature == -999 and Pressure == -999 then
			Print_to_Log(2, DeviceName .. ' relative humidity is ' .. Humidity .. '%')
			response = DeviceName .. ' ' .. Humidity .. '%'
		else
			if Pressure ~= -999 then
				Print_to_Log(2, DeviceName .. ' temperature is ' .. Temperature .. '°C, relative humidity is ' .. Humidity .. '% and pressure is ' .. Pressure .. 'hPa')
				response = DeviceName .. ' ' .. Temperature .. '°C & ' .. Humidity .. '% & ' .. Pressure .. 'hPa'
			else
				if Humidity ~= -999 then
					Print_to_Log(2, DeviceName .. ' temperature is ' .. Temperature .. '°C and relative humidity is ' .. Humidity .. '%')
					response = DeviceName .. ' ' .. Temperature .. '°C & ' .. Humidity .. '%'
				else
					Print_to_Log(2, DeviceName .. ' temperature is ' .. Temperature .. '°C')
					response = DeviceName .. ' ' .. Temperature .. '°C'
				end
			end
		end
	end
	return nil, response;
end

function temperature_module.handler(parsed_cli)
	local status, result, idx
	local response = ''
	if string.lower(parsed_cli[2]) == 'temperature' then
		DeviceName = Form_Device_name(parsed_cli)
		if DeviceName == nil then
			Print_to_Log(0, 'No Temperature Device Name given')
			return 1, 'No Temperature Device Name given'
		end
		status, response = temperature(DeviceName)
	elseif string.lower(parsed_cli[2]) == 'tempall' then
		-- get all devices with temp info
		Deviceslist = Domo_Device_List('devices&used=true&filter=temp')
		result = Deviceslist['result'] or {}
		status = ''
		if type(result) == 'table' then
			for k, record in pairs(result) do
				if type(record) == 'table' then
					-- as default simply use the status field
					-- use the DTGBOT_type_status to retrieve the status from the "other devices" field as defined in the table.
					if DTGBOT_type_status[record.Type] ~= nil then
						if DTGBOT_type_status[record.Type].Status ~= nil then
							status = ''
							CurrentStatus = DTGBOT_type_status[record.Type].Status
							for i = 1, #CurrentStatus do
								if status ~= '' then
									status = status .. ' - '
								end
								local cindex, csuffix = next(CurrentStatus[i])
								status = status .. tostring(record[cindex]) .. tostring(csuffix)
							end
						end
					else
						status = tostring(record.Status)
					end
					Print_to_Log(2, ' !!!! found temp device', record.Name, record.Type, status)
				end
				response = response .. record.Name .. ':' .. status .. '\n'
			end
		end
	else
		-- Get list of all user variables
		idx = Domo_Idx_From_Variable_Name('DevicesWithTemperatures')
		if idx == 0 then
			Print_to_Log(0, 'User Variable DevicesWithTemperatures not set in Domoticz')
			return 1, 'User Variable DevicesWithTemperatures not set in Domoticz'
		end
		-- Get user variable DevicesWithTemperature
		DevicesWithTemperatures = Domo_Get_Variable_Value(idx)
		Print_to_Log(0, DevicesWithTemperatures)
		-- Retrieve the names
		DeviceNames = Domo_Get_Names_From_Variable(DevicesWithTemperatures)
		-- Loop round each of the devices with temperature
		if DeviceNames ~= nil then
			response = ''
			local r
			for i, DeviceName in ipairs(DeviceNames) do
				status, r = temperature(DeviceName)
				response = response .. r .. '\n'
			end
		else
			response = 'No device names found in ' .. DevicesWithTemperatures
		end
	end
	return status, response
end

local temperature_commands = {
	['tempall'] = { handler = temperature_module.handler, description = 'tempall - show all devices with a temperature value.' },
	['temperature'] = { handler = temperature_module.handler, description = 'temperature - temperature devicename - returns temperature level of devicename and when last updated' },
	['temperatures'] = { handler = temperature_module.handler, description = 'temperatures - temperatures - returns temperature level of DevicesWithTemperatures and when last updated' }
}

function temperature_module.get_commands()
	return temperature_commands;
end

return temperature_module;

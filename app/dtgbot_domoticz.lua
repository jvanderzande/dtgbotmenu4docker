_G.dtg_domoticz_version = '1.0 202512221118'
--[[
	A set of support functions used for DTGBOT
	Developer: Jos v.d.Zande
	This is a spinoff of the oroginal DTGBOT developed by s.gibbon https://github.com/steps39
	GNU GENERAL PUBLIC LICENSE
]]

function PerformDomoticzRequest(dUrl, retries, loglevel)
	loglevel = loglevel or 99
	if not dUrl then return nil, nil end
	retries = retries or 1
	local domoticz_tries = 0
	dUrl = _G.DomoticzUrl .. '/json.htm?' .. dUrl
	Print_to_Log(9, 'JSON request <' .. dUrl .. '>')
	local decoded_response, jresponse, status
	-- So just keep trying after 1 second sleep
	while (jresponse == nil) do
		domoticz_tries = domoticz_tries + 1
		-- set timeout to 3 sec
		_G.HTTP.TIMEOUT = (3)
		jresponse, status = _G.HTTP.request(dUrl)
		if (jresponse ~= nil) then
			break
		end
		if domoticz_tries >= retries then
			Print_to_Log(9, 'No response from domoticz:' .. domoticz_tries)
			break
		end
		_G.SOCKET.sleep(1)
	end
	--
	Print_to_Log(9, '<< status:' .. (status or '??') .. '  response <' .. (jresponse or '??') .. '>')
	--
	if jresponse ~= nil then
		decoded_response = _G.JSON.decode(jresponse)
	else
		if loglevel ~= 99 then
			Print_to_Log(loglevel, 'JSON request <' .. dUrl .. '>')
			Print_to_Log(loglevel, '<< status:' .. (status or '??') .. '  response <' .. (jresponse or '??') .. '>')
		end
		decoded_response = nil
	end
	return decoded_response, (status or 999), (jresponse or '')
end

function _G.Check_Json_Result(decoded_response)
	local jsonok = false
	if decoded_response ~= nil then
		if decoded_response.status ~= nil and decoded_response.status:lower() == 'ok' then
			jsonok = true
		end
	end
	return jsonok
end

function Form_Device_name(parsed_cli)
	-- joins together parameters after the command name to form the full "device name"
	Print_to_Log(0, parsed_cli[2])
	DeviceName = parsed_cli[3]
	Print_to_Log(0, parsed_cli[3])
	local len_parsed_cli = #parsed_cli
	if len_parsed_cli > 3 then
		for i = 4, len_parsed_cli do
			DeviceName = DeviceName .. ' ' .. parsed_cli[i]
			Print_to_Log(0, parsed_cli[i])
		end
	end
	Print_to_Log(0, DeviceName)
	return DeviceName
end

function Form_Device_names(parsed_cli)
	-- joins together parameters after the command name to form the full "device name"
	--command = parsed_cli[2]
	DeviceNames = {}
	DeviceNames[1] = ''
	local j = 1
	local len_parsed_cli = #parsed_cli
	local bit
	for i = 3, len_parsed_cli do
		bit = parsed_cli[i]
		if not (string.match(bit, ',')) then
			bit = string.gsub(bit, ' ', '')
			if (DeviceNames[j] == '') then
				DeviceNames[j] = bit
			else
				DeviceNames[j] = DeviceNames[j] .. ' ' .. bit
			end
		else
			-- Needed to deal with , ,word, word,word etc..
			bit = string.gsub(bit, ',', ' , ')
			for w in string.gmatch(bit, '([^ ]+)') do
				w = string.gsub(w, ' ', '')
				if (w == ',') then
					j = j + 1
					DeviceNames[j] = ''
				else
					if (DeviceNames[j] == '') then
						DeviceNames[j] = w
					else
						DeviceNames[j] = DeviceNames[j] .. ' ' .. w
					end
				end
			end
		end
	end
	return DeviceNames
end

-- returns list of all user variables - called early by dtgbot
-- in case Domoticz is not running will retry
-- allowing Domoticz time to start
function Domo_Variable_List()
	local dUrl = 'type=command&param=getuservariables'
	local decoded_response, status, jresponse = PerformDomoticzRequest(dUrl, 2)
	if status ~= 200 then
		Print_to_Log(-1, 'Domoticz returned status:' .. status .. '   response:' .. (jresponse or ''))
	else
		if decoded_response == nil then
			decoded_response = {}
			decoded_response['result'] = '{}'
		end
	end
	return decoded_response
end

-- returns idx of a user variable from name
function Domo_Variable_List_Names_IDXs()
	local record, decoded_response, result
	decoded_response = Domo_Variable_List() or {}
	result = decoded_response['result']
	local variables = {}
	if result then
		for i = 1, #result do
			record = result[i]
			if type(record) == 'table' then
				variables[record['Name']] = record['idx']
			end
		end
	end
	return variables
end

function Domo_Idx_From_Variable_Name(DeviceName)
	return Variablelist[DeviceName]
end

-- returns the value of the variable from the idx
function Domo_Get_Variable_Value(idx)
	if idx == nil then
		return ''
	end
	local dUrl = 'type=command&param=getuservariable&idx=' .. tostring(idx)
	local decoded_response, status = PerformDomoticzRequest(dUrl, 2)
	if decoded_response then
		Print_to_Log(2, _G.Sprintf('Idx:%s  Value:%s ', idx, decoded_response['result'][1]['Value']))
		if decoded_response and decoded_response['result'] and decoded_response['result'][1] and decoded_response['result'][1]['Value'] then
			return decoded_response['result'][1]['Value']
		end
	else
		Print_to_Log(2, _G.Sprintf('!! Unable to get value for Idx:%s  Value: ?? ', idx))
	end
	return ''
end

function Domo_Set_Variable_Value(idx, name, Type, value)
	-- store the value of a user variable
	local dUrl = 'type=command&param=updateuservariable&idx=' .. idx .. '&vname=' .. name .. '&vtype=' .. Type .. '&vvalue=' .. tostring(value)
	local decoded_response, status = PerformDomoticzRequest(dUrl, 2)
	if status == 200 then
		return true
	end
	return false
end

-- ### Not Used currently
function Domo_Create_Variable(name, Type, value)
	-- creates user variable
	local dUrl = 'type=command&param=saveuservariable&vname=' .. name .. '&vtype=' .. Type .. '&vvalue=' .. tostring(value)
	local decoded_response, status = PerformDomoticzRequest(dUrl, 2)
	if status == 200 then
		return true
	end
	return false
end

function Domo_Get_Names_From_Variable(DividedString)
	local Names = {}
	for Name in string.gmatch(DividedString, '[^|]+') do
		Names[#Names + 1] = Name
		Print_to_Log(2, 'Name :' .. Name)
	end
	if Names == {} then
		Names = nil
	end
	return Names
end

-- returns a device table of Domoticz items based on type i.e. devices or scenes
function Domo_Device_List(DeviceType, idx)
	local dUrl
	-- Use new API format as of Revison 15326.
	if DeviceType == 'plandevices' then
		if idx then
			dUrl = 'type=command&param=get' .. DeviceType .. '&idx=' .. idx
		else
			Print_to_Log(0, ' idx parameter missing for DevicelistByName update :' .. DeviceType)
		end
	else
		if (_G.DomoticzBuildDate or 0) > 20230601 then
			dUrl = 'type=command&param=get' .. DeviceType .. '&order=name&used=true'
		else
			dUrl = 'type=' .. DeviceType .. '&order=name&used=true'
		end
	end
	local decoded_response, status = PerformDomoticzRequest(dUrl, 2)
	if decoded_response == nil then
		decoded_response = {}
		decoded_response['result'] = '{}'
	end
	return decoded_response or {}
end

-- returns a list of Domoticz items based on type i.e. devices or scenes
function Domo_Get_Device_Information(DeviceType)
	--returns a device idx based on its name
	local record, decoded_response
	decoded_response = Domo_Device_List(DeviceType) or {}
	local result = decoded_response['result'] or {}
	local devicesbyname = {}
	local dcount = 0;
	local devicesbyidx = {}
	if result ~= nil then
		for i = 1, #result do
			record = result[i]
			if type(record) == 'table' then
				if DeviceType == 'plans' then
					devicesbyname[record['Name']] = record['idx']
					--devicesbyname[record['Name']] = record
					dcount = dcount + 1
				else
					devicesbyname[string.lower(record['Name'])] = record
					devicesbyidx[record['idx']] = record
					--devicesbyname[record['idx']] = record['Name']
					--if DeviceType == 'scenes' then
					--	--devicesbyidx[record['idx']] = { Type = record['Type'], SwitchType = record['Type'] }
					--	devicesbyidx[record['idx']] = record
					--end
					dcount = dcount + 1
				end
			end
		end
		Print_to_Log(2, '  DeviceType:' .. DeviceType .. '  count:' .. dcount .. '   _G.DomoticzBuildDate:' .. _G.DomoticzBuildDate)
	else
		Print_to_Log(0, ' !!!! Domo_Get_Device_Information(): nothing found for ', DeviceType)
	end
	return devicesbyname, devicesbyidx
end

function Domo_Idx_From_Name(DeviceName, DeviceType)
	--returns a device idx based on its name
	if DeviceType == 'devices' then
		if DevicelistByName[string.lower(DeviceName)] then
			return DevicelistByName[string.lower(DeviceName)].idx
		else
			Print_to_Log(9, string.lower(DeviceName) .. ' not in table DevicelistByName!?')
			return nil
		end
	elseif DeviceType == 'scenes' then
		if ScenelistByName[string.lower(DeviceName)] then
			return ScenelistByName[string.lower(DeviceName)].idx
		else
			Print_to_Log(9, string.lower(DeviceName) .. ' not in table ScenelistByName!?')
			return nil
		end
	else
		return Roomlist[DeviceName]
	end
end

function Domo_Retrieve_Status(idx, DeviceType)
	local dUrl, jresponse, status, decoded_response
	if (_G.DomoticzBuildDate or 0) > 20230601 then
		dUrl = 'type=command&param=get' .. DeviceType .. '&rid=' .. tostring(idx)
	else
		dUrl = 'type=' .. DeviceType .. '&rid=' .. tostring(idx)
	end
	decoded_response, status = PerformDomoticzRequest(dUrl)
	return decoded_response
end

-- support function to scan through the Devices and Scenes idx tables and retrieve the required information for it
function Domo_Devinfo_From_Name(idx, DeviceName, DeviceScene)
	local k, record, Type, DeviceType, SwitchType
	local found = 0
	local rDeviceName = ''
	local status = ''
	local LevelNames = ''
	local LevelInt = 0
	local MaxDimLevel = 100
	local ridx = 0
	local tvar
	if DeviceScene ~= 'scenes' then
		-- Check for Devices
		-- Have the device name
		if DeviceName ~= '' then
			idx = Domo_Idx_From_Name(DeviceName, 'devices')
		end
		Print_to_Log(2, '==> start Domo_Devinfo_From_Name', idx, DeviceName)
		if idx ~= nil and idx ~= 0 then
			tvar = Domo_Retrieve_Status(idx, 'devices')
			if not tvar or not tvar['result'] then
				found = 9
			else
				record = tvar['result'][1]
				if record ~= nil and record.Name ~= nil and record.idx ~= nil then
					Print_to_Log(2, 'device ', DeviceName, record.Name, idx, record.idx)
				end
				if type(record) == 'table' then
					ridx = record.idx
					rDeviceName = record.Name
					DeviceType = 'devices'
					Type = record.Type
					LevelInt = record.LevelInt
					if LevelInt == nil then
						LevelInt = 0
					end
					LevelNames = record.LevelNames
					if LevelNames == nil then
						LevelNames = ''
					end
					-- as default simply use the status field
					-- use the DTGBOT_type_status to retrieve the status from the "other devices" field as defined in the table.
					Print_to_Log(2, 'Type ', Type)
					if DTGBOT_type_status[Type] ~= nil then
						Print_to_Log(2, 'DTGBOT_type_status[Type] ', JSON.encode(DTGBOT_type_status[Type]))
						if DTGBOT_type_status[Type].Status ~= nil then
							status = ''
							CurrentStatus = DTGBOT_type_status[Type].Status
							Print_to_Log(2, 'CurrentStatus ', JSON.encode(CurrentStatus))
							for i = 1, #CurrentStatus do
								if status ~= '' then
									status = status .. ' - '
								end
								local cindex, csuffix = next(CurrentStatus[i])
								status = status .. tostring(record[cindex]) .. tostring(csuffix)
								Print_to_Log(2, 'cindex:', cindex, '  csuffix:', csuffix, '  status:', status)
							end
						end
					else
						SwitchType = record.SwitchType
						-- Check for encoded selector LevelNames
						if SwitchType == 'Selector' then
							if string.find(LevelNames, '[|,]+') then
								Print_to_Log(2, '--  < 4.9700 selector switch levelnames: ', LevelNames)
							else
								LevelNames = _G.MIME.unb64(LevelNames)
								Print_to_Log(2, '--  >= 4.9700  decoded selector switch levelnames: ', LevelNames)
							end
						end
						MaxDimLevel = record.MaxDimLevel
						LevelInt = record.LevelInt
						status = tostring(record.Status)
						-- Set the Dimmer level in case it is a dimmer device.
						if SwitchType == 'Dimmer' and record.Status ~= 'Off' and LevelInt > 0 and LevelInt < MaxDimLevel then
							status = tostring(LevelInt * 100 / MaxDimLevel) .. '%'
							Print_to_Log(9, '@@@@  Change status dimmer from ' .. tostring(record.Status) .. ' to ' .. status)
						end
					end
					found = 1
					--~         Print_to_Log(2," !!!! found device",record.Name,rDeviceName,record.idx,ridx)
				end
			end
		end
		--~     Print_to_Log(2," !!!! found device",rDeviceName,ridx)
	end
	-- Check for Scenes
	if found == 0 then
		if DeviceName ~= '' then
			idx = Domo_Idx_From_Name(DeviceName, 'scenes')
		else
			DeviceName = Domo_Idx_From_Name(idx, 'scenes')
		end
		if idx and ScenelistByIDX[idx] then
			DeviceName = ScenelistByIDX[idx].Name
			DeviceType = 'scenes'
			ridx = idx
			rDeviceName = DeviceName
			SwitchType = ScenelistByIDX[idx]['SwitchType']
			Type = ScenelistByIDX[idx]['Type']
			found = 1
		end
	end
	-- Check for Scenes
	if found == 0 or found == 9 then
		ridx = 9999
		DeviceType = 'command'
		Type = 'command'
		SwitchType = 'command'
	end
	Print_to_Log(2, ' --< Domo_Devinfo_From_Name:', found, ridx, rDeviceName, DeviceType, Type, SwitchType, status, LevelNames, LevelInt)
	return ridx, rDeviceName, DeviceType, Type, SwitchType, MaxDimLevel, status, LevelNames, LevelInt
end

-- Switch functions
function Domo_SwitchID(DeviceName, idx, DeviceType, state)
	if string.lower(state) == 'on' then
		state = 'On'
	elseif string.lower(state) == 'off' then
		state = 'Off'
	else
		return 'state must be on or off!'
	end
	local dUrl = 'type=command&param=switch' .. DeviceType .. '&idx=' .. idx .. '&switchcmd=' .. state
	local decoded_response, status = PerformDomoticzRequest(dUrl, 2)

	if _G.Check_Json_Result(decoded_response) then
		return 'Switched ' .. DeviceName .. ' ' .. state
	end
	return 'Failed to switch ' .. DeviceName .. ' to ' .. state
end

function Domo_sSwitchName(DeviceName, DeviceType, SwitchType, idx, state)
	local dUrl, response, status, decoded_response
	state = StrTrim(state)
	if idx == nil then
		response = 'Devicename ' .. DeviceName .. ' is nil.'
		return response, 990
	else
		local subgroup = 'light'
		if DeviceType == 'scenes' then
			subgroup = 'scene'
		end
		if string.lower(state) == 'on' then
			state = 'On'
			dUrl = 'type=command&param=switch' .. subgroup .. '&idx=' .. idx .. '&switchcmd=' .. state
		elseif string.lower(state) == 'off' then
			state = 'Off'
			dUrl = 'type=command&param=switch' .. subgroup .. '&idx=' .. idx .. '&switchcmd=' .. state
		elseif string.lower(string.sub(state, 1, 9)) == 'set level' then
			dUrl = 'type=command&param=switch' .. subgroup .. '&idx=' .. idx .. '&switchcmd=Set%20Level&level=' .. string.sub(state, 11)
		else
			response = 'state must be on, off or set level!'
			return response, 991
		end
		Print_to_Log(9, '   -- PerformDomoticzRequest:', dUrl)
		decoded_response, status = PerformDomoticzRequest(dUrl, 2)
		if _G.Check_Json_Result(decoded_response) then
			response = DTGMenu_translate_desc(_G.MenuLanguage, 'Switched') .. ' ' .. (DeviceName or '?') .. ' => ' .. (state or '?')
		else
			response = 'Failed to switch ' .. (DeviceName or '?') .. ' to ' .. (state or '?')
		end
	end
	Print_to_Log(0, '   -< performed action on Device ' .. DeviceName .. ' (' .. idx .. ')=>' .. (state or '?') .. '  response:' .. response)
	return response, status
end

-- other functions
function FileExists(name)
	local f = io.open(name, 'r')
	if f ~= nil then
		io.close(f)
		return true
	else
		return false
	end
end

function Domoticz_Version(loglevel)
	_G.DomoticzBuildDate = ''
	_G.DomoticzVersion = ''
	_G.DomoticzRevision = 0
	loglevel = loglevel or 1
	local dUrl = 'type=command&param=getversion'
	local decoded_response, status, jresponse = PerformDomoticzRequest(dUrl, 2, loglevel)
	if decoded_response then
		-- Set the Global variables for Domoticz version and revision
		_G.DomoticzRevision = (decoded_response['Revision'] or 0)
		_G.DomoticzVersion = (decoded_response['version'] or 0)
		-- build_time: "2023-06-18 14:39:26" convert to number 20230618 to allow for comparing
		_G.DomoticzBuildDate = (decoded_response['build_time'] or '')
		-- somehow revision isn't always returned by domoticz, so using the build number for that
		-- "version" : "2025.2 (build 16993)"
		if _G.DomoticzRevision == 0 and _G.DomoticzVersion ~= '' then
			Print_to_Log(0, '*>> Domoticz DomoticzVersionRevision missing, using Version build info instead')
			Print_to_Log(0, '*>> Domoticz DomoticzVersion  :' .. _G.DomoticzVersion)
			_G.DomoticzRevision = _G.DomoticzVersion:match('%(build.(%d+)%)') or '??'
			Print_to_Log(0, '*>> Domoticz DomoticzRevision :' .. _G.DomoticzRevision)
		end
	end
	if (_G.DomoticzBuildDate == '') then
		Print_to_Log(loglevel, 'Domoticz getversion failed')
		_G.DomoticzRevision = 0
		_G.DomoticzVersion = 0
		_G.DomoticzBuildDate = 0
	else
		_G.DomoticzBuildDate = _G.DomoticzBuildDate:gsub('(%d+)%-(%d+)%-(%d+).*', '%1%2%3') or ''
		_G.DomoticzBuildDate = tonumber(_G.DomoticzBuildDate or '0') or 0
		Print_to_Log(0, '*** Domoticz DomoticzRevision :' .. _G.DomoticzRevision)
		Print_to_Log(0, '*** Domoticz DomoticzVersion  :' .. _G.DomoticzVersion)
		Print_to_Log(0, '*** Domoticz DomoticzBuildDate:' .. _G.DomoticzBuildDate)
		if status ~= 200 then
			Print_to_Log(0, '*** Domoticz rc <> 200:' .. tostring(status))
		end
	end
	return (status == 200 and _G.DomoticzRevision ~= 0)
end

function Domoticz_Language()
	local dUrl
	if (_G.DomoticzBuildDate or 0) > 20230601 then
		dUrl = 'type=command&param=getlanguages'
	else
		dUrl = 'type=command&param=getlanguage'
	end
	local decoded_response, status = PerformDomoticzRequest(dUrl, 2)
	if not decoded_response or not decoded_response['language'] then
		Print_to_Log(-1, '! received invalid return from domoticz, resort to default language: en', _G.DomoticzBuildDate, dUrl)
		return 'en'
	end
	if decoded_response then
		Print_to_Log(-1, 'Domoticz language is set to:' .. (decoded_response['language'] or ' en (?)'))
		return decoded_response['language'] or 'en'
	end
	return 'en'
end

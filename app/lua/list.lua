local list_module = {}
--JSON = assert(loadfile "_G.JSON.lua")() -- one-time load of the routines

--- the handler for the list commands. a module can have more than one handler. in this case the same handler handles two commands
function list_module.handler(parsed_cli)
	local response = ''
	local jresponse, decoded_response, status

	local match_type, mode
	local i

	if parsed_cli[2] == 'dump' then
		mode = 'full'
	else
		mode = 'brief'
	end
	if parsed_cli[3] then
		match_type = string.lower(parsed_cli[3])
	else
		match_type = ''
	end

	local t
	if (_G.DomoticzBuildDate or 0) > 20230601 then
		t = _G.DomoticzUrl .. '/json.htm?type=command&param=getdevices'
	else
		t = _G.DomoticzUrl .. '/json.htm?type=devices'
	end
	jresponse, status = _G.HTTP.request(t)
	decoded_response = _G.JSON.decode(jresponse) or {}
	if type(decoded_response) == 'table' then
		for k, record in pairs(decoded_response) do
			Print_to_Log(2, k, type(record))
			if type(record) == 'table' then
				for k1, v1 in pairs(record) do
					if string.find(string.lower(v1.Type), match_type) then
						response = response .. List_Device_Attr(v1, mode) .. '\n'
					end
					--				Print_to_Log(2, k1, v1)
				end
			else
				Print_to_Log(2, record)
			end
		end
	end
	Print_to_Log(2, response)
	return status, response
end

local list_commands = {
	['list'] = { handler = list_module.handler, description = 'List devices, either all or specific type' },
	['dump'] = { handler = list_module.handler, description = 'List all information about devices, either all or specific type' }
}

function list_module.get_commands()
	return list_commands
end

return list_module

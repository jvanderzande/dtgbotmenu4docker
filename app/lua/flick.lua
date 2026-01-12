local flick_module = {};
--JSON = assert(loadfile "_G.JSON.lua")() -- one-time load of the routines

function flick_module.handler(parsed_cli)
	local response = ''
	local jresponse, decoded_response, status;

	local i, idx, state, t;
	for i, t in ipairs(parsed_cli) do
		Print_to_Log(0, i, t)
	end


	if parsed_cli[3] then
		idx = tonumber(parsed_cli[3]);
		Print_to_Log(0, 'In flick idx: ' .. idx)
		if parsed_cli[4] then
			state = parsed_cli[4];
		else
			state = 'On';
		end
		if string.lower(state) == 'on' then
			state = 'On';
		elseif string.lower(state) == 'off' then
			state = 'Off';
		else
			return status, 'state must be on or off!';
		end
	else
		return status, 'Device idx must be given!'
	end

	Print_to_Log(0, 'in flick_handler!');
	t = _G.DomoticzUrl .. '/json.htm?type=command&param=switchlight&idx=' .. idx .. '&switchcmd=' .. state .. '&level=0';
	Print_to_Log(0, 'JSON request <' .. t .. '>');
	jresponse, status = _G.Perform_Webquery(t, 99, 3)
	Print_to_Log(9, 'raw jason', jresponse)
	if status == 200 then
		decoded_response = _G.JSON.decode(jresponse) or {}
		if type(decoded_response) == 'table' then
			if decoded_response['status'] == 'OK' then
				response = 'switch flicked ' .. idx .. ' to ' .. state
			else
				response = 'Error: flick ' .. idx .. ' to ' .. state .. ' failed'
			end
		end
	else
		response = "Error Domoticz request rc = " .. tostring(status or '?')
	end

	return status, response;
end

local flick_commands = {
	['flick'] = { handler = flick_module.handler, description = 'flick a switch by idx' }
}

function flick_module.get_commands()
	return flick_commands;
end

return flick_module;

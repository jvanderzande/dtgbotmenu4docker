local nflick_module = {};
--JSON = assert(loadfile "_G.JSON.lua")() -- one-time load of the routines

function nflick_module.handler(parsed_cli)
	local response = ''
	local jresponse, decoded_response, status;

	local i, idx, state, t;
	for i, t in ipairs(parsed_cli) do
		Print_to_Log(2, i, t)
	end

	if parsed_cli[3] then
		if tonumber(parsed_cli[3]) ~= nil then
			idx = tonumber(parsed_cli[3]);
		else
			idx = Domo_Idx_From_Name(parsed_cli[3], 'devices')
		end
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
		return status, 'Device name must be given!'
	end

	Print_to_Log(1, 'in flick_handler!');
	t = _G.DomoticzUrl .. '/json.htm?type=command&param=switchlight&idx=' .. idx .. '&switchcmd=' .. state .. '&level=0';
	Print_to_Log(2, 'JSON request <' .. t .. '>');
	jresponse, status = _G.HTTP.request(t)
	Print_to_Log(9, 'raw jason', jresponse)
	return status, response;
end

local nflick_commands = {
	['nflick'] = { handler = nflick_module.handler, description = 'flick a switch by name' }
}

function nflick_module.get_commands()
	return nflick_commands;
end

return nflick_module;

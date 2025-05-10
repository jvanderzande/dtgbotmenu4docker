local monit_module = {};
--JSON = assert(loadfile "_G.JSON.lua")() -- one-time load of the routines

--- the handler for the list commands. a module can have more than one handler. in this case the same handler handles two commands
function monit_module.handler(parsed_cli)
	local response = ''
	local jresponse, decoded_response, status, action;
	local replymarkup = ''
	local i;
	if parsed_cli[3] == nil then
		action = ''
	else
		action = string.lower(parsed_cli[3])
	end
	Print_to_Log(0, 'action:' .. action)
	if action == 'on' then
		status = 1
		os.execute('sudo monit monitor all&&sleep 3')
		os.execute('sudo monit reload&&sleep 2')
		os.execute('sudo service monit restart&&sleep 5')
		--~ 		replymarkup = '{"keyboard":[["Monit Off"],["Monit Ok"]],"one_time_keyboard":true}'
		--~ 		replymarkup = ''
	elseif action == 'off' then
		os.execute('sudo monit unmonitor all&&sleep 5')
		response = 'Monit monitoring stopped'
		--~ 		replymarkup = '{"keyboard":[["Monit On"],["Monit Ok"]],"one_time_keyboard":true}'
		status = 1
	elseif action == 'ok' then
		response = 'ok'
		--~ 		replymarkup = default_replymarkup
		status = 1
	else
		local handle = io.popen('sudo monit summary')
		if handle then
			response = string.gsub(handle:read('*a'), '\n', '\n')
			handle:close()
		end
		Print_to_Log(0, 'msg:' .. response)
		Print_to_Log(0, 'KB:' .. replymarkup)
		status = 0
	end

	Print_to_Log(0, response)
	return status, response, replymarkup;
end

local monit_commands = {
	['monit'] = { handler = monit_module.handler, description = 'Manage Monit: monit (on/off)' }
}

function monit_module.get_commands()
	return monit_commands;
end

return monit_module;

local help_module = {};

--- the handler for the list commands. a module can have more than one handler. in this case the same handler handles two commands
function help_module.handler(parsed_cli)
	local response
	local status = nil;
	local command_dispatch

	local command = parsed_cli[3]
	if (command ~= '' and command ~= nil) then
		command_dispatch = _G.Available_Commands[string.lower(command)];
		if command_dispatch then
			response = command_dispatch.description;
		else
			response = command .. ' was not found - check spelling and capitalisation - Help for list of commands'
		end
		return status, response
	end
	local DotPos
	local HelpText = '(all command will also work without the /)\n'
	HelpText = HelpText .. '⚠️ Internal commands: ⚠️\n'
	HelpText = HelpText .. 'Start Menu: /menu'
	if DTGMenu_Lang[_G.MenuLanguage].command['menu'] and DTGMenu_Lang[_G.MenuLanguage].command['menu']:lower() ~= 'menu' then
		HelpText = HelpText .. ' or /' .. DTGMenu_Lang[_G.MenuLanguage].command['menu']
	end
	HelpText = HelpText .. '\n'
	HelpText = HelpText .. 'Keyboard toggle: /_ToggleKeyboard \n'
	HelpText = HelpText .. 'Reload Config: /_reloadconfig \n'
	HelpText = HelpText .. 'Reload modules: /_reloadmodules \n\n'
	HelpText = HelpText .. '⚠️ Available Lua commands ⚠️ \n'
	for i, help in pairs(_G.Available_Commands) do
		Print_to_Log(1, 'add Lua >', i, help.description)
		HelpText = HelpText .. '/' .. string.match(help.description, '%S+') .. ', '
	end
	HelpText = string.sub(HelpText, 1, -3) .. '\nHelp Command - gives usage information, i.e. Help On \n\n'
	--  Telegram_SendMessage(SendTo,HelpText,ok_cb,false)
	local Functions = io.popen('ls ' .. _G.BotBashScriptPath .. '*.sh')
	HelpText = HelpText .. '⚠️ Available Shell commands ⚠️ \n'
	if Functions then
		for line in Functions:lines() do
			Print_to_Log(1, 'add Bash >', line)
			local BSPos = line:match '^.*()/' or 0
			DotPos = string.find(line, '%.') or 0
			HelpText = HelpText .. '-' .. string.sub(line, BSPos, DotPos - 1) .. '\n'
		end
	end
	return status, HelpText;
end

local help_commands = {
	['help'] = { handler = help_module.handler, description = 'help - list all help information' },
	['start'] = { handler = help_module.handler, description = 'start - list all help information' }
}

function help_module.get_commands()
	return help_commands;
end

return help_module;

_G.dtg_main_functions_version = '1.0 202512162038'
_G.msgids_removed = {}
--[[
	Functions library for the Main process in DTGBOT
	Developer: jvdzande
	This is a spinoff of the oroginal DTGBOT developed by s.gibbon https://github.com/steps39
	GNU GENERAL PUBLIC LICENSE
]]
-- ==================================================================================================
-- dtgbot initialisation step to:
--  initialise room, device, scene and variable list from Domoticz
--  load the available modules
-- ==================================================================================================
function _G.CheckTelegramConnection(loglevel)
	loglevel = loglevel or 1
	_G.Persistent.TelegramBotOffset = _G.Persistent.TelegramBotOffset or 0
	local url = _G.Sprintf('%sgetMe', _G.Telegram_Url, 1, 0)
	local decoded_response, status, jresponse = PerformTelegramRequest(url)
	-- local decoded_response, status, jresponse = "Debugging", 999, '{text="debugging"}'
	if (status ~= 200) then
		Print_to_Log(loglevel, url .. '  status:' .. (status or '??') .. '   response:' .. (jresponse or ''))
	end
	return status == 200, decoded_response, status, jresponse
end

---------------------------------------------------------
-- GetUrl to set protocol and timeout
function _G.PerformTelegramRequest(url)
	local resp = {}
	Print_to_Log(9, url)
	local r, returncode, h, s =
		_G.HTTPS.request {
			url = url,
			sink = ltn12.sink.table(resp),
			protocol = 'tlsv1_2',
			timeout = (_G.Telegram_Longpoll_TimeOut or 10) + 20
		}
	returncode = returncode or 9999


	local response = ''
	-- read response table records and make them one string
	for i = 1, #resp do
		response = response .. resp[i]
	end
	Print_to_Log(9, 'Telegram response:', returncode, response)
	return response, returncode
end

function Load_MenuWhiteList()
	Print_to_Log(9, 'Update ChatIDWhiteList:')
	-- Check id white list Config
	_G.ChatIDWhiteList = ChatIDWhiteList or {}
	-- Build Associate array for Menu white list from config in ChatIDWhiteList
	_G.MenuWhiteList = {}
	-- get ChatID settings
	for iSendTo, Defs in pairs(ChatIDWhiteList) do
		if ((Defs.ShowMenu or '') ~= '') then
			MenuWhiteList[iSendTo] = MenuWhiteList[iSendTo] or {}
			for iMenu in (Defs.ShowMenu or ''):gmatch('%s*(%d+)%s*,?') do
				MenuWhiteList[iSendTo][tostring(iMenu)] = 1
			end
			Print_to_Log(9, '  Chatid:' .. iSendTo .. '  Name:' .. (Defs.Name or 'nil') .. '  Menus:' .. (Defs.ShowMenu or 'nil'))
		else
			if MenuWhiteList['0'] then
				Print_to_Log(9, '  Chatid:' .. iSendTo .. '  Name:' .. (Defs.Name or 'nil') .. '  Menus:' .. (MenuWhiteList['0'].ShowMenu or 'All'))
			else
				Print_to_Log(9, '  Chatid:' .. iSendTo .. '  Name:' .. (Defs.Name or 'nil') .. '  Menus:All')
			end
		end
	end
end

function _G.DtgBot_Initialise()
	-- loop till we have an config which ensures we can connect to Domoticz and Telegram.
	local telegram_connected = false
	local domoticz_connected = false
	local loopcount = 0
	Print_to_Log(-1, '>> Start Initial connectivity check for Domoticz and Telegram ==')

	_G.Persistent.NotFirstCheck = _G.Persistent.NotFirstCheck or 0

	-- remove indicator file and only create when both domotcz and Telegram successfully connected.
	while not telegram_connected or not domoticz_connected do
		loopcount = loopcount + 1
		-- ==========================================
		-- = Load Default and Userconfigs
		-- ==========================================
		LoadActiveConfig()
		--
		if not _G['DomoticzUrl'] or _G['DomoticzUrl'] == ''
			or not _G['TelegramBotToken'] or _G['TelegramBotToken'] == '' then
			_G.Persistent.NotFirstCheck = 0
			Print_to_Log(-1, '!> Domoticz URL and/or TelegramBotToken not set yet.')
		else
			domoticz_connected = Domoticz_Version(-1)
			if domoticz_connected then
				Print_to_Log(-1, '+> Initial test connection to Domoticz successfull.')
			else
				Print_to_Log(-1, '!> Initial test connection to Domoticz failed!')
			end
			telegram_connected = _G.CheckTelegramConnection(-1)
			if telegram_connected then
				Print_to_Log(-1, '+> Initial test connection to Telegram successfull.')
			else
				Print_to_Log(-1, '!> Initial test connection to Telegram failed!')
			end
		end

		if telegram_connected and domoticz_connected then
			Print_to_Log(-1, '<< All connections working, dtgbot will start.')
			_G.Persistent.NotFirstCheck = 1
			_G.Save_Persistent_Vars()
			break
		end
		-- Keep retrying when we where connected before
		if _G.Persistent.NotFirstCheck == 1 then
			if not domoticz_connected then
				Print_to_Log(-1, '!> problem connecting to DomoticzURL=' .. _G['DomoticzUrl'] .. '. Is the server up?')
			end
			if not telegram_connected then
				Print_to_Log(-1, '!> problem connecting to TelegramBotUrl=' .. _G['Telegram_Url'] .. '. did the BOTTOKEN change or are there connection issues?')
			end
			Print_to_Log(-1, 'Will try again in 15 seconds.')
			_G.SOCKET.sleep(15)
		else
			-- Don't retry when container is started for the firsttime assuming the compose definition is wrong
			Print_to_Log(-1, '> ------------------------------------------------------------------')
			if not domoticz_connected then
				Print_to_Log(-1, '!> problem connecting to DomoticzURL=' .. _G['DomoticzUrl'] .. '. Is it correct in the compose definitions ?')
			end
			if not telegram_connected then
				Print_to_Log(-1, '!> problem connecting to Telegram with BotToken=' .. _G['Telegram_Url'] .. '. Is it the correct BOTTOKEN?')
			end
			Print_to_Log(-1, '!> Fix your docker-compose.yml environment variable(s) and try to restart.')
			Print_to_Log(-1, '!> environment:')
			Print_to_Log(-1, '!>   - TZ=Europe/Amsterdam                                    # Timezone setting')
			Print_to_Log(-1, '!>   - DomoticzURL=' .. _G['DomoticzUrl'] .. '      # your domoticz url')
			Print_to_Log(-1, '!>   - TelegramBotToken=' .. _G['TelegramBotToken'] .. '      # your bottoken')
			Print_to_Log(-1, '> ------------------------------------------------------------------')
			os.exit(99)
		end
	end

	-- Make backup of config at startup
	os.execute("cp " .. _G.BotDataPath .. 'dtgbot__configuser.json ' ..  _G.BotDataPath .. 'dtgbot__configuser_prev.json')

	--Set global variables _G.DomoticzRevision _G.DomoticzVersion
	Print_to_Log(-1, 'Domoticz version :' .. _G.DomoticzVersion .. '  Revision:' .. _G.DomoticzRevision .. '  BuildDate:' .. _G.DomoticzBuildDate)
	Print_to_Log(-1, 'Domoticz url used:' .. _G.DomoticzUrl:gsub('//.*@', '//'))
	Variablelist = Domo_Variable_List_Names_IDXs()
	Print_to_Log(2, 'Get Devices   --------------------------------------------------')
	_G.DevicelistByName, _G.DevicelistByIDX = Domo_Get_Device_Information('devices')
	Print_to_Log(2, 'Get Scenes    --------------------------------------------------')
	_G.ScenelistByName, _G.ScenelistByIDX = Domo_Get_Device_Information('scenes')
	Print_to_Log(2, 'Get Rooms     --------------------------------------------------')
	Roomlist = Domo_Get_Device_Information('plans')

	-- Get Language from Domoticz
	_G.DomoLanguage = Domoticz_Language()

	-- Load all modules
	Load_LUA_Modules()

	-- Check id white list Config
	Load_MenuWhiteList()
	Print_to_Log(2, 'Result MenuWhiteList for ChatIDs:' .. JSON.encode(MenuWhiteList))
	-- Retrieve id Menu white list
end

-- ==================================================================================================
-- Main Functions to Process Received Message
-- ==================================================================================================
-- Step 1: Check Message content, validity and preprocess data
function PreProcess_Received_Message(tt)
	-- return the encountered error in stead of crashing the script
	--  if unexpected_condition then
	--    error()
	--  end
	-- extract the message part for regular messages
	local msg = tt['message']
	local strmsg = _G.JSON.encode(msg)
	Print_to_Log(3, ' Start Preprocess for:', strmsg)

	-- extract the message part for callback messages from inline keyboards
	if tt['callback_query'] ~= nil then
		-- checking for callback_query message from inline keyboard.
		Print_to_Log(3, '<== Received callback_query, reformating result to be able to process.')
		msg = tt['callback_query']
		msg.chat = {}
		msg.chat.id = msg.message.chat.id
		msg.message_id = msg.message.message_id
		msg.text = msg.data
	elseif tt['channel_post'] ~= nil then
		-- extract change some fields for channel messages to use the same field names
		Print_to_Log(3, '<== Received channel message, reformating result to be able to process.')
		msg = tt['channel_post']
		msg.from = {}
		msg.from.id = msg.chat.id
	elseif not tt['message'] and tt['edited_message'] then
		-- Received update edit for previous messages
		Print_to_Log(3, '-> Received edited_message so use that content.')
		msg = tt['edited_message']
	end

	if (msg == nil) then
		return 'Received message table empty'
	end
	local ReceivedText = ''
	local msg_type = 'command'
	local msg_id

	--Check to see if id is whitelisted..... When not allowd:  createrecord in log and exit
	local ChatID = tostring(msg.chat.id)
	local SenderID = tostring(msg.from.id)
	local msg_id = tostring(msg.message_id)

	-- use Group id as SenderID when message is send from a group id.
	if ChatID ~= '' and SenderID ~= ChatID then
		Print_to_Log(2, 'Use ChatID ' .. ChatID .. ' in stead of SenderID: ' .. SenderID)
		SenderID = ChatID
	end

	if not ID_WhiteList_Check(SenderID) then
		Print_to_Log(2, 'id ' .. SenderID .. ' not in white list, command ignored')
		Telegram_SendMessage(ChatID, '⚡️Id ' .. SenderID .. ' has no access⚡️', msg_id)
		return '', 'ID not authorized'
	end

	local chat_type = ''
	-- determine the chat_type
	if msg.chat.type == 'channel' then
		chat_type = 'channel'
	elseif msg.message ~= nil and msg.message.chat.id ~= nil then
		chat_type = 'callback'
	end
	-- get the appropriate info from the different message types
	local responsev, statusv, decoded_responsev, result, filelink
	if msg.text then -- check if message is text
		-- check for received voicefiles
		ReceivedText = msg.text
		if (msg.chat.type and msg.chat.type:match('group') or (msg.chat.type and msg.chat.type:match('channel'))) then
			Print_to_Log(0, _G.Sprintf('!!>> msg_id:%s SenderID:%s  ChatID %s text: %s', msg_id, SenderID, ChatID, ReceivedText))
			ReceivedText = ReceivedText:match('([^@]*)@-') -- strip possible @group/channel name
			Print_to_Log(0, _G.Sprintf('!!<< msg_id:%s SenderID:%s  ChatID %s text: %s', msg_id, SenderID, ChatID, ReceivedText))
		end
	elseif msg.voice then -- check if message is voicefile
		-- check for received voicefiles
		Print_to_Log(0, 'msg.voice.file_id:', msg.voice.file_id)
		responsev, statusv = _G.PerformTelegramRequest(_G.Telegram_Url .. 'getFile?file_id=' .. msg.voice.file_id)
		if statusv == 200 then
			Print_to_Log(2, 'responsev:', responsev)
			decoded_responsev = _G.JSON.decode(responsev) or {}
			result = decoded_responsev['result']
			filelink = result['file_path']
			Print_to_Log(2, 'filelink:', filelink)
			ReceivedText = 'voice ' .. filelink
			msg_type = 'voice'
		end
	elseif msg.video_note then -- check if message is videofile
		Print_to_Log(0, 'msg.video_note.file_id:', msg.video_note.file_id)
		responsev, statusv = _G.PerformTelegramRequest(_G.Telegram_Url .. 'getFile?file_id=' .. msg.video_note.file_id)
		if statusv == 200 then
			Print_to_Log(2, 'responsev:', responsev)
			decoded_responsev = _G.JSON.decode(responsev) or {}
			result = decoded_responsev['result']
			filelink = result['file_path']
			Print_to_Log(2, 'filelink:', filelink)
			ReceivedText = 'video ' .. filelink
			msg_type = 'video'
		end
	elseif msg.chat.type == 'private' and not msg.text then
		msg.edited_message = tt['edited_message'] ~= nil
		chat_type = 'private'
		if msg.edited_message then
			msg.chat.type = 'private_edit'
			chat_type = 'private_edit'
		end
		ReceivedText = 'other_private_message ' .. _G.JSON.encode(msg)
		--return 'ignore private-internal msg as there is no text field defined.'
		Print_to_Log(0, 'private message without text field: Try to pass to other_private_message.lua or sh script.')
		msg_type = 'private'
	end
	--################################################################################################################
	-- Handle the received command and capture any errors to avoid hardcrash
	--print(ReceivedText)
	Print_to_Log(3, _G.Sprintf(' Preprocess->HandleCommand: MsgID:%s SenderID:%s  ChatID %s ChatType: %s Text: %s', msg_id, SenderID, ChatID, chat_type, ReceivedText))
	_G.Persistent.commandline = ReceivedText
	local result_status3, result3, result_err3 = xpcall(HandleCommand, ErrorHandler, ReceivedText, SenderID, ChatID, msg_id, chat_type)
	ReceivedText = _G.Persistent.commandline
	if not result_status3 then
		-- Hard error process - send warning to telegram to inform sender of the failure amd return the info for logging
		Telegram_SendMessage(ChatID, _G.Sprintf('⚡️ Command caused error. check dtgbot log ⚡️\nError:%s', result3[1]), msg_id)
		Print_to_Log(0, _G.Sprintf('<- !!! function PreProcess_Received_Message failed: \nError:%s\n%s', result3[1], result3[2]))
		return '', 'PreProcess_Received_Message failed'
	end
	-- No hard error process
	if result_err3 == nil then
		Print_to_Log(0, '<- Succesfully handled incoming request')
	else
		if msg_type == 'voice' then
			Print_to_Log(0, '!! Voice file received but voice.sh or lua not found to process it. skipping the message.')
			Telegram_SendMessage(ChatID, '⚡️ voice.sh or lua missing?? ⚡️', msg_id)
		elseif msg_type == 'video' then
			Print_to_Log(0, '!! Video file received but video_note.sh or lua not found to process it. Skipping the message.')
			Telegram_SendMessage(ChatID, '⚡️ video_note.sh or lua missing?? ⚡️', msg_id)
		elseif msg_type == 'private' then
			Print_to_Log(0, '!! Other messages received but other_private_message.sh or lua not found to process it. Skipping the message.')
			Telegram_SendMessage(ChatID, '⚡️ other_private_message.sh or lua missing?? ⚡️', msg_id)
		else
			--print(ReceivedText)
			Telegram_SendMessage(ChatID, '⚡️ ' .. (result or '?') .. ' ' .. (result_err3 or '?') .. ' ⚡️', msg_id)
		end
	end
	return result3, result_err3
end

---------------------------------------------------------
-- Step 2: Handle the received command/data
-- Process the received command
function HandleCommand(cmd, SendTo, Group, MessageId, chat_type)

	chat_type = chat_type or ''
	local found = nil
	local parsed_command = {}
	local text, command_dispatch, status, replymarkup
	local handled_by = 'other'
	local newmessage

	-- set to last used Keyboard menu type
	_G.Persistent[SendTo] = _G.Persistent[SendTo] or {}
	if _G.Persistent[SendTo].UseInlineMenu then
		UseInlineMenu = _G.Persistent[SendTo].UseInlineMenu == 'true'
	else
		_G.Persistent[SendTo].UseInlineMenu = tostring(UseInlineMenu)
	end

	Print_to_Log(0, _G.Sprintf('-> HandleCommand=> cmd:%s  SendTo:%s  Group:%s  chat_type:%s ', cmd, SendTo, Group, chat_type))

	-- use Group when message is send from a group id
	if Group ~= '' and SendTo ~= Group then
		Print_to_Log(2, 'Use GroupId ' .. Group .. ' in stead of SendtoId: ' .. SendTo)
		SendTo = Group
	end

	if UseInlineMenu then
		Print_to_Log(2, 'Set Handler to DTGil.handler')
		_G.Available_Commands['menu'] = { handler = DTGil.handler, description = 'Will start menu functionality.' }
		_G.Available_Commands['dtgmenu'] = { handler = DTGil.handler, description = 'Will start menu functionality.' }
		replymarkup = '{"remove_keyboard":true}'
	else
		Print_to_Log(2, 'Set Handler to DTGbo.handler')
		_G.Available_Commands['menu'] = { handler = DTGbo.handler, description = 'Will start menu functionality.' }
		_G.Available_Commands['dtgmenu'] = { handler = DTGbo.handler, description = 'Will start menu functionality.' }
	end

	--- parse the command
	--Command_Prefix is set in the dtgbot.cfg, default ""
	--    start with entry "stuff" when no prefix defined to ensure the same table position for the rest
	Command_Prefix = Command_Prefix or ''

	-- strip the beginning / from any command
	-- the / infront of a comment make the text a link you can click by Telegram, so usefull to add in send text.
	cmd = cmd:gsub('^/', '')
	-- get commandline parameters
	for w in cmd:gmatch('([^ ]+)') do
		if #parsed_command == 0 then
			if Command_Prefix ~= '' then
				-- check for a valid prefix
				if w ~= Command_Prefix then
					return 1 -- not a command so successful but nothing done
				end
			else
				table.insert(parsed_command, 'stuff')
			end
		end
		table.insert(parsed_command, w)
		Print_to_Log(2, _G.Sprintf(' - parsed_command[%s]  %s', #parsed_command, w))
	end
	-- return when no command
	if (parsed_command[2] == nil) then
		return '', 'command missing'
	end
	---------------------------------------------------------------------------
	-- Start with DTGMENU when it isn't an "inlineaction" command.
	--   inlineaction commands need to be processed directly by inlineaction.lua
	---------------------------------------------------------------------------
	local savereplymarkup = ''
	if (parsed_command[2] ~= 'inlineaction')
		and (_G.Persistent.UseDTGMenu == 1
			or string.lower(parsed_command[2]) == DTGMenu_Lang[_G.MenuLanguage].command['menu']
			or string.lower(parsed_command[2]) == 'dtgmenu'
			or string.lower(parsed_command[2]) == 'menu')
		and (chat_type ~= 'channel') then
		-- set menu active
		_G.Persistent.UseDTGMenu = 1
		Print_to_Log(0, _G.Sprintf('-> forward to dtgmenu :%s -> %s', cmd, parsed_command[2]))
		command_dispatch = _G.Available_Commands['dtgmenu'] or { handler = {} }
		found, text, replymarkup, newmessage = command_dispatch.handler(parsed_command, SendTo, cmd)
		if found then
			handled_by = 'menu'
		elseif UseInlineMenu and parsed_command[2] == 'menu' then
			-- remove the 2 layer inline menu commands
			for i = 2, #parsed_command - 2, 1 do
				Print_to_Log(2, parsed_command[i] or 'nil', parsed_command[i + 2] or 'nil')
				if not parsed_command[i + 2] or parsed_command[i + 2] == '' then
					parsed_command[i] = ''
					break
				end
				parsed_command[i] = parsed_command[i + 2]
				parsed_command[i + 2] = ''
			end
		end
		-- Update Command when previous was the real command and this msg is the answer to the prompt
		if _G.Persistent.prompt==1 and _G.Persistent.promptcommandline ~= '' then
			parsed_command[3] = parsed_command[2]
			parsed_command[2] = _G.Persistent.promptcommandline
			_G.Persistent.prompt = 0
			_G.Persistent.promptcommandline = ''
			Print_to_Log(2, 'Changed command to:', parsed_command[2], parsed_command[3])
		end
		savereplymarkup = replymarkup
	end
	---------------------------------------------------------------------------
	-- End integration for dtgmenu.lua option
	---------------------------------------------------------------------------
	-------- process commandline ------------
	-- first check for some internal dtgbot commands
	-- command reload modules will reload all LUA modules without having to restart the Service
	--Print_to_Log(0, '-> ' .. string.lower(cmd) .. " =?= " .. string.lower(DTGMenu_Lang[_G.MenuLanguage].command['exit_menu'] or '???'))

	if string.lower(parsed_command[2]) == '_reloadmodules' then
		Print_to_Log(0, '-> Start _reloadmodules process.')
		if MenuMessagesCleanOnExit then
			-- remove all previous menu messages
			Telegram_Save_Clean_Messages(SendTo, 0, 0, 'menu', true)
			-- remove the exit_menu message
			Telegram_Remove_Message(SendTo, MessageId)
			-- set MessageId to '' because we can't reply to it anymore
			MessageId = ''
		end
		text = DTGMenu_translate_desc(_G.MenuLanguage, 'exit', 'exit Menu type /menu to show it again.')
		Telegram_SendMessage(SendTo, 'Reloading dtgbot:' .. text, MessageId, replymarkup, '', handled_by)
		os.exit(1)

		--[[ this doesn't update the LUA changes in the loaded chuncks so restart for now.
		text = 'modules reloaded'
		found = true
		_G.Available_Commands = {}
		-- ensure the require packages for dtgmenu are removed
		package.loaded['dtgmenubottom'] = nil
		package.loaded['dtgmenuinline'] = nil
		-- Now reload the modules
		Load_LUA_Modules()
		]]
	elseif string.lower(parsed_command[2]) == '_reloadconfig' then
		Print_to_Log(0, '-> Start _reloadconfig process.')
		if MenuMessagesCleanOnExit then
			-- remove all previous menu messages
			Telegram_Save_Clean_Messages(SendTo, 0, 0, 'menu', true)
			-- remove the exit_menu message
			Telegram_Remove_Message(SendTo, MessageId)
			-- set MessageId to '' because we can't reply to it anymore
			MessageId = ''
		end
		text = DTGMenu_translate_desc(_G.MenuLanguage, 'exit', 'exit Menu type /menu to show it again.')
		Telegram_SendMessage(SendTo, 'Reloading dtgbot:' .. text, MessageId, replymarkup, '', handled_by)
		os.exit(1)
	elseif string.lower(parsed_command[2]) == 'exit_menu'
		or string.lower(cmd) == string.lower(DTGMenu_Lang[_G.MenuLanguage].command['exit_menu'] or 'exit_menu') then
		Print_to_Log(0, '-> Start exit_menu process.')
		if MenuMessagesCleanOnExit then
			-- remove all previous menu messages
			Telegram_Save_Clean_Messages(SendTo, 0, 0, 'menu', true)
			-- remove the exit_menu message
			Telegram_Remove_Message(SendTo, MessageId)
			-- set MessageId to '' because we can't reply to it anymore
			MessageId = ''
			text = DTGMenu_translate_desc(_G.MenuLanguage, 'exit', 'exit Menu type /menu to show it again.')
		end
		found = true
	elseif string.lower(parsed_command[2]) == '_cleanall' then
		Print_to_Log(0, '-> Start _cleanall process.')
		Telegram_Save_Clean_Messages(SendTo, MessageId, 0, '', true)
		found = true
		text = ''
	elseif string.lower(parsed_command[2]) == '_togglekeyboard' then
		Print_to_Log(0, '-> Start _ToggleKeyboard process.')
		----------------------------------
		-- start disabled current keyboard
		local tcommand = { '', 'Exit_Menu', 'Exit_Menu', '' }
		local icmdline = 'Exit_Menu'
		local iMessageId = MessageId
		local mtype = ''
		if UseInlineMenu then
			tcommand = { 'menu exit', 'menu', 'exit', '' }
			icmdline = ''
			Print_to_Log(2, _G.Sprintf('_G.Persistent.LastInlinemessage_id=%s', _G.Persistent.LastInlinemessage_id or 'nil'))
			iMessageId = _G.Persistent.LastInlinemessage_id or MessageId
			mtype = 'callback'
		end
		command_dispatch = _G.Available_Commands['dtgmenu'] or { handler = {} }
		status, text, replymarkup = command_dispatch.handler(tcommand, SendTo, icmdline)
		chat_type = ''
		Telegram_SendMessage(SendTo, 'removed keyboard', iMessageId, replymarkup, mtype, handled_by)
		----------------------------------
		-- toggle setting
		UseInlineMenu = not UseInlineMenu
		_G.Persistent[SendTo].UseInlineMenu = tostring(UseInlineMenu)
		----------------------------------
		-- Reset handler
		--Load_LUA_Module("dtgmenu")
		if UseInlineMenu then
			Print_to_Log(2, 'Set Handler to DTGil.handler')
			_G.Available_Commands['menu'] = { handler = DTGil.handler, description = 'Will start menu functionality.' }
			_G.Available_Commands['dtgmenu'] = { handler = DTGil.handler, description = 'Will start menu functionality.' }
			replymarkup = '{"remove_keyboard":true}'
		else
			Print_to_Log(2, 'Set Handler to DTGbo.handler')
			_G.Available_Commands['menu'] = { handler = DTGbo.handler, description = 'Will start menu functionality.' }
			_G.Available_Commands['dtgmenu'] = { handler = DTGbo.handler, description = 'Will start menu functionality.' }
		end
		----------------------------------
		-- show Keyboard
		local tcommand = { 'menu', 'menu', 'menu', '' }
		command_dispatch = _G.Available_Commands['dtgmenu'] or { handler = {} }
		found, text, replymarkup = command_dispatch.handler(tcommand, SendTo, 'menu')

		Print_to_Log(0, '-> end  _ToggleKeyboard process.')
		found = true
	elseif not found then
		-- check for loaded LUA modules
		Print_to_Log(9, _G.Sprintf('Not found as Menu or Fixed command so try Lua or Bash options for %s', string.lower(parsed_command[2])))
		command_dispatch = _G.Available_Commands[string.lower(parsed_command[2])]
		if command_dispatch then
			Print_to_Log(9, _G.Sprintf('->run lua command %s', string.lower(parsed_command[2])))
			found, text, replymarkup = command_dispatch.handler(parsed_command, SendTo, MessageId, savereplymarkup)
			text = text or ''
			handled_by = string.lower(parsed_command[2])
			found = true
			if found and string.lower(parsed_command[2]) == 'menu' then
				handled_by = 'menu'
			end
		else
			-- check for BASH modules
			local function processbash(bashpath)
				text = ''
				local f = io.popen('cd ' .. bashpath .. ' && ls *.sh') or {}
				local cmda = string.lower(tostring(parsed_command[2]))
				local len_parsed_command = #parsed_command
				local params = string.sub(cmd, string.len(cmda) + 1)
				for line in f:lines() do
					Print_to_Log(2, 'checking line ' .. line)
					if (line:match(cmda)) then
						Print_to_Log(0, _G.Sprintf('->run bash command %s %s %s', line, SendTo, params))
						-- run bash script and collect returned text.
						Print_to_Log(0, 'cmd:bash ' .. bashpath .. line .. ' ' .. SendTo .. ' ' .. params)
						handled_by = string.lower(parsed_command[2])
						-- add following variables to the env
						local SetEnv = '\n' ..
								'export DomoticzUrl=' .. _G.DomoticzUrl .. '\n' ..
								'export Telegram_Url=' .. _G.Telegram_Url .. '\n' ..
								'export DomoticzRevision=' .. _G.DomoticzRevision .. '\n' ..
								'export DomoticzVersion=' .. _G.DomoticzVersion:match("[%d%.]*") .. '\n' ..
								'export DomoticzBuildDate=' .. _G.DomoticzBuildDate .. '\n'
						Print_to_Log(2, _G.Sprintf('->Set env %s', SetEnv))
						local handle = io.popen(SetEnv .. ' bash ' .. bashpath .. line .. ' ' .. SendTo .. ' ' .. params)
						if handle then
							text = handle:read('*a')
							handle:close()
						end
						-- ensure the text isn't nil
						text = text or ''
						Print_to_Log(2, 'returned text=' .. text)
						-- only get the last 400 characters to avoid generating many messages when something is wrong
						text = text:sub(-400)
						-- remove ending CR LF
						text = text:gsub('[\n\r]$', '')
						Print_to_Log(2, 'cleaned returned text=' .. text)
						-- default to "done"when no text is returned as it use to be.
						if text == '' then
							text = 'done.'
						end
						found = true
					end
				end
			end

			Print_to_Log(_G.Sprintf('->Check user BASH for ', string.lower(parsed_command[2])))
			processbash(_G.BotBashScriptPath)
		end
		-- try dtgmenu as final resort in case we're out of sync
		if (not found) and _G.Persistent.UseDTGMenu == 0 and chat_type ~= 'channel' then
			Print_to_Log(0, _G.Sprintf('-> forward to dtgmenu as last resort :%s', cmd))
			command_dispatch = _G.Available_Commands['dtgmenu'] or { handler = {} }
			found, text, replymarkup = command_dispatch.handler(parsed_command, SendTo, cmd)
		end
	end
	--~ replymarkup
	if parsed_command[2] ~= 'inlineaction' and (replymarkup == nil or replymarkup == '') and savereplymarkup then
		-- restore the menu supplied replymarkup in case the shelled LUA didn't provide one
		replymarkup = savereplymarkup or ''
		Print_to_Log(2, 'restored previous replymarkup:' .. replymarkup)
	elseif (replymarkup == 'remove') then
		replymarkup = ''
	end
	---------------------------------------------------------------------------------
	-- return when not found
	if not found then
		return '', 'not found'
	end

	text = text or ''
	-- send the response to the sender
	if (newmessage) then
		MessageId = nil
		chat_type = ''
	end
	if text ~= '' then
		-- send multiple message when larger than 4000 characters
		while string.len(text) > 0 do
			Telegram_SendMessage(SendTo, string.sub(text, 1, 4000), MessageId, replymarkup, chat_type, handled_by)
			text = string.sub(text, 4000, -1)
		end
	elseif replymarkup ~= savereplymarkup or chat_type == 'callback' then
		-- Set msg text for normal messages to send the replymarkup
		if chat_type ~= 'callback' or text == '' then
			text = 'done'
		end
		Telegram_SendMessage(SendTo, text, MessageId, replymarkup, chat_type, handled_by)
	end
	return 'ok'
end

-- ==== Functions section ============================================================================
-- simulate sprintf for easy string formatting
_G.Sprintf = function(s, ...)
	return s:format(...)
end

-- Format string variable
local function ExportString(s)
	return string.format('%q', s)
end

---------------------------------------------------------
-- print to log with time and date
function Print_to_Log(loglevel, logmessage, ...)
	-- handle calls without loglevel and assume 0: Print_to_Log(message)
	logmessage = logmessage or ''
	loglevel = tonumber(loglevel) or 0
	local logconsole = (loglevel < 0)
	local msgprev = ''
	logmessage = logmessage or ''

	if (loglevel <= (_G.BotLogLevel or 0)) then
		local logcount = #{ ... }
		if logcount > 0 then
			for i, v in pairs({ ... }) do
				if type(v) == 'table' then
					for i2, v2 in pairs({ ... }) do
						if type(v2) ~= 'table' then
							logmessage = logmessage .. ' [' .. i2 .. ']:' .. (tostring(v2) or 'nil')
						end
					end
				else
					logmessage = logmessage .. '; ' .. i .. ':' .. (tostring(v) or 'nil')
				end
			end
			logmessage = logmessage:gsub('[\r\n]', '')
		end

		local lvl2 = ''
		local lvl3 = ''
		if loglevel > 8 then
			-- Add stack info
			lvl2 = '-> * '
			if debug.getinfo(2) and debug.getinfo(2).name then
				--lvl2 = "->"..string.format("%-15s",debug.getinfo(2).name) .. ""
				lvl2 = '->' .. debug.getinfo(2).name .. ' '
			end
			lvl3 = '-> * '
			if debug.getinfo(3) and debug.getinfo(3).name then
				--lvl3 = "->"..string.format("%-15s",debug.getinfo(3).name) .. ""
				lvl3 = '->' .. debug.getinfo(3).name .. ' '
			end
		end
		-- print message to logfile or console
		if _G.BotLogFile ~= '' then
			local file = io.open(_G.BotLogFile, 'a')
			if file ~= nil then
				file:write(_G.Sprintf('%s %s: %s %s\n', os.date('%Y-%m-%d %H:%M:%S'), lvl3 .. lvl2, msgprev, logmessage))
				file:close()
			end
		end
		if logconsole or _G.BotLogFile == '' then
			print(_G.Sprintf('%s %s: %s %s', os.date('%Y-%m-%d %H:%M:%S'), lvl3 .. lvl2, msgprev, logmessage))
		end
	end
end

---------------------------------------------------------
-- FileExists check
function FileExists(name)
	local f = io.open(name, 'r')
	if f ~= nil then
		io.close(f)
		return true
	else
		return false
	end
end

---------------------------------------------------------
-- Config Save
function SaveTableToJSONFile(table, filename)
	if (not filename) then
		Print_to_Log(2, 'SaveTableToJSONFile: No filename provided')
		return nil
	end
	local file = io.open(filename, 'w')
	if file then
		file:write(tostring(JSON.encode(table, { indent = true })))
		file:close()
	else
		Print_to_Log(2, 'SaveTableToJSONFile:Failed to open file for writing:' .. filename)
	end
end

---------------------------------------------------------
-- Config Load
function LoadTableFromJSONFile(filename)
	if (not filename) then
		Print_to_Log(2, 'LoadTableFromJSONFile: No filename provided')
		return nil
	end
	local file = io.open(filename, 'r')
	if file then
		local content = file:read('*a')
		file:close()
		return JSON.decode(content)
	else
		Print_to_Log(2, 'LoadTableFromJSONFile: Failed to open file for reading:' .. filename)
		return nil
	end
end

---------------------------------------------------------
-- ### Not Used at this moment
-- print table to log for debugging
function TablePrintToLog(t, tab, lookup)
	lookup = lookup or { [t] = 1 }
	tab = tab or ''
	for i, v in pairs(t) do
		Print_to_Log(2, tab .. tostring(i), v)
		if type(i) == 'table' and not lookup[i] then
			lookup[i] = 1
			Print_to_Log(2, tab .. 'Table: i')
			TablePrintToLog(i, tab .. '\t', lookup)
		end
		if type(v) == 'table' and not lookup[v] then
			lookup[v] = 1
			Print_to_Log(2, tab .. 'Table: v')
			TablePrintToLog(v, tab .. '\t', lookup)
		end
	end
end

---------------------------------------------------------
-- ### Not Used at this moment
-- Var dump to logfile for debugging
function VarDumpToLog(value, depth, key)
	local linePrefix = ''
	local spaces = ''

	if key ~= nil then
		linePrefix = '[' .. key .. '] = '
	end

	if depth == nil then
		depth = 0
	else
		depth = depth + 1
		for i = 1, depth do
			spaces = spaces .. '  '
		end
	end

	if type(value) == 'table' then
		local mTable = getmetatable(value)
		if mTable == nil then
			Print_to_Log(2, spaces .. linePrefix .. '(table) ')
		else
			Print_to_Log(2, spaces .. '(metatable) ')
			value = mTable
		end
		for tableKey, tableValue in pairs(value) do
			VarDumpToLog(tableValue, depth, tableKey)
		end
	elseif type(value) == 'function' or type(value) == 'thread' or type(value) == 'userdata' or value == nil then
		Print_to_Log(2, spaces .. tostring(value))
	else
		Print_to_Log(2, spaces .. linePrefix .. '(' .. type(value) .. ') ' .. tostring(value))
	end
end

---------------------------------------------------------
-- Original XMPP function to list device properties
function List_Device_Attr(dev, mode)
	local result = ''
	local exclude_flag
	-- Don't dump these fields as they are boring. Name data and idx appear anyway to exclude them
	local exclude_fields = { 'Name', 'Data', 'idx', 'SignalLevel', 'CustomImage', 'Favorite', 'HardwareID', 'HardwareName', 'HaveDimmer', 'HaveGroupCmd', 'HaveTimeout', 'Image', 'IsSubDevice', 'Notifications', 'PlanID', 'Protected', 'ShowNotifications',
		'StrParam1', 'StrParam2', 'SubType', 'SwitchType', 'SwitchTypeVal', 'Timers', 'TypeImg', 'Unit', 'Used', 'UsedByCamera', 'XOffset', 'YOffset' }
	result = '<' .. dev.Name .. '>, Data: ' .. dev.Data .. ', Idx: ' .. dev.idx
	if mode == 'full' then
		for k, v in pairs(dev) do
			exclude_flag = 0
			for i, k1 in ipairs(exclude_fields) do
				if k1 == k then
					exclude_flag = 1
					break
				end
			end
			if exclude_flag == 0 then
				result = result .. k .. '=' .. tostring(v) .. ', '
			else
				exclude_flag = 0
			end
		end
	end
	return result
end

---------------------------------------------------------
-- Load all Modules and report any errors without failing
function Load_LUA_Modules()
	Print_to_Log(0, 'Loading internal dtgmenu modules:')
	local t = assert(loadfile(_G.ScriptDirectory .. 'dtgmenu.lua'))()
	local cl = t:get_commands()
	local result_status = ''
	for c, r in pairs(cl) do
		result_status = result_status .. c .. ','
		_G.Available_Commands[c] = r
	end
	if not result_status then
		Print_to_Log(0, _G.Sprintf('!! Module dtgmenu.lua failed to load?'))
	else
		Print_to_Log(0, ' -module->dtgmenu.lua  commands:' .. (result_status or '???'))
	end
	-- Load dtgbot_inlineaction module
	local result_status4, result4 = xpcall(Load_LUA_Module, ErrorHandler, 'dtgbot_inlineaction', _G.ScriptDirectory)
	result4 = result4 or { '?', '?' }
	if not result_status4 then
		Print_to_Log(0, _G.Sprintf("!! Module dtgbot_inlineaction failed to load, so won't be available until a 'reloadmodules' command:\nError:%s\n%s", result4[1], result4[2]))
	else
		Print_to_Log(0, ' -module->dtgbot_inlineaction  commands:' .. (result4 or '???'))
	end
	-- check if dtgmenu.lua loaded succesfully
	if _G.Available_Commands['dtgmenu'] ~= nil then
		Print_to_Log(0, 'loaded dtgmenu_version      :' .. (_G.dtgmenu_version or '?'))
		if _G.dtgmenuinline_version then
			Print_to_Log(0, 'loaded dtgmenuinline version:' .. (_G.dtgmenuinline_version or '?'))
		end
		if _G.dtgmenubottom_version then
			Print_to_Log(0, 'loaded dtgmenubottom version:' .. (_G.dtgmenubottom_version or '?'))
		end

		-- Initialise and populate dtgmenu tables in case the menu is switched on
		_G.Persistent.UseDTGMenu = tonumber(_G.Persistent.UseDTGMenu) or 0
		Print_to_Log(0, _G.Sprintf('Menu restored state %s (0=disabled;1=enabled)', _G.Persistent.UseDTGMenu))
		MsgInfo = MsgInfo or {}
		-- initialise menu tables
		PopulateMenuTab(1, '')
	end

	Print_to_Log(0, 'Loading command modules from /modules/lua:')
	local f = io.popen('cd ' .. _G.BotLuaScriptPath .. ' && ls *.lua') or {}
	for m in f:lines() do
		Print_to_Log(2, 'checking ' .. m)
		if (m:match('_[dD][eE][mM][oO]')) then
			Print_to_Log(0, _G.Sprintf('->Skip module %s', m))
		else
			local result_status4, result4 = xpcall(Load_LUA_Module, ErrorHandler, m, _G.BotLuaScriptPath)
			result4 = result4 or { '?', '?' }
			if not result_status4 then
				Print_to_Log(0, _G.Sprintf("!! Module %s failed to load, so won't be available until a 'reloadmodules' command:\nError:%s\n%s", m, result4[1], result4[2]))
			else
				Print_to_Log(2, ' -module->' .. (m or '???') .. '  commands:' .. (result4 or '???'))
			end
		end
	end
end

---------------------------------------------------------
-- load the individual module
function Load_LUA_Module(mName, mDir)
	if not mName then return nil end
	local result = ''
	-- add .lua when missing
	if not mName:find('%.lua$') then
		mName = mName .. '.lua'
	end
	local t = assert(loadfile(mDir .. mName))()
	local cl = t:get_commands()
	for c, r in pairs(cl) do
		result = result .. c .. ','
		_G.Available_Commands[c] = r
	end
	return result
end

---------------------------------------------------------
-- allow for variables to be saved/restored
function _G.Save_Persistent_Vars()
	-- save all persistent variables to file
	Print_to_Log(2, _G.Sprintf('Save _G.Persistent table %s', _G.BotDataPath .. 'dtgbot_persistent.json'))
	SaveTableToJSONFile(_G.Persistent or {}, _G.BotDataPath .. 'dtgbot_persistent.json')
end

---------------------------------------------------------
-- ### Not Used at this moment
-- Calculate the timestamp difference in seconds with current time
function TimeDiff(s)
	local year = string.sub(s, 1, 4)
	local month = string.sub(s, 6, 7)
	local day = string.sub(s, 9, 10)
	local hour = string.sub(s, 12, 13)
	local minutes = string.sub(s, 15, 16)
	local seconds = string.sub(s, 18, 19)
	local t1 = os.time()
	local t2 = os.time { year = year, month = month, day = day, hour = hour, min = minutes, sec = seconds }
	return os.difftime(t1, t2)
end

---------------------------------------------------------
-- Url Encode
function Url_Encode(str)
	if (str) then
		str = string.gsub(str, '\n', '\r\n')
		str =
			string.gsub(
				str,
				'([^%w %-%_%.%~])',
				function(c)
					return string.format('%%%02X', string.byte(c))
				end
			)
		str = string.gsub(str, ' ', '+')
	end
	return str
end

---------------------------------------------------------
-- Check if ID is WHiteListed so allowed to send commands
function ID_WhiteList_Check(SendTo)
	SendTo = tostring(SendTo)
	--Check id against whitelist
	if not ChatIDWhiteList[SendTo] then
		Print_to_Log(0, '! Telegram ChatID ' .. SendTo .. ' Not in ChatIDWhiteList.')
		return false
	end
	--"Active": "false"
	-- if ChatIDWhiteList[SendTo]["Name"] == "blocked" then
	if ChatIDWhiteList[SendTo]['Active'] == 'false' then
		Print_to_Log(0, '! Telegram ChatID ' .. SendTo .. ' is blocked')
		return false
	end
	-- Validated against ChatIDWhiteList
	Print_to_Log(2, 'Telegram ChatID ' .. SendTo .. ' is in the Whitelist : ' .. (ChatIDWhiteList[SendTo].Name or '??'))
	return true
end

-- ====  Telegram functions ================================================================
---------------------------------------------------------
-- Send Message to Telegram
function Telegram_SendMessage(SendTo, Message, MessageId, replymarkup, chat_type, handled_by)
	chat_type = chat_type or ''
	MessageId = MessageId or ''
	replymarkup = replymarkup or ''
	Message = Message or ''
	Print_to_Log(3, '=> Telegram_SendMessage ' ..
		'SendTo:', SendTo,
		'MessageId:', MessageId,
		'chat_type:', chat_type,
		'handled_by:', handled_by,
		'Message:', Message,
		'replymarkup:' .. replymarkup)
	local response, status
	local UpdateMsgId = 0
	local t_replymarkup = '&reply_markup='
	if replymarkup and replymarkup ~= '' then
		t_replymarkup = '&reply_markup=' .. Url_Encode(replymarkup)
	end
	-- Process callback messages
	if chat_type == 'callback' then
		-- Delete option for message with inline keyboard
		if Message == 'remove' then
			Print_to_Log(2, _G.Telegram_Url .. 'deleteMessage?chat_id=' .. SendTo .. '&message_id=' .. MessageId)
			response, status = _G.PerformTelegramRequest(_G.Telegram_Url .. 'deleteMessage?chat_id=' .. SendTo .. '&message_id=' .. MessageId)
		else
			-- rebuild new message with inlinemenu when the old message can't be updated
			Print_to_Log(2, _G.Telegram_Url .. 'editMessageText?chat_id=' .. SendTo .. '&message_id=' .. MessageId .. '&text=' .. Url_Encode(Message) .. t_replymarkup)
			response, status = _G.PerformTelegramRequest(_G.Telegram_Url .. 'editMessageText?chat_id=' .. SendTo .. '&message_id=' .. MessageId .. '&text=' .. Url_Encode(Message) .. t_replymarkup)
		end
		if status == 400 and string.find(response:lower(), "message can't be edited") then
			Print_to_Log(3, status .. '<== ', response)
			Print_to_Log(3, '==> /sendMessage?chat_id=' .. SendTo .. '&text=' .. Message .. t_replymarkup)
			response, status = _G.PerformTelegramRequest(_G.Telegram_Url .. 'sendMessage?chat_id=' .. SendTo .. '&reply_to_message_id=' .. MessageId .. '&text=' .. Url_Encode(Message) .. t_replymarkup)
		end
	else
		-- Process other messages
		if chat_type == 'channel' then
			-- channel messages don't support menus
			replymarkup = ''
		end
		-- when its an _edit message then search for the previous send and update that.
		--  == 'private_edit'
		if chat_type:find('_edit$') then
			_G.Persistent[SendTo] = _G.Persistent[SendTo] or {}
			_G.Persistent[SendTo].PrivateMsgsInfo = _G.Persistent[SendTo].PrivateMsgsInfo or {}
			_G.Persistent[SendTo].PrivateMsgsInfo[tostring(MessageId)] = _G.Persistent[SendTo].PrivateMsgsInfo[tostring(MessageId)] or 0
			UpdateMsgId = _G.Persistent[SendTo].PrivateMsgsInfo[tostring(MessageId)]

			Print_to_Log(3, ' ##### chat_type:', chat_type, ' handled_by:', handled_by, ' >>>> UpdateMsgId:', UpdateMsgId)
		end

		if UpdateMsgId ~= 0 then
			response, status = _G.PerformTelegramRequest(_G.Telegram_Url .. 'editMessageText?chat_id=' .. SendTo .. '&message_id=' .. UpdateMsgId .. '&text=' .. Url_Encode(Message))
			Print_to_Log(2, _G.Telegram_Url .. 'editMessageText?chat_id=' .. SendTo .. '&message_id=' .. UpdateMsgId .. '&text=' .. Url_Encode(Message))
			Print_to_Log(3, status .. ' <1== ', response)
			if status == 400 and string.find(response:lower(), "message can't be edited") then
				Print_to_Log(3, status .. ' <2== ', response)
				Print_to_Log(3, '==> /sendMessage?chat_id=' .. SendTo .. '&text=' .. Message)
				response, status = _G.PerformTelegramRequest(_G.Telegram_Url .. 'sendMessage?chat_id=' .. SendTo .. '&text=' .. Url_Encode(Message))
			end
		else
			Print_to_Log(2, _G.Telegram_Url .. 'sendMessage?chat_id=' .. SendTo .. '&reply_to_message_id=' .. MessageId .. '&text=' .. Url_Encode(Message) .. t_replymarkup)
			response, status = _G.PerformTelegramRequest(_G.Telegram_Url .. 'sendMessage?chat_id=' .. SendTo .. '&reply_to_message_id=' .. MessageId .. '&text=' .. Url_Encode(Message) .. t_replymarkup)
		end
		Print_to_Log(2, _G.Sprintf('response=%s', response))
		if status == 200 then
			local decoded_response = _G.JSON.decode(response or {}) or {}
			if decoded_response.result ~= nil and decoded_response.result.message_id ~= nil then
				Print_to_Log(2, _G.Sprintf('   Message sent ' .. (decoded_response.result.message_id or '') .. ' . status=%s', status))
				_G.Persistent[SendTo] = _G.Persistent[SendTo] or {}
				_G.Persistent[SendTo].iLastcommand = _G.Persistent[SendTo].iLastcommand or ''
				Telegram_Save_Clean_Messages(SendTo, decoded_response.result.message_id, MessageId, handled_by, false)
				Print_to_Log(2, _G.Sprintf('_G.Persistent.UseDTGMenu=%s', _G.Persistent.UseDTGMenu))
				Print_to_Log(2, _G.Sprintf('_G.Persistent[SendTo].iLastcommand=%s', _G.Persistent[SendTo].iLastcommand))
				-- Save Reply messageid for private messages to allow for updating it later.
				--if not chat_type:find('_edit$') then
				_G.Persistent[SendTo] = _G.Persistent[SendTo] or {}
				_G.Persistent[SendTo].PrivateMsgsInfo = _G.Persistent[SendTo].PrivateMsgsInfo or {}
				Print_to_Log(3, ' ##### chat_type:', chat_type, ' handled_by:', handled_by, ' NewReplyId:', MessageId, _G.Persistent[SendTo].PrivateMsgsInfo[MessageId])
				--> Keep 10 highest msgids to keep the table small:
				--Print_to_Log(0, "###>>"..JSON.encode(_G.Persistent[SendTo].PrivateMsgsInfo))
				local keys = {}
				for key, _ in pairs(_G.Persistent[SendTo].PrivateMsgsInfo) do
					if key ~= '' then
						table.insert(keys, tonumber(key))
					end
				end
				--Print_to_Log(0, "-->>"..JSON.encode(keys))
				-- Sort keys in descending order
				table.sort(keys, function(a, b) return a > b end)
				-- Select the top 10 keys and store them in a new table
				local top10 = {}
				for i = 1, math.min(10, #keys) do
					--Print_to_Log(0, "--++ top10:"..tostring(keys[i]) .. "=" .. (_G.Persistent[SendTo].PrivateMsgsInfo[tostring(keys[i])] or '??') .. " => " .. (_G.Persistent[SendTo].PrivateMsgsInfo[keys[i]] or '??'))
					-- keys seems to be both number as strings
					top10[keys[i]] = _G.Persistent[SendTo].PrivateMsgsInfo[tostring(keys[i])] or (_G.Persistent[SendTo].PrivateMsgsInfo[keys[i]] or '--')
				end
				--Print_to_Log(0, "-- top10 <"..JSON.encode(top10))
				--Print_to_Log(0, "###>>"..JSON.encode(_G.Persistent[SendTo].PrivateMsgsInfo))
				_G.Persistent[SendTo].PrivateMsgsInfo = top10
				--Print_to_Log(0, "###<<"..JSON.encode(_G.Persistent[SendTo].PrivateMsgsInfo))
				--<-- Keep 10 highest msgids
				-- add last message
				_G.Persistent[SendTo].PrivateMsgsInfo[tostring(MessageId)] = decoded_response.result.message_id
				--end
				if _G.Persistent.UseDTGMenu == 1 and _G.Persistent[SendTo].iLastcommand == 'menu' then
					_G.Persistent.LastInlinemessage_id = decoded_response.result.message_id
					Print_to_Log(2, _G.Sprintf('save _G.Persistent.LastInlinemessage_id=%s', _G.Persistent.LastInlinemessage_id))
					_G.Persistent[SendTo].iLastcommand = ''
				end
			else
				Print_to_Log(0, _G.Sprintf('   Message not sent. status=%s -> %s', status, response))
			end
		end
		return
	end
end

-------------------------------------------------------------------------
-- Save current message ID's and clean up previous messages when defined
function Telegram_Save_Clean_Messages(From_Id, nsmsgid, nrmsgid, handled_by, remAll)
	remAll = remAll or false
	handled_by = handled_by or ''
	MenuMessagesMaxShown = tonumber(MenuMessagesMaxShown)
	-- do not save or delete messages when MenuMessagesMaxShown = 0
	Print_to_Log(2, _G.Sprintf('===CleanMessage handled_by:%s remAll=%s', handled_by, remAll))
	if (handled_by == 'other_private_message') then
		Print_to_Log(2, _G.Sprintf('---Skip messagecleanup for %s', handled_by))
		return
	end
	if ((MenuMessagesMaxShown or 0) == 0 and handled_by == 'menu') or ((OtherMessagesMaxShown or 0) == 0 and handled_by ~= 'menu') then
		if handled_by ~= '' then
			Print_to_Log(0, _G.Sprintf('---CleanMessage handled_by:%s', handled_by))
		end
		return
	end

	if not _G.Persistent[From_Id] then
		_G.Persistent[From_Id] = {}
	end
	if not _G.Persistent[From_Id].MsgsInfo then
		_G.Persistent[From_Id].MsgsInfo = {}
	end
	Old_Messages = _G.Persistent[From_Id].MsgsInfo

	-- remove old messages
	while (#Old_Messages >= MenuMessagesMaxShown) or remAll do
		-- break when table is empty
		if #Old_Messages == 0 then
			break
		end
		-- get first table entry en remove from table.
		local cmsg = table.remove(Old_Messages, 1)

		Print_to_Log(9, _G.Sprintf('smsgid=%s| rmsgid=%s| DelTS=%s| DelTR=%s|', tostring(cmsg.smsgid), tostring(cmsg.rmsgid), msgids_removed[tostring(cmsg.smsgid)] or '?', msgids_removed[tostring(cmsg.rmsgid)] or '?'))

		-- don't remove msgid's the receive updates
		if nrmsgid ~= cmsg.smsgid and msgids_removed[tostring(cmsg.smsgid)] ~= 'done' then
			Telegram_Remove_Message(From_Id, cmsg.smsgid)
			msgids_removed[tostring(cmsg.smsgid)] = 'done'
		end
		if nrmsgid ~= cmsg.rmsgid and msgids_removed[tostring(cmsg.rmsgid)] ~= 'done' then
			Telegram_Remove_Message(From_Id, cmsg.rmsgid)
			msgids_removed[tostring(cmsg.rmsgid)] = 'done'
		end
	end
	-- _cleanall: also the send command to totally clean all messages
	if remAll then
		if ((nsmsgid or 0) ~= 0) then
			Print_to_Log(9, _G.Sprintf(' Remove nsmsgid %s', nsmsgid))
			Telegram_Remove_Message(From_Id, nsmsgid)
			msgids_removed[tostring(nsmsgid)] = 'done'
		end
	else
		-- add the latest message to table
		if ((nrmsgid or 0) ~= 0 and (nsmsgid or 0) ~= 0) then
			Print_to_Log(2, _G.Sprintf('   Current %s.Add messages to table for %s: %s - %s', #Old_Messages, From_Id, nrmsgid, nsmsgid))
			table.insert(Old_Messages, { smsgid = nsmsgid, rmsgid = nrmsgid })
		end
	end
end

function Telegram_Remove_Message(SendTo, MessageId)
	Print_to_Log(2, _G.Sprintf('Delete MessageId:%s for SendTo:%s', MessageId, SendTo))
	if (tonumber(SendTo) or 0) == 0 or (tonumber(MessageId) or 0) == 0 then
		return
	end
	-- Remove requested MsgId
	local response, status = _G.PerformTelegramRequest(_G.Telegram_Url .. 'deleteMessage?chat_id=' .. SendTo .. '&message_id=' .. MessageId)
	-- update MsgTime when update is successful
	local decoded_response = _G.JSON.decode(response or {}) or {}
	if status == 200 then
		Print_to_Log(2, _G.Sprintf('   Message %s deleted.', MessageId))
	else
		Print_to_Log(2, _G.Sprintf('   !!! Message %s not deleted! %s', MessageId, (decoded_response.description or response)))
	end
end

function StrTrim(s)
	s = s or ''
  return s:match "^%s*(.-)%s*$"
end
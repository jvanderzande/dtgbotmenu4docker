_G.dtgbot_version = '1.0 202505081503'
--[[
	Main process for DTGBOT
	Developer: jvdzande
	This is a spinoff of the oroginal DTGBOT developed by s.gibbon https://github.com/steps39
	GNU GENERAL PUBLIC LICENSE
]]

-- -------------------------------------------------------
-- Used Directories

_G.Telegram_Longpoll_TimeOut = 30 -- used to set the max wait time for both the longpoll and the _G.HTTPS timeout

print('########## Docker ############')
_G.ScriptDirectory = '/dtgbot/'
_G.BotLuaScriptPath = '/modules/lua/'
_G.BotBashScriptPath = '/modules/bash/'
_G.BotDataPath = '/data/'
-- log info
_G.BotLogFile = _G.BotDataPath .. 'logs/dtgbot.log' --
_G.BotCheckFile = '/tmp/dtgloop.txt'                -- used to check if process is still looping correctly without hangs
_G.BotTempDir = '/tmp/'
_G.BotLogLevel = 1

os.execute('echo ' .. os.date('%Y-%m-%d %H:%M:%S') .. ' > ' .. _G.BotCheckFile)

-----------------------------------------------------------
-- Function to handle the HardErrors
--   returns the error and callstack in 2 parameter table

function ErrorHandler(x)
	print('\n### ErrorHandler Failed:\nError-->' .. (x or '?'))
	return { x, debug.traceback() }
end

function ErrorHandler_y(x)
	print('\n### ErrorHandler_y Failed:\nError-->' .. (x or '?'))
	return { x, debug.traceback() }
end

function ErrorHandler_x(x)
	print('\n### ErrorHandler_x Failed:\nError-->' .. (x or '?'))
	return { x, debug.traceback() }
end

-- ###################################################################
-- Initialization process
-- ###################################################################
local yreturn_status, yresult =
	xpcall(
		function()
			--------------------------------------------------------------------------------
			--  and add to the packages search path
			--?? package.path = _G.ScriptDirectory .. '?.lua;' .. _G.ScriptDirectory .. package.path
			package.path = _G.ScriptDirectory .. '?.lua;' .. package.path
			--------------------------------------------------------------------------------
			-- Load required files
			_G.HTTP = require 'socket.http' --lua-sockets
			_G.ltn12 = require('ltn12')
			_G.SOCKET = require 'socket' --lua-sockets
			_G.HTTPS = require 'ssl.https' --lua-sockets
			_G.JSON = require 'json'     -- lua-json
			_G.MIME = require('mime')    -- ???

			_G.ConfigActive = {}         -- table to store the active config
			_G.ConfigUser = {}           -- table to store the user configuration
			_G.ConfigDefault = {}        -- table to store the default configurations
			--------------------------------------------------------------------------------
			-- dtgbot Lua libraries
			--------------------------------------------------------------------------------
			-- Load All general Main functions
			require('dtgbot_main_functions')
			require('dtgbot_domoticz')

			function _G.LoadConfig(configfile)
				dofile(configfile)
			end

			-- Function to load one or 2 Lua file(s) to retrieve its Config Variables
			function _G.LoadConfigFiletoJson(ConfigLUA, OutputJSONFile, RenameAfterConversion)
				local env = {}
				local content = ''
				if ConfigLUA then
					-- Read the contents of the first file
					local Fi = io.open(ConfigLUA, 'r')
					if Fi then
						Print_to_Log(2, 'Loaded ConfigLUA file:', ConfigLUA)
						content = content .. (Fi:read('*a') or '') .. '\n'
						Fi:close()
						if RenameAfterConversion then
							-- Rename the file to .lua.old
							local newname = ConfigLUA .. '.old'
							os.rename(ConfigLUA, newname)
							Print_to_Log(2, 'Renamed ConfigLUA file:', ConfigLUA, 'to', newname)
						end
					else
						Print_to_Log(2, 'Skip conversion, ConfigFile not found:', ConfigLUA)
						return false
					end
				else
					Print_to_Log(2, 'Skip conversion, No ConfigFile defined!')
					return false
				end
				-- Load the combined content as a chunk

				Print_to_Log(0, 'Start loading config from ' .. ConfigLUA)
				local chunk, err = load(content)
				if not chunk then
					error('Failed to load chunk: ' .. err)
					return false
				end

				env = setmetatable(env, { __index = _G }) -- Set the environment with fallback to _G
				debug.setupvalue(chunk, 1, env)       -- Set the environment for the chunk

				-- Execute the chunk in a protected call
				local success, exec_err = pcall(chunk)
				if not success then
					Print_to_Log(0, 'Error executing chunk: ' .. (exec_err or 'unknown error'))
					return false, 'Error executing chunk: ' .. (exec_err or 'unknown error')
				end

				if ConfigLUA:match('dtgbot__configdefault') then
					-- Add these Envirionment vars to the default config used by web pages
					env.TelegramBotToken = os.getenv('TelegramBotToken') or ''
					env.Telegram_Url = 'https://api.telegram.org/bot' .. (os.getenv('TelegramBotToken') or '?') .. '/'
					env.DomoticzUrl = (os.getenv('DomoticzURL') or '?')
				end
				if OutputJSONFile then
					-- Save the variables to a JSON file
					local Fo = assert(io.open(OutputJSONFile, 'w'))
					if Fo then
						Fo:write(tostring(JSON.encode(env, { indent = true })))
						-- f:write(tostring(JSON.encode(ConfVars, { indent = true })))
						Fo:close()
					end
				end

				return true
			end

			-- Function to merge the 2 config tables
			function _G.TableMergeConfigs(table1, table2)
				local merged = {}
				if type(table1) ~= 'table' then
					Print_to_Log(2, 'TableMergeConfigs: ConfigDefault is not a table:' .. type(table1) .. ' ' .. tostring(table1))
					return {}
				end
				if type(table2) ~= 'table' then
					Print_to_Log(2, 'TableMergeConfigs: ConfigUser is not a table:' .. type(table2) .. ' ' .. tostring(table2))
					return table1
				end
				for k, v in pairs(table1) do
					if type(v) == 'table' and type(table2[k]) == 'table' then
						-- Recursively merge nested tables
						merged[k] = TableMergeConfigs(v, table2[k])
						_G[k] = merged[k]
					else
						-- take the value from table2 when there else keep table1
						merged[k] = table2[k] or v
						_G[k] = merged[k]
					end
				end
				-- User Config loop to add missing keys
				for k, v in pairs(table2) do
					if merged[k] == nil then
						merged[k] = v
						_G[k] = merged[k]
					end
				end
				return merged
			end

			-- Read config file and return string
			function _G.ReadJSONContents(iFile)
				local Fi = io.open(iFile, 'r')
				local contents
				local rc = true
				if Fi then
					contents = _G.JSON.decode((Fi:read('*a') or '')) or {}
					Fi:close()
				else
					Print_to_Log(2, 'Config ' .. iFile .. ' not found, using empty table')
					contents = {}
					rc = false
				end
				return contents, rc
			end

			-- Function to load one or 2 Lua file(s) to retrieve its Config Variables
			function _G.LoadActiveConfig()
				local rc
				-- Load Defaultconfig
				_G.ConfigDefault, rc = ReadJSONContents(_G.BotDataPath .. 'dtgbot__configdefault.json')
				if (not rc) then
					Print_to_Log(2, 'ConfigDefault not found, using empty table')
				end

				-- Load Userconfig
				_G.ConfigUser, rc = ReadJSONContents(_G.BotDataPath .. 'dtgbot__configuser.json')
				if (not rc) then
					Print_to_Log(2, 'dtgbot__configuser.json not found, using empty table')
					Print_to_Log(-1, '---------------------------------')
					Print_to_Log(-1, 'Load/convert old DTGBOT configs')
					-- Import/Convert and existing old config
					LoadConfigFiletoJson(_G.BotDataPath .. 'dtgbot.cfg', _G.BotDataPath .. 'dtgbot.cfg.json')
					LoadConfigFiletoJson(_G.BotDataPath .. 'dtgbot-user.cfg', _G.BotDataPath .. 'dtgbot-user.cfg.json')
					LoadConfigFiletoJson(_G.BotDataPath .. 'dtgmenu.cfg', _G.BotDataPath .. 'dtgmenu.cfg.json')
					local Foc1 = ReadJSONContents(_G.BotDataPath .. 'dtgbot.cfg.json')
					-- Print_to_Log(0, tostring(JSON.encode(Foc1, { indent = true })))
					local Foc2 = ReadJSONContents(_G.BotDataPath .. 'dtgbot-user.cfg.json')
					-- Print_to_Log(0, tostring(JSON.encode(Foc2, { indent = true })))
					local Foc3 = ReadJSONContents(_G.BotDataPath .. 'dtgmenu.cfg.json')
					-- Print_to_Log(0, tostring(JSON.encode(Foc3, { indent = true })))
					local Focm = TableMergeConfigs(Foc1, Foc2)
					Focm = TableMergeConfigs(Focm, Foc3)
					-- Print_to_Log(0, tostring(JSON.encode(Focm, { indent = true })))
					-- get specific variables from old config when they exists
					function MigrateOldSettings(old, new)
						if (Focm[old]) then
							if (ConfigUser[new]) then
								Print_to_Log(-1, ' Skipped Migration ' .. old .. ' to ' .. new .. '  value:' .. JSON.encode(Focm[old]))
								Print_to_Log(-1, '    Old value exists:' .. JSON.encode(ConfigUser[new]))
							elseif (JSON.encode(ConfigDefault[new]) == JSON.encode(Focm[old])) then
								Print_to_Log(-1, ' Skipped Migration ' .. old .. ' to ' .. new .. '  value:' .. JSON.encode(Focm[old]))
								Print_to_Log(-1, '    Same as Default value:' .. JSON.encode(ConfigDefault[new]))
							else
								Print_to_Log(-1, ' Migrate ' .. old .. ' to ' .. new .. '  value:' .. JSON.encode(Focm[old]))
								_G.ConfigUser[new] = Focm[old]
							end
						else
							Print_to_Log(0, ' no old field ' .. old .. ' to migrate')
						end
					end

					MigrateOldSettings('static_dtgmenu_submenus', 'DTGMenu_Static_submenus')
					MigrateOldSettings('SubMenuwidth', 'SubMenuwidth')
					MigrateOldSettings('DevMenuwidth', 'DevMenuwidth')
					MigrateOldSettings('ActMenuwidth', 'ActMenuwidth')
					MigrateOldSettings('FullMenu', 'FullMenu')
					MigrateOldSettings('AlwaysResizeMenu', 'AlwaysResizeMenu')

					-- remove any settings for these as they have to be set via the environment now
					_G.ConfigUser.TelegramBotToken = nil
					_G.ConfigUser.Telegram_Url = nil
					_G.ConfigUser.DomoticzUrl = nil

					local Fo = assert(io.open(_G.BotDataPath .. 'dtgbot__configuser.json', 'w'))
					if Fo then
						Fo:write(tostring(JSON.encode(_G.ConfigUser, { indent = true })))
						Fo:close()
					end
					-- cleanup the old config generated json files
					os.remove(_G.BotDataPath .. 'dtgbot.cfg.json')
					os.remove(_G.BotDataPath .. 'dtgbot-user.cfg.json')
					os.remove(_G.BotDataPath .. 'dtgmenu.cfg.json')
					Print_to_Log(0, '--< Done check for old configs to convert and dtgbot__configuser.json created.')
				end

				_G.ConfigActive = TableMergeConfigs(_G.ConfigDefault, _G.ConfigUser)

				local Fo = assert(io.open(_G.BotDataPath .. 'dtgbot__configactive.json', 'w'))
				if Fo then
					Fo:write(tostring(JSON.encode(_G.ConfigActive, { indent = true })))
					Fo:close()
				end


			end

			-- Copy Standard Config and override when newer than existing
			os.execute('cp -u -p ' .. _G.ScriptDirectory .. 'dtgbot__configdefault.lua ' .. _G.BotDataPath)

			-- ==========================================
			-- = Load/Convert Defaultconfig
			-- ==========================================
			-- Load active config from JSON files
			Print_to_Log(-1, '####################################################################################')
			Print_to_Log(-1, 'Load DTGBOT configuration files')
			LoadConfigFiletoJson(_G.BotDataPath .. 'dtgbot__configdefault.lua', _G.BotDataPath .. 'dtgbot__configdefault.json')
			_G.TelegramBotToken = os.getenv('TelegramBotToken') or ''
			_G.Telegram_Url = 'https://api.telegram.org/bot' .. (os.getenv('TelegramBotToken') or '?') .. '/'
			_G.DomoticzUrl = (os.getenv('DomoticzURL') or '?')
			LoadActiveConfig()

			-- ==========================================
			-- set logfile to datapath
			Print_to_Log(-1, 'Start DTGBOT (git release:' .. (os.getenv('GIT_RELEASE') or '?') .. ')')
			if _G.BotLogFile ~= '' then
				Print_to_Log(-1, 'DTGBOT LogFile set to    :' .. _G.BotLogFile)
			end

			_G.MenuLanguage = _G.MenuLanguage or 'en'
			Print_to_Log(2, '_G.BotLogLevel set to  :' .. _G.BotLogLevel)

			-- Show current INFO in console log
			Print_to_Log(-1, 'Starting dtgbot_version   :' .. (_G.dtgbot_version or '?'))
			Print_to_Log(-1, 'dtg_main_functions_version:' .. (_G.dtg_main_functions_version or '?'))
			Print_to_Log(-1, 'dtg_domoticz_version      :' .. (_G.dtg_domoticz_version or '?'))
			Print_to_Log(-1, 'BotLogLevel set to  :' .. _G.BotLogLevel)

			-- get any persistent variable values
			_G.Persistent = _G.LoadTableFromJSONFile(_G.BotDataPath .. 'dtgbot_persistent.json') or {}
			if (_G.Persistent.UseDTGMenu) then
				Print_to_Log(-1, 'Persistent table loaded')
			else
				Print_to_Log(-1, 'Persistent table will be initialised.')
			end
			-- Install/Update standard scripts in case of updates
			os.execute('mkdir -p ' .. _G.BotBashScriptPath .. ' >> ' .. _G.BotLogFile)
			os.execute('mkdir -p ' .. _G.BotLuaScriptPath .. ' >> ' .. _G.BotLogFile)
			os.execute('cp -u -p ' .. _G.ScriptDirectory .. 'bash/* ' .. _G.BotBashScriptPath .. ' >> ' .. _G.BotLogFile .. ' 2>&1')
			os.execute('cp -u -p ' .. _G.ScriptDirectory .. 'lua/* ' .. _G.BotLuaScriptPath .. ' >> ' .. _G.BotLogFile .. ' 2>&1')
			--------------------------------------------------------------------------------
			-- Load the configuration file this file contains the list of commands
			-- used to define the external files with the command function to load.
			--------------------------------------------------------------------------------
			-- Array to store device list rapid access via index number
			_G.StoredType = 'None'
			_G.StoredList = {}

			-- Table to store functions for commands plus descriptions used by help function
			_G.Available_Commands = {}

			-- define global Variables
			_G.DomoticzRevision = 0
			_G.DomoticzVersion = 0
			_G.DomoticzBuildDate = 0
		end,
		ErrorHandler_y
	)
if not yreturn_status then
	-- Terminate the process as the Initialisation part needs to be successfull for dtgbot to work.
	-- Try to log the hard error to logfile when function is available.
	-- Then end with an Hard Error.
	yresult = yresult or { '?', '?' }
	print('\n### Initialialisation process Failed:\nError-->' .. (yresult[1] or '') .. (yresult[2] or ''))
	error('Terminate DTGBOT as the initialisation failed, which first needs to be fixed.')
end
-- ###################################################################
-- Main process start
-- ###################################################################
local xreturn_status, xresult =
	xpcall(
		function()
			Print_to_Log(0, '------------------------------------------------------')
			Print_to_Log(0, '### Starting dtgbot - Telegram api Bot message handler')
			Print_to_Log(0, '------------------------------------------------------')

			-- initialise tables
			_G.DtgBot_Initialise()

			-- Get the updates
			local telegram_connected = false
			-- initialise to 0 to get the first new message
			local status = 999
			local response = ''
			local decoded_response
			local reloadmodules = false
			-- ==================================================================================================
			-- closed loop to retrieve Telegram messages while service is running
			-- ==================================================================================================
			Print_to_Log(-1, '#> Starting message loop with Telegram servers')
			_G.Persistent.TelegramBotOffset = _G.Persistent.TelegramBotOffset or 0
			Print_to_Log(1, 'TelegramBotOffset=' .. (_G.Persistent.TelegramBotOffset))
			local longpollmaxtime = 1
			while true do
				-- loop till messages is received
				while true do
					-- Update monitorfile each loop
					os.execute('echo ' .. os.date('%Y-%m-%d %H:%M:%S') .. ' > ' .. _G.BotCheckFile)
					-- -----------------------------------------------------------------------------------------------------------
					--> Start LongPoll to Telegram wrapper in it's own error checking routine
					local return_status2, result2 =
						xpcall(
							function()
								local url = _G.Sprintf('%sgetUpdates?timeout=%s&limit=1&offset=%s', _G.Telegram_Url, (longpollmaxtime or 30), _G.Persistent.TelegramBotOffset)
								response, status = _G.PerformTelegramRequest(url)
							end,
							ErrorHandler
						)
					longpollmaxtime = _G.Telegram_Longpoll_TimeOut or 30
					if not return_status2 then
						result2 = result2 or { '?', '?' }
						(Print_to_Log or print)('\n### Get Telegram Failed, we will just retry:\nError-->' .. (result2[1] or ''))
						os.execute('sleep 2')
						status = 999
					end
					--< End LongPoll to Telegram wrapper
					-------------------------------------------------------------------------------------
					-- reload user config for simple changes
					local n_rc, n_errmsg = pcall(LoadActiveConfig)
					-- check for errors returned
					if not n_rc then
						Print_to_Log(-1, '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!', 1)
						Print_to_Log(-1, '!!!!> LoadActiveConfig() failed with errors: ' .. n_errmsg, 1)
						Print_to_Log(-1, '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!', 1)
					else
						-- reload Whitelist in case it changed
						Load_MenuWhiteList()
					end
					-----------------------------------------------------------------------------------------------------------
					if status == 200 then
						if not telegram_connected then
							Print_to_Log(-1, '-> In contact with Telegram servers. Start Longpoll loop every ' .. _G.Telegram_Longpoll_TimeOut .. ' seconds.')
							if _G.BotLogFile ~= '' then
								Print_to_Log(-1, '===========================================================================')
								Print_to_Log(-1, 'Further detailed Logging can be found in ' .. _G.BotLogFile)
								Print_to_Log(-1, 'Open http://DTGBOT-Host:8099 to view log and update configuration settings.')
								Print_to_Log(-1, '===========================================================================')
							end
							telegram_connected = true
						end
						-- check if there is a message or just a timeout with empty response
						decoded_response = _G.JSON.decode(response or { result = {} })
						decoded_response = decoded_response or {}
						if decoded_response['result'][1] ~= nil and decoded_response['result'][1]['update_id'] ~= nil then
							-- contains data so exit while to continue to process
							--Print_to_Log(3, 'response received:', response)
							break
						end
						Print_to_Log(1, '- No bot messages, next longpoll..')
					else
						Print_to_Log(0, _G.Sprintf('Longpoll ended with status:%s response:%s', status, result2))
						-- status <> 200 ==> error?
						if telegram_connected then
							Print_to_Log(-1, _G.Sprintf('\n### Lost contact with Telegram servers, received Non 200 status:%s', (status or '?'), (response or '?')))
							telegram_connected = false
						end
						-- pause a little on failure
						os.execute('sleep 1')
						response = ''
					end
				end
				-------------------------------------------------------------------------------------
				--> Get current update_id and set +1 for the next one to get.
				local tt = decoded_response['result'][1] or {}
				Print_to_Log(2, 'update_id ', tt.update_id)
				-- set next msgid we want to receive
				_G.Persistent.TelegramBotOffset = tt.update_id + 1
				Print_to_Log(2, 'TelegramBotOffset ' .. _G.Persistent.TelegramBotOffset)
				-- save the persistent variables to save the TelegramBotOffset to the table.
				-- this to a void reprocessing the same message in case of reboot during processing
				-- This allows for a reboot command to be send without being re-processed causing a loop
				_G.Save_Persistent_Vars()
				-- reload modules in case a command failure happened so you can update the modules without a dtgbot restart
				if reloadmodules then
					_G.Available_Commands = {}
					Load_LUA_Modules()
					reloadmodules = false
				end

				-->> Start processing message and capture any errors to avoid hardcrash
				if tt['callback_query'] ~= nil then
					Print_to_Log(0, _G.Sprintf('=> Received Telegram callback_query id: %s Content: %s', tt.update_id, _G.JSON.encode(tt['callback_query'])))
				elseif tt['channel_post'] ~= nil then
					Print_to_Log(0, _G.Sprintf('=> Received Telegram channel_post   id: %s Content: %s', tt.update_id, _G.JSON.encode(tt['channel_post'])))
				elseif not tt['message'] and tt['edited_message'] then
					Print_to_Log(0, _G.Sprintf('=> Received Telegram edited_message id: %s Content: %s', tt.update_id, _G.JSON.encode(tt['edited_message'])))
				elseif tt['message'] ~= nil then
					Print_to_Log(0, _G.Sprintf('=> Received Telegram message        id: %s Content: %s', tt.update_id, _G.JSON.encode(tt['message'])))
				end
				local result_status, result, result_err = xpcall(PreProcess_Received_Message, ErrorHandler, tt)
				if not result_status then
					-- HardError encountered so reporting the information
					-- reload LUA modules so they can be updated without restarting the service
					Print_to_Log(0, _G.Sprintf('<- !!! Msg process hard failed: \nError:%s\n%s', result[1], result[2]))
					reloadmodules = true
				else
					-- No Hard Errors, so check for second retuned param which is used for internal errors
					if (result_err or '') ~= '' then
						Print_to_Log(0, _G.Sprintf('<- !!! Msg process failed:%s %s', result, result_err))
						reloadmodules = true
					else
						Print_to_Log(0, _G.Sprintf('<= Msg processed: %s', result))
					end
				end
				-- save the persistent variables afer each message processed
				_G.Save_Persistent_Vars()
				--<< End processing message
			end
		end,
		ErrorHandler_x
	)

if not xreturn_status then
	xresult = xresult or { '?', '?' }
	print('\n### Main process Failed:\nError-->' .. (xresult[1] or '') .. (xresult[2] or ''))
end

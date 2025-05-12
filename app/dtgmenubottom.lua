_G.dtgmenubottom_version = '1.0 202505122058'
--[[
	Script to support the Bottmon Menu Keyboard option for DTGBOT
	Developer: jvdzande
	GNU GENERAL PUBLIC LICENSE
]]

local dtgmenubottom = {}
local bLastCommand = {}

------------------------------------------------------------------------------
--- START Build the reply_markup functions.
--  this function will build the requested menu layout and calls the function to retrieve the devices/scenes  details.
-------------------------------------------------------------------------------
function dtgmenubottom.makereplymenu(SendTo, Level, submenu, devicename)
  -- These are the possible menu level's ..
  -- mainmenu   -> will show all first level static and dynamic (rooms) options
  -- submenu    -> will show the second level menu for the select option on the main menu
  -- devicemenu -> will show the same menu as the previous but now add the possible action at the top of the menu
  --
  if submenu == nil then
    submenu = ''
  end
  if devicename == nil then
    devicename = ''
  end
  Print_to_Log(2, 'Start makereplymenu:', SendTo, Level, submenu, devicename)

  ------------------------------------------------------------------------------
  -- First build the _G.dtgmenu_submenus table with the required level information
  ------------------------------------------------------------------------------
  --~ moved to refresh:   PopulateMenuTab(Level,submenu)

  ------------------------------------------------------------------------------
  -- start the build of the 3 levels of the keyboard menu
  ------------------------------------------------------------------------------
  Print_to_Log(2, '  -> makereplymenu  Level:', Level, 'submenu', submenu, 'devicename', devicename)
  local t = 1
  local l1menu = ''
  local l2menu = ''
  local l3menu = ''
  --~   Sort & Loop through the compiled options returned by PopulateMenuTab
  for i, get in orderedPairs(_G.dtgmenu_submenus) do
    -- ==== Build mainmenu - level 1 which is the bottom part of the menu, showing the Rooms and static definitions
    -- Avoid adding start and menu as these are handled separately.
    (function()
      -- Don't used this for menu or strat command
      if i == 'menu' and i == 'start' then return end
      -- Check if ChatID is allowed for this item
      if get.whitelist ~= '' and not ChkInTable(get.whitelist, SendTo) then return end

      -- test if anything is specifically defined for this user in Telegram-RoomsShowninMenu`
      if not get.RoomNumber then
        Print_to_Log(2, SendTo .. ' Fixed item/No Roomnumber -> add to menu: ' .. i)
        l1menu = l1menu .. i .. '|'
        return
      end

      -- Check Whitelist for the Sender's id
      if MenuWhiteList[SendTo] then
        if MenuWhiteList[SendTo][get.RoomNumber]                                      -- SendTo -> has room number in the list
          or MenuWhiteList[SendTo]['99']                                              -- SendTo -> Show All
          or (MenuWhiteList[SendTo]['0'] and MenuWhiteList['0'][get.RoomNumber]) then -- SendTo -> use defaults
          Print_to_Log(3, SendTo .. ' MenuWhiteList Check room:' .. (get.RoomNumber) .. '/' .. i .. ' is Whitelisted. -> add room button')
        else
          Print_to_Log(2, SendTo .. ' MenuWhiteList Check room:' .. (get.RoomNumber) .. '/' .. i .. ' not Whitelisted! -> skip room button')
          return
        end
        -- else check for the standard/default menus to be shown
      elseif MenuWhiteList['0'] then
        if MenuWhiteList['0'] and MenuWhiteList['0'][get.RoomNumber] then
          Print_to_Log(3, 'Default MenuWhiteList Check room:' .. (get.RoomNumber) .. '/' .. i .. ' is Whitelisted. -> add room button')
        else
          Print_to_Log(2, 'Default MenuWhiteList Check room:' .. (get.RoomNumber) .. '/' .. i .. ' not Whitelisted! -> skip room button')
          return
        end
      else
        Print_to_Log(3, SendTo .. ' No 0(Default) or SendTo Whitelist defined so -> add to menu: ' .. i)
      end
      l1menu = l1menu .. i .. '|'
    end)()
  end
  -- ==== Build Submenu - showing the Devices from the selected room of static config
  --                      This will also add the device status when showdevstatus=true for the option.
  Print_to_Log(2, 'submenu: ' .. submenu)
  if (Level == 'submenu' or Level == 'devicemenu')
    and _G.dtgmenu_submenus[submenu] and _G.dtgmenu_submenus[submenu].buttons then
    -- loop through all devined "buttons in the Config
    for i, get in orderedPairs(_G.dtgmenu_submenus[submenu].buttons) do
      (function()
        -- process all found devices in  _G.dtgmenu_submenus buttons table
        if i == '' then
          Print_to_Log(2, '  - Skipping Empty button name:' .. JSON.encode(get))
          return
        end
        local switchstatus = ''
        Print_to_Log(2, '   - Submenu item:', i, _G.dtgmenu_submenus[submenu].showdevstatus, get.DeviceType, get.idx, get.Name or '?', get.status or '?')
        local didx, dDeviceName, dDeviceType, dType, dSwitchType, dMaxDimLevel
        get.whitelist = get.whitelist or ''
        if get.whitelist ~= '' and not ChkInTable(get.whitelist, SendTo) then
          Print_to_Log(2, '   - SendTo not in whitelist for Submenu item.')
          return
        end
        -- add the device status to the button when requested
        if _G.dtgmenu_submenus[submenu].showdevstatus == 'y' then
          didx, dDeviceName, dDeviceType, dType, dSwitchType, dMaxDimLevel, switchstatus, LevelNames, LevelInt = Domo_Devinfo_From_Name(get.idx, get.Name, get.DeviceType)
          switchstatus = switchstatus or ''
          if switchstatus ~= '' then
            if dSwitchType == 'Selector' then
              switchstatus = ' - ' .. getSelectorStatusLabel(get.actions, LevelInt)
            else
              --~ 							Print_to_Log(0,switchstatus)
              switchstatus = tostring(switchstatus)
              switchstatus = switchstatus:gsub('Set Level: ', '')
              switchstatus = ' - ' .. switchstatus
            end
          end
        end
        -- add to the total menu string for later processing
        l2menu = l2menu .. i .. switchstatus .. '|'
        -- show the actions menu immediately for this devices since that is requested in the config
        -- this can avoid having the press 2 button before getting to the actions menu
        if get.showactions and devicename == '' then
          Print_to_Log(2, '  - Changing to Device action level due to showactions:', i)
          Level = 'devicemenu'
          devicename = i
        end
        Print_to_Log(2, l2menu)
        -- ==== Build DeviceActionmenu
        -- do not build the actions menu when NoDevMenu == true. EG temp devices have no actions
        if _G.dtgmenu_submenus[submenu].NoDevMenu or Level ~= 'devicemenu' or i ~= devicename then
          return
        end
        --
        SwitchType = _G.dtgmenu_submenus[submenu].buttons[devicename].SwitchType
        Type = _G.dtgmenu_submenus[submenu].buttons[devicename].Type
        if (DTGBOT_type_status[Type] == nil or DTGBOT_type_status[Type].DisplayActions ~= false) then
          if (DTGBOT_type_status[Type] ~= nil) then
          end
          -- set reply markup to the override when provide
          l3menu = get.actions
          Print_to_Log(2, ' ---< ', Type, SwitchType, ' using replymarkup:', l3menu)
          -- else use the default reply menu for the SwitchType
          if (l3menu or '') == '' then
            l3menu = DTGMenu_Lang[_G.MenuLanguage].devices_options[SwitchType]
            -- use the type in case of devices like a Thermostat / Setpoint
            l3menu = l3menu or DTGMenu_Lang[_G.MenuLanguage].devices_options[Type]
            if not l3menu then
              Print_to_Log(2, '  !!! No default DTGMenu_Lang[_G.MenuLanguage].devices_options for SwitchType:', SwitchType, Type)
              l3menu = 'Aan,Uit'
            end
          end
          Print_to_Log(2, '   -< ' .. tostring(SwitchType) .. ' using replymarkup:', l3menu)
        end
      end)()
    end
  end
  -------------------------------------------------------------------
  -- Start building the proper layout for the 3 levels of menu items
  -------------------------------------------------------------------
  -- Always add "exit_menu" as last option to level1 menu
  l1menu = l1menu .. (DTGMenu_Lang[_G.MenuLanguage].command['exit_menu'] or 'Exit_Menu')
  ------------------------------
  -- start build total replymarkup
  local replymarkup = '{"keyboard":['
  ------------------------------
  -- Add level 3 first if needed
  ------------------------------
  if l3menu ~= '' then
    replymarkup = replymarkup .. dtgmenubottom.buildmenu(l3menu, ActMenuwidth, '') .. ','
    l1menu = DTGMenu_Lang[_G.MenuLanguage].command['back']
  end
  ------------------------------
  -- Add level 2 next if needed
  ------------------------------
  if l2menu ~= '' then
    local mwitdh = tonumber(DevMenuwidth or 3)
    if _G.dtgmenu_submenus[submenu].Menuwidth ~= nil then
      if tonumber(_G.dtgmenu_submenus[submenu].Menuwidth) >= 2 then
        mwitdh = tonumber(_G.dtgmenu_submenus[submenu].Menuwidth)
      end
    end
    replymarkup = replymarkup .. dtgmenubottom.buildmenu(l2menu, mwitdh, '') .. ','
    l1menu = DTGMenu_Lang[_G.MenuLanguage].command['back']
  end
  -------------------------------
  -- Add level 1 -- the main menu
  --------------------------------
  replymarkup = replymarkup .. dtgmenubottom.buildmenu(l1menu, (SubMenuwidth or 3), '') .. ']'
  -- add the resize menu option when desired. this sizes the keyboard menu to the size required for the options
  if AlwaysResizeMenu then
    --~     replymarkup = replymarkup .. ',"resize_keyboard":true'
    replymarkup = replymarkup .. ',"selective":true,"resize_keyboard":true'
  end
  -- Close the total statement
  replymarkup = replymarkup .. '}'

  -- save the full replymarkup and only send it again when it changed to minimize traffic to the TG client
  if bLastCommand['replymarkup'] == replymarkup then
    Print_to_Log(2, '  -< replymarkup: No update needed')
    replymarkup = ''
  else
    Print_to_Log(2, '  -< replymarkup:' .. replymarkup)
    bLastCommand['replymarkup'] = replymarkup
  end
  -- save menus
  bLastCommand['l1menu'] = l1menu -- rooms or submenu items
  bLastCommand['l2menu'] = l2menu -- Devices scenes or commands
  bLastCommand['l3menu'] = l3menu -- actions
  _G.Persistent[SendTo].bbLastCommand = bLastCommand
  return replymarkup, devicename
end

-- convert the provided menu options into a proper format for the replymenu
function dtgmenubottom.buildmenu(menuitems, width, extrachar)
  local replymenu = ''
  local t = 0
  Print_to_Log(2, ' process buildmenu:', menuitems, ' w:', width)
  for dev in string.gmatch(menuitems, '[^|,]+') do
    if t == width then
      replymenu = replymenu .. '],'
      t = 0
    end
    if t == 0 then
      replymenu = replymenu .. '["' .. extrachar .. '' .. dev .. '"'
    else
      replymenu = replymenu .. ',"' .. extrachar .. '' .. dev .. '"'
    end
    t = t + 1
  end
  if replymenu ~= '' then
    replymenu = replymenu .. ']'
  end
  Print_to_Log(2, '    -< buildmenu:', replymenu)
  return replymenu
end

-----------------------------------------------
--- END Build the reply_markup functions.
-----------------------------------------------
-----------------------------------------------
--- START the main process handler
-----------------------------------------------
function dtgmenubottom.handler(menu_cli, SendTo, commandline)
  -- handle incomming Telegram messages for DTGMENU Bottom

  if _G.Persistent[SendTo] then
    bLastCommand = _G.Persistent[SendTo].bbLastCommand or {}
  else
    bLastCommand = {}
    _G.Persistent[SendTo] = {}
  end

  -- initialise the user table in case it runs the firsttime
  bLastCommand['submenu'] = bLastCommand['submenu'] or ''
  bLastCommand['device'] = bLastCommand['device'] or ''
  bLastCommand['l1menu'] = bLastCommand['l1menu'] or ''
  bLastCommand['l2menu'] = bLastCommand['l2menu'] or ''
  bLastCommand['l3menu'] = bLastCommand['l3menu'] or ''
  bLastCommand['replymarkup'] = bLastCommand['replymarkup'] or ''
  bLastCommand['prompt'] = bLastCommand['prompt'] or 0
  --
  Print_to_Log(2, '==> dtgmenubottom Handle ->' .. menu_cli[2])
  Print_to_Log(2, ' => SendTo:', SendTo)
  local command = tostring(menu_cli[2])
  local lcommand = string.lower(command)
  commandline = commandline or ''
  local lcommandline = string.lower(commandline)
  local param1 = ''
  -- Retrieve the first parameter after the command in case provided.
  if menu_cli[3] ~= nil then
    param1 = tostring(menu_cli[3]) -- the command came in through the standard DTGBOT process
  elseif menu_cli[2] ~= nil then
    param1 = tostring(menu_cli[2]) -- the command came in via the DTGMENU exit routine
  end
  Print_to_Log(2, ' => commandline  :', commandline)
  Print_to_Log(2, ' => command      :', command)
  Print_to_Log(2, ' => param1       :', param1)
  Print_to_Log(2, ' => Lastmenu submenu  :', bLastCommand['l1menu'])
  Print_to_Log(2, ' => Lastmenu devs/cmds:', bLastCommand['l2menu'])
  Print_to_Log(2, ' => Lastmenu actions  :', bLastCommand['l3menu'])
  Print_to_Log(2, ' => Lastcmd prompt :', bLastCommand['prompt'])
  Print_to_Log(2, ' => Lastcmd submenu:', bLastCommand['submenu'])
  Print_to_Log(2, ' => Lastcmd device :', bLastCommand['device'])

  -------------------------------------------------
  -- set local variables
  -------------------------------------------------
  local lparam1 = string.lower(param1)
  local cmdisaction = ChkInTable(bLastCommand['l3menu'], commandline)
  local cmdisbutton = ChkInTable(bLastCommand['l2menu'], commandline)
  local cmdissubmenu = ChkInTable(bLastCommand['l1menu'], commandline)
  local response
  local replymarkup
  local status
  -- When the command is not a button or submenu and the last Action options contained a "?" and the current command is numeric we assume this is a manual set percentage
  if not (cmdisaction or cmdisbutton or cmdissubmenu) and ChkInTable(bLastCommand['l3menu'], '?') and string.find(command, '%d') then
    cmdisaction = true
  end
  Print_to_Log(2, ' =>      cmdisaction :', tostring(cmdisaction))

  -------------------------------------------------
  -- Process "start" or "menu" commands
  -------------------------------------------------
  -- Exit menu
  if lcommand == 'menu' and param1 == 'exit' then
    -- Clear menu end set exit messge
    response = DTGMenu_Lang[_G.MenuLanguage].text['exit']
    replymarkup = ''
    status = 1
    _G.Persistent[SendTo].bbLastCommand = nil
    Print_to_Log(0, '==< Exit main bottom menu')
    return status, response, replymarkup
  end

  -- Build main menu and return
  if cmdisaction == false and (
      lcommand == 'menu'
      or lcommand == DTGMenu_Lang[_G.MenuLanguage].command['menu']:lower()
      or lcommand == 'dtgmenu'
      or lcommand == 'showmenu'
      or lcommand == 'start'
    ) then
    _G.Persistent.UseDTGMenu = 1
    Print_to_Log(2, _G.Sprintf('_G.Persistent.UseDTGMenu=%s', _G.Persistent.UseDTGMenu))
    -- ensure the menu is always rebuild for Menu or Start
    bLastCommand['replymarkup'] = ''
    response = DTGMenu_translate_desc(_G.MenuLanguage, 'main', 'Select the submenu.')
    replymarkup = dtgmenubottom.makereplymenu(SendTo, 'mainmenu')
    bLastCommand['submenu'] = ''
    bLastCommand['device'] = ''
    bLastCommand['l2menu'] = ''
    bLastCommand['l3menu'] = ''
    Print_to_Log(2, '-< Show main menu')
    _G.Persistent[SendTo].bbLastCommand = bLastCommand
    return true, response, replymarkup
  end
  -- Hide main menu and return
  if cmdisaction == false and
    (
      lcommand == 'exit_menu'
      or (lcommandline == DTGMenu_Lang[_G.MenuLanguage].command['exit_menu'])
    ) then
    -- ensure the menu is always rebuild for Menu or Start
    response = DTGMenu_translate_desc(_G.MenuLanguage, 'exit', 'exit Menu type /menu to show it again.')
    bLastCommand['replymarkup'] = ''
    replymarkup = '{"remove_keyboard":true}'
    bLastCommand['submenu'] = ''
    bLastCommand['device'] = ''
    bLastCommand['l2menu'] = ''
    bLastCommand['l3menu'] = ''
    Print_to_Log(0, '-< hide main menu')
    _G.Persistent[SendTo].bbLastCommand = bLastCommand
    _G.Persistent.UseDTGMenu = 0
    Print_to_Log(2, _G.Sprintf('_G.Persistent.iUseDTGMenu=%s', _G.Persistent.UseDTGMenu))
    -- clean all messages but last when option MenuMessagesCleanOnExit is set true
    --    if MenuMessagesCleanOnExit then
    --      Telegram_Save_Clean_Messages(SendTo, 0, 0, 'menu', true)
    --    end

    return true, response, replymarkup
  end

  -------------------------------------------------
  -- process prompt input for "command" Type
  -------------------------------------------------
  -- When returning from a "prompt"action" then hand back to DTGBOT with previous command + param and reset keyboard to just MENU
  if bLastCommand['prompt'] == 1 then
    -- make small keyboard
    replymarkup = '{"keyboard":[["showmenu"]],"resize_keyboard":true}'
    response = ''
    -- add previous command to the current command
    _G.Persistent.promptcommandline = bLastCommand['device']
    bLastCommand['submenu'] = ''
    bLastCommand['device'] = ''
    bLastCommand['l1menu'] = ''
    bLastCommand['l2menu'] = ''
    bLastCommand['l3menu'] = ''
    bLastCommand['prompt'] = 0
    Print_to_Log(2, '-< prompt and found regular lua command and param was given. -> hand back to dtgbot to run', commandline)
    _G.Persistent[SendTo].bbLastCommand = bLastCommand
    return false, response, replymarkup
  end

  -----------------------------------------------------
  -- process when command is not known in the last menu
  -----------------------------------------------------
  -- hand back to DTGBOT reset keyboard to just MENU
  if cmdisaction == false and cmdisbutton == false and cmdissubmenu == false then
    -- make small keyboard
    replymarkup = '{"keyboard":[["showmenu"]],"resize_keyboard":true}'
    response = ''
    --    commandline = bLastCommand["device"] .. " " .. commandline
    bLastCommand['submenu'] = ''
    bLastCommand['device'] = ''
    bLastCommand['l1menu'] = ''
    bLastCommand['l2menu'] = ''
    bLastCommand['l3menu'] = ''
    bLastCommand['prompt'] = 0
    Print_to_Log(2, '-< Unknown as menu option so hand back to dtgbot to handle')
    _G.Persistent[SendTo].bbLastCommand = bLastCommand
    return false, response, replymarkup
  end

  -------------------------------------------------
  -- continue set local variables
  -------------------------------------------------
  local submenu = ''
  local devicename = ''
  local action = ''
  local status = false
  local response = ''
  local DeviceType = 'devices'
  local SwitchType = ''
  local idx = ''
  local realdevicename
  local Type = ''
  local dstatus = ''
  local MaxDimLevel = 0
  local LevelInt = 0
  if cmdissubmenu then
    submenu = commandline
  end

  ----------------------------------------------------------------------
  -- Set needed variable when the command is a known device menu button
  ----------------------------------------------------------------------
  if cmdisbutton then
    submenu = bLastCommand['submenu']
    devicename = command -- use command as that should only contain the values of the first param
    if _G.dtgmenu_submenus[submenu] == nil then
      Print_to_Log(2, 'Error not found  => submenu :', submenu)
    elseif _G.dtgmenu_submenus[submenu].buttons[devicename] == nil then
      Print_to_Log(2, 'Error not found  => devicename :', devicename)
    else
      realdevicename = _G.dtgmenu_submenus[submenu].buttons[devicename].Name or '?'
      Type = _G.dtgmenu_submenus[submenu].buttons[devicename].Type or '?'
      idx = _G.dtgmenu_submenus[submenu].buttons[devicename].idx or '?'
      DeviceType = _G.dtgmenu_submenus[submenu].buttons[devicename].DeviceType or '?'
      SwitchType = _G.dtgmenu_submenus[submenu].buttons[devicename].SwitchType or '?'
      MaxDimLevel = _G.dtgmenu_submenus[submenu].buttons[devicename].MaxDimLevel or 0
      LevelInt = _G.dtgmenu_submenus[submenu].buttons[devicename].LevelInt or 0
      dstatus = _G.dtgmenu_submenus[submenu].buttons[devicename].status or '?'
      Print_to_Log(2, ' => devicename :', devicename)
      Print_to_Log(2, ' => realdevicename :', realdevicename)
      Print_to_Log(2, ' => idx:', idx)
      Print_to_Log(2, ' => Type :', Type)
      Print_to_Log(2, ' => DeviceType :', DeviceType)
      Print_to_Log(2, ' => SwitchType :', SwitchType)
      Print_to_Log(2, ' => MaxDimLevel:', MaxDimLevel)
    end
    if DeviceType ~= 'command' then
      _, _, _, _, _, _, dstatus, LevelNames, LevelInt = Domo_Devinfo_From_Name(idx, realdevicename, DeviceType)
      Print_to_Log(2, ' => dstatus    :', dstatus)
      Print_to_Log(2, ' => LevelNames :', LevelNames)
      Print_to_Log(2, ' => LevelInt   :', LevelInt)
    end
  end
  ----------------------------------------------------------------------
  -- Set needed variables when the command is a known action menu button
  ----------------------------------------------------------------------
  if cmdisaction then
    submenu = bLastCommand['submenu']
    devicename = bLastCommand['device']
    realdevicename = _G.dtgmenu_submenus[submenu].buttons[devicename].Name
    action = lcommand -- use lcommand as that should only contain the values of the first param
    Type = _G.dtgmenu_submenus[submenu].buttons[devicename].Type
    idx = _G.dtgmenu_submenus[submenu].buttons[devicename].idx
    DeviceType = _G.dtgmenu_submenus[submenu].buttons[devicename].DeviceType
    SwitchType = _G.dtgmenu_submenus[submenu].buttons[devicename].SwitchType
    MaxDimLevel = _G.dtgmenu_submenus[submenu].buttons[devicename].MaxDimLevel
    LevelInt = _G.dtgmenu_submenus[submenu].buttons[devicename].LevelInt or MaxDimLevel
    if DeviceType ~= 'command' then
      _, _, _, _, _, _, dstatus, LevelNames, LevelInt = Domo_Devinfo_From_Name(idx, realdevicename, DeviceType)
      Print_to_Log(2, ' => dstatus    :', dstatus)
      Print_to_Log(2, ' => LevelNames :', LevelNames)
      Print_to_Log(2, ' => LevelInt   :', LevelInt)
    end
    Print_to_Log(2, ' => devicename :', devicename)
    Print_to_Log(2, ' => realdevicename :', realdevicename)
    Print_to_Log(2, ' => idx:', idx)
    Print_to_Log(2, ' => Type :', Type)
    Print_to_Log(2, ' => DeviceType :', DeviceType)
    Print_to_Log(2, ' => SwitchType :', SwitchType)
    Print_to_Log(2, ' => MaxDimLevel:', MaxDimLevel)
    Print_to_Log(2, ' => LevelNames :', LevelNames)
  end
  local replymarkup = ''
  local rellev = 0.0

  -------------------------------------------------
  -- process Type="command" (none devices/scenes
  -------------------------------------------------
  if Type == 'command' then
    --  when Button is pressed and Type "command" and no actions defined for the command then check for prompt and hand back without updating the keyboard
    if cmdisbutton and ChkEmpty(_G.dtgmenu_submenus[submenu].buttons[command].actions) then
      -- prompt for parameter when requested in the config
      if _G.dtgmenu_submenus[bLastCommand['submenu']].buttons[commandline].prompt then
        -- no prompt defined so simply return to dtgbot with status 0 so it will be performed and reset the keyboard to just MENU
        bLastCommand['device'] = commandline
        bLastCommand['prompt'] = 1
        _G.Persistent.prompt = true
        replymarkup = '{"force_reply":true}'
        bLastCommand['replymarkup'] = replymarkup
        status = true
        response = DTGMenu_translate_desc(_G.MenuLanguage, 'Specifyvalue')
        Print_to_Log(2, '-<1 found regular lua command that need Param ')
      else
        replymarkup = '{"keyboard":[["menu"]],"resize_keyboard":true}'
        status = false
        bLastCommand['submenu'] = ''
        bLastCommand['device'] = ''
        bLastCommand['l1menu'] = ''
        bLastCommand['l2menu'] = ''
        bLastCommand['l3menu'] = ''
        Print_to_Log(2, '-<1 found regular lua command. -> hand back to dtgbot to run')
      end
      _G.Persistent[SendTo].bbLastCommand = bLastCommand
      return status, response, replymarkup
    end

    --  when Action is pressed and Type "command"  then hand back to DTGBOT with previous command + param and reset keyboard to just MENU
    if devicename ~= '' and cmdisaction then
      --  if command is one of the actions of a command DeviceType hand it now back to DTGBOT
      replymarkup = '{"keyboard":[["menu"]],"resize_keyboard":true}'
      response = ''
      -- add previous command ot the current command
      commandline = bLastCommand['device'] .. ' ' .. commandline
      bLastCommand['submenu'] = ''
      bLastCommand['device'] = ''
      bLastCommand['l1menu'] = ''
      bLastCommand['l2menu'] = ''
      bLastCommand['l3menu'] = ''
      Print_to_Log(2, '-<2 found regular lua command. -> hand back to dtgbot to run:' .. bLastCommand['device'] .. ' ' .. commandline)
      _G.Persistent[SendTo].bbLastCommand = bLastCommand
      return false, response, replymarkup
    end
  end

  -------------------------------------------------
  -- process submenu button pressed
  -------------------------------------------------
  -- ==== Show Submenu when no device is specified================
  if cmdissubmenu then
    bLastCommand['submenu'] = submenu
    Print_to_Log(2, ' - Showing Submenu as no device name specified. submenu: ' .. submenu)
    local rdevicename
    -- when showactions is defined for a device, the devicename will be returned
    replymarkup, rdevicename = dtgmenubottom.makereplymenu(SendTo, 'submenu', submenu)
    -- not an menu command received
    if rdevicename ~= '' then
      bLastCommand['device'] = rdevicename
      Print_to_Log(2, ' -- Changed to devicelevel due to showactions defined for device ' .. rdevicename)
      response = DTGMenu_translate_desc(_G.MenuLanguage, 'SelectOptionwo') .. ' ' .. rdevicename
    else
      response = submenu .. ':' .. DTGMenu_translate_desc(_G.MenuLanguage, 'Select', 'Select option.')
    end
    Print_to_Log(2, '-< show options in submenu.')
    _G.Persistent[SendTo].bbLastCommand = bLastCommand
    return true, response, replymarkup
  end

  -------------------------------------------------------
  -- process device button pressed on one of the submenus
  -------------------------------------------------------
  if cmdisbutton then
    -- create reply menu and update table with device details
    replymarkup = dtgmenubottom.makereplymenu(SendTo, 'devicemenu', submenu, devicename)
    -- Save the current device
    bLastCommand['device'] = devicename
    local switchstatus = ''
    local found = 0
    if DeviceType == 'scenes' then
      --~     elseif Type == "Temp" or Type == "Temp + Humidity" or Type == "Wind" or Type == "Rain" then
      if Type == 'Group' then
        response = DTGMenu_translate_desc(_G.MenuLanguage, 'SelectGroup')
        Print_to_Log(2, '-< Show group options menu plus other devices in submenu.')
      else
        response = DTGMenu_translate_desc(_G.MenuLanguage, 'SelectScene')
        Print_to_Log(2, '-< Show scene options menu plus other devices in submenu.')
      end
    elseif DTGBOT_type_status[Type] ~= nil and DTGBOT_type_status[Type].DisplayActions == false then
      -- when temp device is selected them just return with resetting keyboard and ask to select device.
      response = DTGMenu_translate_desc(_G.MenuLanguage, 'Select', 'Select option.')
      Print_to_Log(2, "-< Don't do anything as a temp device was selected.")
    elseif DeviceType == 'devices' then
      -- Only show current status in the text when not shown on the action options
      if _G.dtgmenu_submenus[submenu].showdevstatus == 'y' then
        switchstatus = dstatus or ''
        if switchstatus ~= '' then
          switchstatus = tostring(switchstatus)
          switchstatus = switchstatus:gsub('Set Level: ', '')
        end
        -- Get the correct Label for a Selector switch which belongs to the level.
        if SwitchType == 'Selector' then
          switchstatus = getSelectorStatusLabel(LevelNames, LevelInt)
        end
        response = DTGMenu_translate_desc(_G.MenuLanguage, 'SelectOptionwo')
      else
        switchstatus = dstatus
        response = DTGMenu_translate_desc(_G.MenuLanguage, 'SelectOption') .. ' ' .. switchstatus
      end
      Print_to_Log(2, '-< Show device options menu plus other devices in submenu.')
    else
      response = DTGMenu_translate_desc('Select', _G.MenuLanguage, 'Select option.')
      Print_to_Log(2, '-< Show options menu plus other devices in submenu.')
    end
    _G.Persistent[SendTo].bbLastCommand = bLastCommand
    return true, response, replymarkup
  end

  -------------------------------------------------
  -- process action button pressed
  -------------------------------------------------
  -- Specials
  -------------------------------------------------
  if Type == 'Setpoint' or Type == 'Thermostat' then
    -- prompt for themperature
    if commandline == '?' then
      replymarkup = '{"force_reply":true}'
      bLastCommand['replymarkup'] = replymarkup
      response = DTGMenu_translate_desc(_G.MenuLanguage, 'Specifyvalue')
      Print_to_Log(2, '-< ' .. response)
      return true, response, replymarkup
    else
      if commandline == '+' or commandline == '-' then
        dstatus = dstatus:gsub('°C', '')
        dstatus = dstatus:gsub('°F', '')
        dstatus = dstatus:gsub(' ', '')
        commandline = tonumber(dstatus) + tonumber(commandline .. '0.5')
      end
      -- set thermostate temperature
      local dUrl = 'type=command&param=udevice&idx=' .. idx .. '&nvalue=0&svalue=' .. commandline
      local decoded_response, status = PerformDomoticzRequest(dUrl, 2)
      if decoded_response then
        response = 'Set ' .. realdevicename .. ' to ' .. commandline .. '°C'
      else
        response = 'Failed to Set ' .. realdevicename .. ' to ' .. commandline .. '°C'
      end
    end
  elseif SwitchType == 'Selector' then
    -------------------------------------------------
    -- regular On/Off/Set Level
    -------------------------------------------------
    local sfound, Selector_Option = ChkInTable(string.lower(LevelNames), string.lower(action))
    if sfound then
      if LevelNames:sub(1, 1) ~= '|' then
        Selector_Option = Selector_Option - 1
      end
      Selector_Option = (Selector_Option) * 10
      Print_to_Log(2, '    -> Selector Switch level found ', Selector_Option, LevelNames, action)
      response = Domo_sSwitchName(realdevicename, DeviceType, SwitchType, idx, 'Set Level ' .. Selector_Option)
    else
      response = 'Selector Option not found:' .. action
    end
  elseif ChkInTable(string.lower(DTGMenu_Lang[_G.MenuLanguage].switch_options['Off']), string.lower(action)) then
    response = Domo_sSwitchName(realdevicename, DeviceType, SwitchType, idx, 'Off')
  elseif ChkInTable(string.lower(DTGMenu_Lang[_G.MenuLanguage].switch_options['On']), string.lower(action)) then
    response = Domo_sSwitchName(realdevicename, DeviceType, SwitchType, idx, 'On')
  elseif string.find(action, '%d') then           -- assume a percentage is specified.
    -- calculate the proper level to set the dimmer
    action = action:gsub('%%', '')                -- remove % sign
    rellev = tonumber(action) * MaxDimLevel / 100 -- calculate the relative level
    action = string.format('%.0f', rellev)        -- remove decimals
    response = Domo_sSwitchName(realdevicename, DeviceType, SwitchType, idx, 'Set Level ' .. action)
  elseif action == '+' or action == '-' then
    -- calculate the proper level to set the dimmer
    dstatus = tostring(status2number(dstatus))
    Print_to_Log(2, ' + or - command: dstatus:', tonumber(dstatus), 'action..10:', action .. '10')
    action = tostring(tonumber(dstatus) + tonumber(action .. '10'))
    if tonumber(action) > 100 then
      action = '100'
    end
    if tonumber(action) < 0 then
      action = '0'
    end
    rellev = MaxDimLevel / 100 * tonumber(action) -- calculate the relative level
    action = string.format('%.0f', rellev)        -- remove decimals
    response = Domo_sSwitchName(realdevicename, DeviceType, SwitchType, idx, 'Set Level ' .. action)
  elseif commandline == '?' then
    -------------------------------------------------
    -- Unknown Action
    -------------------------------------------------
    replymarkup = '{"force_reply":true}'
    bLastCommand['replymarkup'] = replymarkup
    response = DTGMenu_translate_desc(_G.MenuLanguage, 'Specifyvalue')
    Print_to_Log(2, '-<' .. response)
    return true, response, replymarkup
  else
    response = DTGMenu_translate_desc(_G.MenuLanguage, 'UnknownChoice') .. action
  end
  replymarkup = dtgmenubottom.makereplymenu(SendTo, 'devicemenu', submenu, devicename)
  Print_to_Log(2, '-< ' .. response)
  return true, response, replymarkup
end

-----------------------------------------------
--- END the main process handler
-----------------------------------------------
return dtgmenubottom

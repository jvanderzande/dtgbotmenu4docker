_G.dtgmenuinline_version = '1.0 202505122058'
local dtgmenuinline = {}

--[[
	Script to support the Inline Menu option for DTGBOT
	Developer: jvdzande
	GNU GENERAL PUBLIC LICENSE
]]

------------------------------------------------------------------------------
--- START Build the reply_markup functions.
--  this function will build the requested menu layout and calls the function to retrieve the devices/scenes  details.
-------------------------------------------------------------------------------
function dtgmenuinline.makereplymenu(SendTo, Level, submenu, devicename)
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

  ------------------------------------------------------------------------------
  -- start the build of the 3 levels of the keyboard menu
  ------------------------------------------------------------------------------
  Print_to_Log(2, '  -> makereplymenu  Level:', Level, 'submenu', submenu, 'devicename', devicename)
  local t = 0
  local l1menu = ''
  local l2menu = ''
  local l3menu = ''
  local newbutton
  -- ==== Build Submenu - showing the Devices from the selected room of static config
  --                      This will also add the device status when showdevstatus=true for the option.
  Print_to_Log(2, '     submenu: ' .. submenu)
  if (Level == 'submenu' or Level == 'devicemenu')
    and _G.dtgmenu_submenus[submenu] and _G.dtgmenu_submenus[submenu].buttons then
    t = 0
    -- loop through all defined "buttons in the Config
    local DevMwitdh = DevMenuwidth or 3
    if _G.dtgmenu_submenus[submenu].Menuwidth ~= nil then
      if tonumber(_G.dtgmenu_submenus[submenu].Menuwidth) >= 2 then
        DevMwitdh = tonumber(_G.dtgmenu_submenus[submenu].Menuwidth, 10)
      end
    end
    --
    for i, get in orderedPairs(_G.dtgmenu_submenus[submenu].buttons) do
      -- process all found devices in _G.dtgmenu_submenus buttons table
      (function()
        if i == '' then
          Print_to_Log(2, '  - Skipping Empty button name:' .. JSON.encode(get))
          return
        end
        local switchstatus = ''
        local callback_prompt = ''
        Print_to_Log(2, '   - Submenu item:', i, _G.dtgmenu_submenus[submenu].showdevstatus, get.DeviceType, get.idx, get.status)
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
              switchstatus = ' ' .. getSelectorStatusLabel(get.actions, LevelInt)
            else
              switchstatus = tostring(switchstatus)
              switchstatus = switchstatus:gsub('Set Level: ', '')
              switchstatus = switchstatus:gsub(' ', '')
              switchstatus = ' ' .. switchstatus
            end
          end
        end
        -- add marker at the end of the callback that we use to send a prompt for input when we receive this
        if get.prompt then
          callback_prompt = ' *prompt*'
        end
        -- add to the total menu string for later processing
        -- t, newbutton = dtgmenuinline.buildmenuitem(string.sub(i, 1, (ButtonTextwidth or 20) - string.len(switchstatus)) .. switchstatus, 'menu', submenu .. ' ' .. i, DevMwitdh, t)
        t, newbutton = dtgmenuinline.buildmenuitem(string.sub(i, 1, (ButtonTextwidth or 20) - string.len(switchstatus)) .. switchstatus, 'menu', submenu .. ' ' .. i .. callback_prompt, DevMwitdh, t)
        l2menu = l2menu .. newbutton
        -- show the actions menu immediately for this devices since that is requested in the config
        -- this can avoid having the press 2 button before getting to the actions menu
        if get.showactions and devicename == '' then
          Print_to_Log(2, '    - Changing to Device action level due to showactions:', i)
          Level = 'devicemenu'
          devicename = i
        end
        -- ==== Build DeviceActionmenu
        -- do not build the actions menu when NoDevMenu == true. EG temp devices have no actions
        if _G.dtgmenu_submenus[submenu].NoDevMenu or Level ~= 'devicemenu' or i ~= devicename then
          return
        end
        -- do not build the actions menu when DisplayActions == false on Device level. EG temp devices have no actions
        SwitchType = _G.dtgmenu_submenus[submenu].buttons[devicename].SwitchType
        Type = _G.dtgmenu_submenus[submenu].buttons[devicename].Type
        if (DTGBOT_type_status[Type] == nil or DTGBOT_type_status[Type].DisplayActions ~= false) then
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
              l3menu = DTGMenu_Lang[_G.MenuLanguage].devices_options['On/Off']
            end
          end
          Print_to_Log(2, '   -< ' .. tostring(SwitchType) .. ' using replymarkup:', l3menu)
        end
      end)()
    end
    l2menu = l2menu .. ']'
  end
  -------------------------------------------------------------------
  -- Start building the proper layout for the 3 levels of menu items
  -------------------------------------------------------------------
  ------------------------------
  -- start build total replymarkup
  local replymarkup = '{"inline_keyboard":['
  ------------------------------
  -- Add level 3 first if needed
  ------------------------------
  if l3menu ~= '' then
    replymarkup = replymarkup .. dtgmenuinline.buildmenu(l3menu, ActMenuwidth, 'menu ' .. submenu .. ' ' .. devicename) .. ','
    Print_to_Log(3, '>> inline L3:', l3menu, 'replymarkup:', replymarkup)
  end
  ------------------------------
  -- Add level 2 next if needed
  ------------------------------
  if l2menu ~= '' then
    replymarkup = replymarkup .. l2menu .. ','
    Print_to_Log(3, '>> inline L2:', l2menu, 'replymarkup:', replymarkup)
  end
  -------------------------------
  -- Add level 1 -- the main menu
  --------------------------------
  t = 0
  SubMenuwidth = SubMenuwidth or 3
  if (FullMenu or l2menu == '') then
    --~   Sort & Loop through the compiled options returned by PopulateMenuTab
    for i, get in orderedPairs(_G.dtgmenu_submenus) do
      (function()
        -- ==== Build mainmenu - level 1 which is the bottom part of the menu, showing the Rooms and static definitins
        -- Avoid adding start and menu as these are handled separately.
        -- Don't used this for menu or strat command
        if i == 'menu' and i == 'start' then return end
        -- Check if ChatID is allowed for this item
        if get.whitelist ~= '' and not ChkInTable(get.whitelist, SendTo) then return end
        -- test if anything is specifically defined for this user in Telegram-RoomsShowninMenu`
        AllowButton = true
        if get.RoomNumber then
          if MenuWhiteList[SendTo] then
            if MenuWhiteList[SendTo][get.RoomNumber] or MenuWhiteList[SendTo]['99'] or (MenuWhiteList[SendTo]['0'] and MenuWhiteList['0'][get.RoomNumber]) then
              Print_to_Log(2, SendTo .. ' MenuWhiteList Check room:' .. (get.RoomNumber) .. '/' .. i .. ' is Whitelisted. -> add room button')
            else
              Print_to_Log(2, SendTo .. ' MenuWhiteList Check room:' .. (get.RoomNumber) .. '/' .. i .. ' not Whitelisted! -> skip room button')
              AllowButton = false
            end
          elseif MenuWhiteList['0'] then
            if MenuWhiteList['0'] and MenuWhiteList['0'][get.RoomNumber] then
              Print_to_Log(2, 'Default MenuWhiteList Check room:' .. (get.RoomNumber) .. '/' .. i .. ' is Whitelisted. -> add room button')
            else
              Print_to_Log(2, 'Default MenuWhiteList Check room:' .. (get.RoomNumber) .. '/' .. i .. ' not Whitelisted! -> skip room button')
              AllowButton = false
            end
          else
            Print_to_Log(2, SendTo .. ' No 0(Default) or SendTo Whitelist defined so -> add to menu: ' .. i)
          end
        else
          Print_to_Log(2, SendTo .. ' Fixed item/No Roomnumber -> add to menu: ' .. i)
        end
        -- only add button when needed/allowed
        if AllowButton then
          t, newbutton = dtgmenuinline.buildmenuitem(i, 'menu', i, SubMenuwidth, t)
          Print_to_Log(3, ' -> t:', t, 'newbutton:', newbutton)
          if newbutton then
            l1menu = l1menu .. newbutton
          end
        end
      end)()
    end
  end
  -- add Menu & Exit
  local menuexit = (DTGMenu_Lang[_G.MenuLanguage].command['exit_menu'] or 'Exit Menu')
  local menuhome = (DTGMenu_Lang[_G.MenuLanguage].command['home'] or 'Home')
  t, newbutton = dtgmenuinline.buildmenuitem(menuhome, 'menu', 'menu', SubMenuwidth, t)
  --  t, newbutton = dtgmenuinline.buildmenuitem('Menu', 'menu', 'menu', SubMenuwidth, t)
  l1menu = l1menu .. newbutton
  t, newbutton = dtgmenuinline.buildmenuitem(menuexit, 'menu', 'exit', SubMenuwidth, t)
  --  t, newbutton = dtgmenuinline.buildmenuitem('Exit', 'menu', 'exit', SubMenuwidth, t)
  l1menu = l1menu .. newbutton
  l1menu = l1menu .. ']'
  replymarkup = replymarkup .. l1menu .. ']'
  --(not working with inline keyboards (yet?). add the resize menu option when desired. this sizes the keyboard menu to the size required for the options
  --~   replymarkup = replymarkup..',"resize_keyboard":true'
  --~   replymarkup = replymarkup..',"hide_keyboard":true,"selective":false'
  replymarkup = replymarkup .. '}'
  Print_to_Log(3, '>> inline L1:', l1menu, 'replymarkup:', replymarkup)
  Print_to_Log(0, '  -< replymarkup:' .. replymarkup)
  -- save menus
  return replymarkup, devicename
end

-- convert the provided menu options into a proper format for the replymenu
function dtgmenuinline.buildmenu(menuitems, width, prefix)
  local replymenu = ''
  local t = 0
  Print_to_Log(2, '      process buildmenu:', menuitems, ' w:', width)
  for dev in string.gmatch(menuitems, '[^|,]+') do
    if t == width then
      replymenu = replymenu .. '],'
      t = 0
    end
    if t == 0 then
      replymenu = replymenu .. '[{"text":"' .. dev .. '","callback_data":"' .. prefix .. ' ' .. dev .. '"}'
    else
      replymenu = replymenu .. ',{"text":"' .. dev .. '","callback_data":"' .. prefix .. ' ' .. dev .. '"}'
    end
    t = t + 1
  end
  if replymenu ~= '' then
    replymenu = replymenu .. ']'
  end
  Print_to_Log(2, '    -< buildmenu:', replymenu)
  return replymenu
end

-- convert the provided menu options into a proper format for the replymenu
function dtgmenuinline.buildmenuitem(menuitem, prefix, Callback, width, t)
  local replymenu = ''
  Print_to_Log(2, '       process buildmenuitem:', menuitem, prefix, Callback, ' w:' .. (width or 'nil'), ' t:' .. (t or 'nil'))
  if t == width then
    replymenu = replymenu .. '],'
    t = 0
  end
  if t == 0 then
    replymenu = replymenu .. '['
  else
    replymenu = replymenu .. ','
  end
  replymenu = replymenu .. '{"text":"' .. menuitem .. '","callback_data":"' .. prefix .. ' ' .. Callback .. '"}'
  t = t + 1
  Print_to_Log(2, '    -< buildmenuitem:', 't:' .. t, replymenu)
  return t, replymenu
end

-----------------------------------------------
--- END Build the reply_markup functions.
-----------------------------------------------
--
-----------------------------------------------
--- START the main process handler
-----------------------------------------------
function dtgmenuinline.handler(menu_cli, SendTo)
  -- rebuilt the total commandline after dtgmenu
  local commandline = ''    -- need to rebuild the commndline for feeding back
  local commandlinex = ''   -- need to rebuild the commndline for feeding back
  local parsed_command = {} -- rebuild table without the dtgmenu command in case we need to hand it back as other command
  local menucmd = false
  local status
  local response
  local replymarkup
  local bLastCommand = {}
  if _G.Persistent[SendTo] then
    bLastCommand = _G.Persistent[SendTo].bbLastCommand or {}
  else
    bLastCommand = {}
    _G.Persistent[SendTo] = {}
  end


  for nbr, param in pairs(menu_cli) do
    Print_to_Log(2, 'nbr:', nbr, ' param:', param)
    -- check if
    if nbr == 2 and param:lower() == 'menu' then
      menucmd = true
    end
    if nbr > 2 then
      commandline = commandline .. param .. ' '
    end
    -- build commandline without menu to feedback when it is an LUA/BASH command defined in the Menu
    if nbr < 2 or nbr > 3 then
      table.insert(parsed_command, param)
      commandlinex = commandlinex .. param .. ' '
    end
  end
  commandline = tostring(commandline)
  commandline = string.sub(commandline, 1, string.len(commandline) - 1)
  local lcommandline = string.lower(commandline)
  --
  Print_to_Log(0, '==> dtgmenuinline Handle -->' .. commandline)
  Print_to_Log(2, ' => SendTo:', SendTo)

  --
  local param1       = ''
  local param2       = ''
  local param3       = ''
  local param4       = ''
  local cmdisaction  = false
  local cmdisbutton  = false
  local cmdissubmenu = false

  -- get all parameters
  if menu_cli[3] ~= nil then
    param1       = tostring(menu_cli[3])
    cmdissubmenu = true
    cmdisbutton  = false
    cmdisaction  = false
  end
  if param1 == '' then
    param1 = 'menu'
  end
  --
  if menu_cli[4] ~= nil then
    param2       = tostring(menu_cli[4])
    cmdissubmenu = false
    cmdisbutton  = true
    cmdisaction  = false
  end
  if menu_cli[5] ~= nil then
    param3       = tostring(menu_cli[5])
    cmdissubmenu = false
    cmdisbutton  = false
    cmdisaction  = true
  end
  --
  if menu_cli[6] ~= nil then
    param4 = tostring(menu_cli[6])
  end
  Print_to_Log(2, ' => commandline  :', commandline)
  Print_to_Log(2, ' => commandlinex :', commandlinex)
  Print_to_Log(2, ' => param1       :', param1)
  Print_to_Log(2, ' => param2       :', param2)
  Print_to_Log(2, ' => param3       :', param3)
  Print_to_Log(2, ' => param4       :', param4)
  Print_to_Log(2, ' => cmdisaction :', cmdisaction)
  Print_to_Log(2, ' => cmdisbutton :', cmdisbutton)
  Print_to_Log(2, ' => cmdissubmenu:', cmdissubmenu)

  -- return when not a menu item and hand it back to be processed as regular command
  if not menucmd then
    if (_G.Persistent.inlinemenu and _G.Persistent.inlinemenu.prompt) then
      _G.Persistent.prompt = true
      _G.Persistent.promptcommandline = _G.Persistent.inlinemenu.command
      commandlinex = _G.Persistent.inlinemenu.command .. ' ' .. menu_cli[2]
      _G.Persistent.inlinemenu.command = ''
      _G.Persistent.inlinemenu.prompt = false
      Print_to_Log(0, '==<1 found regular lua command with prompted device. -> hand back to dtgbot to run', commandlinex)
    else
      Print_to_Log(0, '==<1 found regular lua command. -> hand back to dtgbot to run', commandlinex, parsed_command[2])
    end
    return false, '', ''
  end

  -------------------------------------------------
  -- Process "start" or "menu" commands
  -------------------------------------------------
  -- Build main menu and return
  if param1:lower() == 'menu'
    or param1:lower() == DTGMenu_Lang[_G.MenuLanguage].command['menu']:lower()
    or param1:lower() == 'dtgmenu'
    or param1:lower() == 'start'
    or (cmdisbutton and (
      param2:lower() == 'menu'
      or param2:lower() == DTGMenu_Lang[_G.MenuLanguage].command['menu']:lower()
      or param2:lower() == 'dtgmenu')
    ) then
    response = DTGMenu_Lang[_G.MenuLanguage].text['main']
    replymarkup = dtgmenuinline.makereplymenu(SendTo, 'mainmenu')
    status = 1
    _G.Persistent.UseDTGMenu = 1
    _G.Persistent[SendTo].iLastcommand = 'menu'
    Print_to_Log(0, '==< Show main menu')
    return status, response, replymarkup
  end
  -------------------------------------------------
  -- Process "exit" command
  -------------------------------------------------
  -- Exit menu
  if param1 == 'exit' then
    -- Clear menu end set exit message
    response = DTGMenu_Lang[_G.MenuLanguage].text['exit']
    replymarkup = ''
    status = 1
    -- reset vars
    _G.Persistent.UseDTGMenu = 0
    _G.Persistent[SendTo].iLastcommand = ''

    Print_to_Log(0, '==< Exit main inline menu')
    return status, response, replymarkup
  end

  -------------------------------------------------
  -- continue set local variables
  -------------------------------------------------
  local submenu        = param1
  local devicename     = param2
  local action         = param3
  local status         = 0
  local response       = ''
  local DeviceType     = 'devices'
  local SwitchType     = ''
  local idx            = ''
  local Type           = ''
  local realdevicename = ''
  local dstatus        = ''
  local rellev         = 0
  local MaxDimLevel    = 0
  local LevelNames     = ''
  local LevelInt       = 0
  if cmdissubmenu then
    submenu = param1
  end

  local dummy
  ----------------------------------------------------------------------
  -- Set needed variables when the command is a known action menu button
  ----------------------------------------------------------------------
  if cmdisbutton or cmdisaction then
    Print_to_Log(2, ' => submenu :', submenu)
    Print_to_Log(2, ' => devicename :', devicename)
    Print_to_Log(2, ' => _G.dtgmenu_submenus[submenu] :', _G.dtgmenu_submenus[submenu])
    Print_to_Log(2, ' => _G.dtgmenu_submenus[submenu].buttons[devicename] :', _G.dtgmenu_submenus[submenu].buttons[devicename])
    realdevicename = _G.dtgmenu_submenus[submenu].buttons[devicename].Name
    Type           = _G.dtgmenu_submenus[submenu].buttons[devicename].Type
    idx            = _G.dtgmenu_submenus[submenu].buttons[devicename].idx
    DeviceType     = _G.dtgmenu_submenus[submenu].buttons[devicename].DeviceType
    SwitchType     = _G.dtgmenu_submenus[submenu].buttons[devicename].SwitchType
    MaxDimLevel    = _G.dtgmenu_submenus[submenu].buttons[devicename].MaxDimLevel
    Print_to_Log(2, ' => realdevicename :', realdevicename)
    Print_to_Log(2, ' => idx:', idx)
    Print_to_Log(2, ' => Type :', Type)
    Print_to_Log(2, ' => DeviceType :', DeviceType)
    Print_to_Log(2, ' => SwitchType :', SwitchType)
    Print_to_Log(2, ' => MaxDimLevel :', MaxDimLevel)
    if DeviceType ~= 'command' then
      dummy, dummy, dummy, dummy, dummy, dummy, dstatus, LevelNames, LevelInt = Domo_Devinfo_From_Name(idx, realdevicename, DeviceType)
      Print_to_Log(2, ' => dstatus    :', dstatus)
      Print_to_Log(2, ' => LevelNames :', LevelNames)
      Print_to_Log(2, ' => LevelInt   :', LevelInt)
    end
  end

  local jresponse
  local decoded_response
  local replymarkup = ''

  -------------------------------------------------
  -- process Type="command" (none devices/scenes
  -------------------------------------------------
  if Type == 'command' then
    if (param3 == '*prompt*') then
      _G.Persistent.inlinemenu = {}
      _G.Persistent.inlinemenu.prompt = true
      _G.Persistent.inlinemenu.command = param2
      replymarkup = '{"force_reply":true}'
      status = 0
      response = DTGMenu_translate_desc(_G.MenuLanguage, 'Specifyvalue')
      Print_to_Log(2, '-<1 found regular lua command that need Param ')
      return true, 'specify device', replymarkup, true
    end

    if cmdisaction or (cmdisbutton and ChkEmpty(_G.dtgmenu_submenus[submenu].buttons[devicename].actions)) then
      status = 0
      replymarkup, _ = dtgmenuinline.makereplymenu(SendTo, 'submenu', submenu)
      Print_to_Log(0, '==<2 found regular lua command. -> hand back to dtgbot to run', commandlinex, parsed_command[2])
      _G.Persistent[SendTo]['iLastcommand'] = parsed_command[2]
      return false, '', replymarkup
    end
  end
  -------------------------------------------------
  -- process submenu button pressed
  -------------------------------------------------
  -- ==== Show Submenu when no device is specified================
  if cmdissubmenu then
    Print_to_Log(2, ' - Showing Submenu as no device name specified. submenu: ' .. submenu)
    local rdevicename
    -- when showactions is defined for a device, the devicename will be returned
    replymarkup, rdevicename = dtgmenuinline.makereplymenu(SendTo, 'submenu', submenu)
    -- not an menu command received
    if rdevicename ~= '' then
      Print_to_Log(2, ' -- Changed to devicelevel due to showactions defined for device ' .. rdevicename)
      response = DTGMenu_Lang[_G.MenuLanguage].text['SelectOptionwo'] .. ' ' .. rdevicename
    else
      response = submenu .. ':' .. DTGMenu_Lang[_G.MenuLanguage].text['Select']
    end
    status = 1
    Print_to_Log(0, '==< show options in submenu.')
    return status, response, replymarkup
  end

  -------------------------------------------------------
  -- process device button pressed on one of the submenus
  -------------------------------------------------------
  status = 1
  if cmdisbutton then
    -- create reply menu and update table with device details
    replymarkup = dtgmenuinline.makereplymenu(SendTo, 'devicemenu', submenu, devicename)
    local switchstatus = ''
    local found = 0
    if DeviceType == 'scenes' then
      if Type == 'Group' then
        response = DTGMenu_Lang[_G.MenuLanguage].text['SelectGroup']
        Print_to_Log(0, '==< Show group options menu plus other devices in submenu.')
      else
        response = DTGMenu_Lang[_G.MenuLanguage].text['SelectScene']
        Print_to_Log(0, '==< Show scene options menu plus other devices in submenu.')
      end
    elseif DTGBOT_type_status[Type] ~= nil and DTGBOT_type_status[Type].DisplayActions == false then
      -- when temp device is selected them just return with resetting keyboard and ask to select device.
      status = 1
      response = DTGMenu_Lang[_G.MenuLanguage].text['SelectOption'] .. dstatus
      Print_to_Log(2, "==< Don't do anything as a temp device was selected.")
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
        response = DTGMenu_Lang[_G.MenuLanguage].text['SelectOptionwo'] .. devicename .. '(' .. switchstatus .. ')'
      else
        switchstatus = dstatus
        response = DTGMenu_Lang[_G.MenuLanguage].text['SelectOptionwo'] .. devicename .. ' ' .. DTGMenu_Lang[_G.MenuLanguage].text['SelectOption'] .. ' ' .. switchstatus
      end
      Print_to_Log(0, '==< Show device options menu plus other devices in submenu.')
    else
      response = DTGMenu_Lang[_G.MenuLanguage].text['Select']
      Print_to_Log(0, '==< Show options menu plus other devices in submenu.')
    end

    return status, response, replymarkup
  end

  -------------------------------------------------
  -- process action button pressed
  -------------------------------------------------
  -- Specials
  -------------------------------------------------
  Print_to_Log(2, '   -> Start Action:' .. action)

  if Type == 'SetPoint' or Type == 'Thermostat' then
    -- Set Temp + or - .5 degrees
    local saction = tostring(action)
    if action == '+' or action == '-' then
      dstatus = dstatus:gsub('°C', '')
      dstatus = dstatus:gsub('°F', '')
      dstatus = dstatus:gsub(' ', '')
      saction = tostring(tonumber(dstatus) + tonumber(action .. '0.5'))
    end
    -- set thermostat temperature
    local dUrl = 'type=command&param=udevice&idx=' .. idx .. '&nvalue=0&svalue=' .. saction
    local decoded_response, status = PerformDomoticzRequest(dUrl, 2)
    if decoded_response then
      response = 'Set ' .. realdevicename .. ' to ' .. action
    else
      response = 'Faild to Set ' .. realdevicename .. ' to ' .. action
    end
  elseif SwitchType == 'Selector' then
    local sfound, Selector_Option = ChkInTable(LevelNames, action)
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
    -------------------------------------------------
    -- regular On/Off/Set Level
    -------------------------------------------------
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
    -- calculate the proper leve lto set the dimmer
    dstatus = tostring(status2number(dstatus))
    Print_to_Log(2, ' + or - command: dstatus:', tonumber(dstatus), 'action..10:', action .. '10')
    action = tostring(tonumber(dstatus) + tonumber(action .. '10'))
    if tonumber(action) > 100 then action = '100' end
    if tonumber(action) < 0 then action = '0' end
    rellev = MaxDimLevel / 100 * tonumber(action) -- calculate the relative level
    action = string.format('%.0f', rellev)        -- remove decimals
    response = Domo_sSwitchName(realdevicename, DeviceType, SwitchType, idx, 'Set Level ' .. action)
    -------------------------------------------------
    -- Unknown Action
    -------------------------------------------------
  else
    response = DTGMenu_Lang[_G.MenuLanguage].text['UnknownChoice'] .. action
  end
  status = 1

  replymarkup = dtgmenuinline.makereplymenu(SendTo, 'devicemenu', submenu, devicename)
  Print_to_Log(0, '==< ' .. response)
  return status, response, replymarkup
end

-----------------------------------------------
--- END the main process handler
-----------------------------------------------
return dtgmenuinline

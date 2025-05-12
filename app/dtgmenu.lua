_G.dtgmenu_version = '1.0 202505122058'
-- ============================================================================================================
-- ============================================================================================================
-- Menu script which enables the option in DTGBOT to use a reply keyboard to perform actions on:
--  - all defined devices per defined ROOM in Domotics.
--
-- programmer: Jos van der Zande
-- ============================================================================================================
-----------------------------------------------------------------------------------------------------------------------
-- these are the different formats of reply_markup. looksimple but needed a lot of testing before it worked :)
--
-- >show the custom keyboard and stay up after option selection first 3 on the first line and menu on the second
--	reply_markup={"keyboard":[["opt 1","opt 2","opt 3"],["menu"]]}
-- >show the custom keyboard and minimises after option selection
--	reply_markup={"keyboard":[["opt 1","opt 2","opt 3"],["menu"]],"one_time_keyboard":true}
-- >Remove the custom keyboard
--old	reply_markup={"hide_keyboard":true}
--new  reply_markup={"remove_keyboard":true}
--old	reply_markup={"hide_keyboard":true,"selective":false}
-- >force normal keyboard to ask for input
--	reply_markup={"force_reply":true}
--	reply_markup={"force_reply":true,"selective":false}
-- >Resize the keyboard
--	reply_markup={"keyboard":[["menu"]],"resize_keyboard":true}
--  reply_markup={"keyboard":[["opt 1","opt 2","opt 3"],["menu"]],"resize_keyboard":true}
--// ExportString( string )
--// returns a "Lua" portable version of the string
--------------------------------------
-- Include config
--------------------------------------
local config = ''

_G.DTGMenu_Static_submenus = DTGMenu_Static_submenus or {}
_G.MenuLanguage = MenuLanguage or _G.DomoLanguage
_G.DTGMenu_Lang = DTGMenu_Lang or {}

-- Defaults Bottom menu type
_G.SubMenuwidth = SubMenuwidth or 3
_G.DevMenuwidth = DevMenuwidth or 3
_G.ActMenuwidth = ActMenuwidth or 8
_G.AlwaysResizeMenu = AlwaysResizeMenu == true

-- Inline Menu  defaults
_G.UseInlineMenu = false
_G.ButtonTextwidth = ButtonTextwidth or 22
_G.ActMenuwidth = ActMenuwidth or 8
_G.FullMenu = FullMenu == true


DTGil = require('dtgmenuinline')
DTGbo = require('dtgmenubottom')

-- definition used by DTGBOT
DTGMenu_Modules = {} -- global!

-- If Domoticz Language is not used then revert to English

if DTGMenu_Lang[_G.MenuLanguage] == nil then
  Print_to_Log(0, 'Domoticz Language ' .. (_G.MenuLanguage or '?') .. ' is not available for dtgmenus. Using English.')
  _G.MenuLanguage = 'en'
end
-- ensure all fields are set properly
DTGMenu_Lang[_G.MenuLanguage] = DTGMenu_Lang[_G.MenuLanguage] or {}
DTGMenu_Lang[_G.MenuLanguage].command = DTGMenu_Lang[_G.MenuLanguage].command or {}
DTGMenu_Lang[_G.MenuLanguage].switch_options = DTGMenu_Lang[_G.MenuLanguage].switch_options or {}
DTGMenu_Lang[_G.MenuLanguage].devices_options = DTGMenu_Lang[_G.MenuLanguage].devices_options or {}
DTGMenu_Lang[_G.MenuLanguage].text = DTGMenu_Lang[_G.MenuLanguage].text or {}

-- we do not allow spaces in these commands so replace them by underscore
DTGMenu_Lang[_G.MenuLanguage].command['back'] = (DTGMenu_Lang[_G.MenuLanguage].command['back'] or 'Back'):gsub(' ', '_')
DTGMenu_Lang[_G.MenuLanguage].command['menu'] = (DTGMenu_Lang[_G.MenuLanguage].command['menu'] or 'Menu'):gsub(' ', '_')
DTGMenu_Lang[_G.MenuLanguage].command['exit_menu'] = (DTGMenu_Lang[_G.MenuLanguage].command['exit_menu'] or 'Exit_Menu'):gsub(' ', '_')

DTGMenu_Lang[_G.MenuLanguage].switch_options['On'] = DTGMenu_Lang[_G.MenuLanguage].switch_options['On'] or 'On,Close,Start'
DTGMenu_Lang[_G.MenuLanguage].switch_options['Off'] = DTGMenu_Lang[_G.MenuLanguage].switch_options['Off'] or 'Off,Open'

DTGMenu_Lang[_G.MenuLanguage].devices_options['Blinds'] = DTGMenu_Lang[_G.MenuLanguage].devices_options['Blinds'] or 'Open,Close'
DTGMenu_Lang[_G.MenuLanguage].devices_options['Blinds Percentage'] = DTGMenu_Lang[_G.MenuLanguage].devices_options['Blinds Percentage'] or 'Open,25%,50%,75%,Close'
DTGMenu_Lang[_G.MenuLanguage].devices_options['Scene'] = DTGMenu_Lang[_G.MenuLanguage].devices_options['Scene'] or 'Start'
DTGMenu_Lang[_G.MenuLanguage].devices_options['Group'] = DTGMenu_Lang[_G.MenuLanguage].devices_options['Group'] or 'Off,On'
DTGMenu_Lang[_G.MenuLanguage].devices_options['On/Off'] = DTGMenu_Lang[_G.MenuLanguage].devices_options['On/Off'] or 'Off,On'
DTGMenu_Lang[_G.MenuLanguage].devices_options['Push On Button'] = DTGMenu_Lang[_G.MenuLanguage].devices_options['Push On Button'] or 'On'
DTGMenu_Lang[_G.MenuLanguage].devices_options['Dimmer'] = DTGMenu_Lang[_G.MenuLanguage].devices_options['Dimmer'] or 'Off,On,25%,50%,75%,99%,?'
DTGMenu_Lang[_G.MenuLanguage].devices_options['SetPoint'] = DTGMenu_Lang[_G.MenuLanguage].devices_options['SetPoint'] or '17,18,19,20,20.5,21,21.5,-,+,?'
DTGMenu_Lang[_G.MenuLanguage].devices_options['Thermostat'] = DTGMenu_Lang[_G.MenuLanguage].devices_options['Thermostat'] or '17,18,19,20,20.5,21,21.5,-,+,?'

DTGMenu_Lang[_G.MenuLanguage].text['start'] = DTGMenu_Lang[_G.MenuLanguage].text['start'] or 'Hi, welcome to Domoticz.'
DTGMenu_Lang[_G.MenuLanguage].text['main'] = DTGMenu_Lang[_G.MenuLanguage].text['main'] or 'Select the submenu.'
DTGMenu_Lang[_G.MenuLanguage].text['exit'] = DTGMenu_Lang[_G.MenuLanguage].text['exit'] or 'Exit'
DTGMenu_Lang[_G.MenuLanguage].text['Select'] = DTGMenu_Lang[_G.MenuLanguage].text['Select'] or 'Select option.'
DTGMenu_Lang[_G.MenuLanguage].text['SelectGroup'] = DTGMenu_Lang[_G.MenuLanguage].text['SelectGroup'] or 'Select the group option.'
DTGMenu_Lang[_G.MenuLanguage].text['SelectScene'] = DTGMenu_Lang[_G.MenuLanguage].text['SelectScene'] or 'Start scene?'
DTGMenu_Lang[_G.MenuLanguage].text['SelectOptionwo'] = DTGMenu_Lang[_G.MenuLanguage].text['SelectOptionwo'] or 'Select new status.'
DTGMenu_Lang[_G.MenuLanguage].text['SelectOption'] = DTGMenu_Lang[_G.MenuLanguage].text['SelectOption'] or 'Select new status. Current status='
DTGMenu_Lang[_G.MenuLanguage].text['Specifyvalue'] = DTGMenu_Lang[_G.MenuLanguage].text['Specifyvalue'] or 'Type value'
DTGMenu_Lang[_G.MenuLanguage].text['Switched'] = DTGMenu_Lang[_G.MenuLanguage].text['Switched'] or 'Change'
DTGMenu_Lang[_G.MenuLanguage].text['UnknownChoice'] = DTGMenu_Lang[_G.MenuLanguage].text['UnknownChoice'] or 'Unknown option:'


------------------------------------------------------------------------------
-- Start Functions to SORT the TABLE
-- Copied from internet location: -- http://lua-users.org/wiki/SortedIteration
-- These are used to sort the items on the menu alphabetically
-------------------------------------------------------------------------------
-- declare local variables
local function __genOrderedIndex(t)
  local orderedIndex = {}
  for key in pairs(t) do
    table.insert(orderedIndex, key)
  end
  table.sort(orderedIndex)
  return orderedIndex
end

function table.map_length(t)
  local c = 0
  for k, v in pairs(t) do
    c = c + 1
  end
  return c
end

local function orderedNext(t, state)
  -- Equivalent of the next function, but returns the keys in the alphabetic
  -- order. We use a temporary ordered key table that is stored in the
  -- table being iterated.

  local key = nil
  if state == nil then
    -- the first time, generate the index
    t.__orderedIndex = __genOrderedIndex(t)
    key = t.__orderedIndex[1]
  else
    -- fetch the next value
    for i = 1, table.map_length(t.__orderedIndex) do
      if t.__orderedIndex[i] == state then
        key = t.__orderedIndex[i + 1]
      end
    end
  end

  if key then
    return key, t[key]
  end

  -- no more value to return, cleanup
  t.__orderedIndex = nil
  return
end

function _G.orderedPairs(t)
  -- Equivalent of the pairs() function on tables. Allows to iterate
  -- in order
  return orderedNext, t, nil
end

-------------------------------------------------------------------------------
-- END Functions to SORT the TABLE
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Start Function to set the new devicestatus. needs changing moving to on
-------------------------------------------------------------------------------

-- Create a button per room.
function MakeRoomMenus(iLevel, iSubmenu)
  iSubmenu = tostring(iSubmenu)
  Print_to_Log(2, 'Creating Room Menus:', iLevel, iSubmenu)
  local room_number = 0
  local room_name = ''
  local mbuttons = {}

  ------------------------------------
  -- process all Rooms
  ------------------------------------
  for rname, rnumber in pairs(Roomlist) do
    room_name = rname
    room_number = rnumber
    local rbutton = room_name:gsub(' ', '_')
    --
    -- only get all details per Room in case we are not building the Mainmenu.
    -- Else
    --Group change    if iLevel ~= "mainmenu"
    --Group change    and iSubmenu == rbutton or "[scene] ".. iSubmenu == rbutton then
    -----------------------------------------------------------
    -- retrieve all devices/scenes for this plan from Domoticz
    -----------------------------------------------------------
    local Devsinplan = _G.Domo_Device_List('plandevices', room_number) or {}
    local DIPresult = Devsinplan['result'] or {}
    Print_to_Log(2, 'For room ' .. room_name .. '/' .. room_number .. ' got some devices and/or scenes')
    _G.dtgmenu_submenus[rbutton] = { RoomNumber = room_number, whitelist = '', showdevstatus = 'y', buttons = {} }
    -----------------------------------------------------------
    -- process all found entries in the plan record
    -----------------------------------------------------------
    if type(DIPresult) == 'table' then
      mbuttons = {}
      local function GetStatusFromTables(idx, name, type)
        Print_to_Log(9, 'GetStatusFromTables: ' .. (idx or '?') .. ' ' .. (name or '??') .. ' ' .. (type or '?') .. ' ')
        local record = nil
        if idx then
          if type == 'devices' then
            record = _G.DevicelistByIDX[idx]
          elseif type == 'scenes' then
            record = _G.ScenelistByIDX[idx]
          end
        end
        if name and not record then
          if type == 'devices' then
            record = _G.DevicelistByName[idx]
          elseif type == 'scenes' then
            record = _G.ScenelistByName[idx]
          end
        end
        local DeviceName = ''
        local DeviceType = ''
        local Type = ''
        local SwitchType = ''
        local MaxDimLevel = 0
        local Status = ''
        local LevelNames = ''
        if record then
          DeviceName = record['Name'] or ''
          DeviceType = type or ''
          Type = record['Type'] or ''
          SwitchType = record['SwitchType'] or ''
          MaxDimLevel = record['MaxDimLevel'] or 0
          Status = record['Status'] or ''
          LevelNames = record['LevelNames'] or ''
        end
        return idx, DeviceName, DeviceType, Type, SwitchType, MaxDimLevel, Status, LevelNames
      end

      for d, DIPrecord in pairs(DIPresult) do
        if type(DIPrecord) == 'table' then
          local DeviceType = 'devices'
          local SwitchType = ''
          local Type = ''
          local Status = ''
          local LevelNames = ''
          local MaxDimLevel = 100
          local idx = DIPrecord.devidx
          local name = DIPrecord.Name
          local DUMMY = { 'result' }
          DUMMY['result'] = {}
          Print_to_Log(2, ' - Plan record:', DIPrecord.Name, DIPrecord.devidx, DIPrecord.type)
          if DIPrecord.type == 1 then
            Print_to_Log(9, '--> scene record')
            --idx, DeviceName, DeviceType, Type, SwitchType, MaxDimLevel, Status = Domo_Devinfo_From_Name(idx, '', 'scenes')
            idx, DeviceName, DeviceType, Type, SwitchType, MaxDimLevel, Status = GetStatusFromTables(idx, '', 'scenes')
          else
            Print_to_Log(9, '--> device record idx:' .. idx)
            --idx, DeviceName, DeviceType, Type, SwitchType, MaxDimLevel, Status, LevelNames = Domo_Devinfo_From_Name(idx, '', 'devices')
            idx, DeviceName, DeviceType, Type, SwitchType, MaxDimLevel, Status, LevelNames = GetStatusFromTables(idx, '', 'devices')
            Print_to_Log(9, '-#> device info: idx ' .. idx)
            Print_to_Log(9, '-#> device info DeviceName:' .. DeviceName)
            Print_to_Log(9, '-#> device info DeviceType:' .. DeviceType)
            Print_to_Log(9, '-#> device info Type:' .. Type)
            Print_to_Log(9, '-#> device info SwitchType:' .. SwitchType)
            Print_to_Log(9, '-#> device info MaxDimLevel:' .. MaxDimLevel)
            Print_to_Log(9, '-#> device info Status:' .. Status)
            if SwitchType == 'Selector' then
              if string.find(LevelNames, '[|,]+') then
                Print_to_Log(2, '--  < 4.9700 selector switch levelnames: ', LevelNames)
              else
                LevelNames = _G.MIME.unb64(LevelNames)
                Print_to_Log(2, '--  >= 4.9700  decoded selector switch levelnames: ', LevelNames)
              end
            end
            Print_to_Log(9, '-#> x device info LevelNames:' .. LevelNames)
          end
          -- Remove the name of the room from the device if it is present and any susequent Space or Hyphen or underscore
          local button = string.gsub(DeviceName, room_name .. '[%s-_]*', '')
          -- But reinstate it if less than 3 letters are left
          if #button < 3 then
            button = DeviceName
          end
          -- Remove any spaces from the device name and replace them by underscore.
          button = string.gsub(button, '%s+', '_')
          -- Add * infront of button name when Scene or Group
          if DeviceType == 'scenes' then
            button = '*' .. button
          end
          -- fill the button table records with all required fields
          mbuttons[button] = {}
          -- Retrieve id white list
          mbuttons[button].whitelist = '' -- Not implemented for Dynamic menu: Whitelist number(s) for this device, blank is ALL
          -- check for LevelNames
          if LevelNames == '' or LevelNames == nil then
            mbuttons[button].actions = '' -- Not implemented for Dynamic menu: Hardcoded Actions for the device
          else
            mbuttons[button].actions = LevelNames:gsub('|', ',')
          end
          mbuttons[button].prompt = false      -- Not implemented for Dynamic menu: Prompt TG client for the variable text
          mbuttons[button].showactions = false -- Not implemented for Dynamic menu: Show Device action menu right away when its menu is selected
          mbuttons[button].Name = DeviceName   -- Original devicename needed to be able to perform the "Set new status" commands
          mbuttons[button].idx = idx
          mbuttons[button].DeviceType = DeviceType
          mbuttons[button].SwitchType = SwitchType
          mbuttons[button].Type = Type
          mbuttons[button].MaxDimLevel = MaxDimLevel -- Level required to calculate the percentage for devices that do not use 100 for 100%
          mbuttons[button].Status = Status
          Print_to_Log(2, ' Dynamic ->', rbutton, button, DeviceName .. '=' .. idx, DeviceType, Type, SwitchType, MaxDimLevel, Status)
        end
      end
    end
    --Group change    end
    -- Save the Room entry with optionally all its devices/sceens
    Print_to_Log(9, '$$$$$> ' .. rbutton .. ' ->RoomButtons:' .. JSON.encode(mbuttons))
    _G.dtgmenu_submenus[rbutton] = { RoomNumber = room_number, whitelist = '', showdevstatus = 'y', buttons = mbuttons }
  end
end

--
-----------------------------------------------
--- END population the table
-----------------------------------------------

-----------------------------------------------
--- Start Misc Function to support the process
-----------------------------------------------
-- get translation
function DTGMenu_translate_desc(mLanguage, input, default)
  mLanguage = mLanguage or 'en'
  input = input or '?'
  local response = default or input
  if (DTGMenu_Lang[mLanguage] == nil) then
    Print_to_Log(0, '  - Language not defined in config', mLanguage)
  elseif (DTGMenu_Lang[mLanguage].text[input] == nil) then
    Print_to_Log(0, '  - Language keyword not defined in config:', mLanguage, input)
  else
    response = DTGMenu_Lang[mLanguage].text[input]
  end
  return response
end

-- function to return a numeric value for a device Status.
function _G.status2number(switchstatus)
  -- translater the switchstatus to a number from 0-100
  switchstatus = tostring(switchstatus)
  Print_to_Log(2, '--> status2number Input switchstatus', switchstatus)
  if switchstatus == 'Off' or switchstatus == 'Open' then
    switchstatus = 0
  elseif switchstatus == 'On' or switchstatus == 'Closed' then
    switchstatus = 100
  else
    -- retrieve number from: "Set Level: 49 %"
    switchstatus = switchstatus:gsub('Set Level: ', '')
    switchstatus = switchstatus:gsub(' ', '')
    switchstatus = switchstatus:gsub('%%', '')
  end
  Print_to_Log(2, '--< status2number Returned switchstatus', switchstatus)
  return switchstatus
end

-- SCAN through provided delimited string for the second parameter
function ChkInTable(itab, idev)
  local cnt = 0
  if itab ~= nil then
    for dev in string.gmatch(itab, '[^|,]+') do
      cnt = cnt + 1
      if dev == idev then
        Print_to_Log(2, '-< ChkInTable found: ' .. idev, cnt, itab)
        return true, cnt
      end
    end
  end
  Print_to_Log(2, '-< ChkInTable not found: ' .. idev, cnt, itab)
  return false, 0
end

-- SCAN through provided delimited string for the second parameter
function _G.getSelectorStatusLabel(itab, ival)
  Print_to_Log(2, ' getSelectorStatusLabel: ', ival, itab)
  local cnt = 0
  -- Required when the string starts with a ",x,x"!
  itab = ' ' .. itab
  --
  if itab ~= nil then
    -- convert 0;10;20;30  etc  to 1;2;3;5  etc
    local cval = ival
    if cval > 9 then
      cval = (cval / 10)
    end
    -- get the label and return
    for lbl in string.gmatch(itab, '[^|,]+') do
      if cnt == cval then
        Print_to_Log(2, '-< getSelectorStatusLabel found: ' .. lbl, cnt, itab)
        return lbl
      end
      cnt = cnt + 1
    end
  end
  Print_to_Log(2, '-< getSelectorStatusLabel not found: ' .. ival, cnt, itab)
  return ival .. '?'
end

-----------------------------------------------
-- this function will rebuild the _G.dtgmenu_submenus table each time it is called.
-- It will first read through the static menu items defined in DTGMENU.CRG in table DTGMenu_Static_submenus
-- It will then call the MakeRoomMenus() function to add the dynamic options from Domoticz Room configuration
function PopulateMenuTab(iLevel, iSubmenu)
  local buttonnbr = 0
  Print_to_Log(2, _G.Sprintf('####  Start populating Menu Array.  ilevel:%s  iSubmenu:$s', iLevel, iSubmenu))
  -- reset menu table and rebuild
  _G.dtgmenu_submenus = {}

  Print_to_Log(2, 'Submenu table including Static buttons defined in Config:', iLevel, iSubmenu)
  for submenu, get in pairs(DTGMenu_Static_submenus) do
    local mbuttons = {}
    Print_to_Log(2, '=>', submenu, get.whitelist, get.showdevstatus, get.Menuwidth)
    if DTGMenu_Static_submenus[submenu].buttons ~= nil then
      --Group change      if iLevel ~= "mainmenu" and iSubmenu == submenu then
      for button, dev in pairs(DTGMenu_Static_submenus[submenu].buttons) do
        -- Get device/scene details
        local idx, DeviceName, DeviceType, Type, SwitchType, MaxDimLevel, Status = Domo_Devinfo_From_Name(9999, button, 'anything')
        -- fill the button table records with all required fields
        -- Remove any spaces from the device name and replace them by underscore.
        button = string.gsub(button, '%s+', '_')
        -- Add * infront of button name when Scene or Group
        if DeviceType == 'scenes' then
          button = '*' .. button
        end
        mbuttons[button] = {}
        mbuttons[button].whitelist = dev.whitelist     -- specific for the static config: Whitelist number(s) for this device, blank is ALL
        mbuttons[button].actions = dev.actions         -- specific for the static config: Hardcoded Actions for the device
        mbuttons[button].prompt = dev.prompt           -- specific for the static config: Prompt TG cleint for the variable text
        mbuttons[button].showactions = dev.showactions -- specific for the static config: Show Device action menu right away when its menu is selected
        mbuttons[button].Name = DeviceName
        mbuttons[button].idx = idx
        mbuttons[button].DeviceType = DeviceType
        mbuttons[button].SwitchType = SwitchType
        mbuttons[button].Type = Type
        mbuttons[button].MaxDimLevel = MaxDimLevel -- Level required to calculate the percentage for devices that do not use 100 for 100%
        mbuttons[button].Status = Status
        Print_to_Log(2, ' static ->', submenu, button, DeviceName, idx, DeviceType, Type, SwitchType, MaxDimLevel, Status)
      end
    else
      Print_to_Log(2, ' static entry has no buttons ->', JSON.encode(DTGMenu_Static_submenus[submenu]))
    end
    -- Save the submenu entry with optionally all its devices/sceens
    _G.dtgmenu_submenus[submenu] = {
      whitelist = get.whitelist,
      RoomNumber = get.RoomNumber,
      showdevstatus = get.showdevstatus,
      Menuwidth = get.Menuwidth,
      buttons = mbuttons
    }
    --Group change     end
  end
  Print_to_Log(2, '##$$$$$ static buttons generated ->', JSON.encode(dtgmenu_submenus, { indent = true }))
  -- Add the room/plan menu's after the static is populated
  MakeRoomMenus(iLevel, iSubmenu)
  Print_to_Log(2, '####  End populating Menu Array')
  return
end

--
-- Simple check function whether the input field is nil or empty ("")
function ChkEmpty(itxt)
  if itxt == nil or itxt == '' then
    return true
  end
  return false
end

-----------------------------------------------
--- END Misc Function to support the process
-----------------------------------------------

function DTGMenu_Modules.get_commands()
  return dtgmenu_commands
end

-- define the menu table and initialize the table first time
Menuidx = 0
_G.dtgmenu_submenus = {}
_G.buttons = {}
_G.dtgmenu_commands = {}

-- process all previous found devices & scenes


-- Set the appropriate handler to use for the keyboard
if UseInlineMenu then
  _G.dtgmenu_commands = {
    ['menu'] = { handler = DTGil.handler, description = 'Will start menu functionality.' },
    ['dtgmenu'] = { handler = DTGil.handler, description = 'Will start menu functionality.' }
  }
else
  _G.dtgmenu_commands = {
    ['menu'] = { handler = DTGbo.handler, description = 'Will start menu functionality.' },
    ['dtgmenu'] = { handler = DTGbo.handler, description = 'Will start menu functionality.' }
  }
end

return DTGMenu_Modules

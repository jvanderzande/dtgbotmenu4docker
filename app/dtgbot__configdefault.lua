-- These are default dtgbotmenu settings that shouldn't be changed
_G.dtgconfigdefault_version = '1.0 202505122059'

BotLogLevel                     = 1    --# Loglevel 0-99

---- chatid's table allowed to use DTGBOT
ChatIDWhiteList                 = {}

MenuMessagesCleanOnExit         = true -- Enable(true)/disable(false):Show only the last x commands, and remove the rest.
MenuMessagesMaxShown            = 2    -- Menu:Show only the last x commands, and remove the rest. 0=show all
OtherMessagesMaxShown           = 8    -- Other: Show only the last x commands, and remove the rest. 0=show all

-- bottomMenu  defaults
SubMenuwidth = 3 -- default max number of horizontal options in the mainmenu, can be overridded by Menuwidth per item.
DevMenuwidth = 3 -- default max number of horizontal options in the submenu
ActMenuwidth = 8 -- default max number of horizontal options in the menu
AlwaysResizeMenu = true

-- InlineMenu  defaults
ButtonTextwidth = 22 -- Set the max text you want on the button. the Devicename will be truncated to fit the status in case requested.
FullMenu = false     -- this determines whether to show all levels or skip the Level2 when level3 is shown

---------------------------------------------------------------
--> define the mainmenu menuitems.
DTGMenu_Static_submenus         = {}
DTGMenu_Static_submenus['Misc'] = {
	whitelist = '',
	showdevstatus = 'n',
	Menuwidth = 3,
	buttons = {
		['_ReloadConfig']   = { whitelist = '' },
		['_ToggleKeyboard'] = { whitelist = '' },
		['systemstatus']    = { whitelist = '' },
	}
}

MenuLanguage = 'en'
--=====(Language tables)========================================================
---------------------------------
-- define the options for each Language
-- ["XX"]  Languages code
-- 		["switch_options"] 	=  "Action,Action'
-- 		["devices_options"] =  SwitchType as known in Domoticz
--   		 actions			=""  Default actions to be shown in the menu per device
-- 		["text"] 			=  Translation of standard reply text
--   		 "keywords"			="xxx"  Text to be used for the keyword
--

DTGMenu_Lang                    = {}
-- English (Default) definition
DTGMenu_Lang['en']              = {
	command = {
		['back'] = 'Back',
		['menu'] = 'menu',           -- define alternative for starting the menu
		['exit_menu'] = 'Exit Menu', -- define alternative for exiting the menu.. also used as button text
		['home'] = 'Home',           -- define alternative for Home for inline menus
	},
	switch_options = {
		['On'] = 'On,Close,Start',
		['Off'] = 'Off,Open',
	},
	devices_options = {
		['Blinds'] = 'Open,Close',
		['Blinds Percentage'] = 'Open,25%,50%,75%,Close',
		['Scene'] = 'Start',
		['Group'] = 'Off,On',
		['On/Off'] = 'Off,On',
		['Push On Button'] = 'On',
		['Dimmer'] = 'Off,On,25%,50%,75%,99%,?',
		['Setpoint'] = '15,18,19,20,20.5,21,21.5,-,+,?',
		['Thermostat'] = '15,18,19,20,20.5,21,21.5,-,+,?',
	},
	text = {
		['start'] = 'Hi, welcome to Domoticz.',
		['main'] = 'Select the submenu.',
		['exit'] = 'Exit Menu, type /menu to show it again',
		['Select'] = 'Select option.',
		['SelectGroup'] = 'Select the group option.',
		['SelectScene'] = 'Start scene?',
		['SelectOptionwo'] = 'Select new status.',
		['SelectOption'] = 'Select new status. Current status=',
		['Specifyvalue'] = 'Type value',
		['Switched'] = 'Change',
		['UnknownChoice'] = 'Unknown option:',
	},
}

-- Spanish definition
DTGMenu_Lang['es'] = {
	command = {
		['back'] = 'atrás',
		['menu'] = 'menu',           -- define alternative for starting the menu
		['exit_menu'] = 'Exit_Menu', -- define alternative for exiting the menu.. also used as button text
		['home'] = 'Home',           -- define alternative for Home for inline menus
	},
	switch_options = {
		['On'] = 'On,Abierto,Encendido,Activado',
		['Off'] = 'Off,Cerrado,Apagado,Desactivado',
	},
	devices_options = {
		['Blinds'] = 'Abrir,Cerrar',
		['Blinds Percentage'] = 'Abrir,25%,50%,75%,Cerrar,-,+',
		['Scene'] = 'Activar',
		['Group'] = 'Off,On',
		['On/Off'] = 'Off,On',
		['Dimmer'] = 'Off,On,25%,50%,75%,99%,-,+',
		['Setpoint'] = '17,18,19,20,20.5,21,21.5,-,+,?',
		['Thermostat'] = '17,18,19,20,20.5,21,21.5,-,+,?',
	},
	text = {
		['start'] = 'Hola, bienvenido a Domoticz.',
		['main'] = 'Elija un submenu.',
		['exit'] = 'Menu cerrado. escriba /menu para abrirlo de nuevo.',
		['Select'] = 'Elija de nuevo',
		['SelectGroup'] = 'Seleccione un grupo.',
		['SelectScene'] = 'Activar la escena?',
		['SelectOptionwo'] = 'Seleccione ',
		['SelectOption'] = 'Estado actual: ',
		['Specifyvalue'] = 'Indique el valor',
		['Switched'] = 'Modificado',
		['UnknownChoice'] = 'Opcion desconocida: ',
	},
}

-- Italian definition --
DTGMenu_Lang["it"] = {
	command = {
			["back"] = "Indietro",
			["menu"] = "Avvia_Menu",
			["exit_menu"] = "Chiudi_Menu",
			['home'] = 'Home',
		},
	switch_options = {
		["On"] = 'On,Chiuso,Start',
		["Off"] = 'Off,Aperto',
	},
	devices_options = {
		["Blinds"] = 'Aperto,Chiuso',
		["Blinds Percentage"] = 'Aperto,25%,50%,75%,Chiuso',
		["Scene"] = 'Start',
		["Group"] = 'Off,On',
		["On/Off"] = 'Off,On',
		["Push On Button"] = 'On',
		["Dimmer"] = 'Off,On,30%,40%,50%,60%,70%,80%,90%,99%,?',
		["Thermostat"] = '20,20.5,21,21.5,22,23,24,25,?',
	},
	text={
		["start"] = "Ciao, benvenuto.",
		["main"] = "Scegli sotto menu.",
		["exit"] = "Chiudi Menu, digita /menu per visualizzarlo di nuovo",
		["Select"] = "Scegli opzione.",
		["SelectGroup"] = "Seleziona opzione del gruppo.",
		["SelectScene"] = "Avvio scena?",
		["SelectOptionwo"] = "Seleziona nuovo stato.",
		["SelectOption"] = "Stato corrente=",
		["Specifyvalue"] = "Inserisci valore",
		["Switched"] = "Cambia",
		["UnknownChoice"] = "Opzione non riconosciuta:",
	},
}

-- Nederlands definition --
DTGMenu_Lang['nl']  = {
	command = {
		['back'] = 'Terug',
		['menu'] = 'Start_Menu',      -- define alternative for starting the menu
		['exit_menu'] = 'Stop_menu',  -- define alternative for exiting the menu.. also used as button text
		['home'] = 'Thuis',            -- define alternative for Home for inline menus
	},
	switch_options = {
		['On'] = 'On,Aan,Start,Activate,Dicht,Neer',
		['Off'] = 'Off,Uit,Disarm,Open,Op',
	},
	devices_options = {
		['Blinds'] = 'Open,Dicht',
		['Blinds Percentage'] = 'Op,25%,50%,75%,Neer',
		['Scene'] = 'Start',
		['Group'] = 'Uit,Aan',
		['On/Off'] = 'Uit,Aan',
		['Push On Button'] = 'Aan',
		['Dimmer'] = 'Uit,Aan,20%,40%,60%,80%,99%,-,+',
		['Setpoint'] = '17,18,19,20,20.5,21,21.5,-,+,?',
		['Thermostat'] = '17,18,19,20,20.5,21,21.5,-,+,?',
	},
	text = {
		['start'] = 'Hallo, welkom bij Domoticz.',
		['main'] = 'Kies een submenu.',
		['exit'] = 'Sluit Menu, /menu laat hem weer zien.',
		['Select'] = 'Kies een optie.',
		['SelectGroup'] = 'Kies optie voor de groep.',
		['SelectScene'] = 'Start scene?',
		['SelectOptionwo'] = 'Kies nieuwe status.',
		['SelectOption'] = 'Kies nieuwe status. Huidige stand=',
		['Specifyvalue'] = 'Geef waarde',
		['Switched'] = 'Verander',
		['UnknownChoice'] = 'Onbekende keuze:',
	},
}

---------------------------------------------------------------------------------------------------
--> define the status field to be reported on the button and whether this Type needs an action menu
-- Defaul: Status = Status and Actions = True
--  ["xxx"] =  Type of Device
--     status   ="fieldname"  Fielddname to be used for the status value
--     status2  ="fieldname"  option second Fielddname to be used for the secong status value
--     StatusSuffix  ="xx"  character(s) to add behind the status.
--     DisplayActions  ="fieldname"  Filedname to be used for the status value
DTGBOT_type_status  = {
	['P1 Smart Meter'] = {
		['Status'] = { { Data = '' } },
		['DisplayActions'] = false,
	},
	['Air Quality'] = {
		['Status'] = { { Data = '' } },
		['DisplayActions'] = false,
	},
	['Lux'] = {
		['Status'] = { { Data = '' } },
		['DisplayActions'] = false,
	},
	['Rain'] = {
		['Status'] = { { Rain = 'mm/h' } },
		['DisplayActions'] = false,
	},
	['Wind'] = {
		['Status'] = { { Speed = 'km/h' } },
		['DisplayActions'] = false,
	},
	['Temp'] = {
		['Status'] = { { Temp = '°C' } },
		['DisplayActions'] = false,
	},
	['Temp + Humidity'] = {
		['Status'] = { { Temp = '°C' }, { Humidity = '%' } },
		['DisplayActions'] = false,
	},
	['Temp + Humidity + Baro'] = {
		['Status'] = { { Temp = '°C' }, { Humidity = '%' }, { Barometer = 'hPa' }, { ForecastStr = '' } },
		['DisplayActions'] = false,
	},
	['Temp + Baro'] = {
		['Status'] = { { Temp = '°C' }, { Barometer = 'hPa' }, { ForecastStr = '' } },
		['DisplayActions'] = false,
	},
	['Setpoint'] = {
		['Status'] = { { SetPoint = '°C' } },
		['DisplayActions'] = true,
	},
	['Thermostat'] = {
		['Status'] = { { SetPoint = '°C' } },
		['DisplayActions'] = true,
	},
	['UV'] = {
		['Status'] = { { UVI = 'uvi' } },
		['DisplayActions'] = false,
	},
	['General'] = {
		['Status'] = { { Data = '' } },
		['DisplayActions'] = false,
	},
}

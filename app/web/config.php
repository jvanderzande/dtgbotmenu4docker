<?php
// Configuration Page for DTGBOT
$StartOption = '';
$StartOption = isset($_GET['StartOption']) ? $_GET['StartOption'] : $StartOption;
$StartOption = isset($_POST['StartOption']) ? $_POST['StartOption'] : $StartOption;
?>
<html>

<head>
    <meta charset="utf-8">
    <meta http-equiv="content-type" content="text/html; charset=UTF-8">
    <script src="js/jquery.min.js"></script>
    <script src="js/jquery-ui.min.js"></script>
    <title>DTGBOT Config Editor</title>
    <link rel="icon" href="/DTGBOT.svg" type="image/svg+xml">

    <!-- CodeMirror css -->
    <link rel="stylesheet" type="text/css" href="css/codemirror.css">
    <!-- CodeMirror source -->
    <script src="js/codemirror.js"></script>
    <!-- add an add-on -->
    <script src="js/matchbrackets.js"></script>
    <script src="js/active-line.js"></script>
    <script src="js/continuecomment.js"></script>
    <script src="js/comment.js"></script>
    <script src="js/javascript.js"></script>

    <style>
        body {
            background-color: #eaeaea;
        }

        td {
            vertical-align: top;
        }
        .CodeMirror-selected {
            background-color:rgb(243, 255, 8) !important;
        }
        .CodeMirror {
            font-family: monospace;
            font-size: 14px;
            border: solid 1px #000;
        }
    </style>


</head>

<script type="text/javascript">
    ChatIDWhiteList_config = null;
    DomoRooms = '';
    DomoConfig =''
    ConfigChangesActive = false;
    ConfigLastUpdated = 0;
    LastJSONEdit = ""
    DomoOK = false;
    TelegramOK = false;
    StartOption = '<?php echo $StartOption; ?>';
    let DTGMenu_Lang_editor = null;
    let DTGMenu_Static_submenus_editor = null;
    let DTGBOT_type_status_editor = null;
    $(document).ready(function() {
        // Get current config and wait for it to finish before setting up the gui
        GetInitConfigDone = false;
        Config_Action("get", '')
        var initVar = setInterval(function() {
            if (GetInitConfigDone) {
                clearInterval(initVar);
            }
        }, 200);


        // optional do initial check at startup, but we now check the log for messages to determine the status
        GetDomoRooms();
        ConfigChangesActive = false;

        setTimeout(function() {
            ConfigChangesActive = false;
            document.getElementById("resultstatus").value = 'All loaded.'
        }, 1000);
    });

    function updateconfigtable(init=false) {
        // Build config input fields in Table
        // optional do initial check at startup, but we now check the log for messages to determine the status
        if (!document.getElementById("MenuMessagesCleanOnExit")) {
            // Build the restconfig screen
            var ctable1 = document.getElementById('tRestConfig1');
            // Row 1
            var row = ctable1.insertRow();
            row.insertCell(0).innerHTML = 'MenuMessagesCleanOnExit:';
            row.cells[0].onmouseover=function() {HelpText('MenuMessagesCleanOnExit')};
            row.insertCell(1).innerHTML =  `<input type="checkbox" id="MenuMessagesCleanOnExit" onchange="ChangeConfigInput('MenuMessagesCleanOnExit','bool')" onmouseover="HelpText(this.id)" size="1" value="" />`;
            row.insertCell(2).innerHTML =  `<b>BottomMenu</b> & <b>InlineMenu</b> settings`;
            row.cells[2].colSpan = 4;

            //Row 2
            row = ctable1.insertRow();
            row.insertCell(0).innerHTML = 'MenuMessagesMaxShown:';
            row.cells[0].onmouseover=function() {HelpText('MenuMessagesMaxShown')};
            row.insertCell(1).innerHTML = `<input type="input" id="MenuMessagesMaxShown" onchange="ChangeConfigInput('MenuMessagesMaxShown','number')" onmouseover="HelpText(this.id)" size="1" value="" />`;
            row.insertCell(2).innerHTML = 'SubMenuwidth:';
            row.cells[2].onmouseover=function() {HelpText('SubMenuwidth')};
            row.insertCell(3).innerHTML = `<input type="input" id="SubMenuwidth" onchange="ChangeConfigInput('SubMenuwidth','number')" onmouseover="HelpText(this.id)" size="1" value="" />`;
            row.insertCell(4).innerHTML = 'ButtonTextwidth:';
            row.cells[4].onmouseover=function() {HelpText('ButtonTextwidth')};
            row.insertCell(5).innerHTML = `<input type="input" id="ButtonTextwidth" onchange="ChangeConfigInput('ButtonTextwidth','number')" onmouseover="HelpText(this.id)" size="1" value="" />`;

            //Row 3
            row = ctable1.insertRow();
            row.insertCell(0).innerHTML = 'OtherMessagesMaxShown:';
            row.cells[0].onmouseover=function() {HelpText('OtherMessagesMaxShown')};
            row.insertCell(1).innerHTML = `<input type="input" id="OtherMessagesMaxShown" onchange="ChangeConfigInput('OtherMessagesMaxShown','number')" onmouseover="HelpText(this.id)" size="1" value="" />`;
            row.insertCell(2).innerHTML = 'DevMenuwidth:';
            row.cells[2].onmouseover=function() {HelpText('DevMenuwidth')};
            row.insertCell(3).innerHTML = `<input type="input" id="DevMenuwidth" onchange="ChangeConfigInput('DevMenuwidth','number')" onmouseover="HelpText(this.id)" size="1" value="" />`;
            row.insertCell(4).innerHTML = 'FullMenu:';
            row.cells[4].onmouseover=function() {HelpText('FullMenu')};
            row.insertCell(5).innerHTML =  `<input type="checkbox" id="FullMenu" onchange="ChangeConfigInput('FullMenu','bool')" onmouseover="HelpText(this.id)" size="1" value="" />`;

            //Row 4
            row = ctable1.insertRow();
            inputlanguages = `<select id="MenuLanguage" onchange="ChangeConfigInput('MenuLanguage','string')" onmouseover="HelpText(this.id)">`
            for (var key in CurrDTGBotConfig.DTGMenu_Lang) {
                inputlanguages += '<option value='+key+'>'+key+'</option>'
            }
            inputlanguages += '</select>'
            row.insertCell(0).innerHTML = 'MenuLanguage:';
            row.cells[0].onmouseover=function() {HelpText('MenuLanguage')};
            row.insertCell(1).innerHTML = inputlanguages;
            row.insertCell(2).innerHTML = 'ActMenuwidth:';
            row.cells[2].onmouseover=function() {HelpText('ActMenuwidth')};
            row.insertCell(3).innerHTML = `<input type="input" id="ActMenuwidth" onchange="ChangeConfigInput('ActMenuwidth','number')" onmouseover="HelpText(this.id)" size="1" value="" />`;
            row.insertCell(4).innerHTML = 'AlwaysResizeMenu:';
            row.cells[4].onmouseover=function() {HelpText('AlwaysResizeMenu')};
            row.insertCell(5).innerHTML =  `<input type="checkbox" id="AlwaysResizeMenu" onchange="ChangeConfigInput('AlwaysResizeMenu','bool')" onmouseover="HelpText(this.id)" size="1" value="" />`;

            //Row 5
            row = ctable1.insertRow();
            row.insertCell(0).innerHTML = 'BotLogLevel:';
            row.insertCell(1).innerHTML = `<select id="BotLogLevel" onchange="ChangeConfigInput('BotLogLevel','number')" onmouseover="HelpText(this.id)">
                    <option value=0 >Off</option>
                    <option value=1 >Min</option>
                    <option value=2 >More</option>
                    <option value=9 >Debug</option>
                    </select>`;
            row.cells[0].onmouseover=function() {HelpText('BotLogLevel')};

            row.insertCell(2).innerHTML =  `<input type="submit" id="restoredefault" value="restore defaults" onclick="RestoreDefaults()" onmouseover="HelpText(this.id)" />`;
            row.cells[2].colSpan = 4;
            row.cells[2].style.border = 0;
            row.cells[2].align = 'center';

            if (init) {
                return
            }

            if (CurrDTGBotConfig.BotLogLevel > 2) CurrDTGBotConfig.BotLogLevel = 9
            document.getElementById('BotLogLevel').value = CurrDTGBotConfig.BotLogLevel;

            //Row 6
            row = ctable1.insertRow();
            row.insertCell(0).innerHTML =  `<textarea id="HelpText" style="text-wrap:nowrap; width:600; height:320; min-height:100; display:block;" readonly disabled>Help</textarea>`;
            row.cells[0].colSpan = 6;
            row.cells[0].style.border = 2;

            //Right Table
            var ctable2 = document.getElementById('tRestConfig2');
            row = ctable2.insertRow();
            row.innerHTML = `
            <td>
                <table><tr><td>
                    <input type="submit" id="bLanguage" value="Language" onclick="UpdateTextAreaObject(\'ShowLanguage\')" onmouseover="HelpText(\'DTGMenu_Lang\')" />
                    <input type="submit" id="bStaticMenus" value="StaticMenus" onclick="UpdateTextAreaObject(\'ShowStaticMenus\')" onmouseover="HelpText(\'DTGMenu_Static_submenus\')"  />
                    <input type="submit" id="bDevTypes" value="DevTypes" onclick="UpdateTextAreaObject(\'ShowDevTypes\')" onmouseover="HelpText(\'DTGBOT_type_status\')" />
                    </td>
                    <td><div id="ConfigTextArea"></div></td>
                    <td><div id="ConfigTextAreaUpdate"> </div></td>
                </tr>
                </table>
            </td>
            `;
            row = ctable2.insertRow();
            row.innerHTML = '<td onmouseover="HelpText(\'DTGMenu_Lang\')"><textarea id="DTGMenu_Lang"                       style="width:600; height:400; min-height:100; display:block;"></textarea></td>';
            row = ctable2.insertRow();
            row.innerHTML = '<td onmouseover="HelpText(\'DTGMenu_Static_submenus\')"><textarea id="DTGMenu_Static_submenus" style="width:600; height:400; min-height:100; display:none;"></textarea></td>';
            row = ctable2.insertRow();
            row.innerHTML = '<td onmouseover="HelpText(\'DTGBOT_type_status\')"><textarea id="DTGBOT_type_status"           style="width:600; height:400; min-height:100; display:none;"></textarea></td>';

        }
        document.getElementById("MenuMessagesCleanOnExit").checked = CurrDTGBotConfig.MenuMessagesCleanOnExit
        document.getElementById("MenuMessagesMaxShown").value = CurrDTGBotConfig.MenuMessagesMaxShown
        document.getElementById("OtherMessagesMaxShown").value = CurrDTGBotConfig.OtherMessagesMaxShown
        if (document.getElementById("MenuMessagesCleanOnExit").checked) {
            document.getElementById("MenuMessagesMaxShown").disabled = false
            document.getElementById("OtherMessagesMaxShown").disabled = false
        } else {
            document.getElementById("MenuMessagesMaxShown").disabled = true
            document.getElementById("OtherMessagesMaxShown").disabled = true
        }

/*
-- bottomMenu  defaults
SubMenuwidth = 3 -- default max number of horizontal options in the mainmenu, can be overridded by Menuwidth per item.
DevMenuwidth = 3 -- default max number of horizontal options in the submenu
ActMenuwidth = 8 -- default max number of horizontal options in the menu
AlwaysResizeMenu = true

-- InlineMenu  defaults
ButtonTextwidth = 22 -- Set the max text you want on the button. the Devicename will be truncated to fit the status in case requested.
FullMenu = true -- this determines whether to show all levels or skip the Level2 when level3 is shown
*/

        document.getElementById("SubMenuwidth").value = CurrDTGBotConfig.SubMenuwidth
        document.getElementById("DevMenuwidth").value = CurrDTGBotConfig.DevMenuwidth
        document.getElementById("ActMenuwidth").value = CurrDTGBotConfig.ActMenuwidth
        document.getElementById("ButtonTextwidth").value = CurrDTGBotConfig.ButtonTextwidth
        document.getElementById("AlwaysResizeMenu").checked = CurrDTGBotConfig.AlwaysResizeMenu
        document.getElementById("FullMenu").checked = CurrDTGBotConfig.FullMenu

        document.getElementById("MenuLanguage").value = CurrDTGBotConfig.MenuLanguage
        document.getElementById("DTGMenu_Lang").value = JSON.stringify(CurrDTGBotConfig.DTGMenu_Lang[CurrDTGBotConfig.MenuLanguage], null, 3);
        document.getElementById("DTGMenu_Static_submenus").value = JSON.stringify(CurrDTGBotConfig.DTGMenu_Static_submenus, null, 3);
        document.getElementById("DTGBOT_type_status").value = JSON.stringify(CurrDTGBotConfig.DTGBOT_type_status, null, 3);

        if (LastJSONEdit == '') {
            LastJSONEdit = 'ShowLanguage'
        }
        if (!DTGMenu_Lang_editor) {
            DTGMenu_Lang_editor = CodeMirror.fromTextArea(document.getElementById("DTGMenu_Lang"), {
                matchBrackets: true,
                autoCloseBrackets: true,
                mode: "application/ld+json",
                lineWrapping: false
            });
            DTGMenu_Static_submenus_editor = CodeMirror.fromTextArea(document.getElementById("DTGMenu_Static_submenus"), {
                matchBrackets: true,
                autoCloseBrackets: true,
                mode: "application/ld+json",
                lineWrapping: false

            });
            DTGBOT_type_status_editor = CodeMirror.fromTextArea(document.getElementById("DTGBOT_type_status"), {
                matchBrackets: true,
                autoCloseBrackets: true,
                mode: "application/ld+json",
                lineWrapping: false
            });
            DTGMenu_Lang_editor.setSize("550", "430");
            DTGMenu_Static_submenus_editor.setSize("550", "430");
            DTGBOT_type_status_editor.setSize("550", "430");


            DTGMenu_Lang_editor.on("change", function(cm, change) {
                testJsonInput(cm, change, "DTGMenu_Lang")
            });

            DTGMenu_Static_submenus_editor.on("change", function(cm, change) {
                testJsonInput(cm, change, "DTGMenu_Static_submenus")
            });

            DTGBOT_type_status_editor.on("change", function(cm, change) {
                testJsonInput(cm, change, "DTGBOT_type_status")
            });

            function testJsonInput(cm, change, sourceobj) {
                // Change background color dynamically
                if (isValidJSON(cm.getValue())) {
                    a_newcontent = JSON.parse(cm.getValue());
                    newcontent = JSON.stringify(a_newcontent, null, 3);
                    if (sourceobj == "DTGMenu_Lang") {
                        a_orgvalue = CurrDTGBotConfig[sourceobj][CurrDTGBotConfig.MenuLanguage]
                    } else {
                        a_orgvalue = CurrDTGBotConfig[sourceobj]
                    }
                    // Check if content changed
                    if (newcontent == JSON.stringify(a_orgvalue, null, 3)) {
                        cm.getWrapperElement().style.backgroundColor = "#ffffff";
                    } else {
                        cm.getWrapperElement().style.backgroundColor = "#E8F5E9";
                        //Update ConfigUserFile
                        if (sourceobj == "DTGMenu_Lang") {
                            CurrDTGBotConfig[sourceobj][CurrDTGBotConfig.MenuLanguage] = a_newcontent
                        } else {
                            CurrDTGBotConfig[sourceobj] = a_newcontent
                        }
                        Config_Action("update", {[sourceobj]: CurrDTGBotConfig[sourceobj]})
                        //let now = new Date();
                        //let currentTime = now.toLocaleTimeString({ hour: '2-digit', minute: '2-digit', second: '2-digit' });
                        document.getElementById("ConfigTextAreaUpdate").innerHTML = `<small>=>Updated user config</small>`;
                        // Flash screen to notify of the update
                        cm.getWrapperElement().style.backgroundColor = "#e1e9fe";
                        setTimeout(function() {
                            cm.getWrapperElement().style.backgroundColor = "#E8F5E9";
                        }, 300);
                    }
                } else {
                    cm.getWrapperElement().style.backgroundColor = "#FBE9E7";
                }
            }
        }
        UpdateTextAreaObject(LastJSONEdit, false)
        SetRoomTable();
    }

    function SetRoomTable () {
        // build rooms / access table
        roomstbl = "<tr>"
        // Show Rooms  children[0].innerHTML
        if (DomoRooms == '') {
            return
        }
        Rooms = DomoRooms;
        // Sort logic
        function SortRoomName( a, b ) {
            if ( a.Name < b.Name ) return -1;
            if ( a.Name > b.Name ) return 1;
            return 0;
        }
        Rooms.sort( SortRoomName );
        Roomlist = []
        Roomcnt = 0
        DefaultShowMenu = ''
        DefaultRoomsRow = ''
        DefaultRoomsRow += '<tr><td bgcolor= "PowderBlue">-</td>'
        DefaultRoomsRow += '<td bgcolor= "PowderBlue">0</td>'
        DefaultRoomsRow += '<td bgcolor= "PowderBlue"><input type="input" size="4" value="Default"></td>'
        DefaultRoomsRow +=  '<td bgcolor= "PowderBlue"></td>'

        roomstbl += "<th>Act</th><th>ChatID</th><th>Name</th><th>Use<br>Default</th>"
        for (const [key, value] of Object.entries(Rooms)) {
            Roomcnt += 1
            Roomlist[Roomcnt] = []
            Roomlist[Roomcnt]["idx"] = value.idx
            Roomlist[Roomcnt]["name"] = value.Name
            roomstbl += "<th>" + value.Name + '<br>' + value.idx + "</th>"
            DefaultShowMenu += value.idx + ","
            DefaultRoomsRow +=  '<td bgcolor= "PowderBlue"><input type="checkbox"  id="0_' + value.idx + '" onclick="UpdateRoomAccess(this)" checked/></td>'
        }
        DefaultRoomsRow += "</tr>"

        // Show Rooms
        roomstbl += "</tr>"
        // get default menus defined
        if (CurrDTGBotConfig.ChatIDWhiteList["0"]) {
            DefaultShowMenu = CurrDTGBotConfig.ChatIDWhiteList["0"].ShowMenu || ""
        } else {
            roomstbl +=  DefaultRoomsRow
        }
        BlockedCnt = 0
        for (const [key, value] of Object.entries(CurrDTGBotConfig.ChatIDWhiteList)) {
            if (key == "0") {
                value.Name = 'Default';
                value.Active = true;
            }
            value.Name = value.Name || '';
            value.Active = (value.Active || false).toString()
            RowOption = '';
            if (value.Active == 'false') {
                BlockedCnt += 1
                rbcolor = "red"
                RowOption = '';
            } else {
                rbcolor = ((key == "0") ? "PowderBlue" : "white")
            }
            RowOption = '';
            roomstbl += '<tr><td bgcolor= "' + rbcolor + '"><input type="checkbox" id="' + key + '_act" onclick="UpdateRoomAccess(this)" onmouseover="HelpText(\'ChatidActivate\')" ' + ( (value.Active == 'true' || key == "0") ? ' checked ' : '') + ((key == "0") ? " disabled" : "") + '/></td>'
            roomstbl += '<td bgcolor= "' + rbcolor + '">' + key + '</td>'
            roomstbl += '<td bgcolor= "' + rbcolor + '"><input type="input" id="' + key + '_name" onchange="UpdateRoomAccess(this)"  onmouseover="HelpText(\'ChatidName\')" size="5" value="' + value.Name + '"></td>'
            usedefaults = (value.ShowMenu == undefined || value.ShowMenu == '0' )
            if (value.Active == 'false') {
                rbcolor = "red"
            } else {
                rbcolor = ((key == "0" || usedefaults) ? "PowderBlue" : "white")
                roomstbl +=  '<td bgcolor= "' + rbcolor + '">'
                if (key != "0") roomstbl +=  '<input type="checkbox" id="' + key + '_0" onclick="UpdateRoomAccess(this)" onmouseover="HelpText(\'UseDefault\')" ' + ( usedefaults ? ' checked ' : '') + '/>'
                roomstbl +=  '</td>'
                for (let index = 0; index < Roomcnt; index++) {
                    var re = new RegExp(',' + Roomlist[index+1]['idx'] +  ',');
                    roomdisabled = (usedefaults ? ' disabled' : '')
                    roomchecked = ((usedefaults && re.test(',' + DefaultShowMenu)) || re.test(',' + value.ShowMenu) ? ' checked' : '')
                    roomstbl +=  '<td bgcolor= "' + rbcolor + '"><input type="checkbox"  id="' + key + '_' + Roomlist[index+1]['idx'] + '" onclick="UpdateRoomAccess(this)"' + roomchecked + roomdisabled  + '/></td>'
                }
                roomstbl += "</tr>"
            }
        }
        if(BlockedCnt > 0) {
            document.getElementById("hChatIDWhiteList").innerHTML = "<b>Check box infront of ChatID to allow access.<b>";
            document.getElementById("hChatIDWhiteList").style.backgroundColor = "#fab2ac";
        } else {
            document.getElementById("hChatIDWhiteList").innerHTML = "";
            document.getElementById("hChatIDWhiteList").style.backgroundColor = "#ffffff";
        }

        roomstbl += "</tr>"
        //var ctable = document.getElementById("roomaccess");
        //let ctbody = ctable.createTBody();
        //ctbody.innerHTML = roomstbl;
        var ctable = document.getElementById("roomaccess");
        if (ctable.tBodies.length == 0) {
            ctbody = ctable.createTBody();
        } else {
            ctbody = ctable.tBodies[0]
        }
        ctbody.innerHTML = roomstbl;
        test=1
    }

    function Add_config_field(Element, c1, c2, c3, c4, c5) {
        var ctable = document.getElementById(Element);
        var row = ctable.insertRow();
        row.insertCell(0).innerHTML = (c1 || '');
        row.insertCell(1).innerHTML = (c2 || '');
        row.insertCell(2).innerHTML = (c3 || '');
        row.insertCell(3).innerHTML = (c4 || '');
        row.insertCell(4).innerHTML = (c5 || '');
    }

    function Add_Row_config_field(Element, c1) {
        var ctable = document.getElementById(Element);
        var row = ctable.insertRow();
        row.insertCell(0).innerHTML = (c1 || '');
    }

    function UpdateTextarea(cb) {
        if (cb.id == "DTGMenu_Lang") {
            if (JSON.stringify(CurrDTGBotConfig.DTGMenu_Lang[CurrDTGBotConfig.MenuLanguage], null, 3) != cb.value ) {
                CurrDTGBotConfig.DTGMenu_Lang[CurrDTGBotConfig.MenuLanguage] = JSON.parse(cb.value)
                Result = Config_Action("update", {"DTGMenu_Lang": CurrDTGBotConfig.DTGMenu_Lang})
            }
        } else if (cb.id == "DTGMenu_Static_submenus") {
            if (JSON.stringify(CurrDTGBotConfig.DTGMenu_Static_submenus, null, 3) != cb.value ) {
                CurrDTGBotConfig.DTGMenu_Static_submenus = JSON.parse(cb.value)
                Result = Config_Action("update", {"DTGMenu_Static_submenus": CurrDTGBotConfig.DTGMenu_Static_submenus})
            }
        } else if (cb.id == "DTGBOT_type_status") {
            if (JSON.stringify(CurrDTGBotConfig.DTGBOT_type_status, null, 3) != cb.value ) {
                CurrDTGBotConfig.DTGBOT_type_status = JSON.parse(cb.value)
                Result = Config_Action("update", {"DTGBOT_type_status": CurrDTGBotConfig.DTGBOT_type_status})
            }
        }
        return;
    }

    function UpdateRoomAccess(cb) {
        var table = document.getElementById("roomaccess");
        var table2=cb.parentElement.parentElement.parentElement.parentElement
        cbid=cb.id.split('_');
        cbrChatId = cbid[0]
        cbrroomidx = cbid[1]
        cbchecked = cb.checked
        // goto correct row in table
        for (var r = 1; r < table.rows.length; r++) {
            tChatId = table.rows[r].cells[1].innerText
            if (tChatId == cbrChatId) {
                newShowMenu = ''
                // check for default row and extra checkmark set
                if (table.rows[r].cells[4] == undefined) {
                    // Use defaults for any just Enabled/Unblocked ChatID
                    newShowMenu = '0'
                } else {
                    for (let c = 4; c < table.rows[r].cells.length; c++) {
                        if (table.rows[r].cells[c].childNodes[0].checked) {
                            nid=table.rows[r].cells[c].childNodes[0].id.split('_');
                            newShowMenu +=  nid[1] + ","
                        }
                    }
                }
                // Use default
                if (cbrroomidx == '0' && cbrChatId != '0' && cb.checked) {
                    newShowMenu = '0'
                }
                newName = table.rows[r].cells[2].childNodes[0].value;
                CurrDTGBotConfig.ChatIDWhiteList[cbrChatId] = CurrDTGBotConfig.ChatIDWhiteList[cbrChatId] || {}
                CurrDTGBotConfig.ChatIDWhiteList[cbrChatId].Name = newName
                CurrDTGBotConfig.ChatIDWhiteList[cbrChatId].ShowMenu = newShowMenu
                CurrDTGBotConfig.ChatIDWhiteList[cbrChatId].Active = table.rows[r].cells[0].childNodes[0].checked
                //Config_Action("update", '{"ChatIDWhiteList":{"'+cbrChatId+'":{"Name":"'+newName+ '","ShowMenu":"'+newShowMenu + '","Active":"' + table.rows[r].cells[0].childNodes[0].checked +  '"}}}')
            }
        }
        Config_Action("update", {"ChatIDWhiteList": CurrDTGBotConfig["ChatIDWhiteList"]})
        return;
    }

    // Update config fields
    function ChangeConfigInput(Fieldname, type='string') {
        if (type == 'number') {
            nvalue= Number(document.getElementById(Fieldname).value)
            if (isNaN(nvalue)) {
                document.getElementById("resultstatus").value = Fieldname + " value invalid!"
                document.getElementById("resultstatus").style.background = "red"
                return
            }
            CurrDTGBotConfig[Fieldname] = Number(document.getElementById(Fieldname).value);
        } else if (type == 'bool') {
            CurrDTGBotConfig[Fieldname] = document.getElementById(Fieldname).checked;
        } else if (type == 'string') {
            CurrDTGBotConfig[Fieldname] = document.getElementById(Fieldname).value;
        } else {
            CurrDTGBotConfig[Fieldname] = document.getElementById(Fieldname).value;
        }
        Config_Action("update", {
                [Fieldname] : CurrDTGBotConfig[Fieldname]
            }
        )
        document.getElementById("resultstatus").style.background = "lightgreen"
        setTimeout(function() {
            document.getElementById("resultstatus").style.background = "lightyellow"
        }, 300);
        // Update GUI field that might have changed
        UpdateTextAreaObject('ShowLanguage', false)
        document.getElementById("DTGMenu_Lang").value = JSON.stringify(CurrDTGBotConfig.DTGMenu_Lang[CurrDTGBotConfig.MenuLanguage], null, 3);
        DTGMenu_Lang_editor.setValue(document.getElementById("DTGMenu_Lang").value);
        if (document.getElementById("MenuMessagesCleanOnExit").checked) {
            document.getElementById("MenuMessagesMaxShown").disabled = false
            document.getElementById("OtherMessagesMaxShown").disabled = false
        } else {
            document.getElementById("MenuMessagesMaxShown").disabled = true
            document.getElementById("OtherMessagesMaxShown").disabled = true
        }
        // Set focus back on inputfield
        // document.getElementById(Fieldname).focus()
        return
    }

        // Update config fields
    function RestoreDefaults() {
        Config_Action('restoredefault')
        document.getElementById("resultstatus").style.background = "lightgreen"
        setTimeout(function() {
            document.getElementById("resultstatus").style.background = "lightyellow"
        }, 300);
        // Update GUI field that might have changed
        UpdateTextAreaObject('ShowLanguage', false)
        document.getElementById("DTGMenu_Lang").value = JSON.stringify(CurrDTGBotConfig.DTGMenu_Lang[CurrDTGBotConfig.MenuLanguage], null, 3);
        DTGMenu_Lang_editor.setValue(document.getElementById("DTGMenu_Lang").value);
        if (document.getElementById("MenuMessagesCleanOnExit").checked) {
            document.getElementById("MenuMessagesMaxShown").disabled = false
            document.getElementById("OtherMessagesMaxShown").disabled = false
        } else {
            document.getElementById("MenuMessagesMaxShown").disabled = true
            document.getElementById("OtherMessagesMaxShown").disabled = true
        }
        return
    }

    const isValidJSON = str => {
        try {
            JSON.parse(str);
            return true;
        } catch (e) {
            return false;
        }
    };

    function UpdateTextAreaObject(option='', setfocus=true) {
        if (option=='ShowLanguage') {
            LastJSONEdit = option;
            document.getElementById("bLanguage").style.backgroundColor = "#FFDF00";
            document.getElementById("bStaticMenus").style.backgroundColor = "";
            document.getElementById("bDevTypes").style.backgroundColor = "";
            // show and hide the appropriate codemirror objects belonging to the textareas
            DTGMenu_Lang_editor.getWrapperElement().style.display = "block";
            DTGMenu_Static_submenus_editor.getWrapperElement().style.display = "none";
            DTGBOT_type_status_editor.getWrapperElement().style.display = "none";
            if (setfocus) DTGMenu_Lang_editor.focus();
            return
        }
        if(option=='ShowStaticMenus') {
            LastJSONEdit = option;
            document.getElementById("bLanguage").style.backgroundColor = "";
            document.getElementById("bStaticMenus").style.backgroundColor = "#FFDF00";
            document.getElementById("bDevTypes").style.backgroundColor = "";
            // show and hide the appropriate codemirror objects belonging to the textareas
            DTGMenu_Lang_editor.getWrapperElement().style.display = "none";
            DTGMenu_Static_submenus_editor.getWrapperElement().style.display = "block";
            DTGBOT_type_status_editor.getWrapperElement().style.display = "none";
            if (setfocus) DTGMenu_Static_submenus_editor.focus();
            return
        }
        if(option=='ShowDevTypes') {
            LastJSONEdit = option;
            document.getElementById("bLanguage").style.backgroundColor = "";
            document.getElementById("bStaticMenus").style.backgroundColor = "";
            document.getElementById("bDevTypes").style.backgroundColor = "#FFDF00";
            // show and hide the appropriate codemirror objects belonging to the textareas
            DTGMenu_Lang_editor.getWrapperElement().style.display = "none";
            DTGMenu_Static_submenus_editor.getWrapperElement().style.display = "none";
            DTGBOT_type_status_editor.getWrapperElement().style.display = "block";
            if (setfocus) DTGBOT_type_status_editor.focus();
            return
        }
    }


    function Config_Action(iaction, idata) {
        if (iaction == 'update') {
            // build data array
            if (typeof idata === 'object' || Array.isArray(idata)) {
                idata = JSON.stringify(idata)
            }
            var savestatus = $.ajax({
                url: "config_actions.php",
                // dataType: "JSON",
                dataType: "text",
                data: {
                    action: iaction,
                    data_input: idata
                },
                type: 'POST',
                cache: false,
                async: false,
                timeout: 2000,
                success: function(data) {
                    Result = JSON.parse(data)
                    CurrDTGBotConfig = JSON.parse(Result.config);
                    updateconfigtable();
                    ConfigChangesActive = true;
                    document.getElementById("resultstatus").value = Result["Status"]
                    return ;
                },
                error: function(xhr, textStatus, errorThrown) {
                    error = "??";
                    alert(errorThrown);
                },
            });
        } else if (iaction == 'restoredefault') {
            var savestatus = $.ajax({
                url: "config_actions.php",
                dataType: "JSON",
                data: {
                    action: iaction,
                    data_input: ''
                },
                type: 'GET',
                cache: false,
                async: false,
                timeout: 2000,
                success: function(data) {
                    ConfigChangesActive = true;
                    if (data.config == undefined) {
                        alert("Error: " + data.status);
                        return;
                    }
                    CurrDTGBotConfig = JSON.parse(data.config);
                    updateconfigtable();
                    return;
                    //alert(JSON.stringify(data))
                    //alert(JSON.stringify(JSON.parse(data)));
                },
                error: function(xhr, textStatus, errorThrown) {
                    error = "??";
                    alert(errorThrown);
                },
            });
        } else if (iaction == 'get') {
            var savestatus = $.ajax({
                url: "config_actions.php",
                dataType: "JSON",
                data: {
                    action: iaction,
                    data_input: JSON.stringify(idata)
                },
                type: 'GET',
                cache: false,
                async: false,
                timeout: 2000,
                success: function(data) {
                    CurrDTGBotConfig = JSON.parse(data.config);
                    updateconfigtable();
                    GetInitConfigDone = true;
                    return;
                },
                error: function(xhr, textStatus, errorThrown) {
                    error = "??";
                    alert(errorThrown);
                    return '{}';
                },
            });
        }
        return savestatus
    }

    function GetDomoRooms() {
        // use URL from gui to ensure we use the latest version.
        var lurl = CurrDTGBotConfig.DomoticzUrl + "/json.htm?type=command&param=getplans&order=name&used=true"
        // document.getElementById("CheckDomo").value = "Checking Domoticz";
        // document.getElementById("resultstatus").value = "Getting Room info from Domoticz";
        var savestatus = $.ajax({
            url: "check_url.php",
            dataType: "text",
            data: {
                url: lurl,
                timeout: 3
            },
            type: 'GET',
            cache: false,
            async: true,
            timeout: 2000,
            success: function(sdata) {
                data = JSON.parse(sdata);
                if (data["status"] == "OK") {
                    DomoOK = true;
                    // Update room info
                    document.getElementById("roomaccess").style.display = "block";
                    DomoRooms = data.result;
                    SetRoomTable()
                } else {
                    DomoOK = false;
                    document.getElementById("resultstatus").value = "Domoticz Failed:" + data["status"]
                    document.getElementById("roomaccess").style.display = "none";
                }
            },
            error: function(xhr, textStatus, errorThrown) {
                DomoOK = false;
                if (xhr.responseText === undefined) {
                    document.getElementById("resultstatus").value = "Domoticz:" + xhr.statusText
                } else {
                    document.getElementById("resultstatus").value = "Domoticz:" + xhr.responseText
                }
                document.getElementById("roomaccess").style.display = "none";
            },
        });
        return savestatus
    }

    function MainMenu() {
        window.close();
        //window.location.replace('/');
    }

    // Define the helptext for the inputfields
    let helptextHtml = [];
    let JSONBackGround = `
\nBackgroundColor:
 - White => No Change
 - Red   => JSON Error - Not Saved
 - Green => Valid JSON - Changes are immediately Saved to the UserConfig
`
    helptextHtml["MenuMessagesCleanOnExit"] = "Select this to cleanup all messages after the Menu is closed"
    helptextHtml["MenuMessagesMaxShown"] = "Define the max shown messages for the Menu.\nThe rest will be removed as new ones are added."
    helptextHtml["OtherMessagesMaxShown"] = "Define the max messages generated by the other tasks of DTGBOT.\nThe rest will be removed as new ones are added."
    helptextHtml["MenuLanguage"] = "Select one of the avaiable menu language to use."
    helptextHtml["BotLogLevel"] = "Define the Log Level for DTGBOT process.\nOff/Min/More/Debug"
    helptextHtml["DTGMenu_Lang"] = "Update the default DTGBOT menu language definition." + JSONBackGround
    helptextHtml["DTGMenu_Static_submenus"] =
`Update the default DTGBOT static menu definition.

-> define the mainmenu menuitems.
  ["xxx"] =  Specify the name of the Submenu. EG: Lights; Screens; Misc
     whitelist    ="" (whitelisted ChatIDs or blank to show everybody)
     showdevstatus="" ("y" wil show Device state. Useful for ligths etc
     Menuwidth    =x   Override the default DevMenuwidth.

-> define the custom buttons(Device/Scene/Command) of each submenu
  buttons={
   ["xxx"] =  Specify the name of the Device/Scene or command.
      whitelist  =""   (whitelisted ChatIDs or blank to show everybody)
      actions    =""   (By default, the "menu_lang["XX"].devices_options" will be shown for the different DeviceTypes. This parameter allow you to override this default)
      showactions=true (Show the actions right away for this device when the submenu is selected.)
      prompt     =true (Prompt for an extra paramters. eg when button=temperature, you need the sensor name prompted before running the command.)

      {
   "MyButtons": {
      "buttons": {
         "temperature": {
            "prompt":true
         }
      }
   }` + JSONBackGround
    helptextHtml["DTGBOT_type_status"] = "Update the default DTGBOT menu device type definition." + JSONBackGround
    helptextHtml["SubMenuwidth"] = "Max horizontal buttons in mainmenu (Both Menus)"
    helptextHtml["DevMenuwidth"] = "Max horizontal Devices/Options (Both Menus)"
    helptextHtml["ActMenuwidth"] = "Max options for a device shown (Both Menus)"
    helptextHtml["ButtonTextwidth"] = "Max textlength on a button (inlineMenu)"
    helptextHtml["FullMenu"] = "Show Stacked menus for inline or just active menu level.  (inlineMenu)"
    helptextHtml["AlwaysResizeMenu"] = "Always Resize the BottomMenu. (BottomMenu)"
    helptextHtml["restoredefault"] = "Restore the settings of this block back to the default config."
    helptextHtml["bEdit"] = "Open the dtgbot__configuser.json file and edit it directly."

    function HelpText(id) {
        if (helptextHtml[id]) {
            document.getElementById("HelpText").innerHTML = id + ":\n" + helptextHtml[id]
        } else {
            document.getElementById("HelpText").innerHTML = id + ":\nhelp"
        }
    }
</script>

<body>
    <div id="Buttons">
        <table>
            <tr>
                <td>
                    <button id="bClose" onclick="MainMenu()">Close Config</button>
                </td>
                <td>
                    <button id="bEdit" onmouseover="HelpText(this.id)" onclick="location.href = '/config_editfile.php?Option=EDITUSER';">Edit User Config File</button>
                </td>
            </tr>
        </table>
    </div>
    <div id="MainConfig">
        <b>Rooms selection per Telegram ChatID</b>
        <table id='roomaccess' border=1 style="width:fit-content">
        </table>
        <div id="hChatIDWhiteList"></div>
    </div>
    <!-- The form -->
    <div id="RestConfig">
        <table id='tRestConfig' border="0">
            <tr><td>
                <table id='tRestConfig1' border="1">
                <tr><td colspan=2><b>Other DTGBOT settings</b></td></tr>
                </table>
            </td><td>
                <table id='tRestConfig2' border="1">
                </table>
            </td></tr>
        </table>
    </div>
    &nbsp;&nbsp;&nbsp;Result:<input type="text" id="resultstatus" size="100" value="" readonly />
</body>
</html>
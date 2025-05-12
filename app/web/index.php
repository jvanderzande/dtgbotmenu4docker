<?php
// main webpage for DTGBOT
?>
<html>

<head>
    <meta charset="utf-8">
    <meta http-equiv="content-type" content="text/html; charset=UTF-8">
    <title>DTGBOT Status</title>
    <link rel="icon" href="/DTGBOT.svg" type="image/svg+xml">
    <script src="js/jquery.min.js"></script>
    <script src="js/jquery-ui.min.js"></script>
    <!-- CodeMirror css -->
    <link rel="stylesheet" type="text/css" href="css/codemirror.css">
    <!-- CodeMirror source -->
    <script src="js/codemirror.js"></script>
    <!-- add an add-on -->
    <script src="js/matchbrackets.js"></script>
    <script src="js/active-line.js"></script>
    <style>
        body {
            background-color: #eaeaea;
        }

        td {
            vertical-align: top;
        }
        .CodeMirror-selected {
            background-color:rgb(255, 255, 0) !important;
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
    CurrDTGBotConfig = '';
    UserDTGBotConfig = '';
    ConfigwindowOpen = false;
    hpopup = null;
    ConfigwindowOpen = false;
    DomoOK = false;
    TelegramOK = false;
    DTGBOTDockerOK = true;
    initVar = 0;
    pTot_LogMsg = '';
    let myCodeMirror = null;
    G_SearchMatches = null;
    G_SearchMatchCur = -1;

    function InitialCheck() {
        GetInitConfigDone = false;
        Config_Action("get", '')

        var chknewconfig = setInterval(function() {
            if (GetInitConfigDone) {
                clearInterval(chknewconfig);
            }
        }, 200);

        ChkTelegram();
        ChkDomo();
        //resizedivs()
        ConfigwindowOpen = false;
        if (initVar != 0) {
            clearInterval(initVar);
        }
        var textarea = document.getElementById('LogText');
        textarea.scrollTop = textarea.scrollHeight;

        if (ConfigwindowOpen && initVar == 0) {
            initVar = setInterval(InitialCheck, 2000);
        }
        // Initialise gui fields
        if (CurrDTGBotConfig.BotLogLevel > 2) CurrDTGBotConfig.BotLogLevel = 9
        document.getElementById('BotLogLevel').value = CurrDTGBotConfig.BotLogLevel;
    }

   $(document).ready(function() {
        // start the init cycle
        InitialCheck();
        Get_log()

        // auto update textarea with log text
        setInterval(function() {
            if (!ConfigwindowOpen) {
                // get current config see if its updated
                if (!DomoOK || !TelegramOK) {
                    Config_Action("get", '')
                }
                // Check telegram when log is getting old.
                if (!TelegramOK && CurrDTGBotConfig.TelegramBotToken !== undefined)  {
                    ChkTelegram();
                }
                // Check Domoticz each cycle
                if (CurrDTGBotConfig.DomoticzUrl !== undefined) {
                    ChkDomo();
                }
            }
            // get log text
            Get_log()
        }, 5000);
    });

    function UpdateStatusField(text){
        var localdate = new Date();
        var ttime=('00' + localdate.getHours()).slice(-2) + ':' + ('00' + localdate.getMinutes()).slice(-2) + ':' + ('00' + localdate.getSeconds()).slice(-2);
        //document.getElementById("resultstatus").value = ttime + ":" + text
    }

    function resizedivs() {
        // set all sizes of the divs
        Win_oheight = window.innerHeight
        Win_height = window.outerHeight
        Top_height = document.getElementById("MainConfig").scrollHeight
        Main_height = document.getElementById("dmain").scrollHeight
        document.getElementById("dmain").style.height=Win_oheight - Top_height - 40
        // Match the size of the original textarea
        let textarea = document.getElementById('LogText');
        myCodeMirror.setSize(textarea.parentElement.offsetWidth, textarea.parentElement.offsetHeight);
    }

    function ChangeLogLevel() {
        Config_Action("update", {
                "BotLogLevel": Number(document.getElementById('BotLogLevel').value)
            }
        )
        if (CurrDTGBotConfig.BotLogLevel > 2) CurrDTGBotConfig.BotLogLevel = 9
        document.getElementById('BotLogLevel').value = CurrDTGBotConfig.BotLogLevel;
    }
    function decodeHTMLEntities(text) {
        const tempElement = document.createElement("textarea");
        tempElement.innerHTML = text;
        return tempElement.value;
    }

    function Get_log(LogAction = 0) {

        // Download content textarea (dtgbot.log)
        if (LogAction == 2) {
            function dataUrl(data) {
                return "data:x-application/xml;charset=utf-8," + escape(data);
            }
            var downloadLink = document.createElement("a");
            downloadLink.href = dataUrl(document.getElementById("LogText").value);
            downloadLink.download = "dtgbot.log";
            document.body.appendChild(downloadLink);
            downloadLink.click();
            document.body.removeChild(downloadLink);

            return
        }
        const zeroPad = (num, places) => String(num).padStart(places, '0')

        // api call to get_log.php to CLearlog or get content.
        var savestatus = $.ajax({
            url: "get_log.php",
            dataType: "text",
            data: {
                clearlog: (LogAction == 1 ? "y" : "n")
            },
            type: 'GET',
            cache: false,
            async: true,
            timeout: 2000,
            success: function(data) {
                let textarea = document.getElementById('LogText');
                let result = [];
                let prevMessage = "";
                let prevline = "";
                let skippedlines = 0;
                let skip = false;
                let LastCycle = "";
                let loglines= 0;
                lines = data.match(/[^\r\n]+/g)
                lines.forEach((line, index) => {
                    if (line.indexOf("No bot messages") > 0) {
                        LastCycle = line.substring(0,19)
                        if ((lines[index+1]||'').indexOf("No bot messages") > 0 ) {
                            if (!skip) {
                                loglines++;
                                result.push(line);
                                //result.push(line);
                                skip = true
                            } else {
                                skippedlines += 1
                            }
                            return
                        }
                    }
                    if (line.indexOf("Received Telegram message") > 0) {
                        LastCycle = line.substring(0,19)
                    }
                    if (skip) { // && lines.length -1 > index) {
                        skip = false
                        if (skippedlines > 0) {
                            loglines++;
                            result.push(" --> skipped " + skippedlines + " similar messages.");
                            //result.push(" --> skipped " + skippedlines + " similar messages.");
                        }
                        skippedlines = 0
                        LastCycle = line.substring(0,19)
                    }
                    loglines++;
                    result.push(line);
                    //result.push(line);
                    prevline = line;
                });
                // process received & preprocessed text
                pTot_LogMsg = (typeof(Tot_LogMsg) == "undefined" ? "" : Tot_LogMsg);
                Tot_LogMsg = result.join("\n");
                // Only update textarea when the log actually changed
                var lastlines = lines.slice(-2);
                var secondlast=lastlines[0] || "";
                if (pTot_LogMsg != Tot_LogMsg) {
                    textarea.innerHTML = result.join("\n");
                    // Check Telegram
                    if (LastCycle == "" && secondlast.indexOf("-- Log cleared --") > 0) {
                        LastCycle = secondlast.substring(0,19)
                    }
                    let tLastCycle = Date.parse(LastCycle);
                    // Mark Telegram has issue when last cylce is older than 1 minute
                    if (Date.now() - tLastCycle < 60000) {
                        TelegramOK = true;
                        document.getElementById("TelegramStatus").style.backgroundColor = "#c1f5c8";
                    } else {
                        TelegramOK = false;
                        document.getElementById("TelegramStatus").style.backgroundColor = "#fab2ac";
                    }

                    // Initialize CodeMirror only once
                    if (!myCodeMirror) {
                        myCodeMirror = CodeMirror.fromTextArea(textarea, {
                            readOnly: true,
                            mode: null,
                            lineNumbers: true,
                            lineWrapping: false,
                            cursorHeight: 0
                        });
                        const scrollInfo = myCodeMirror.getScrollInfo();
                        myCodeMirror.scrollTo(0, scrollInfo.height)
                    } else {
                        // Save the current scroll position
                        const scrollInfo = myCodeMirror.getScrollInfo();
                        // Save the current selection range
                        const selection = myCodeMirror.listSelections();

                        t1 = Math.round(scrollInfo.height - scrollInfo.top);
                        gotoend = false
                        if (scrollInfo.clientHeight+50 >= t1) {
                            gotoend = true
                        } else {
                            gotoend = false
                        }

                        // Update the content of the existing CodeMirror instance
                        myCodeMirror.setValue(decodeHTMLEntities(result.join("\n")));
                        const scrollInfon = myCodeMirror.getScrollInfo();
                        // Restore the scroll position
                        if (gotoend) {
                            myCodeMirror.scrollTo(0, scrollInfon.height)
                        } else {
                            myCodeMirror.scrollTo(scrollInfo.left, scrollInfo.top);
                            if (selection[0].anchor.ch != selection[0].head.ch) {
                                // Restore the selection range
                                myCodeMirror.setSelections(selection);
                            }
                        }
                        SearchLog();
                        const save_background = myCodeMirror.getWrapperElement().style.backgroundColor
                        myCodeMirror.getWrapperElement().style.backgroundColor = "#eaeaea";
                        setTimeout(function() {
                            myCodeMirror.getWrapperElement().style.backgroundColor = save_background;
                        }, 300);
                    }
                }
                resizedivs();
            },
            error: function(xhr, textStatus, errorThrown) {
                if (xhr.responseText === undefined) {
                    UpdateStatusField("get_log:" + xhr.statusText)
                } else {
                    UpdateStatusField("get_log:" + xhr.responseText)
                }            },
        });
    }

    function Config_Action(iaction, idata) {
        if (iaction == 'update') {
            // build data array
            if (typeof idata === 'object' || Array.isArray(idata)) {
                idata = JSON.stringify(idata)
            }
            var savestatus = $.ajax({
                url: "config_actions.php",
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
                    UserDTGBotConfig = JSON.parse(Result.configuser);
                    UpdateStatusField(Result["Status"])
                    CurrDTGBotConfig = JSON.parse(Result.config);
                    UserDTGBotConfig = JSON.parse(Result.configuser);
                    return ;                },
                error: function(xhr, textStatus, errorThrown) {
                    error = "??";
                    alert(errorThrown);
                },
            });
        } else if (iaction == 'restoredefault') {
            var savestatus = $.ajax({
                url: "config_actions.php",
                dataType: "text",
                data: {
                    action: iaction,
                    data_input: ''
                },
                type: 'GET',
                cache: false,
                async: false,
                timeout: 2000,
                success: function(data) {
                    Result = JSON.parse(data)
                    CurrDTGBotConfig = JSON.parse(Result.config);
                    UserDTGBotConfig = JSON.parse(Result.configuser);
                    return;
                },
                error: function(xhr, textStatus, errorThrown) {
                    error = "??";
                    alert(errorThrown);
                },
            });
        } else if (iaction == 'get') {
            var savestatus = $.ajax({
                url: "config_actions.php",
                dataType: "text",
                data: {
                    action: iaction,
                    data_input: JSON.stringify(idata)
                },
                type: 'GET',
                cache: false,
                async: false,
                timeout: 2000,
                success: function(data) {
                    GetInitConfigDone = true;
                    Result = JSON.parse(data)
                    CurrDTGBotConfig = JSON.parse(Result.config);
                    UserDTGBotConfig = JSON.parse(Result.configuser);
                    return;
                },
                error: function(xhr, textStatus, errorThrown) {
                    if (DTGBOTDockerOK) {
                        error = "Retrieving the log failed, is DTGBOT Docker running?";
                        alert(error);
                        DTGBOTDockerOK = false
                    }
                    return '{}';
                },
            });
        }
        return savestatus
    }

    ////
    // Use the Docker container to check the Domo URL as this could be an internal IP Address!
    function ChkDomo(task = 0) {
        var lurl = CurrDTGBotConfig.DomoticzUrl + "/json.htm?type=command&param=getversion"
        // check when Telegram is OK to disable the top part
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
            timeout: 3000,
            success: function(sdata) {
                data = JSON.parse(sdata);
                if (data["status"] == "OK") {
                    document.getElementById("DomoticzStatus").style.backgroundColor = "#c1f5c8";
                    DomoOK = true;
                } else {
                    document.getElementById("DomoticzStatus").style.backgroundColor = "#fab2ac";
                    DomoOK = false;
                }
            },
            error: function(xhr, textStatus, errorThrown) {
                document.getElementById("DomoticzStatus").style.backgroundColor = "#fab2ac";
                if (xhr.responseText === undefined) {
                    UpdateStatusField("Domoticz:" + xhr.statusText)
                } else {
                    UpdateStatusField("Domoticz:" + xhr.responseText)
                }
                DomoOK = false;
            },
        });
        return savestatus
    }

    function ChkTelegram(task = 0) {
        var lurl = 'https://api.telegram.org/bot' + CurrDTGBotConfig.TelegramBotToken + '/getMe'
        //document.getElementById("CheckTelegram").value = "Checking Telegram";
        var savestatus = $.ajax({
            url: lurl,
            dataType: "json",
            type: 'GET',
            cache: false,
            async: true,
            timeout: 4000,
            success: function(data) {
                error = data;
                //document.getElementById("CheckTelegram").value = "Telegram OK";
                document.getElementById("TelegramStatus").style.backgroundColor = "#c1f5c8";
                TelegramOK = true;
            },
            error: function(xhr, textStatus, errorThrown) {
                document.getElementById("TelegramStatus").style.backgroundColor = "#fab2ac";
                TelegramOK = false;
                if (xhr.responseText === undefined) {
                    UpdateStatusField("Telegram:" + xhr.statusText)
                } else {
                    UpdateStatusField("Telegram:" + xhr.responseText)
                }
            },
        });
    }

    function MainMenu() {
        window.location.replace('/');
    }

    function OpenConfigWindow() {
        var w = 1230;
        var h = window.screen.height * .9;
        var l = window.screen.width - w;
        var t = 20
        window.open('config.php', 'DTGBOT Config', 'left=' + l + ',top=' + t + ',width=' + w + ',height=' + h );
    }

    function escapeRegExp(string) {
        return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); // $& means the whole matched string
    }
    function SearchLog(event) {
        let searchTerm = document.getElementById("isearch").value;
        if (searchTerm == "") {
            document.getElementById("isearch").style.backgroundColor = "#ffffff";
            document.getElementById("isearchline").innerHTML = "";
            return;
        }

        // Get the full content of the CodeMirror editor
        const fullText = myCodeMirror.getValue();

        // Find the index of the search term
        const regexp = new RegExp(escapeRegExp(searchTerm),"ig");
        G_SearchMatches = [...fullText.matchAll(regexp)];
        // Perform this part when Search text is changed
        if (G_SearchMatches.length > 0) {
            if (G_SearchMatchCur == -1) {
                G_SearchMatchCur = 0;
            }
            const index = G_SearchMatches[G_SearchMatchCur].index;
            // Calculate the line and character position
            const lines = fullText.substring(0, index).split("\n");
            const lineNumber = lines.length - 1;
            const charIndex = lines[lines.length - 1].length;

            // Scroll to the line in CodeMirror
            myCodeMirror.scrollIntoView({ line: lineNumber, ch: charIndex }, 100);

            // Highlight the search term
            myCodeMirror.setSelection({ line: lineNumber, ch: charIndex }, { line: lineNumber, ch: charIndex + searchTerm.length });

            // Update the search status
            document.getElementById("isearch").style.backgroundColor = "#c1f5c8";
            document.getElementById("isearchline").innerHTML = "line:" + (lineNumber + 1) + " (" + (G_SearchMatchCur+1) + " of " + G_SearchMatches.length + ")";
        } else {
            // No match found
            G_SearchMatches = null;
            G_SearchMatchCur = -1;
            document.getElementById("isearch").style.backgroundColor = "#fab2ac";
            document.getElementById("isearchline").innerHTML = "No match found";
            //selected = myCodeMirror.getCursor()
            selection = myCodeMirror.listSelections();
            // Stay on the line where we were when defined.
            if (selection[0] && selection[0].line) {
                myCodeMirror.setSelection({ line: selection[0].line, ch: selection[0].ch });
            }
        }
    }
    // Goto Next/Previous occurance of a search string
    function SearchLogEvent(event) {
        if (event.code !== "ArrowDown" && event.code !== "ArrowUp") {
            return;
        }
        // only when previously matches were found
        if (!G_SearchMatches) {
            document.getElementById("isearch").style.backgroundColor = "#ffffff";
            return;
        }
        // Process the Up/Down
        let index = -1
        if (event.code === "ArrowDown" && G_SearchMatchCur < G_SearchMatches.length-1) {
            G_SearchMatchCur++;
        } else if (event.code === "ArrowUp" && G_SearchMatchCur > 0) {
            G_SearchMatchCur--;
        }
        if (G_SearchMatchCur >= 0 && G_SearchMatches.length > G_SearchMatchCur) {
            //let searchTerm = document.getElementById("isearch").value;
            index = G_SearchMatches[G_SearchMatchCur].index;
            // Calculate the line and character position
            const fullText = myCodeMirror.getValue();
            const lines = fullText.substring(0, index).split("\n");
            const lineNumber = lines.length - 1;
            const charIndex = lines[lines.length - 1].length;

            // Scroll to the line in CodeMirror
            myCodeMirror.scrollIntoView({ line: lineNumber, ch: charIndex }, 100);

            // Highlight the search term
            myCodeMirror.setSelection({ line: lineNumber, ch: charIndex }, { line: lineNumber, ch: charIndex + G_SearchMatches[G_SearchMatchCur][0].length });

            // Update the search status
            document.getElementById("isearch").style.backgroundColor = "#c1f5c8";
            document.getElementById("isearchline").innerHTML = "line:" + (lineNumber + 1)+ " (" + (G_SearchMatchCur+1) + " of " + G_SearchMatches.length + ")";
        }
    }

    function gotoTop(){
        // myCodeMirror.goDocStart   //didn't work
        myCodeMirror.scrollIntoView({ line: 0, ch: 1 }, 0);
    }
    function gotoEnd(){
        // myCodeMirror.goDocEnd  //didn't work
        const fullText = myCodeMirror.getValue();
        const lines = fullText.split("\n");
        myCodeMirror.scrollIntoView({ line: lines.length-1 , ch: 1 }, 20);
    }

</script>

<body>
    <div id="MainConfig">
        <table id="CheckDTGBOTConfig">
            <tr>
                <td>DTGBOT Main Menu</td>
                <?php /*
                <td colspan=2><input type="text" id="resultstatus" size="40" value="" /></td>
                <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
                */ ?>
                <td><input type="input" id="DomoticzStatus" name="DomoticzStatus" size="8" value="Domoticz"/></td>
                <td><input type="input" id="TelegramStatus" name="TelegramStatus" size="8" value="Telegram"/></td>
                <td><button id="OpenConfigWindow" onclick="OpenConfigWindow()">Configuration Menu</button></td>
                <td>&nbsp;&nbsp;&nbsp;&nbsp;Version:<?php echo(getenv('GIT_RELEASE')); ?></td>
            </tr>
        </table>
    </div>
    <table>
        <tr>
            <td>
                <button onclick="Get_log(1)">ClearLog</button>
            </td>
            <td>
                <button onclick="Get_log(2)">DownloadLog</button>
            </td>
            <td>LogLevel:</td>
            <td>
                <select id="BotLogLevel" onchange="ChangeLogLevel()">
                    <option value=0 >Off</option>
                    <option value=1 >Min</option>
                    <option value=2 >More</option>
                    <option value=9 >Debug</option>
                </select>
            </td>
            <td>
                SearchLog:<input type="text" id="isearch" size="25" value="" oninput="SearchLog(event)" onKeyDown=SearchLogEvent(event) />
            </td>
            <td>
                <div id="isearchline"></div>
            </td>
            <td>
                <button onclick="gotoTop()">Top</button>
            </td>
            <td>
                <button onclick="gotoEnd()">Bottom</button>
            </td>
            </tr>
    </table>
    <div id="dmain">
        <textarea id="LogText" name="LogText" class="container__textarea" style="text-wrap:nowrap; width:95%; height:95%; min-height:90%; "></textarea>
    </div>

</body>
</html>
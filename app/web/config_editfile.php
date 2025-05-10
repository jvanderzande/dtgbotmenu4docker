<?php
// configuration
$url = '/';
$DTGBotDataPath = getenv('DTGBotDataPath');
if ($DTGBotDataPath == '') {
    $DTGBotDataPath = '/data/';
}
$Option = '';
$Option = isset($_GET['Option']) ? $_GET['Option'] : $Option;
$Option = isset($_POST['Option']) ? $_POST['Option'] : $Option;

$nextstep = '';
$nextstep = isset($_GET['nextstep']) ? $_GET['nextstep'] : $nextstep;
$nextstep = isset($_POST['nextstep']) ? $_POST['nextstep'] : $nextstep;

if ($Option == "SHOWDEFAULT") {
    $configfile = 'dtgbot__configdefault.json';
    $filetask="View";
} else {
    $configfile = 'dtgbot__configuser.json';
    $filetask="Edit";
}
$file = $DTGBotDataPath . $configfile;
$nfile = $DTGBotDataPath . "new_" . $configfile;
$tfile = $DTGBotDataPath . "tst_" . $configfile;

$TempFileDir = getenv('TempFileDir');
if ($TempFileDir == '') {
    $TempFileDir = '/tmp/';
}

//~ print(date("Y-m-d H:i:s"));
//print_r($_POST);
// check if form has been submitted
$luaerror = "";
if (isset($_POST['code'])) {
    // validate json
    $json = json_decode($_POST['code'], true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        $luaerror = json_last_error_msg();
        print("Config has JSON Error(s):<br><b> <textarea style=\"color: red;\" cols=\"120\" rows=\"2\" readonly>{$luaerror}</textarea></b>");
    } else {
        file_put_contents($DTGBotDataPath . $configfile, $_POST['code']);
        file_put_contents($DTGBotDataPath . 'logs/dtgbot.log', date("Y-m-d H:i:s") . " ************************************************************\n", FILE_APPEND);
        file_put_contents($DTGBotDataPath . 'logs/dtgbot.log', date("Y-m-d H:i:s") . " ** Config Saved. DTGBOT will now restart to load the config.\n", FILE_APPEND);
        file_put_contents($DTGBotDataPath . 'logs/dtgbot.log', date("Y-m-d H:i:s") . " ************************************************************\n", FILE_APPEND);
        // echo "nextstep = $nextstep";
        if ($nextstep == 'ConfigMenu') {
            // Kill process "lua dtgbot__main.lua" to force a restart during longpoll wait and reload of the config
            // echo "nextstep2 = $nextstep";
            echo '<meta http-equiv="refresh" content="5; url=/config.php" />';
            echo 'Config is saved, DTGBOT will restart now. Page will reload after 5 seconds';
            exec('bash -c "pkill -f dtgbot__main.lua > /dev/null 2>&1 &"');
            exit();
        } else {
            // Close this extra popup window
            echo "
                Config is saved, DTGBOT will restart now. Page will be closed in 5 seconds
                <script>
                    setTimeout(function() {
                        window.close();
                    }, 5000);
                </script>
            ";
            // Kill process "lua dtgbot__main.lua" to force a restart during longpoll wait and reload of the config
            exec('bash -c "sleep 1 && pkill -f dtgbot__main.lua > /dev/null 2>&1 &"');
            exit();
        }
    }
    $text = $_POST['code'];
    $filetask = 'Edit';
} else {
    // read the configfile
    $text = file_get_contents($file);
}

if (isset($_POST['filetask'])) {
    $filetask = $_POST['filetask'];
} else {
    $filetask = (isset($filetask) ? $filetask : 'View');
}

//$text = str_ireplace(array("\n"), '\\n', $text);
//$text = str_ireplace(array("\r"), '\\r', $text);
//$text = str_ireplace(array("'"), "\'", $text);

?>
<!DOCTYPE html>
<html>

<head>
    <meta charset="utf-8">
    <meta http-equiv="content-type" content="text/html; charset=UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>DTGBOT Full Config Editor</title>
    <link rel="icon" href="/DTGBOT.svg" type="image/svg+xml">
    <style>
        body {
            background-color: #eaeaea;
        }

        .CodeMirror-line-numbers {
            margin: .4em;
            padding: 0;
            font-family: monospace;
            font-size: 10pt;
            color: black;
        }

        td {
            vertical-align: top;
        }

    </style>
</head>

<body>
    <table>
        <tr>
            <td>
                <button onclick="MainMenu()">Close Config</button>
            </td>
            <td>
                <button onclick="ConfigMenu()">Configuration Menu</button>
            </td>
            <?php
            if ($configfile == "dtgbot__configdefault.lua" || $configfile == "dtgbot__configdefault.json") {
                print ('<td><button onclick="location.href = \'/config_editfile.php?Option=EDITUSER\';">Edit User Config File</button></td>');
            } else {
                print ('<td><button id="bSaveLoad" onclick="SaveLoad()" disabled>Save User Config & Restart DTGBOT</button></td>');
                print ('<td><button id="bViewDefault" onclick="location.href = \'/config_editfile.php?Option=SHOWDEFAULT\';">View Default Config</button></td>');
            }
        print ('</tr>');
        print ('<tr>');
        print ("  <td colspan=4><big><b>$filetask</b> config-file: $configfile </big></td>");
        print ('<tr>');
        print ('</table>');
    ?>
    <form action="/config_editfile.php" id="filetextsave" method="post">
        <div style="border: 1px solid black; padding: 0px;">
            <textarea id="code" name="code" rows="40" oninput="TypingTextAreaObject(this,event)" style="text-wrap:nowrap; width:95%; height:95%; min-height:90%; ">?</textarea>
        </div>
        <input type="input" id="nextstep" name="nextstep" value="" />
    </form>

    <script type="text/javascript">
        var filetask = "<?php echo $filetask?>";
        var orgcontent = `<?php echo $text; ?>`

        function CheckChanges() {
            var snewcontent = document.getElementById("code").value;
            var newcontent = ''
            if (isValidJSON(snewcontent)) {
                newcontent = JSON.stringify(JSON.parse(document.getElementById("code").value), null, 3);
            }
            if (orgcontent != newcontent){
                if (isValidJSON(newcontent)) {
                    if (confirm("You have unsaved changes. Do you want to save them first?")) {
                        SaveLoad();
                        return false;
                    } else {
                        return true
                    }
                } else if (!isValidJSON(newcontent)){
                    if (confirm("You have unsaved changes, but the JSON is invalid. Do you want to cancel the changes?")) {
                        return true;
                    }else {
                        return false // do nothing
                    }
                } else {
                    return true;
                }
            } else {
                return true;
            }
            //window.location.replace('/');
        }

        function ConfigMenu() {
            document.getElementById("nextstep").value = "ConfigMenu"
            if (CheckChanges()) window.location.replace('/config.php');
        }

        function MainMenu() {
            document.getElementById("nextstep").value = "MainMenu"
            if (CheckChanges()) window.close();
        }

        function SaveLoad() {
            document.getElementById("filetextsave").submit();
        }

        // Test for valid JSON
        const isValidJSON = str => {
            try {
                JSON.parse(str);
                return true;
            } catch (e) {
                return false;
            }
        };

        if (isValidJSON(orgcontent)) {
            orgcontent = JSON.stringify(JSON.parse(orgcontent), null, 3);
        }
        document.getElementById("code").value =  orgcontent;
        if (filetask == 'View') {
            document.getElementById("code").readOnly = true;
            document.getElementById("code").style.backgroundColor = "#cdd7e2";
        } else {
            document.getElementById("code").style.backgroundColor = "#e6e6e6";
        }

        function TypingTextAreaObject(element,event) {
            if (isValidJSON(element.value)) {
                newcontent = JSON.stringify(JSON.parse(element.value), null, 3);
                if (newcontent == orgcontent) {
                    element.style.backgroundColor = "#e6e6e6";
                    document.getElementById("bViewDefault").disabled = false;
                    document.getElementById("bSaveLoad").disabled = true;
                } else {
                    //format JSON on enter ->
                    //inputType :"historyUndo"  "insertLineBreak"
                    if(event.inputType === "insertLineBreak") {
                        start = element.selectionStart;
                        l1char = element.value.charAt(start);
                        // find same characters in newcontent close the original position start
                        l1start = newcontent.indexOf(l1char, start-1);
                        if (l1start > -1) {
                            start = l1start;
                        }
                        element.value = newcontent
                        element.selectionStart = start;
                        element.selectionEnd = start;
                    }
                    element.style.backgroundColor = "#c1f5c8";
                    document.getElementById("bSaveLoad").disabled = false;
                    document.getElementById("bViewDefault").disabled = true;
                }
            } else {
                element.style.backgroundColor = "#f5a142"
                document.getElementById("bSaveLoad").disabled = true;
                document.getElementById("bViewDefault").disabled = true;
            }
        }
    </script>
</body>
</html>

<?php

// configuration
$url = '/';
$DTGBotDataPath = getenv('DTGBotDataPath');
$ConfigActive = [];
$ConfigDefault = [];
$ConfigUser = [];

if ($DTGBotDataPath == '') {
    $DTGBotDataPath = '/data/';
}
//=== Debugging ======
$debug = true;
$cacheJson = false;
function dprint($itxt)
{
    global $debug, $DTGBotDataPath;
    if($debug) {
        //print($itxt);
        file_put_contents($DTGBotDataPath . 'logs/config_update.log', $itxt, FILE_APPEND);
    }
}
function dprint_r($itxt)
{
    global $debug, $DTGBotDataPath;
    ;
    if($debug) {
        //print_r($itxt);
        file_put_contents($DTGBotDataPath . 'logs/config_update.log', json_encode($itxt, JSON_FORCE_OBJECT + JSON_PRETTY_PRINT), FILE_APPEND);
    }
}
// Get Current configs
load_Configs();
// Merge the Default & User arrays into the active config
$ConfigActive = array_replace_recursive($ConfigDefault, $ConfigUser);

$action = isset($_GET['action']) ? $_GET['action'] : "get";
$action = isset($_POST['action']) ? $_POST['action'] : $action;
$data_input = isset($_GET['data_input']) ? $_GET['data_input'] : '{"": {}}' ;
$data_input = isset($_POST['data_input']) ? $_POST['data_input'] : $data_input ;
//print($data_input);
//dprint("$data_input\n");

$response = array();
$response["configaction"] = "$action";
$Status = "unknown";

if ($action != "get") {
    dprint("\n>>--" . date("Y-m-d H:i:s") . " ---\n");
    dprint("> action:$action data_input:$data_input \n");
}
//
if ($action == "get") {
    ksort($ConfigActive);
    $Status = "Get Config Ok";
} elseif ($action == "restoredefault")  {
    unset($ConfigUser["MenuMessagesCleanOnExit"]);
    unset($ConfigUser["MenuMessagesMaxShown"]);
    unset($ConfigUser["OtherMessagesMaxShown"]);
    unset($ConfigUser["MenuLanguage"]);

    unset($ConfigUser["SubMenuwidth"]);
    unset($ConfigUser["DevMenuwidth"]);
    unset($ConfigUser["ActMenuwidth"]);
    unset($ConfigUser["ButtonTextwidth"]);
    unset($ConfigUser["FullMenu"]);
    unset($ConfigUser["AlwaysResizeMenu"]);

    unset($ConfigUser["DTGMenu_Lang"]);
    unset($ConfigUser["DTGBOT_type_status"]);
    $ConfigUser['DTGuserconfig_version'] = date("Y-m-d H:i:s");
    // save the text contents to temp file
    $file = $DTGBotDataPath . 'dtgbot__configuser.json';
    file_put_contents($file, json_encode($ConfigUser, JSON_UNESCAPED_SLASHES + JSON_FORCE_OBJECT + JSON_PRETTY_PRINT));
    $Status = "Defaults restored";
} elseif ($action == "update")  {
    $o_data_input = null;
    if (isJson($data_input)) {
        $o_data_input = json_decode($data_input, true);
    }
    if (!$o_data_input || !is_array($o_data_input)) {
        $response["Status"] = "Invalid JSON input";
        $response["config"] = json_encode("");
        $response["data"] = "$data_input";
        print_r(json_encode($response, JSON_PRETTY_PRINT + JSON_FORCE_OBJECT));
        die("");
    }
    // Loop through input and determine the changes
    $ChangesMade = Update_Config($o_data_input, $ConfigUser, $ConfigDefault);
    if ($ChangesMade > 0) {
        $ConfigUser['DTGuserconfig_version'] = date("Y-m-d H:i:s");
        // save the text contents to temp file
        $file = $DTGBotDataPath . 'dtgbot__configuser.json';
        file_put_contents($file, json_encode($ConfigUser, JSON_UNESCAPED_SLASHES + JSON_FORCE_OBJECT + JSON_PRETTY_PRINT));
        $Status = "Config changes saved: $ChangesMade";
    } else {
        $Status = "No Changes";
    }
}

// Merge the Default & User arrays into the active config
$ConfigActive = array_replace_recursive($ConfigDefault, $ConfigUser);
$response["config"] = json_encode($ConfigActive);
$response["configuser"] = json_encode($ConfigUser);
$response["Status"] = date("H:i:s ") ."$Status";
print_r(json_encode($response, JSON_PRETTY_PRINT));
if ($data_input != "") {
}
if ($action == "get") {
    //dprint("... Done.\n");
} else {
    dprint("< action:$action Done. Changes made:$ChangesMade \n");
}
$file = $DTGBotDataPath . 'dtgbot__configactive.json';
file_put_contents($file, json_encode($ConfigActive, JSON_UNESCAPED_SLASHES + JSON_FORCE_OBJECT + JSON_PRETTY_PRINT));

// dprint("<<------------------------------------------------------------------------------------------\n");

exit;
// --- end ------------------------------------------------------------------------------


function isJson($string)
{
    if (! is_string($string) || $string == '') {
        return false;
    }
    json_decode($string);
    return json_last_error() === JSON_ERROR_NONE;
}
//==========================================================================================
//
//==========================================================================================
function Update_Config($iData, &$iUserConfig, $iDefaultConfig, $level = 0, $fields = '', $ChangesMade = 0)
{
    $level += 1;
    // dprint("-> Level: $level => $ChangesMade\n");
    if (is_array($iData)) {
        $iActiveConfig = array_replace_recursive($iDefaultConfig, $iUserConfig);
        foreach($iData as $field => $fvalue) {
            // Build the Left side of the equal sign
            if ($level == 1) {
                $nfields = "$field";                // first level variable
            } else {
                $nfields = "{$fields}[\"$field\"]"; // lower level variable inside array
            }
            if (is_array($fvalue)) {
                dprint("-> Level:$level  Array:$field->$nfields\n");
                $iJSON = json_encode($fvalue);
                if (array_key_exists($field, $iDefaultConfig)) {
                    $dJSON = json_encode($iDefaultConfig[$field]);
                } else {
                    $dJSON = json_encode([]);
                }
                if ($iJSON == $dJSON) {
                    dprint("  -> Input Data the same as default for {$nfields}\n");
                    if (is_array($iUserConfig) && array_key_exists($field, $iUserConfig)) {
                        //$niDataUser = &$iUserConfig[$field];
                        dprint("!!! Removed: User config as it's equal to Default\n");
                        unset($iUserConfig[$field]);
                        $ChangesMade++;
                    }
                    continue;
                }
                // dprint_r($iUserConfig);
                // dprint("\n-------------------------------------------\n");
                // check for default information
                if (is_array($iUserConfig) && array_key_exists($field, $iUserConfig)) {
                    //$niDataUser = &$iUserConfig[$field];
                    dprint("    - User config already exists\n");
                } else {
                    //$niDataUser = [];
                    $iUserConfig[$field] = [];
                    dprint("    - New User Config for $field \n");
                    // Add declare into output for sub array when not existing in both Default and User Array
                }
                $niDataUser = &$iUserConfig[$field];
                // check for default information
                if (is_array($iDefaultConfig) && array_key_exists($field, $iDefaultConfig)) {
                    $niDataDefault = $iDefaultConfig[$field];
                    dprint("    - Default exists\n");
                } else {
                    $niDataDefault = [];
                    dprint("    - NO Default exists\n");
                    // Add declare into output for sub array when not existing in both Default and User Array
                }
                // is associate array ["string1", "string2"]
                $ChangesMade = Update_Config($iData[$field], $niDataUser, $niDataDefault, $level, "{$nfields}", $ChangesMade);
                // dprint("<- $level => $ChangesMade\n");
                // dprint("<= $level->$field -> $fields  | $nfields\n");
                // dprint_r($iUserConfig);
                // dprint("\n-------------------------------------------\n");
            } else {
                // check if this field was in the input JSON and report its status
                // dprint("-> Level:$level  Fields: $field->$nfields\n");
                dprint("-> Level:$level");
                if (is_array($iData) &&  array_key_exists($field, $iData)) {
                    $viData = (is_array($iData) &&  array_key_exists($field, $iData) ? $iData[$field] : '');
                    $vDataUser = (is_array($iUserConfig) &&  array_key_exists($field, $iUserConfig) ? $iUserConfig[$field] : '');
                    $vDataDefault = (is_array($iDefaultConfig) &&  array_key_exists($field, $iDefaultConfig) ? $iDefaultConfig[$field] : '');
                    /*
                    dprint("i:$viData  u:$vDataUser  d:$vDataDefault \n");
                    dprint("\n idata:");
                    dprint_r($iData);
                    dprint("\n DataUser:");
                    dprint_r($iUserConfig);
                    dprint("\n iDataDefault:");
                    dprint_r($iDefaultConfig);
                    dprint("\n--------------------------\n");
                    */
                    if ($viData !== '' && $viData === $vDataUser) {
                        dprint(" -> Unchanged: {$nfields} = $fvalue \n");
                    } elseif ($viData !== '' && $vDataUser === '') {
                        if ($viData === $vDataDefault) {
                            dprint(" -> Unchanged:{$nfields} = $fvalue \n");
                            //unset($iUserConfig[$field]);
                        } else {
                            dprint("!!! Added  :{$nfields} = $fvalue   (default->$vDataDefault)\n");
                            $iUserConfig[$field] = $fvalue;
                            $ChangesMade++;
                        }
                    } else {
                        if ($viData === $vDataDefault) {
                            dprint("!!! Change back to default:{$nfields} = $fvalue (old->$vDataUser  default->$vDataDefault)\n");
                            unset($iUserConfig[$field]);
                        } else {
                            dprint("!!! Updated: {$nfields} = $fvalue  (old->$vDataUser  default->$vDataDefault) \n");
                            $iUserConfig[$field] = $fvalue;
                        }
                        $ChangesMade++;
                    }
                }
            }
            //print("<-$level $fields:\n $UserConfigStr --------------------------------\n");
        }
        //############################################################################
        // Check for UserConfig entries not in the input for level > 1
        if ($level > 1){
            foreach($iUserConfig as $field => $fvalue) {
                // Build the Left side of the equal sign
                if ($level == 1) {
                    $nfields = "$field";                // first level variable
                } else {
                    $nfields = "{$fields}[\"$field\"]"; // lower level variable inside array
                }
                // Do not remove ChatIDWhiteList enties
                if (substr($nfields, 0, 15) == "ChatIDWhiteList") {
                    continue;
                }
                if (is_array($fvalue)) {
                    $uJSON = json_encode($fvalue);
                    if (array_key_exists($field, $iData)) {
                        $iJSON = json_encode($iData[$field]);
                    } else {
                        unset($iUserConfig[$field]);
                        dprint("-> Level:$level");
                        dprint("!!! Removed Key: {$nfields} from UserConfig --> NO Input exists anymore.\n");
                        $ChangesMade++;
                    }
                    if ($uJSON == $iJSON) {
                        // dprint("-> Input Data the same as user Data for {$nfields}\n");
                        continue;
                    }
                } else {
                    // check if this field was in the input JSON and report its status
                    $viData = (is_array($iData) &&  array_key_exists($field, $iData) ? $iData[$field] : '?');
                    $vDataUser = (is_array($iUserConfig) &&  array_key_exists($field, $iUserConfig) ? $iUserConfig[$field] : '?');
                    $vDataDefault = (is_array($iDefaultConfig) &&  array_key_exists($field, $iDefaultConfig) ? $iDefaultConfig[$field] : '?');
                    if ($viData === '?' && $vDataUser !== '?') {
                        dprint("-> Level:$level");
                        dprint("!!! Removed: {$nfields} from UserConfig --> NO Input exists anymore.  Old Value: $fvalue \n");
                        unset($iUserConfig[$field]);
                        $ChangesMade++;
                    }
                }
                //print("<-$level $fields:\n $UserConfigStr --------------------------------\n");
            }
        }
    }
    // dprint(" <- Level:$level Changes:$ChangesMade\n");
    return $ChangesMade;
}

// -------------------------------------------------------------------------------------------------------------
// Function to build a JSON config from the LUA config variables defined in the default and user config files.
// -------------------------------------------------------------------------------------------------------------
function load_Configs()
{
    global $DTGBotDataPath, $ConfigDefault, $ConfigUser;
    $file = $DTGBotDataPath . 'dtgbot__configdefault.json';
    if (file_exists($file)) {
        $output = file_get_contents($file);
        if ($output) {
            $ConfigDefault = json_decode($output, true);
        }
    }
    $file = $DTGBotDataPath . 'dtgbot__configuser.json';
    if (file_exists($file)) {
        $output = file_get_contents($file);
        if ($output) {
            $ConfigUser = json_decode($output, true);
        }
    }
    return;
}

<?php
// configuration
$url = '/';
$DTGBotDataPath = getenv('DTGBotDataPath');
if ($DTGBotDataPath == '') {
    $DTGBotDataPath = '/data/';
}
$clearlog = (isset($_GET['clearlog']) ? $_GET['clearlog'] : "n") ;

// read the textfile
$file = $DTGBotDataPath.'logs/dtgbot.log';
$ConfigUser = $DTGBotDataPath.'dtgbot__configuser.json';
if ($clearlog == 'y') {
    // save log to prev log
    file_put_contents("$file.prev", file_get_contents($file));
    $text = date("Y-m-d H:i:s") . " : -- Log cleared --\n";
    file_put_contents($file, $text);
    echo($text);
} else {
    $logtext = file_get_contents($file);
    preg_match_all("|Telegram ChatID ([-\d]*) Not in ChatIDWhiteList|U",$logtext, $out, PREG_PATTERN_ORDER);
    $cnt = 0;
    if (count($out) > 0) {
        $output = file_get_contents($ConfigUser);
        $CurrDTGBotConfig = json_decode($output, true) ;
    }
    // Process Whitelist against any log message errors to fiend missing chatid's
    foreach ($out[1] as $TelegramId) {
        // Check if in config already
        if (!isset($CurrDTGBotConfig["ChatIDWhiteList"])) {
            $CurrDTGBotConfig["ChatIDWhiteList"] = [];
        }

        if (!isset($CurrDTGBotConfig["ChatIDWhiteList"][$TelegramId])) {
            // Add as blocked and show in the gui
            $cnt += 1;
            $CurrDTGBotConfig["ChatIDWhiteList"][$TelegramId] = ["Name" => "???","Active" => "false"];
            file_put_contents($file, date("Y-m-d H:i:s") . " !!! Telegram ChatID $TelegramId added to ChatIDWhiteList. Open Configuration Menu to unblock the account.\n", FILE_APPEND);
        }
    }
    if ($cnt > 0) {
        // Save the new config
        file_put_contents($ConfigUser, json_encode($CurrDTGBotConfig, JSON_UNESCAPED_SLASHES + JSON_FORCE_OBJECT + JSON_PRETTY_PRINT));
    }

    echo htmlspecialchars((string)file_get_contents($file));
}
?>
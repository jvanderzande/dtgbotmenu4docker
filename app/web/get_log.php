<?php
// configuration

// Check if PIN verification is needed
require_once 'security.php';
if (!requirePIN()) {
    die("Login Required");
}

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
    // exec('bash -c "sh /dtgbotinit/logrotate.sh dtgbot.log" > /tmp/logrotate.log 2>&1');
    rotateLogfile("dtgbot.log", true);
    echo htmlspecialchars((string)file_get_contents($file));
} else {
    // check logrotation first
    rotateLogs();
    // get the text
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

// process logfiles in directory of specific file
function rotateLogs(string $files="dtg*.log", bool $pforced = false): void
{
    $logDir   = '/data/logs';
   /* ---------------- main ---------------- */
    if (!chdir($logDir)) {
        echo "rotateLogs: Cannot change to {$logDir}\n";
        return;
    }

    // get files
    $sfiles = glob($files);
    foreach ($sfiles as $logfile) {
        if (is_file($logfile)) {
            rotateLogfile($logfile, $pforced);
        }
    }
}

// process single logfile
function rotateLogfile(string $file, bool $pforced = false): void
{
    /* ---------------- configuration ---------------- */
    $logDir   = '/data/logs';
    $maxSize  = (getenv('LOG_MAX_SIZE') == '' ? 1 : (int) getenv('LOG_MAX_SIZE')) * 1024 * 1024;   // 1 MB
    $maxAge   = getenv('LOG_MAX_AGE')  == '' ? 7 : (int) getenv('LOG_MAX_AGE');                    // 4 days (creation age)
    $keep     = getenv('LOG_KEEP')      == '' ? 5 : (int) getenv('LOG_KEEP');                      // retain last 5
    $createdFile = '.' . basename($file) . '.created';
    // cd into logdir
    if (!chdir($logDir)) {
        echo "rotateLogs: Cannot change to {$logDir}\n";
        return;
    }

    // initialize creation timestamp
    if (!file_exists($createdFile)) {
        file_put_contents($createdFile, time());
    }

    $created  = (int) file_get_contents($createdFile);
    $ageDays  = intdiv(time() - $created, 86400);
    $size     = filesize($file);

    if (!$pforced && $size < $maxSize && $ageDays < $maxAge) {
        // echo "rotateLogs: Checking {$file} ({$size} < {$maxSize} bytes, {$ageDays}<{$maxAge} days old)\n";
        return;
    }
    // echo "rotateLogs: Rotating {$file} ({$size} < {$maxSize} bytes, {$ageDays}<{$maxAge} days old)\n";

    $timestamp = date('Ymd-His');
    $rotated   = "{$file}.{$timestamp}";

    // echo "  Rotating {$file}\n";

    if (!copy($file, $rotated)) {
        echo "rotateLogs:  !! Failed to copy {$file}\n";
        return;
    }

    // truncate + init line
    file_put_contents(
        $file,
        date('Y-m-d H:i:s') . " Logfile $file rotated to -> {$rotated}\n"
    );

    // compress rotated file
    exec('gzip ' . escapeshellarg($rotated));

    // reset creation time
    file_put_contents($createdFile, time());

    // retention: keep newest N
    $archives = glob("{$file}.*.gz");
    rsort($archives);      // newest first (timestamped names)

    foreach (array_slice($archives, $keep) as $old) {
        unlink($old);
    }
}
?>
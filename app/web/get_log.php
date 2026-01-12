<?php
// configuration

// Check if PIN verification is needed
require_once 'security.php';

// Allow localhost requests without PIN verification
$remoteAddr = $_SERVER['REMOTE_ADDR'];
$isLocalhost = ($remoteAddr === '127.0.0.1' || $remoteAddr === 'localhost' || $remoteAddr === '::1');

if (!$isLocalhost && !requirePIN()) {
    die("Login Required");
}

$url = '/';
$DTGBotDataPath = getenv('DTGBotDataPath');
if ($DTGBotDataPath == '') {
    $DTGBotDataPath = '/data/';
}
$clearlog = (isset($_GET['clearlog']) ? $_GET['clearlog'] : "n") ;
$checklog = (isset($_GET['checklog']) ? "y" : "n") ;

// read the textfile
$file = $DTGBotDataPath.'logs/dtgbot.log';
$prevfile = $DTGBotDataPath.'logs/prev_dtgbot.log';
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
    if ($compressed) {
        $logtext = compressDuplicateLogMessages($logtext);
    }
    if ($lastlines > 0) {
        $lines = explode("\n", $logtext);
        $logtext = implode("\n", array_slice($lines, -$lastlines));
    }
    return $logtext;
}

// Collapse runs of identical log message bodies (keep first and last, insert skipped count)
function compressDuplicateLogMessages(string $logtext): string
{
    $lines = preg_split("/\r\n|\n|\r/", $logtext);
    $out = [];
    $n = count($lines);
    $i = 0;
    while ($i < $n) {
        $line = $lines[$i];
        if ($line === '') {
            $out[] = $line;
            $i++;
            continue;
        }

        // Normalize by removing leading timestamp (YYYY-MM-DD HH:MM:SS : ) if present
        $norm = preg_replace('/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} :\s*/', '', $line);

        // Find run of subsequent lines with same normalized message
        $j = $i + 1;
        while ($j < $n) {
            $next = $lines[$j];
            $nextNorm = preg_replace('/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} :\s*/', '', $next);
            if ($nextNorm === $norm) {
                $j++;
            } else {
                break;
            }
        }

        $run = $j - $i;
        if ($run <= 2) {
            // copy all lines as-is for short runs (1 or 2)
            for ($k = $i; $k < $j; $k++) {
                $out[] = $lines[$k];
            }
        } else {
            // keep first, indicate skipped count, keep last
            $out[] = $lines[$i];
            $skipped = $run - 2;
            $out[] = "--> skipped {$skipped} similar messages.";
            $out[] = $lines[$j - 1];
        }

        $i = $j;
    }

    return implode("\n", $out);
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
        date('Y-m-d H:i:s') . "=============== Logfile $file rotated to -> {$rotated} =======================\n"
    );

    // save dtgbot.log to prevdtgbot.log for display purposes
    if ($file == 'dtgbot.log') {
        copy($file, 'prev_dtgbot.log');
    }
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
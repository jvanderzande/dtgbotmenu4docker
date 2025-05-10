<?php
// configuration
//$_POST['iUrl'] = "http://192.168.0.196:8088/json.htm?type=command&param=getversion"";
//$_POST['iUrl'] = "http://localhost:8086/json.htm?type=command&param=getversion"";

if (!isset($_GET['url']))  die('{"status":"error no url defined"}');

$timeout = intval(isset($_GET['timeout']) ? $_GET['timeout'] : 3) ;
if ($timeout < 1) $timeout = 3;

// set timeout to avoid waiting
ini_set('default_socket_timeout', $timeout);
// return the received response
$resp = @file_get_contents($_GET['url']);
if (isJson($resp)) die ($resp);
die('{"url": "' . $_GET['url'] . '","status":"No JSON response:'.$resp.'"}');

function isJson($string) {
    json_decode($string);
    return json_last_error() === JSON_ERROR_NONE;
 }
?>
<?php

function getLatestDockerHubTag($tag = 'latest'): array
{
    $namespace = 'jvdzande';
    $repo      = 'dtgbotmenu';
    $url = "https://hub.docker.com/v2/repositories/$namespace/$repo/tags?page_size=100";

    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 10,
        CURLOPT_USERAGENT => 'Docker-Version-Checker/1.0'
    ]);

    $response = curl_exec($ch);

    if ($response === false) {
        throw new Exception(curl_error($ch));
    }

    $status = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($status !== 200) {
        throw new Exception("Docker Hub API returned HTTP $status");
    }

    $data = json_decode($response, true);

    if (!isset($data['results'])) {
        throw new Exception("Invalid API response");
    }

    // Find most recently pushed tag
    usort($data['results'], function ($a, $b) {
        return strtotime($b['tag_last_pushed'] ?? 0)
             <=> strtotime($a['tag_last_pushed'] ?? 0);
    });

    $tagdata = $data['results'][0];
    $lastver = $data['results'][1];
    $digest = '';

    // find tag=$tag (latest or prerelease)
    for ($i = 1; $i < count($data['results']); $i++) {
        if ($tag == $data['results'][$i]['name']) {
            $digest = $data['results'][$i]['digest'];
            $tagdata = $data['results'][$i];
            break;
        }
    }
    // find tag=vx.x.x for the same digest used with tag='latest'
    for ($i = 1; $i < count($data['results']); $i++) {
        if ($digest == $data['results'][$i]['digest'] && substr($data['results'][$i]['name'],0,1) == "v") {
            $lastver = $data['results'][$i];
            break;
        }
    }
    return [
        'tag'     => $tagdata['name'],
        'pushed'  => $tagdata['tag_last_pushed'],
        'digest'  => $digest,
        'vtag'     => $lastver['name'],
        'vpushed'     => $lastver['tag_last_pushed']
    ];
}
?>
<?php
if (!defined('OZIE_API')) { http_response_code(403); exit; }

$user = require_auth();
$db   = db();

if (!empty(json_body()['all_devices'])) {
    $uid  = (int)$user['id'];
    $stmt = $db->prepare("DELETE FROM api_tokens WHERE user_id = ?");
    $stmt->bind_param('i', $uid);
} else {
    $tid  = (int)$user['_token_id'];
    $stmt = $db->prepare("DELETE FROM api_tokens WHERE id = ?");
    $stmt->bind_param('i', $tid);
}
$stmt->execute();
$stmt->close();

ok(null, 'Logged out.');

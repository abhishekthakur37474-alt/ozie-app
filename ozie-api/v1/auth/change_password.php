<?php
if (!defined('OZIE_API')) { http_response_code(403); exit; }

$user = require_auth();
require_fields(['current_password', 'new_password']);

$current = input_str('current_password');
$new     = input_str('new_password');

if (strlen($new) < 6)  fail('Password must be at least 6 characters.', 422, ['new_password' => 'Minimum 6 characters.']);
if (strlen($new) > 64) fail('Password must be at most 64 characters.', 422, ['new_password' => 'Maximum 64 characters.']);
if ($new === $current) fail('New password must be different from the current password.', 422, ['new_password' => 'Same as current password.']);

$db  = db();
$uid = (int)$user['id'];

$stmt = $db->prepare("SELECT password FROM users WHERE id = ? LIMIT 1");
$stmt->bind_param('i', $uid);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$row) fail('Password change is not available for this account type.', 409);

// Google-only accounts have an empty password: they can set one without a current password
$hasPassword = ($row['password'] ?? '') !== '';
if ($hasPassword && !password_matches($current, $row['password'])) {
    fail('Current password is incorrect.', 422, ['current_password' => 'Incorrect password.']);
}

$hash = password_hash($new, PASSWORD_DEFAULT);
$upd  = $db->prepare("UPDATE users SET password = ? WHERE id = ?");
$upd->bind_param('si', $hash, $uid);
$upd->execute();
$upd->close();

// Log out every other device, keep this one
$tid = (int)$user['_token_id'];
$del = $db->prepare("DELETE FROM api_tokens WHERE user_id = ? AND id <> ?");
$del->bind_param('ii', $uid, $tid);
$del->execute();
$del->close();

ok(null, 'Password updated successfully.');

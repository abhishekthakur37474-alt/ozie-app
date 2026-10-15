<?php
if (!defined('OZIE_API')) { http_response_code(403); exit; }

require_fields(['token', 'password']);
$token = input_str('token');
$new   = input_str('password');

if (strlen($new) < 4) fail('Password must be at least 4 characters long.', 422);

$db   = db();
$stmt = $db->prepare("SELECT id, password FROM users WHERE reset_token = ? AND reset_token_expiry > NOW() LIMIT 1");
$stmt->bind_param('s', $token);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$row) fail('Invalid or expired password reset link.', 400);

if (!empty($row['password']) && password_verify($new, $row['password'])) {
    fail('Your new password cannot be the same as your current password.', 422);
}

$hash = password_hash($new, PASSWORD_DEFAULT);
$upd  = $db->prepare("UPDATE users SET password = ?, reset_token = NULL, reset_token_expiry = NULL WHERE id = ?");
$upd->bind_param('si', $hash, $row['id']);
$upd->execute();
$upd->close();

// Old sessions must not survive a password reset
$del = $db->prepare("DELETE FROM api_tokens WHERE user_id = ?");
$del->bind_param('i', $row['id']);
$del->execute();
$del->close();

ok(null, 'Your password has been successfully updated.');

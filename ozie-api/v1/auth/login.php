<?php
if (!defined('OZIE_API')) { http_response_code(403); exit; }

require_fields(['login_id', 'password']);
$loginId  = input_str('login_id');
$password = input_str('password');

$db   = db();
$user = find_user_for_login($db, $loginId);

if (!$user || !password_matches($password, $user['password'] ?? null)) {
    fail('Invalid email/mobile or password.', 401);
}

set_audit_context($db, $user);
$token = api_token_create((int)$user['id'], input_str('device_name'));

ok(array_merge($token, session_payload($db, $user)), 'Login successful!');

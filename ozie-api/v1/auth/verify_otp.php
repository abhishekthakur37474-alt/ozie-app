<?php
if (!defined('OZIE_API')) { http_response_code(403); exit; }

require_once __DIR__ . '/_signup_helpers.php';

require_fields(['email', 'otp']);
$email = strtolower(input_str('email'));
$otp   = preg_replace('/\D/', '', input_str('otp'));

if (strlen($otp) !== 6) fail('OTP must be 6 digits.', 422);

$db = db();
ensure_signup_table($db);

$stmt = $db->prepare("SELECT id, mobile, name, password_hash, otp_hash, attempts, (expires_at > NOW()) AS still_valid FROM signup_otps WHERE email = ? LIMIT 1");
$stmt->bind_param('s', $email);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$row) fail('No pending registration found. Please sign up again.', 404);

if (!(int)$row['still_valid']) fail('Expired OTP. Please request a new one.', 410);

if ((int)$row['attempts'] >= SIGNUP_MAX_ATTEMPTS) {
    fail('Too many wrong attempts. Please request a new code.', 429);
}

if (!hash_equals((string)$row['otp_hash'], signup_otp_hash($otp, $email))) {
    $upd = $db->prepare("UPDATE signup_otps SET attempts = attempts + 1 WHERE id = ?");
    $upd->bind_param('i', $row['id']);
    $upd->execute();
    $upd->close();
    fail('Invalid OTP. Please check the code and try again.', 422);
}

$name   = (string)$row['name'];
$mobile = (string)$row['mobile'];

// Someone may have registered with this email/mobile while OTP was pending
$conflict = signup_conflict($db, $email, $mobile);
if ($conflict) {
    $del = $db->prepare("DELETE FROM signup_otps WHERE id = ?");
    $del->bind_param('i', $row['id']);
    $del->execute();
    $del->close();
    fail($conflict, 409);
}

$ins = $db->prepare(
    "INSERT INTO users (name, email, mobile, password, user_type, retailer_form_filled, date_reg, is_verified)
     VALUES (?, ?, ?, ?, '', 0, NOW(), 1)"
);
$ins->bind_param('ssss', $name, $email, $mobile, $row['password_hash']);
$ins->execute();
$newId = (int)$db->insert_id;
$ins->close();

$del = $db->prepare("DELETE FROM signup_otps WHERE id = ?");
$del->bind_param('i', $row['id']);
$del->execute();
$del->close();

$user = [
    'id'                   => $newId,
    'name'                 => $name,
    'email'                => $email,
    'mobile'               => $mobile,
    'user_type'            => '',
    'retailer_form_filled' => 0,
];

set_audit_context($db, $user);
$token = api_token_create($newId, input_str('device_name'));

ok(array_merge($token, session_payload($db, $user)), 'Account verification completed successfully!', 201);

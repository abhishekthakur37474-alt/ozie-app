<?php
if (!defined('OZIE_API')) { http_response_code(403); exit; }

require_once __DIR__ . '/_signup_helpers.php';

require_fields(['name', 'email', 'mobile', 'password']);

$name     = input_str('name');
$email    = strtolower(input_str('email'));
$mobile   = normalize_mobile_number(input_str('mobile'));
$password = input_str('password');
$method   = strtolower(input_str('verify_method', 'email'));

$errors = [];
if (mb_strlen($name) < 2 || mb_strlen($name) > 100) $errors['name'] = 'Please enter your full name.';
if (strlen($email) > 255 || !filter_var($email, FILTER_VALIDATE_EMAIL)) $errors['email'] = 'Please provide a valid email address.';
if (!preg_match('/^[0-9]{10}$/', $mobile)) $errors['mobile'] = 'Mobile number must be exactly 10 digits.';
if (strlen($password) < 6) $errors['password'] = 'Password must be at least 6 characters.';
if (strlen($password) > 64) $errors['password'] = 'Password must be at most 64 characters.';
if (!in_array($method, ['email', 'mobile'], true)) $errors['verify_method'] = 'Invalid verification channel.';
if ($errors) fail(reset($errors), 422, $errors);

$db = db();
ensure_signup_table($db);

$conflict = signup_conflict($db, $email, $mobile);
if ($conflict) fail($conflict, 409);

// Throttle: one OTP per email per SIGNUP_RESEND_SECONDS
$stmt = $db->prepare("SELECT TIMESTAMPDIFF(SECOND, last_sent_at, NOW()) AS age FROM signup_otps WHERE email = ? LIMIT 1");
$stmt->bind_param('s', $email);
$stmt->execute();
$pending = $stmt->get_result()->fetch_assoc();
$stmt->close();
if ($pending && (int)$pending['age'] < SIGNUP_RESEND_SECONDS) {
    $wait = SIGNUP_RESEND_SECONDS - (int)$pending['age'];
    fail("Please wait $wait seconds before requesting another code.", 429);
}

$otp    = signup_otp_make();
$ohash  = signup_otp_hash($otp, $email);
$phash  = password_hash($password, PASSWORD_DEFAULT);
$ttl    = max(1, (int)config('otp_ttl_minutes', 10));

$stmt = $db->prepare(
    "INSERT INTO signup_otps (email, mobile, name, password_hash, verify_method, otp_hash, attempts, expires_at, last_sent_at)
     VALUES (?, ?, ?, ?, ?, ?, 0, DATE_ADD(NOW(), INTERVAL $ttl MINUTE), NOW())
     ON DUPLICATE KEY UPDATE
        mobile = VALUES(mobile), name = VALUES(name), password_hash = VALUES(password_hash),
        verify_method = VALUES(verify_method), otp_hash = VALUES(otp_hash), attempts = 0,
        expires_at = VALUES(expires_at), last_sent_at = VALUES(last_sent_at)"
);
$stmt->bind_param('ssssss', $email, $mobile, $name, $phash, $method, $ohash);
$stmt->execute();
$stmt->close();

if (!signup_send_otp($method, $email, $mobile, $name, $otp)) {
    $del = $db->prepare("DELETE FROM signup_otps WHERE email = ?");
    $del->bind_param('s', $email);
    $del->execute();
    $del->close();
    fail($method === 'mobile'
        ? 'Failed to send the WhatsApp code. Please try again.'
        : 'Failed to send the verification email. Please try again.', 502);
}

ok([
    'email'         => $email,
    'verify_method' => $method,
    'expires_in'    => $ttl * 60,
    'resend_after'  => SIGNUP_RESEND_SECONDS,
], $method === 'mobile'
    ? 'OTP verification code sent to your WhatsApp number.'
    : 'OTP verification code sent to your email.');

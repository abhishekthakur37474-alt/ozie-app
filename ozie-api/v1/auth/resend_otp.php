<?php
if (!defined('OZIE_API')) { http_response_code(403); exit; }

require_once __DIR__ . '/_signup_helpers.php';

require_fields(['email']);
$email = strtolower(input_str('email'));

$db = db();
ensure_signup_table($db);

$stmt = $db->prepare("SELECT mobile, name, verify_method, TIMESTAMPDIFF(SECOND, last_sent_at, NOW()) AS age FROM signup_otps WHERE email = ? LIMIT 1");
$stmt->bind_param('s', $email);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$row) fail('No pending registration found. Please sign up again.', 404);

if ((int)$row['age'] < SIGNUP_RESEND_SECONDS) {
    $wait = SIGNUP_RESEND_SECONDS - (int)$row['age'];
    fail("Please wait $wait seconds before requesting another code.", 429);
}

$otp   = signup_otp_make();
$ohash = signup_otp_hash($otp, $email);
$ttl   = max(1, (int)config('otp_ttl_minutes', 10));

if (!signup_send_otp((string)$row['verify_method'], $email, (string)$row['mobile'], (string)$row['name'], $otp)) {
    fail('Failed to resend the code. Please try again.', 502);
}

$upd = $db->prepare("UPDATE signup_otps SET otp_hash = ?, attempts = 0, expires_at = DATE_ADD(NOW(), INTERVAL $ttl MINUTE), last_sent_at = NOW() WHERE email = ?");
$upd->bind_param('ss', $ohash, $email);
$upd->execute();
$upd->close();

ok([
    'resend_after' => SIGNUP_RESEND_SECONDS,
    'expires_in'   => $ttl * 60,
], 'New verification code sent.');

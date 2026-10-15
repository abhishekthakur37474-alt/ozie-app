<?php
if (!defined('OZIE_API')) { http_response_code(403); exit; }

// Same behaviour as web forgot-password.php (email link or WhatsApp link)
require_fields(['identifier']);
$identifier = input_str('identifier');
$db = db();

$expiry = date('Y-m-d H:i:s', strtotime('+10 minutes'));
$token  = bin2hex(random_bytes(16));

if (filter_var($identifier, FILTER_VALIDATE_EMAIL)) {
    $stmt = $db->prepare("SELECT id, name, email FROM users WHERE LOWER(email) = LOWER(?) LIMIT 1");
    $stmt->bind_param('s', $identifier);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$row) fail('This email address is not registered in our database.', 404);

    $upd = $db->prepare("UPDATE users SET reset_token = ?, reset_token_expiry = ? WHERE id = ?");
    $upd->bind_param('ssi', $token, $expiry, $row['id']);
    $upd->execute();
    $upd->close();

    $link = config('reset_link_base') . $token;
    if (!send_reset_email($row['email'], $link, (string)$row['name'])) {
        fail('Failed to deliver the recovery email. Please try again later.', 502);
    }
    ok(['channel' => 'email'], 'A secure recovery link has been dispatched to your email.');
}

$mobile = preg_replace('/[^0-9]/', '', $identifier);
if (strlen($mobile) < 10 || strlen($mobile) > 15) {
    fail('Please enter a valid email address or mobile number.', 422);
}

$like = '%' . substr($mobile, -10);
$stmt = $db->prepare("SELECT id, name, mobile FROM users WHERE mobile LIKE ? LIMIT 1");
$stmt->bind_param('s', $like);
$stmt->execute();
$row = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$row) fail('This mobile number is not registered in our database.', 404);

$upd = $db->prepare("UPDATE users SET reset_token = ?, reset_token_expiry = ? WHERE id = ?");
$upd->bind_param('ssi', $token, $expiry, $row['id']);
$upd->execute();
$upd->close();

if (!send_reset_whatsapp((string)$row['mobile'], (string)$row['name'], $token)) {
    fail('Failed to deliver recovery message via WhatsApp. Please try email recovery instead.', 502);
}
ok(['channel' => 'whatsapp'], 'A secure recovery link has been dispatched to your registered WhatsApp number.');

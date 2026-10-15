<?php
if (!defined('OZIE_API')) { http_response_code(403); exit; }

// Flutter: FirebaseAuth user.getIdToken() -> send as id_token
require_fields(['id_token']);
$idToken = input_str('id_token');

$apiKey = config('firebase_api_key');
$ch = curl_init('https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=' . urlencode((string)$apiKey));
curl_setopt_array($ch, [
    CURLOPT_POST           => true,
    CURLOPT_POSTFIELDS     => json_encode(['idToken' => $idToken]),
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER     => ['Content-Type: application/json'],
    CURLOPT_TIMEOUT        => 15,
]);
$resp = curl_exec($ch);
$http = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

$fb = json_decode((string)$resp, true);
if ($http !== 200 || empty($fb['users'][0]['localId'])) {
    fail('Google sign-in could not be verified. Please try again.', 401);
}

$fbUser = $fb['users'][0];
$uid    = (string)$fbUser['localId'];
$email  = trim((string)($fbUser['email'] ?? ''));
$name   = trim((string)($fbUser['displayName'] ?? input_str('name')));
if ($email === '') fail('Email is required.', 422);
if ($name === '')  $name = strstr($email, '@', true) ?: 'User';

$db = db();
$stmt = $db->prepare("SELECT id, name, email, mobile, user_type, retailer_form_filled FROM users WHERE firebase_uid = ? OR LOWER(email) = LOWER(?) LIMIT 1");
$stmt->bind_param('ss', $uid, $email);
$stmt->execute();
$user = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$user) {
    // Same as web save_users.php: new Google user = retailer, form marked filled
    // mobile/password are NOT NULL without default in `users`, so insert explicit empty values
    $ins = $db->prepare("INSERT INTO users (firebase_uid, name, email, mobile, password, user_type, retailer_form_filled) VALUES (?, ?, ?, '', '', 'retailer', 1)");
    $ins->bind_param('sss', $uid, $name, $email);
    $ins->execute();
    $newId = (int)$db->insert_id;
    $ins->close();

    $user = [
        'id' => $newId, 'name' => $name, 'email' => $email, 'mobile' => null,
        'user_type' => 'retailer', 'retailer_form_filled' => 1,
    ];
} else {
    $upd = $db->prepare("UPDATE users SET firebase_uid = ? WHERE id = ? AND (firebase_uid IS NULL OR firebase_uid = '')");
    $upd->bind_param('si', $uid, $user['id']);
    $upd->execute();
    $upd->close();
}

set_audit_context($db, $user);
$token = api_token_create((int)$user['id'], input_str('device_name'));

ok(array_merge($token, session_payload($db, $user)), 'Login successful!');

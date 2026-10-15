<?php
if (!defined('OZIE_API')) { http_response_code(403); exit; }

/**
 * Partial update. Send only the fields you want to change.
 *   users    : name
 *   retailer : shop_name, address, city, state, pincode   (only if retailer row exists)
 * Email / mobile / credit / GST / PAN are NOT editable here (need verification / admin).
 */
if (!function_exists('mb_strlen')) {   // hosts without mbstring
    function mb_strlen($s) { return strlen($s); }
}

$user = require_auth();
$db   = db();
$uid  = (int)$user['id'];
$body = json_body();

$userFields     = ['name'];
$retailerFields = ['shop_name', 'address', 'city', 'state', 'pincode'];

$errors = [];
$u = [];
$r = [];

foreach ($userFields as $f) {
    if (array_key_exists($f, $body)) $u[$f] = input_str($f);
}
foreach ($retailerFields as $f) {
    if (array_key_exists($f, $body)) $r[$f] = input_str($f);
}

if (!$u && !$r) fail('Nothing to update.', 422);

if (isset($u['name']) && (mb_strlen($u['name']) < 2 || mb_strlen($u['name']) > 100)) {
    $errors['name'] = 'Please enter your full name (2-100 characters).';
}
if (isset($r['shop_name']) && ($r['shop_name'] === '' || mb_strlen($r['shop_name']) > 255)) {
    $errors['shop_name'] = 'Shop name is required (max 255 characters).';
}
if (isset($r['address']) && ($r['address'] === '' || mb_strlen($r['address']) > 1000)) {
    $errors['address'] = 'Address is required.';
}
if (isset($r['city']) && ($r['city'] === '' || mb_strlen($r['city']) > 100)) {
    $errors['city'] = 'City is required.';
}
if (isset($r['state']) && ($r['state'] === '' || mb_strlen($r['state']) > 100)) {
    $errors['state'] = 'State is required.';
}
if (isset($r['pincode']) && !preg_match('/^[0-9]{6}$/', $r['pincode'])) {
    $errors['pincode'] = 'Pincode must be 6 digits.';
}
if ($errors) fail(reset($errors), 422, $errors);

$db->begin_transaction();
try {
    if (isset($u['name'])) {
        $s = $db->prepare("UPDATE users SET name = ? WHERE id = ?");
        $s->bind_param('si', $u['name'], $uid);
        $s->execute();
        $s->close();

        // keep the retailer row's display name in sync
        $s = $db->prepare("UPDATE retailer SET name = ? WHERE user_id = ?");
        $s->bind_param('si', $u['name'], $uid);
        $s->execute();
        $s->close();
    }

    if ($r) {
        $chk = $db->prepare("SELECT id FROM retailer WHERE user_id = ? LIMIT 1");
        $chk->bind_param('i', $uid);
        $chk->execute();
        $chk->store_result();
        $has = $chk->num_rows > 0;
        $chk->close();

        if (!$has) {
            $db->rollback();
            fail('Retailer profile is not available yet. It is created after approval.', 409);
        }

        $sets = [];
        $vals = [];
        foreach ($r as $col => $val) {   // $col comes from the fixed whitelist above
            $sets[] = "`$col` = ?";
            $vals[] = $val;
        }
        $vals[] = $uid;
        $sql = "UPDATE retailer SET " . implode(', ', $sets) . " WHERE user_id = ?";
        $s = $db->prepare($sql);
        $s->bind_param(str_repeat('s', count($vals) - 1) . 'i', ...$vals);
        $s->execute();
        $s->close();
    }

    $db->commit();
} catch (Throwable $e) {
    $db->rollback();
    throw $e;
}

// Return the fresh profile in the same shape as GET
require __DIR__ . '/get.php';

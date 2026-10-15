<?php
if (!defined('OZIE_API')) { http_response_code(403); exit; }

$user = require_auth();
$db   = db();
$uid  = (int)$user['id'];

function photo_url(?string $path): ?string
{
    $path = trim((string)$path);
    if ($path === '') return null;
    if (preg_match('#^https?://#i', $path)) return $path;
    $base = rtrim((string)config('public_base_url', 'https://demo.orderezee.com/'), '/') . '/';
    return $base . ltrim($path, '/');
}

// ---- users row
$stmt = $db->prepare("SELECT id, name, email, mobile, user_type, retailer_form_filled, manufacturer_code, profile_photo, date_reg, is_verified FROM users WHERE id = ? LIMIT 1");
$stmt->bind_param('i', $uid);
$stmt->execute();
$u = $stmt->get_result()->fetch_assoc();
$stmt->close();

$profile = [
    'id'            => $uid,
    'name'          => $u['name']   ?? ($user['name'] ?? null),
    'email'         => $u['email']  ?? ($user['email'] ?? null),
    'mobile'        => $u['mobile'] ?? ($user['mobile'] ?? null),
    'user_type'     => (($u['user_type'] ?? $user['user_type'] ?? '') !== '') ? ($u['user_type'] ?? $user['user_type']) : null,
    'is_verified'   => isset($u['is_verified']) ? ((int)$u['is_verified'] === 1) : null,
    'member_since'  => $u['date_reg'] ?? null,
    'photo'         => $u['profile_photo'] ?? null,
    'photo_url'     => photo_url($u['profile_photo'] ?? null),
];

// ---- retailer details (only exists after approval/onboarding)
$retailer = null;
$stmt = $db->prepare(
    "SELECT name, shop_name, address, city, state, pincode, gps_coordinates, gst, pan, photo,
            retailer_code, category, credit_limit, current_balance, credit_duration, status
     FROM retailer WHERE user_id = ? LIMIT 1"
);
$stmt->bind_param('i', $uid);
$stmt->execute();
$r = $stmt->get_result()->fetch_assoc();
$stmt->close();

if ($r) {
    $limit   = (float)($r['credit_limit'] ?? 0);
    $balance = (float)($r['current_balance'] ?? 0);
    $retailer = [
        'name'             => $r['name'],
        'shop_name'        => $r['shop_name'],
        'address'          => $r['address'],
        'city'             => $r['city'],
        'state'            => $r['state'],
        'pincode'          => $r['pincode'],
        'gps_coordinates'  => $r['gps_coordinates'],
        'gst'              => $r['gst'],
        'pan'              => $r['pan'],
        'retailer_code'    => $r['retailer_code'],
        'category'         => $r['category'],
        'status'           => $r['status'],
        'credit_limit'     => $limit,
        'current_balance'  => $balance,
        'available_credit' => max(0, $limit - $balance),
        'credit_days'      => (int)($r['credit_duration'] ?? 0),
        'photo'            => $r['photo'],
        'photo_url'        => photo_url($r['photo']),
    ];
    if (!$profile['photo_url'] && $retailer['photo_url']) {
        $profile['photo']     = $retailer['photo'];
        $profile['photo_url'] = $retailer['photo_url'];
    }
}

// ---- license details
$license = null;
$stmt = $db->prepare(
    "SELECT license_copy, license_holder_name, license_holder_contact, license_holder_address,
            operator_license_name, operator_license_contact, operator_license_address
     FROM retailer_license WHERE retailer_id = ? LIMIT 1"
);
$stmt->bind_param('i', $uid);
$stmt->execute();
$l = $stmt->get_result()->fetch_assoc();
$stmt->close();

if ($l) {
    $license = [
        'license_copy_url'         => photo_url($l['license_copy']),
        'holder_name'              => $l['license_holder_name'],
        'holder_contact'           => $l['license_holder_contact'],
        'holder_address'           => $l['license_holder_address'],
        'operator_name'            => $l['operator_license_name'],
        'operator_contact'         => $l['operator_license_contact'],
        'operator_address'         => $l['operator_license_address'],
    ];
}

ok(['profile' => $profile, 'retailer' => $retailer, 'license' => $license]);

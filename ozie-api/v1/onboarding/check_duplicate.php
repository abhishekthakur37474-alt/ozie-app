<?php
if (!defined('OZIE_API')) { http_response_code(403); exit; }

/**
 * Live check while the retailer form is being filled (same as web check_duplicate_contact / check_duplicate_license).
 * Body: { "contact_number": "98xxxxxxxx" }  and/or  { "license_number": "L-123" }
 * Returns: { contact_available: bool, license_available: bool }  (only the keys you asked for)
 */
if (!function_exists('digits10')) {
    function digits10($v): string
    {
        $v = preg_replace('/^\+91|^0/', '', (string)$v);
        return preg_replace('/\D/', '', $v);
    }
}

$user = require_auth();
$db   = db();
$uid  = (int)$user['id'];

$contact = digits10(input_str('contact_number'));
$license = input_str('license_number');

if ($contact === '' && $license === '') {
    fail('Provide contact_number or license_number.', 422);
}

$out = [];

if ($contact !== '') {
    if (!preg_match('/^[0-9]{10}$/', $contact)) {
        fail('Contact Number must be exactly 10 digits.', 422, ['contact_number' => 'Must be 10 digits.']);
    }
    $s = $db->prepare("SELECT id FROM vendor_data_sheet WHERE contact_number = ? LIMIT 1");
    $s->bind_param('s', $contact);
    $s->execute();
    $s->store_result();
    $inVendor = $s->num_rows > 0;
    $s->close();

    $s = $db->prepare("SELECT id FROM users WHERE mobile = ? AND id <> ? LIMIT 1");
    $s->bind_param('si', $contact, $uid);
    $s->execute();
    $s->store_result();
    $inUsers = $s->num_rows > 0;
    $s->close();

    $out['contact_available'] = !($inVendor || $inUsers);
}

if ($license !== '') {
    $s = $db->prepare("SELECT id FROM vendor_data_sheet WHERE license_number = ? LIMIT 1");
    $s->bind_param('s', $license);
    $s->execute();
    $s->store_result();
    $out['license_available'] = !($s->num_rows > 0);
    $s->close();
}

ok($out);

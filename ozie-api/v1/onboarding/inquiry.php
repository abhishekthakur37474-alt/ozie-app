<?php
if (!defined('OZIE_API')) { http_response_code(403); exit; }

$user = require_auth();
require_fields(['company_name', 'name', 'contact_number', 'location', 'user_type']);

$company  = input_str('company_name');
$name     = input_str('name');
$contact  = input_str('contact_number');
$industry = input_str('industry');
$location = input_str('location');
$type     = input_str('user_type');
$userId   = (int)$user['id'];
$email    = (string)($user['email'] ?: 'N/A');

$db = db();

// One inquiry per user
$chk = $db->prepare("SELECT id FROM onboarding_inquiries WHERE user_id = ? LIMIT 1");
$chk->bind_param('i', $userId);
$chk->execute();
$chk->store_result();
$exists = $chk->num_rows > 0;
$chk->close();
if ($exists) fail('Your details are already submitted. Our team will contact you.', 409);

// Same as web user-role-selection.php: table is created on first use (DDL must run before the transaction)
$db->query("CREATE TABLE IF NOT EXISTS admin_manufacture (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    company_name VARCHAR(255),
    contact_person VARCHAR(255),
    contact_number VARCHAR(50),
    email VARCHAR(255),
    user_type VARCHAR(50),
    industry VARCHAR(255),
    location VARCHAR(255),
    status VARCHAR(50) DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)");

$db->begin_transaction();
try {
    $s1 = $db->prepare("INSERT INTO onboarding_inquiries (user_id, company_name, name, contact_number, industry, location, user_type) VALUES (?, ?, ?, ?, ?, ?, ?)");
    $s1->bind_param('issssss', $userId, $company, $name, $contact, $industry, $location, $type);
    $s1->execute();
    $s1->close();

    $title = "New Network Inquiry ($type)";
    $msg   = "A new $type inquiry was submitted by $name from $company. Contact: $contact. Location: $location.";
    $s2 = $db->prepare("INSERT INTO admin_notifications (user_id, title, message) VALUES (?, ?, ?)");
    $s2->bind_param('iss', $userId, $title, $msg);
    $s2->execute();
    $s2->close();

    $s3 = $db->prepare("INSERT INTO admin_manufacture (user_id, company_name, contact_person, contact_number, email, user_type, industry, location) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
    $s3->bind_param('isssssss', $userId, $company, $name, $contact, $email, $type, $industry, $location);
    $s3->execute();
    $s3->close();

    $db->commit();
} catch (Throwable $e) {
    $db->rollback();
    throw $e;
}

ok(['inquiry_submitted' => true], 'Details submitted successfully.', 201);

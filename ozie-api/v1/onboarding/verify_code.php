<?php
if (!defined('OZIE_API')) { http_response_code(403); exit; }

require_auth();
require_fields(['code']);
$code = input_str('code');

$stmt = db()->prepare("SELECT id FROM users WHERE manufacturer_code = ? LIMIT 1");
$stmt->bind_param('s', $code);
$stmt->execute();
$stmt->store_result();
$valid = $stmt->num_rows > 0;
$stmt->close();

if (!$valid) fail('Invalid Introduction Code. Please try again.', 422);

// App should now open the retailer form and send this code along with it
ok(['verified' => true, 'code' => $code], 'Code verified successfully!');

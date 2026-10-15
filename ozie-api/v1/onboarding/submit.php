<?php
if (!defined('OZIE_API')) { http_response_code(403); exit; }

/**
 * Retailer registration form (self onboarding). Mirrors web retailer-form.php:
 *  - saves one row in vendor_data_sheet (final_status = 'submitted', salesman_id = 0)
 *  - sets users.mobile = contact_number and users.retailer_form_filled = 1
 *  - notifies all sales_team_leader users
 * After success auth/me returns next_screen = wait_for_approval.
 *
 * JSON body (same names as the web form):
 *  license_retailer_name*, license_number*, shop_name*, contact_number*(10 digits), email,
 *  alternate_contact_number, shop_operator_name, shop_operator_number, outlet_type (Retail|Bar|Restaurant|Wholesale),
 *  area_territory, building_number*, street_name*, landmark, area_locality*, city*, state*, pincode*, country,
 *  latitude, longitude, gps_coordinates, confirm_location_chk*(true),
 *  most_selling_brands*[] , category_preference[], avg_monthly_purchase_cases, our_brand_availability (Yes|No),
 *  avg_monthly_offtake, out_of_stock_frequency (High|Medium|Low), retailer_expectations[],
 *  stock_holding_capacity, purchasing_capacity, payment_behavior, our_brand_visibility, support_towards_brand (each 1-5),
 *  license_photo (base64 string), shop_photos (array of base64 strings, max 5)
 */
if (!function_exists('digits10')) {
    function digits10($v): string
    {
        $v = preg_replace('/^\+91|^0/', '', (string)$v);
        return preg_replace('/\D/', '', $v);
    }
}

function input_list(string $key, int $maxItems = 20): array
{
    $v = json_body()[$key] ?? [];
    if (is_string($v)) {
        $dec = json_decode($v, true);
        $v = is_array($dec) ? $dec : explode(',', $v);
    }
    if (!is_array($v)) return [];
    $out = [];
    foreach ($v as $item) {
        if (!is_scalar($item)) continue;
        $t = trim((string)$item);
        if ($t !== '') $out[] = function_exists('mb_substr') ? mb_substr($t, 0, 100) : substr($t, 0, 100);
        if (count($out) >= $maxItems) break;
    }
    return $out;
}

function input_flag(string $key): bool
{
    $v = json_body()[$key] ?? false;
    return $v === true || $v === 1 || in_array(strtolower((string)$v), ['1', 'true', 'on', 'yes'], true);
}

/** Decodes a base64 / data-URI image, validates it is a real jpeg/png/webp, saves it, returns the file name. */
function save_b64_image(string $b64, string $dir, string $suffix, ?string &$err): ?string
{
    $b64 = preg_replace('#^data:image/[a-zA-Z0-9.+-]+;base64,#', '', trim($b64));
    $b64 = str_replace(' ', '+', $b64);
    $bin = base64_decode($b64, true);
    if ($bin === false || $bin === '') { $err = 'Invalid image data.'; return null; }
    if (strlen($bin) > 4 * 1024 * 1024) { $err = 'Image is too large (max 4 MB).'; return null; }

    $info = @getimagesizefromstring($bin);
    $map  = ['image/jpeg' => 'jpg', 'image/png' => 'png', 'image/webp' => 'webp'];
    if (!$info || !isset($map[$info['mime']])) { $err = 'Only JPG, PNG or WEBP images are allowed.'; return null; }

    $name = time() . '_' . bin2hex(random_bytes(3)) . '_' . $suffix . '.' . $map[$info['mime']];
    if (file_put_contents($dir . $name, $bin) === false) { $err = 'Could not save image.'; return null; }
    @chmod($dir . $name, 0644);
    return $name;
}

$user = require_auth();
$db   = db();
$uid  = (int)$user['id'];

// Only new accounts without a role can self-submit (same rule as web)
if (trim((string)($user['user_type'] ?? '')) !== '') {
    fail('Retailer form is only for new accounts waiting for onboarding.', 403);
}
if (resolve_user_state($db, $user)['next_screen'] === 'wait_for_approval') {
    fail('Your form is already submitted and under review.', 409);
}

// ---------- read + validate
$errors = [];

$licenseName = input_str('license_retailer_name');
$licenseNo   = input_str('license_number');
$shopName    = input_str('shop_name');
$email       = input_str('email');
$contact     = digits10(input_str('contact_number'));
$alt         = digits10(input_str('alternate_contact_number'));
$opName      = input_str('shop_operator_name');
$opNumber    = digits10(input_str('shop_operator_number'));
$outlet      = input_str('outlet_type', 'Retail');
$territory   = input_str('area_territory');

if ($licenseName === '') $errors['license_retailer_name'] = 'License Retailer Name is required.';
if ($licenseNo === '')   $errors['license_number']        = 'License Number is required.';
if ($shopName === '')    $errors['shop_name']             = 'Shop Name is required.';
if (!preg_match('/^[0-9]{10}$/', $contact)) $errors['contact_number'] = 'Contact Number must be exactly 10 digits.';
if ($email !== '' && !filter_var($email, FILTER_VALIDATE_EMAIL)) $errors['email'] = 'Please provide a valid Email Address.';
if ($alt !== '' && !preg_match('/^[0-9]{10}$/', $alt)) $errors['alternate_contact_number'] = 'Alternate Contact Number must be exactly 10 digits.';
if ($opNumber !== '' && !preg_match('/^[0-9]{10}$/', $opNumber)) $errors['shop_operator_number'] = 'Shop Operator Contact Number must be exactly 10 digits.';
if (!in_array($outlet, ['Retail', 'Bar', 'Restaurant', 'Wholesale'], true)) $errors['outlet_type'] = 'Invalid outlet type.';

$building = input_str('building_number');
$street   = input_str('street_name');
$landmark = input_str('landmark');
$locality = input_str('area_locality');
$city     = input_str('city');
$state    = input_str('state');
$pincode  = input_str('pincode');
$country  = input_str('country', 'India');
if ($country === '') $country = 'India';

if ($building === '') $errors['building_number'] = 'Shop/Building Number is required.';
if ($street === '')   $errors['street_name']     = 'Street/Road Name is required.';
if ($locality === '') $errors['area_locality']   = 'Area/Locality is required.';
if ($city === '')     $errors['city']            = 'City is required.';
if ($state === '')    $errors['state']           = 'State is required.';
if ($pincode === '')  $errors['pincode']         = 'Pincode is required.';
elseif (strcasecmp($country, 'India') === 0 && !preg_match('/^[0-9]{6}$/', $pincode)) $errors['pincode'] = 'Pincode must be 6 digits.';
if (!input_flag('confirm_location_chk')) $errors['confirm_location_chk'] = 'Please confirm that you have verified the location.';

$lat = (float)(json_body()['latitude']  ?? 0);
$lng = (float)(json_body()['longitude'] ?? 0);
if ($lat < -90 || $lat > 90 || $lng < -180 || $lng > 180) $errors['latitude'] = 'Invalid coordinates.';
$gps = input_str('gps_coordinates');
if ($gps === '' && ($lat != 0.0 || $lng != 0.0)) $gps = $lat . ',' . $lng;

$brands = input_list('most_selling_brands');
if (!$brands) $errors['most_selling_brands'] = 'Add at least one most selling brand.';
$categories   = input_list('category_preference');
$expectations = input_list('retailer_expectations');

$avail = input_str('our_brand_availability', 'No');
$oos   = input_str('out_of_stock_frequency', 'Medium');
if (!in_array($avail, ['Yes', 'No'], true)) $errors['our_brand_availability'] = 'Must be Yes or No.';
if (!in_array($oos, ['High', 'Medium', 'Low'], true)) $errors['out_of_stock_frequency'] = 'Must be High, Medium or Low.';

$cases   = max(0, min(10000000, (int)input_str('avg_monthly_purchase_cases', '0')));
$offtake = max(0, min(10000000, (int)input_str('avg_monthly_offtake', '0')));

$scores = [];
foreach (['stock_holding_capacity', 'purchasing_capacity', 'payment_behavior', 'our_brand_visibility', 'support_towards_brand'] as $k) {
    $n = (int)input_str($k, '0');
    if ($n < 0 || $n > 5) $errors[$k] = 'Score must be between 1 and 5.';
    $scores[$k] = $n;
}
$total = array_sum($scores);
$avg   = round($total / 5, 2);

// ---------- duplicates (same rules as web)
if ($licenseNo !== '' && !isset($errors['license_number'])) {
    $s = $db->prepare("SELECT id FROM vendor_data_sheet WHERE license_number = ? LIMIT 1");
    $s->bind_param('s', $licenseNo);
    $s->execute();
    $s->store_result();
    if ($s->num_rows > 0) $errors['license_number'] = 'This License Number is already registered.';
    $s->close();
}
if (!isset($errors['contact_number'])) {
    $s = $db->prepare("SELECT id FROM vendor_data_sheet WHERE contact_number = ? LIMIT 1");
    $s->bind_param('s', $contact);
    $s->execute();
    $s->store_result();
    $dupVendor = $s->num_rows > 0;
    $s->close();

    $s = $db->prepare("SELECT id FROM users WHERE mobile = ? AND id <> ? LIMIT 1");
    $s->bind_param('si', $contact, $uid);
    $s->execute();
    $s->store_result();
    $dupUser = $s->num_rows > 0;
    $s->close();

    if ($dupVendor || $dupUser) $errors['contact_number'] = 'This Contact Number is already registered.';
}

// ---------- photos (saved only if everything else is valid)
$uploadDir = (string)config('uploads_dir', dirname(__DIR__, 3) . '/uploads/retailers/');
$uploadDir = rtrim($uploadDir, '/\\') . '/';
$licensePhotoIn = input_str('license_photo');
$shopPhotosIn   = json_body()['shop_photos'] ?? [];
if (!is_array($shopPhotosIn)) $shopPhotosIn = [];
$shopPhotosIn = array_values(array_filter($shopPhotosIn, 'is_string'));
if (count($shopPhotosIn) > 5) $errors['shop_photos'] = 'Maximum 5 shop photos allowed.';

if ($errors) fail(reset($errors), 422, $errors);

if (!is_dir($uploadDir) && !@mkdir($uploadDir, 0755, true)) {
    error_log('[ozie-api] cannot create upload dir ' . $uploadDir);
    fail('Server cannot store photos right now. Please contact support.', 500);
}

$saved = [];   // file names, for cleanup on failure
$licensePhoto = '';
$shopPhotos   = [];
$imgErr = null;

if ($licensePhotoIn !== '') {
    $licensePhoto = save_b64_image($licensePhotoIn, $uploadDir, 'license', $imgErr);
    if ($licensePhoto === null) fail($imgErr, 422, ['license_photo' => $imgErr]);
    $saved[] = $licensePhoto;
}
foreach ($shopPhotosIn as $i => $b64) {
    $n = save_b64_image($b64, $uploadDir, 'shop' . $i, $imgErr);
    if ($n === null) {
        foreach ($saved as $f) @unlink($uploadDir . $f);
        fail($imgErr, 422, ['shop_photos' => "Photo " . ($i + 1) . ": $imgErr"]);
    }
    $saved[]      = $n;
    $shopPhotos[] = $n;
}

$fullAddress = trim("$building, $street, " . ($landmark !== '' ? "$landmark, " : '') . "$locality, $city, $state - $pincode, $country");

$row = [
    'salesman_id'              => 0,
    'license_vendor_name'      => $licenseName,
    'license_number'           => $licenseNo,
    'shop_name'                => $shopName,
    'contact_number'           => $contact,
    'alternate_contact_number' => $alt,
    'email'                    => $email,
    'salesman_name'            => $opName,
    'salesman_contact_number'  => $opNumber,
    'area_territory'           => $territory,
    'exact_location'           => $fullAddress,
    'outlet_type'              => $outlet,
    'gps_coordinates'          => $gps,
    'most_selling_brands'      => json_encode($brands, JSON_UNESCAPED_UNICODE),
    'category_preference'      => json_encode($categories, JSON_UNESCAPED_UNICODE),
    'avg_monthly_purchase_cases' => $cases,
    'our_brand_availability'   => $avail,
    'avg_monthly_offtake'      => $offtake,
    'out_of_stock_frequency'   => $oos,
    'vendor_expectations'      => json_encode($expectations, JSON_UNESCAPED_UNICODE),
    'stock_holding_capacity'   => $scores['stock_holding_capacity'],
    'purchasing_capacity'      => $scores['purchasing_capacity'],
    'payment_behavior'         => $scores['payment_behavior'],
    'our_brand_visibility'     => $scores['our_brand_visibility'],
    'support_towards_brand'    => $scores['support_towards_brand'],
    'total_score'              => $total,
    'average_score'            => $avg,
    'final_status'             => 'submitted',
    'license_photo'            => $licensePhoto,
    'shop_photos'              => json_encode($shopPhotos),
    'building_number'          => $building,
    'street_name'              => $street,
    'landmark'                 => $landmark,
    'area_locality'            => $locality,
    'city'                     => $city,
    'state'                    => $state,
    'pincode'                  => $pincode,
    'country'                  => $country,
    'full_address'             => $fullAddress,
    'latitude'                 => $lat,
    'longitude'                => $lng,
];

$cols = array_keys($row);                       // fixed list above, never user input
$sql  = 'INSERT INTO vendor_data_sheet (`' . implode('`,`', $cols) . '`) VALUES (' . implode(',', array_fill(0, count($cols), '?')) . ')';
$vals = array_map('strval', array_values($row));

$db->begin_transaction();
try {
    $ins = $db->prepare($sql);
    $ins->bind_param(str_repeat('s', count($vals)), ...$vals);
    $ins->execute();
    $vendorId = (int)$db->insert_id;
    $ins->close();

    // same as web: contact number becomes the account mobile, form marked filled
    $upd = $db->prepare("UPDATE users SET mobile = ?, retailer_form_filled = 1 WHERE id = ?");
    $upd->bind_param('si', $contact, $uid);
    $upd->execute();
    $upd->close();

    // notify team leaders
    $msg = "New Vendor Form submitted for $shopName. Please review.";
    $tl  = $db->query("SELECT id FROM users WHERE user_type = 'sales_team_leader'");
    $nIns = $db->prepare("INSERT INTO notifications (user_id, type, message, related_id, created_at) VALUES (?, 'vendor_submission', ?, ?, NOW())");
    while ($t = $tl->fetch_assoc()) {
        $tid = (int)$t['id'];
        $nIns->bind_param('isi', $tid, $msg, $vendorId);
        $nIns->execute();
    }
    $nIns->close();

    $db->commit();
} catch (Throwable $e) {
    $db->rollback();
    foreach ($saved as $f) @unlink($uploadDir . $f);
    throw $e;
}

$user['mobile'] = $contact;
$user['retailer_form_filled'] = 1;
ok(array_merge(['vendor_id' => $vendorId], session_payload($db, $user)), 'Retailer Form submitted successfully!', 201);

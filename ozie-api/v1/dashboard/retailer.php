<?php
if (!defined('OZIE_API')) { http_response_code(403); exit; }

/**
 * GET v1/dashboard/retailer
 * Everything retailer-dashboard.php shows, in one JSON response.
 * Read-only. Business rules copied from the web page (pending-payment filter, credit fallback, scheme filters).
 */

$user = require_auth();
if (($user['user_type'] ?? '') !== 'retailer') {
    fail('Dashboard is available for retailer accounts only.', 403);
}

$db  = db();
$uid = (int)$user['id'];

/* ---------- helpers ---------- */

/** Runs a prepared SELECT, returns all rows. On SQL error (missing table/column) logs and returns [] so one widget cannot break the dashboard. */
function dash_rows(mysqli $db, string $sql, string $types = '', array $params = []): array
{
    try {
        $stmt = $db->prepare($sql);
        if ($types !== '') $stmt->bind_param($types, ...$params);
        $stmt->execute();
        $rows = $stmt->get_result()->fetch_all(MYSQLI_ASSOC);
        $stmt->close();
        return $rows;
    } catch (Throwable $e) {
        error_log('[ozie-api] dashboard query failed: ' . $e->getMessage());
        return [];
    }
}

function dash_row(mysqli $db, string $sql, string $types = '', array $params = []): ?array
{
    $r = dash_rows($db, $sql, $types, $params);
    return $r[0] ?? null;
}

function dash_url(?string $path): ?string
{
    $path = trim((string)$path);
    if ($path === '') return null;
    if (preg_match('#^https?://#i', $path)) return $path;
    $base = rtrim((string)config('public_base_url', 'https://demo.orderezee.com/'), '/') . '/';
    return $base . ltrim($path, '/');
}

function dash_scheme(array $s, string $origin): array
{
    $productId = (int)($s['product_id'] ?? 0);
    $stock     = array_key_exists('stock_available', $s) && $s['stock_available'] !== null ? (int)$s['stock_available'] : null;
    $isPaper   = ($origin === 'Paper Scheme');

    if ($isPaper) {
        $gift = trim((string)($s['gift_name'] ?? '')) !== '' ? $s['gift_name'] : 'Free Gift';
        $img  = trim((string)($s['gift_image'] ?? '')) !== '' ? $s['gift_image'] : 'https://cdn-icons-png.flaticon.com/512/4213/4213958.png';
    } else {
        $gift = $s['gift_name'] ?? null;
        $img  = $s['gift_image'] ?? null;
    }

    // same rule as web modal: product-linked scheme with no stock cannot be used
    $available = true;
    if ($productId > 0 && $stock !== null && $stock <= 0) $available = false;

    $minQty = (int)($s['min_quantity'] ?? 0);
    $minAmt = (float)($s['min_amount'] ?? 0);
    $minText = $minQty > 0 ? "Min Qty $minQty Units" : ($minAmt > 0 ? 'Min Order ₹' . number_format($minAmt, 2) : null);

    return [
        'id'              => (int)($s['id'] ?? 0),
        'origin_type'     => $origin,                       // "Paper Scheme" | "Standard Scheme"
        'title'           => $s['scheme_title'] ?? null,
        'scheme_type'     => $s['scheme_type'] ?? null,
        'product_id'      => $productId > 0 ? $productId : null,
        'product_name'    => $s['product_name'] ?? 'All Products',
        'min_quantity'    => $minQty,
        'min_amount'      => $minAmt,
        'min_text'        => $minText,
        'gift_name'       => $gift,
        'gift_value'      => isset($s['gift_value']) ? (float)$s['gift_value'] : null,
        'gift_image_url'  => dash_url($img),
        'start_date'      => $s['start_date'] ?? null,
        'end_date'        => $s['end_date'] ?? null,
        'stock_available' => $stock,
        'is_available'    => $available,
        'raw'             => $s,                            // full row, in case the app needs more fields
    ];
}

/* ---------- 1. retailer + credit ---------- */

$ret = dash_row($db,
    "SELECT r.name, r.category, r.retailer_code, r.mobile, r.address, r.city, r.state, r.pincode,
            r.gps_coordinates, r.photo, r.credit_duration,
            COALESCE(r.credit_limit, 0) AS credit_limit, COALESCE(r.current_balance, 0) AS current_balance
     FROM retailer r WHERE r.user_id = ? LIMIT 1", 'i', [$uid]);

$name     = trim((string)($ret['name'] ?? '')) !== '' ? $ret['name'] : (trim((string)($user['name'] ?? '')) !== '' ? $user['name'] : 'Retailer');
$category = ($ret['category'] ?? '') !== '' ? $ret['category'] : 'D';
$first    = explode(' ', trim($name))[0] ?: 'Retailer';

// pending payments filter: identical to the web page
$pendingWhere = "ro.payment_status IN ('Pending','pending','Requested','requested','Due','due','Unpaid','unpaid','Partially Paid','Partial Paid','Partially paid')
                 AND ro.invoice_number IS NOT NULL AND TRIM(ro.invoice_number) != '' AND ro.invoice_number NOT LIKE 'PO%'
                 AND ro.user_id = ?";

$sumRow     = dash_row($db, "SELECT COALESCE(SUM(ro.total), 0) AS s, COUNT(*) AS c FROM retailer_orders ro WHERE $pendingWhere", 'i', [$uid]);
$pendingSum = (float)($sumRow['s'] ?? 0);
$pendingCnt = (int)($sumRow['c'] ?? 0);

$limit   = (float)($ret['credit_limit'] ?? 0);
$retBal  = (float)($ret['current_balance'] ?? 0);
$balance = $retBal > 0 ? $retBal : $pendingSum;     // web fallback
$avail   = max(0, $limit - $balance);

/* ---------- 2. today + counters ---------- */

$t = dash_row($db,
    "SELECT COUNT(CASE WHEN DATE(created_at) = CURDATE() THEN 1 END) AS today_orders,
            COALESCE(SUM(CASE WHEN DATE(created_at) = CURDATE() THEN total ELSE 0 END), 0) AS today_sales,
            COALESCE(SUM(CASE WHEN payment_status = 'Paid' AND DATE(updated_at) = CURDATE() THEN total ELSE 0 END), 0) AS today_paid,
            COUNT(CASE WHEN invoice_status = 'Pending' THEN 1 END) AS pending_orders,
            COUNT(CASE WHEN dispatch_status IN ('Dispatched','Received') THEN 1 END) AS dispatched
     FROM retailer_orders WHERE user_id = ?", 'i', [$uid]);

/* ---------- 3. bank card ---------- */

$bankStatus = 'Inactive';
$loan = dash_row($db, "SELECT status FROM loan_applications WHERE user_id = ? ORDER BY id DESC LIMIT 1", 'i', [$uid]);
if ($loan) {
    $st = strtolower(trim((string)($loan['status'] ?? '')));
    $bankStatus = $st === 'approved' ? 'Active' : ($st === 'rejected' ? 'Inactive' : 'Pending');
}

/* ---------- 4. banners ---------- */

$banners = [];
$bRows = dash_rows($db,
    "SELECT DISTINCT bc.* FROM banner_campaigns bc
     LEFT JOIN banner_targets bt ON bc.id = bt.campaign_id
     WHERE bc.status = 'active' AND DATE(bc.start_date) <= CURDATE() AND DATE(bc.end_date) >= CURDATE()
       AND bc.media_url IS NOT NULL
       AND (bt.category = ? OR bc.categories = 'All Categories')
     ORDER BY bc.id DESC", 's', [$category]);
foreach ($bRows as $b) {
    $media = trim((string)$b['media_url']);
    if ($media === '' || $media === 'uploads/interface for app.png') continue;
    $ext     = strtolower(pathinfo($media, PATHINFO_EXTENSION));
    $isVideo = in_array($ext, ['mp4', 'webm', 'mov', 'avi', 'ogg'], true) || (($b['media_type'] ?? '') === 'dynamic');
    $id      = (string)$b['id'];
    // same rule as web: "ad_" ids are direct files, others stream through campaign-media.php
    $stream  = strpos($id, 'ad_') === 0
        ? dash_url($media)
        : dash_url('campaign-media.php?campaign_id=' . $id . '&stream_asset=1&asset_path=' . urlencode($media));
    $banners[] = [
        'id'         => $id,
        'type'       => $isVideo ? 'video' : 'image',
        'media_url'  => $media,
        'stream_url' => $stream,
        'title'      => $b['title'] ?? ($b['name'] ?? null),
    ];
}

/* ---------- 5. schemes ---------- */

$paper = [];
foreach (dash_rows($db,
    "SELECT s.*, p.name AS product_name FROM paper_schemes s LEFT JOIN products p ON s.product_id = p.id
     WHERE s.status = 'active' AND s.start_date <= CURDATE() AND s.end_date >= CURDATE()
       AND (s.category = 'ALL' OR FIND_IN_SET(?, s.category))
     ORDER BY s.id DESC", 's', [$category]) as $row) {
    $paper[] = dash_scheme($row, 'Paper Scheme');
}

$standard = [];
foreach (dash_rows($db,
    "SELECT s.*, p.name AS product_name FROM schemes s LEFT JOIN products p ON s.product_id = p.id
     WHERE s.status = 'active' AND s.start_date <= CURDATE() AND s.end_date >= CURDATE()
       AND (s.category = 'ALL' OR FIND_IN_SET(?, s.category) OR s.retailer_id = ?)
     ORDER BY s.id DESC", 'si', [$category, $uid]) as $row) {
    $standard[] = dash_scheme($row, 'Standard Scheme');
}

/* ---------- 6. latest approved orders (5) ---------- */

$latest = [];
foreach (dash_rows($db,
    "SELECT * FROM retailer_orders WHERE user_id = ? AND invoice_status = 'Approved' ORDER BY created_at DESC LIMIT 5", 'i', [$uid]) as $o) {
    $inv = trim((string)($o['invoice_number'] ?? ''));
    $latest[] = [
        'order_id'       => (int)$o['id'],
        'invoice_number' => $inv !== '' ? $inv : null,
        'display_number' => $inv !== '' ? $inv : 'ORD-' . $o['id'],
        'customer'       => ($o['shipping_name'] ?? '') !== '' ? $o['shipping_name'] : 'Customer',
        'total'          => (float)($o['total'] ?? 0),
        'payment_status' => $o['payment_status'] ?? null,
        'is_paid'        => ($o['payment_status'] ?? '') === 'Paid',
        'created_at'     => $o['created_at'] ?? null,
    ];
}

/* ---------- 7. pending payments (5) ---------- */

$today = date('Y-m-d');
$now   = time();
$dues  = [];
foreach (dash_rows($db,
    "SELECT ro.*, inv.paid_amount AS invoice_paid, inv.due_amount AS invoice_due, inv.subtotal AS invoice_subtotal
     FROM retailer_orders ro LEFT JOIN invoices inv ON ro.invoice_number = inv.invoice_number
     WHERE $pendingWhere
     ORDER BY CASE WHEN ro.due_date < ? AND ro.due_date IS NOT NULL AND ro.due_date != '0000-00-00' THEN 0 ELSE 1 END ASC,
              ro.due_date ASC, ro.id DESC
     LIMIT 5", 'is', [$uid, $today]) as $d) {
    $status  = (string)($d['payment_status'] ?? '');
    $overdue = false;
    $dueDate = null;
    if (!empty($d['due_date']) && $d['due_date'] != '0000-00-00') {
        $ts      = strtotime($d['due_date']);
        $dueDate = date('Y-m-d', $ts);
        if ($now > ($ts + 86400) && !in_array($status, ['Requested', 'Paid'], true)) $overdue = true;
    }
    $dues[] = [
        'order_id'       => (int)$d['id'],
        'invoice_number' => $d['invoice_number'],
        'total'          => (float)($d['total'] ?? 0),
        'paid_amount'    => isset($d['invoice_paid']) ? (float)$d['invoice_paid'] : null,
        'due_amount'     => isset($d['invoice_due'])  ? (float)$d['invoice_due']  : null,
        'due_date'       => $dueDate,
        'payment_status' => $status,
        'is_overdue'     => $overdue,
        'badge'          => $overdue ? 'Overdue' : ($status === 'Requested' ? 'Collection Requested' : 'Pending'),
    ];
}

/* ---------- response ---------- */

ok([
    'greeting' => [
        'name'          => $name,
        'first_name'    => $first,
        'retailer_code' => $ret['retailer_code'] ?? null,
        'category'      => $category,
        'date'          => date('Y-m-d'),
    ],
    'credit' => [
        'limit'            => $limit,
        'current_balance'  => $balance,       // amount used / due
        'available_credit' => $avail,
        'credit_days'      => (int)($ret['credit_duration'] ?? 0),
    ],
    'today' => [
        'orders_count' => (int)($t['today_orders'] ?? 0),
        'sales_value'  => (float)($t['today_sales'] ?? 0),
        'paid_value'   => (float)($t['today_paid'] ?? 0),
    ],
    'counts' => [
        'pending_orders'   => (int)($t['pending_orders'] ?? 0),
        'dispatched'       => (int)($t['dispatched'] ?? 0),
        'pending_payments' => $pendingCnt,
    ],
    'pending_payments_total' => $pendingSum,
    'bank_card' => [
        'status'  => $bankStatus,              // Active | Pending | Inactive
        'message' => $bankStatus === 'Active'
            ? 'Bank card approved and activated for direct ordering.'
            : 'Bank credit card is currently inactive. Apply to activate facility.',
        'action'  => $bankStatus === 'Active' ? null : ($bankStatus === 'Pending' ? 'Track Status' : 'Apply for Card'),
    ],
    'banners'          => $banners,
    'paper_schemes'    => $paper,
    'standard_schemes' => $standard,
    'marquee'          => array_merge($standard, $paper),   // same order as web ticker
    'latest_orders'    => $latest,
    'pending_payments' => $dues,
    'quick_actions'    => [
        ['key' => 'approve_orders', 'label' => 'Approve Orders', 'web' => 'view-orders.php'],
        ['key' => 'pack_orders',    'label' => 'Pack Orders',    'web' => 'retailer-orders.php'],
        ['key' => 'dispatch',       'label' => 'Dispatch',       'web' => 'dispatched-history.php'],
        ['key' => 'invoice',        'label' => 'Invoice',        'web' => 'retailer-invoices.php'],
        ['key' => 'returns',        'label' => 'Returns',        'web' => 'retailer-returns.php'],
        ['key' => 'stock_check',    'label' => 'Stock Check',    'web' => 'admin-product.php'],
    ],
]);

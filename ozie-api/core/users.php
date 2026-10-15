<?php
if (!defined('OZIE_API')) { http_response_code(403); exit; }

const OZIE_ROLES = ['retailer', 'distributor', 'manufacturer', 'brand', 'salesman', 'sales_team_leader', 'bank'];

function normalize_mobile_number($mobile): string
{
    $mobile = preg_replace('/^\+91|^0/', '', (string)$mobile);
    return preg_replace('/\D/', '', $mobile);
}

function find_user_by_id(mysqli $db, int $id): ?array
{
    $stmt = $db->prepare("SELECT id, name, email, mobile, user_type, retailer_form_filled FROM users WHERE id = ? LIMIT 1");
    $stmt->bind_param('i', $id);
    $stmt->execute();
    $u = $stmt->get_result()->fetch_assoc();
    $stmt->close();
    if ($u) return $u;

    // Same fallback as web login: legacy `retailer` table
    $stmt = $db->prepare("SELECT user_id AS id, name, email, mobile FROM retailer WHERE user_id = ? LIMIT 1");
    $stmt->bind_param('i', $id);
    $stmt->execute();
    $r = $stmt->get_result()->fetch_assoc();
    $stmt->close();
    if ($r) {
        $r['user_type'] = 'retailer';
        $r['retailer_form_filled'] = 1;
        return $r;
    }
    return null;
}

/**
 * Same lookup as web auth_manual.php (users first, then retailer table).
 * Returns user row including `password`, or null.
 */
function find_user_for_login(mysqli $db, string $loginId): ?array
{
    $clean  = preg_replace('/[^0-9]/', '', $loginId);
    $suffix = strlen($clean) >= 10 ? substr($clean, -10) : $clean;

    if ($suffix !== '') {
        $like = '%' . $suffix;
        $stmt = $db->prepare("SELECT id, name, email, mobile, password, user_type, retailer_form_filled FROM users WHERE email = ? OR LOWER(email) = LOWER(?) OR mobile = ? OR mobile LIKE ? LIMIT 1");
        $stmt->bind_param('ssss', $loginId, $loginId, $loginId, $like);
    } else {
        $stmt = $db->prepare("SELECT id, name, email, mobile, password, user_type, retailer_form_filled FROM users WHERE email = ? OR LOWER(email) = LOWER(?) OR mobile = ? LIMIT 1");
        $stmt->bind_param('sss', $loginId, $loginId, $loginId);
    }
    $stmt->execute();
    $user = $stmt->get_result()->fetch_assoc() ?: null;
    $stmt->close();
    if ($user) return $user;

    $stmt = $db->prepare("SELECT user_id AS id, name, email, mobile, password FROM retailer WHERE email = ? OR mobile = ? LIMIT 1");
    $stmt->bind_param('ss', $loginId, $loginId);
    $stmt->execute();
    $r = $stmt->get_result()->fetch_assoc();
    $stmt->close();
    if ($r) {
        $r['user_type'] = 'retailer';
        $r['retailer_form_filled'] = 1;
        return $r;
    }
    return null;
}

function password_matches(string $plain, ?string $stored): bool
{
    if ($stored === null || $stored === '') return false;
    if (password_verify($plain, $stored)) return true;
    return $plain === $stored || md5($plain) === $stored; // legacy compatibility (same as web)
}

/**
 * What should the app show next? Mirrors web flow:
 *  role set                      -> dashboard
 *  no role, form filled          -> wait_for_approval
 *  no role, not filled           -> role_selection (inquiry_submitted tells which view)
 */
function resolve_user_state(mysqli $db, array $user): array
{
    $type   = trim((string)($user['user_type'] ?? ''));
    $filled = (int)($user['retailer_form_filled'] ?? 0);

    if (in_array($type, OZIE_ROLES, true)) {
        return ['next_screen' => 'dashboard', 'inquiry_submitted' => false, 'retailer_form_filled' => $filled];
    }

    // Real check (as wait-for-approval.php): retailer form saved in vendor_data_sheet?
    if ($filled !== 1) {
        $mobile = normalize_mobile_number($user['mobile'] ?? '');
        if (strlen($mobile) === 10) {
            $stmt = $db->prepare("SELECT id FROM vendor_data_sheet WHERE contact_number = ? LIMIT 1");
            $stmt->bind_param('s', $mobile);
            $stmt->execute();
            $stmt->store_result();
            $found = $stmt->num_rows > 0;
            $stmt->close();
            if ($found) {
                $uid = (int)$user['id'];
                $upd = $db->prepare("UPDATE users SET retailer_form_filled = 1 WHERE id = ?");
                $upd->bind_param('i', $uid);
                $upd->execute();
                $upd->close();
                $filled = 1;
            }
        }
    }

    if ($filled === 1) {
        return ['next_screen' => 'wait_for_approval', 'inquiry_submitted' => false, 'retailer_form_filled' => 1];
    }

    $uid  = (int)$user['id'];
    $stmt = $db->prepare("SELECT id FROM onboarding_inquiries WHERE user_id = ? LIMIT 1");
    $stmt->bind_param('i', $uid);
    $stmt->execute();
    $stmt->store_result();
    $submitted = $stmt->num_rows > 0;
    $stmt->close();

    return ['next_screen' => 'role_selection', 'inquiry_submitted' => $submitted, 'retailer_form_filled' => 0];
}

function public_user(array $user): array
{
    return [
        'id'        => (int)$user['id'],
        'name'      => $user['name'] ?? null,
        'email'     => $user['email'] ?? null,
        'mobile'    => $user['mobile'] ?? null,
        'user_type' => ($user['user_type'] ?? '') !== '' ? $user['user_type'] : null,
    ];
}

/** Common login/me payload. */
function session_payload(mysqli $db, array $user): array
{
    return array_merge(['user' => public_user($user)], resolve_user_state($db, $user));
}

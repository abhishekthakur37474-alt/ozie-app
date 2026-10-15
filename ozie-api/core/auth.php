<?php
if (!defined('OZIE_API')) { http_response_code(403); exit; }

function api_token_create(int $userId, string $deviceName = ''): array
{
    $db   = db();
    $raw  = bin2hex(random_bytes(32));
    $hash = hash('sha256', $raw);
    $days = max(1, (int)config('token_ttl_days', 90));
    $ip   = substr((string)($_SERVER['REMOTE_ADDR'] ?? ''), 0, 45);
    $ua   = substr((string)($_SERVER['HTTP_USER_AGENT'] ?? ''), 0, 255);
    $dev  = substr($deviceName, 0, 100);

    $stmt = $db->prepare(
        "INSERT INTO api_tokens (user_id, token_hash, device_name, ip_address, user_agent, expires_at)
         VALUES (?, ?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL $days DAY))"
    );
    $stmt->bind_param('issss', $userId, $hash, $dev, $ip, $ua);
    $stmt->execute();
    $stmt->close();

    $r = $db->query("SELECT DATE_ADD(NOW(), INTERVAL $days DAY) AS exp")->fetch_assoc();
    return ['token' => $raw, 'token_type' => 'Bearer', 'expires_at' => $r['exp']];
}

function bearer_token(): string
{
    $h = $_SERVER['HTTP_AUTHORIZATION'] ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? '';
    if ($h === '' && function_exists('getallheaders')) {
        foreach (getallheaders() as $k => $v) {
            if (strtolower($k) === 'authorization') { $h = $v; break; }
        }
    }
    if (stripos($h, 'Bearer ') === 0) return trim(substr($h, 7));
    return '';
}

/**
 * Returns authenticated user array (+ _token_id) or fails with 401.
 */
function require_auth(): array
{
    static $cached = null;
    if ($cached !== null) return $cached;

    $raw = bearer_token();
    if ($raw === '') fail('Authentication required.', 401);

    $db   = db();
    $hash = hash('sha256', $raw);
    $stmt = $db->prepare("SELECT id, user_id, last_used_at FROM api_tokens WHERE token_hash = ? AND expires_at > NOW() LIMIT 1");
    $stmt->bind_param('s', $hash);
    $stmt->execute();
    $tok = $stmt->get_result()->fetch_assoc();
    $stmt->close();

    if (!$tok) fail('Session expired. Please login again.', 401);

    $user = find_user_by_id($db, (int)$tok['user_id']);
    if (!$user) fail('Account not found. Please login again.', 401);

    // touch last_used_at at most every 5 minutes
    if (empty($tok['last_used_at']) || strtotime($tok['last_used_at']) < time() - 300) {
        $u = $db->prepare("UPDATE api_tokens SET last_used_at = NOW() WHERE id = ?");
        $u->bind_param('i', $tok['id']);
        $u->execute();
        $u->close();
    }

    set_audit_context($db, $user);
    $user['_token_id'] = (int)$tok['id'];
    $cached = $user;
    return $cached;
}

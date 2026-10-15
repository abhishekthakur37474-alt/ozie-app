<?php
if (!defined('OZIE_API')) { http_response_code(403); exit; }

function db(): mysqli
{
    static $conn = null;
    if ($conn instanceof mysqli) return $conn;

    mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
    $c = config('db');
    $conn = new mysqli($c['host'], $c['user'], $c['pass'], $c['name']);
    $conn->set_charset('utf8mb4');
    $conn->query("SET time_zone = '" . $conn->real_escape_string(config('db_timezone_offset', '+05:30')) . "'");

    set_audit_context($conn, null);
    return $conn;
}

/**
 * Same session variables the web db.php sets, so DB audit triggers keep working.
 */
function set_audit_context(mysqli $conn, ?array $user): void
{
    $uid   = $user ? (int)($user['id'] ?? 0) : 0;
    $uname = $user ? trim((string)($user['name'] ?? '')) : '';
    $utype = $user ? trim((string)($user['user_type'] ?? '')) : '';
    if ($utype === '') $utype = $user ? 'Portal User' : 'Background Task';

    $safeName   = $conn->real_escape_string($uname);
    $safeType   = $conn->real_escape_string($utype);
    $safeScript = $conn->real_escape_string('ozie-api/' . request_path());

    $conn->query(
        "SET @app_user_id = $uid, " .
        "@app_username = " . ($uname !== '' ? "'$safeName'" : 'NULL') . ", " .
        "@app_user_type = '$safeType', " .
        "@app_script = '$safeScript'"
    );
}

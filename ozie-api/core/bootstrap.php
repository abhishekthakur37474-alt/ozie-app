<?php
if (!defined('OZIE_API')) { http_response_code(403); exit; }

ob_start();
ini_set('display_errors', '0');
error_reporting(E_ALL);

require_once __DIR__ . '/response.php';

$__cfgFile = dirname(__DIR__) . '/config.php';
if (!is_file($__cfgFile)) {
    fail('Server not configured (config.php missing).', 500);
}
$GLOBALS['__ozie_config'] = require $__cfgFile;

function config(?string $key = null, $default = null)
{
    $cfg = $GLOBALS['__ozie_config'];
    if ($key === null) return $cfg;
    $cur = $cfg;
    foreach (explode('.', $key) as $part) {
        if (!is_array($cur) || !array_key_exists($part, $cur)) return $default;
        $cur = $cur[$part];
    }
    return $cur;
}

date_default_timezone_set(config('timezone', 'Asia/Kolkata'));

// CORS
header('Access-Control-Allow-Origin: ' . config('cors_origin', '*'));
header('Access-Control-Allow-Headers: Authorization, Content-Type, X-Requested-With');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Cache-Control: no-store');

set_exception_handler(function ($e) {
    error_log('[ozie-api] ' . get_class($e) . ': ' . $e->getMessage() . ' @ ' . $e->getFile() . ':' . $e->getLine());
    fail('Server error. Please try again.', 500);
});

register_shutdown_function(function () {
    $err = error_get_last();
    if ($err && in_array($err['type'], [E_ERROR, E_PARSE, E_CORE_ERROR, E_COMPILE_ERROR], true)) {
        error_log('[ozie-api] FATAL ' . $err['message'] . ' @ ' . $err['file'] . ':' . $err['line']);
        if (!headers_sent()) {
            http_response_code(500);
            header('Content-Type: application/json; charset=utf-8');
        }
        while (ob_get_level() > 0) ob_end_clean();
        echo json_encode(['success' => false, 'message' => 'Server error. Please try again.', 'data' => null, 'errors' => null]);
    }
});

require_once __DIR__ . '/request.php';
require_once __DIR__ . '/db.php';
require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/users.php';
require_once __DIR__ . '/notify.php';

<?php
if (!defined('OZIE_API')) { http_response_code(403); exit; }

function respond(int $httpCode, bool $success, string $message, $data = null, $errors = null)
{
    while (ob_get_level() > 0) ob_end_clean();
    http_response_code($httpCode);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'success' => $success,
        'message' => $message,
        'data'    => $data,
        'errors'  => $errors,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function ok($data = null, string $message = 'OK', int $code = 200)
{
    respond($code, true, $message, $data, null);
}

function fail(string $message, int $code = 400, $errors = null)
{
    respond($code, false, $message, null, $errors);
}

<?php
if (!defined('OZIE_API')) { http_response_code(403); exit; }

function request_path(): string
{
    $uri  = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
    $script = str_replace('\\', '/', $_SERVER['SCRIPT_NAME'] ?? '');
    if (basename($script) === 'index.php') {
        $base = rtrim(dirname($script), '/');
    } else {
        $docRoot = realpath($_SERVER['DOCUMENT_ROOT'] ?? '') ?: '';
        $apiDir  = realpath(dirname(__DIR__)) ?: '';
        $base = ($docRoot !== '' && strpos($apiDir, $docRoot) === 0)
            ? str_replace('\\', '/', substr($apiDir, strlen($docRoot)))
            : '';
    }
    if ($base !== '' && strpos($uri, $base) === 0) {
        $uri = substr($uri, strlen($base));
    }
    return trim($uri, '/');
}

function json_body(): array
{
    static $data = null;
    if ($data !== null) return $data;
    $raw  = file_get_contents('php://input');
    $json = json_decode((string)$raw, true);
    $data = is_array($json) ? $json : $_POST;
    return $data;
}

function input_str(string $key, string $default = ''): string
{
    $v = json_body()[$key] ?? $default;
    return is_scalar($v) ? trim((string)$v) : $default;
}

function require_fields(array $fields): void
{
    $errors = [];
    foreach ($fields as $f) {
        if (input_str($f) === '') $errors[$f] = 'This field is required.';
    }
    if ($errors) fail('Please fill all required fields.', 422, $errors);
}

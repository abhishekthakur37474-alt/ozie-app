<?php
if (!defined('OZIE_API')) { http_response_code(403); exit; }

/** Loads the existing web mail_config.php (PHPMailer + WhatsApp helpers). */
function load_mail_config(): bool
{
    $path = config('mail_config_path');
    if (!$path || !is_file($path)) {
        error_log('[ozie-api] mail_config.php not found at configured path');
        return false;
    }
    require_once $path;
    return true;
}

function send_reset_email(string $email, string $link, string $name): bool
{
    if (!load_mail_config()) return false;
    if (!function_exists('sendPasswordResetEmail')) {
        error_log('[ozie-api] sendPasswordResetEmail() not defined');
        return false;
    }
    try {
        return (bool)sendPasswordResetEmail($email, $link, $name);
    } catch (Throwable $e) {
        error_log('[ozie-api] reset email failed: ' . $e->getMessage());
        return false;
    }
}

/** Signup OTP by email. Uses sendOTPEmail() from web mail_config.php. */
function send_otp_email(string $email, string $otp, string $name): bool
{
    if (!load_mail_config()) return false;
    if (!function_exists('sendOTPEmail')) {
        error_log('[ozie-api] sendOTPEmail() not defined');
        return false;
    }
    try {
        return (bool)sendOTPEmail($email, $otp, $name);
    } catch (Throwable $e) {
        error_log('[ozie-api] OTP email failed: ' . $e->getMessage());
        return false;
    }
}

/** Signup OTP by WhatsApp. Uses sendWhatsAppOTP() from web mail_config.php. $mobile = 10 digits. */
function send_otp_whatsapp(string $mobile10, string $otp): bool
{
    if (!load_mail_config()) return false;
    if (!function_exists('sendWhatsAppOTP')) {
        error_log('[ozie-api] sendWhatsAppOTP() not defined');
        return false;
    }
    try {
        return (bool)sendWhatsAppOTP('+91' . $mobile10, $otp);
    } catch (Throwable $e) {
        error_log('[ozie-api] OTP whatsapp failed: ' . $e->getMessage());
        return false;
    }
}

function send_reset_whatsapp(string $mobile, string $name, string $token): bool
{
    $wa     = config('whatsapp');
    $mobile = preg_replace('/[^0-9]/', '', $mobile);
    if (strlen($mobile) === 10) $mobile = '91' . $mobile;

    $url = 'https://partnersv1.pinbot.ai/v3/' . $wa['phone_number_id'] . '/messages';
    $payload = [
        'messaging_product' => 'whatsapp',
        'recipient_type'    => 'individual',
        'to'                => $mobile,
        'type'              => 'template',
        'template'          => [
            'name'       => $wa['template'],
            'language'   => ['code' => $wa['language']],
            'components' => [
                ['type' => 'body',   'parameters' => [['type' => 'text', 'text' => $name]]],
                ['type' => 'button', 'sub_type' => 'url', 'index' => '0', 'parameters' => [['type' => 'text', 'text' => $token]]],
            ],
        ],
    ];

    $ch = curl_init($url);
    curl_setopt_array($ch, [
        CURLOPT_POST           => true,
        CURLOPT_POSTFIELDS     => json_encode($payload),
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER     => ['Content-Type: application/json', 'apikey: ' . $wa['api_key']],
        CURLOPT_TIMEOUT        => 15,
    ]);
    curl_exec($ch);
    $code = (int)curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    return $code >= 200 && $code < 300;
}

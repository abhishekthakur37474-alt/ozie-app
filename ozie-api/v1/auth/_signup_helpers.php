<?php
if (!defined('OZIE_API')) { http_response_code(403); exit; }

const SIGNUP_RESEND_SECONDS = 60;
const SIGNUP_MAX_ATTEMPTS   = 5;

/** Pending signups live here until the OTP is verified. Real `users` row is created only after verify. */
function ensure_signup_table(mysqli $db): void
{
    $db->query("CREATE TABLE IF NOT EXISTS signup_otps (
        id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
        email         VARCHAR(255) NOT NULL,
        mobile        VARCHAR(15)  NOT NULL,
        name          VARCHAR(100) NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        verify_method VARCHAR(10)  NOT NULL DEFAULT 'email',
        otp_hash      CHAR(64)     NOT NULL,
        attempts      TINYINT UNSIGNED NOT NULL DEFAULT 0,
        expires_at    DATETIME     NOT NULL,
        last_sent_at  DATETIME     NOT NULL,
        created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY uq_email (email),
        KEY idx_expires (expires_at)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
}

function signup_otp_make(): string
{
    return sprintf('%06d', random_int(0, 999999));
}

function signup_otp_hash(string $otp, string $email): string
{
    return hash('sha256', strtolower($email) . '|' . $otp);
}

/** Returns an error message if email/mobile already registered, else null. */
function signup_conflict(mysqli $db, string $email, string $mobile10): ?string
{
    $like = '%' . $mobile10;

    $stmt = $db->prepare("SELECT id FROM users WHERE LOWER(email) = LOWER(?) LIMIT 1");
    $stmt->bind_param('s', $email);
    $stmt->execute();
    $stmt->store_result();
    $hit = $stmt->num_rows > 0;
    $stmt->close();
    if ($hit) return 'This email address is already registered.';

    $stmt = $db->prepare("SELECT id FROM users WHERE mobile = ? OR mobile LIKE ? LIMIT 1");
    $stmt->bind_param('ss', $mobile10, $like);
    $stmt->execute();
    $stmt->store_result();
    $hit = $stmt->num_rows > 0;
    $stmt->close();
    if ($hit) return 'This mobile number is already registered.';

    // Legacy retailer table (same fallback as login)
    $stmt = $db->prepare("SELECT user_id FROM retailer WHERE LOWER(email) = LOWER(?) OR mobile = ? OR mobile LIKE ? LIMIT 1");
    $stmt->bind_param('sss', $email, $mobile10, $like);
    $stmt->execute();
    $stmt->store_result();
    $hit = $stmt->num_rows > 0;
    $stmt->close();
    if ($hit) return 'This email or mobile number is already registered.';

    return null;
}

function signup_send_otp(string $method, string $email, string $mobile10, string $name, string $otp): bool
{
    return $method === 'mobile'
        ? send_otp_whatsapp($mobile10, $otp)
        : send_otp_email($email, $otp, $name);
}

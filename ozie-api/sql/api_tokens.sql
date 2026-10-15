-- Run once on the tenant DB (phpMyAdmin)
CREATE TABLE IF NOT EXISTS api_tokens (
    id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id      INT NOT NULL,
    token_hash   CHAR(64) NOT NULL,
    device_name  VARCHAR(100) NULL,
    ip_address   VARCHAR(45) NULL,
    user_agent   VARCHAR(255) NULL,
    created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_used_at DATETIME NULL,
    expires_at   DATETIME NOT NULL,
    UNIQUE KEY uq_token_hash (token_hash),
    KEY idx_user (user_id),
    KEY idx_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

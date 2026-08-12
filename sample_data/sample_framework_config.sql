-- Sample Framework Configuration Data for DCCMF Testing

CREATE TABLE IF NOT EXISTS framework_config (
    config_id INT AUTO_INCREMENT PRIMARY KEY,
    config_key VARCHAR(100) NOT NULL UNIQUE,
    config_value VARCHAR(255) NOT NULL,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO framework_config (config_key, config_value, description) VALUES
('MAX_BATCH_SIZE', '500', 'Maximum records per batch execution'),
('DEFAULT_LOCALE', 'en_US', 'System default language and region setting'),
('ENABLE_AUDIT_LOGS', 'true', 'Flag to enable system activity logging'),
('CACHE_EXPIRY_SECONDS', '3600', 'Cache duration for framework metadata');

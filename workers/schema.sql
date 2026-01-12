-- Cloudflare D1 Database Schema for Email Worker
-- Run this with: wrangler d1 execute email-routing-db --file=workers/schema.sql

-- Table for logging all incoming emails
CREATE TABLE IF NOT EXISTS email_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    message_id TEXT UNIQUE NOT NULL,
    from_address TEXT NOT NULL,
    to_address TEXT NOT NULL,
    subject TEXT,
    received_at TEXT NOT NULL,
    size INTEGER DEFAULT 0,
    headers TEXT, -- JSON string of email headers
    processed_at TEXT,
    status TEXT DEFAULT 'received', -- received, processed, failed
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Table for storing complete emails (when action is 'store')
CREATE TABLE IF NOT EXISTS stored_emails (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    message_id TEXT UNIQUE NOT NULL,
    from_address TEXT NOT NULL,
    to_address TEXT NOT NULL,
    subject TEXT,
    raw_content TEXT NOT NULL, -- Complete email content
    received_at TEXT NOT NULL,
    config_id TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Table for email routing rules (backup/cache of KV data)
CREATE TABLE IF NOT EXISTS email_routes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email_address TEXT UNIQUE NOT NULL,
    action TEXT NOT NULL, -- forward, webhook, store
    config TEXT NOT NULL, -- JSON configuration
    active INTEGER DEFAULT 1,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Table for webhook delivery logs
CREATE TABLE IF NOT EXISTS webhook_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email_log_id INTEGER,
    webhook_url TEXT NOT NULL,
    payload TEXT, -- JSON payload sent
    response_status INTEGER,
    response_body TEXT,
    attempt_count INTEGER DEFAULT 1,
    delivered_at TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (email_log_id) REFERENCES email_logs(id)
);

-- Table for email forwarding logs
CREATE TABLE IF NOT EXISTS forward_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email_log_id INTEGER,
    forward_to TEXT NOT NULL,
    status TEXT DEFAULT 'pending', -- pending, sent, failed
    error_message TEXT,
    sent_at TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (email_log_id) REFERENCES email_logs(id)
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_email_logs_to_address ON email_logs(to_address);
CREATE INDEX IF NOT EXISTS idx_email_logs_received_at ON email_logs(received_at);
CREATE INDEX IF NOT EXISTS idx_email_logs_status ON email_logs(status);
CREATE INDEX IF NOT EXISTS idx_stored_emails_to_address ON stored_emails(to_address);
CREATE INDEX IF NOT EXISTS idx_stored_emails_received_at ON stored_emails(received_at);
CREATE INDEX IF NOT EXISTS idx_email_routes_email_address ON email_routes(email_address);
CREATE INDEX IF NOT EXISTS idx_email_routes_active ON email_routes(active);
CREATE INDEX IF NOT EXISTS idx_webhook_logs_email_log_id ON webhook_logs(email_log_id);
CREATE INDEX IF NOT EXISTS idx_forward_logs_email_log_id ON forward_logs(email_log_id);

-- Views for easier querying
CREATE VIEW IF NOT EXISTS email_stats AS
SELECT 
    to_address,
    COUNT(*) as total_emails,
    COUNT(CASE WHEN status = 'processed' THEN 1 END) as processed_emails,
    COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_emails,
    MAX(received_at) as last_email_at
FROM email_logs 
GROUP BY to_address;

CREATE VIEW IF NOT EXISTS daily_email_stats AS
SELECT 
    DATE(received_at) as date,
    to_address,
    COUNT(*) as email_count
FROM email_logs 
GROUP BY DATE(received_at), to_address
ORDER BY date DESC, email_count DESC;

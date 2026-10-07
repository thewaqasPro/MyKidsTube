-- Migration 0001: Admin Settings Table
CREATE TABLE IF NOT EXISTS admin_settings (
    key TEXT PRIMARY KEY,
    value TEXT
);

INSERT OR IGNORE INTO admin_settings (key, value) VALUES ('parent_pin', '1234');

-- Migration 0004: Device Pairing Security Columns
ALTER TABLE devices ADD COLUMN expires_at TEXT;
ALTER TABLE devices ADD COLUMN used INTEGER DEFAULT 0;
ALTER TABLE devices ADD COLUMN raw_token_pending TEXT;

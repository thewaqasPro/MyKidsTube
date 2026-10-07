-- Migration 0003: Parent Sessions Table
CREATE TABLE IF NOT EXISTS parent_sessions (
    token_hash TEXT PRIMARY KEY,
    created_at TEXT NOT NULL,
    expires_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_parent_sessions_expires_at ON parent_sessions (expires_at);

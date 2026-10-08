-- Migration 0005: Enhanced Analytics & Multi-Profile Tracking
ALTER TABLE watch_events ADD COLUMN profile_id TEXT DEFAULT 'kids_all';
ALTER TABLE watch_events ADD COLUMN video_duration INTEGER DEFAULT 0;
ALTER TABLE watch_events ADD COLUMN completion_rate REAL DEFAULT 0.0;
ALTER TABLE watch_events ADD COLUMN is_completed INTEGER DEFAULT 0;
ALTER TABLE watch_events ADD COLUMN is_skipped INTEGER DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_watch_events_device ON watch_events (device_id, event_at);
CREATE INDEX IF NOT EXISTS idx_watch_events_profile ON watch_events (profile_id, event_at);

CREATE TABLE IF NOT EXISTS device_profile_links (
    device_id TEXT NOT NULL,
    profile_id TEXT NOT NULL,
    is_active INTEGER DEFAULT 0,
    last_switched_at TEXT NOT NULL,
    PRIMARY KEY (device_id, profile_id),
    FOREIGN KEY (device_id) REFERENCES devices (id) ON DELETE CASCADE,
    FOREIGN KEY (profile_id) REFERENCES child_profiles (id) ON DELETE CASCADE
);

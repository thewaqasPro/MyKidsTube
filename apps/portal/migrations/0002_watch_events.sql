-- Migration 0002: Watch Events Table
CREATE TABLE IF NOT EXISTS watch_events (
    id TEXT PRIMARY KEY,
    video_id TEXT NOT NULL,
    device_id TEXT,
    seconds_watched INTEGER NOT NULL DEFAULT 0,
    event_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_watch_events_video_id ON watch_events (video_id);

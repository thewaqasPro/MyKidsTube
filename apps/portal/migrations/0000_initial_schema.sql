-- Migration 0000: Initial Base Schema
CREATE TABLE IF NOT EXISTS families (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    parent_pin TEXT DEFAULT '1234',
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS categories (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    icon TEXT DEFAULT 'category',
    display_order INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS child_profiles (
    id TEXT PRIMARY KEY,
    family_id TEXT NOT NULL,
    name TEXT NOT NULL,
    avatar_icon TEXT DEFAULT 'bear',
    age_bracket TEXT DEFAULT 'all',
    created_at TEXT NOT NULL,
    FOREIGN KEY (family_id) REFERENCES families (id)
);

CREATE TABLE IF NOT EXISTS videos (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    duration INTEGER DEFAULT 0,
    duration_formatted TEXT DEFAULT '00:00',
    category_id TEXT NOT NULL,
    source_url TEXT,
    video_file TEXT NOT NULL,
    thumbnail_file TEXT NOT NULL,
    file_size_bytes INTEGER DEFAULT 0,
    quality TEXT DEFAULT '720p',
    created_at TEXT NOT NULL,
    channel_name TEXT DEFAULT '',
    channel_icon TEXT DEFAULT '',
    status TEXT DEFAULT 'pending_download',
    views INTEGER DEFAULT 0,
    watch_seconds INTEGER DEFAULT 0,
    file_verified INTEGER DEFAULT 0,
    youtube_id TEXT,
    FOREIGN KEY (category_id) REFERENCES categories (id)
);

CREATE TABLE IF NOT EXISTS devices (
    id TEXT PRIMARY KEY,
    family_id TEXT,
    profile_id TEXT,
    device_name TEXT NOT NULL,
    pairing_code TEXT UNIQUE,
    status TEXT DEFAULT 'pending',
    auth_token TEXT,
    created_at TEXT NOT NULL,
    FOREIGN KEY (family_id) REFERENCES families (id),
    FOREIGN KEY (profile_id) REFERENCES child_profiles (id)
);

CREATE TABLE IF NOT EXISTS profile_video_assignments (
    profile_id TEXT NOT NULL,
    video_id TEXT NOT NULL,
    category_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    PRIMARY KEY (profile_id, video_id),
    FOREIGN KEY (profile_id) REFERENCES child_profiles (id),
    FOREIGN KEY (video_id) REFERENCES videos (id)
);

-- Seed default initial categories
INSERT OR IGNORE INTO categories (id, name, icon, display_order) VALUES
('shorts', '⚡ Shorts & Reels', 'bolt', 0),
('cartoons', 'Cartoons', 'tv', 1),
('learning', 'Learning & Fun', 'school', 2),
('music', 'Songs & Music', 'music_note', 3),
('nature', 'Animals & Nature', 'pets', 4),
('bedtime', 'Bedtime Stories', 'bedtime', 5);

-- Seed default family and profiles
INSERT OR IGNORE INTO families (id, name, parent_pin, created_at) VALUES
('default_family', 'My Family', '1234', CURRENT_TIMESTAMP);

INSERT OR IGNORE INTO child_profiles (id, family_id, name, avatar_icon, age_bracket, created_at) VALUES
('kids_all', 'default_family', 'All Kids', 'stars', 'all', CURRENT_TIMESTAMP),
('kids_toddler', 'default_family', 'Little Kids', 'teddy', 'toddler', CURRENT_TIMESTAMP);

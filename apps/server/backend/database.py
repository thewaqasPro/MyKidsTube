import sqlite3
import random
import string
import uuid
import re
from typing import List, Dict, Any, Optional
from datetime import datetime
from config import DB_PATH

def get_db():
    conn = sqlite3.connect(str(DB_PATH), timeout=30.0)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA synchronous = NORMAL;")
    conn.execute("PRAGMA cache_size = -2000;")  # Caps memory cache to ~2MB
    return conn

def init_db():
    conn = get_db()
    conn.execute("PRAGMA journal_mode = WAL;")
    cursor = conn.cursor()

    # 1. Families (Tenants)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS families (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        parent_pin TEXT DEFAULT '1234',
        created_at TEXT NOT NULL
    );
    """)

    # 2. Child Profiles (e.g. Maya, Noah, Leo)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS child_profiles (
        id TEXT PRIMARY KEY,
        family_id TEXT NOT NULL,
        name TEXT NOT NULL,
        avatar_icon TEXT DEFAULT 'bear',
        age_bracket TEXT DEFAULT 'all',
        created_at TEXT NOT NULL,
        FOREIGN KEY (family_id) REFERENCES families (id)
    );
    """)

    # 3. Devices (Phones, Tablets)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS devices (
        id TEXT PRIMARY KEY,
        family_id TEXT,
        profile_id TEXT,
        device_name TEXT NOT NULL,
        pairing_code TEXT UNIQUE,
        status TEXT DEFAULT 'pending', -- 'pending', 'paired', 'revoked'
        auth_token TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (family_id) REFERENCES families (id),
        FOREIGN KEY (profile_id) REFERENCES child_profiles (id)
    );
    """)

    # 4. Categories
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        icon TEXT DEFAULT 'category',
        display_order INTEGER DEFAULT 0
    );
    """)

    # 5. Media Catalog
    cursor.execute("""
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
        FOREIGN KEY (category_id) REFERENCES categories (id)
    );
    """)

    # Column migrations for existing databases
    cursor.execute("PRAGMA table_info(videos)")
    video_cols = [c[1] for c in cursor.fetchall()]
    if "channel_name" not in video_cols:
        cursor.execute("ALTER TABLE videos ADD COLUMN channel_name TEXT DEFAULT ''")
    if "channel_icon" not in video_cols:
        cursor.execute("ALTER TABLE videos ADD COLUMN channel_icon TEXT DEFAULT ''")

    # 6. Profile Video Assignments (Who is allowed to watch what)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS profile_video_assignments (
        profile_id TEXT NOT NULL,
        video_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        PRIMARY KEY (profile_id, video_id),
        FOREIGN KEY (profile_id) REFERENCES child_profiles (id),
        FOREIGN KEY (video_id) REFERENCES videos (id)
    );
    """)

    # Seed default family if none exists
    cursor.execute("SELECT COUNT(*) FROM families")
    if cursor.fetchone()[0] == 0:
        now = datetime.utcnow().isoformat()
        cursor.execute(
            "INSERT INTO families (id, name, parent_pin, created_at) VALUES (?, ?, ?, ?)",
            ("default_family", "My Family", "1234", now)
        )
        # Default child profiles
        cursor.execute(
            "INSERT INTO child_profiles (id, family_id, name, avatar_icon, age_bracket, created_at) VALUES (?, ?, ?, ?, ?, ?)",
            ("kids_all", "default_family", "All Kids", "stars", "all", now)
        )
        cursor.execute(
            "INSERT INTO child_profiles (id, family_id, name, avatar_icon, age_bracket, created_at) VALUES (?, ?, ?, ?, ?, ?)",
            ("kids_toddler", "default_family", "Little Kids", "teddy", "toddler", now)
        )

    # Seed default categories if table is empty
    cursor.execute("SELECT COUNT(*) FROM categories")
    if cursor.fetchone()[0] == 0:
        default_categories = [
            ("cartoons", "Cartoons", "tv", 1),
            ("learning", "Learning & Fun", "school", 2),
            ("music", "Songs & Music", "music_note", 3),
            ("bedtime", "Bedtime Stories", "bedtime", 4)
        ]
        cursor.executemany(
            "INSERT INTO categories (id, name, icon, display_order) VALUES (?, ?, ?, ?)",
            default_categories
        )

    conn.commit()
    conn.close()

# --- Family & Child Profile Management ---
def get_or_create_default_family() -> Dict[str, Any]:
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM families LIMIT 1")
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else {"id": "default_family", "name": "My Family"}

def get_child_profiles(family_id: str = "default_family") -> List[Dict[str, Any]]:
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM child_profiles WHERE family_id = ? ORDER BY created_at ASC", (family_id,))
    rows = cursor.fetchall()
    conn.close()
    return [dict(r) for r in rows]

def create_child_profile(family_id: str, name: str, avatar_icon: str = "bear", age_bracket: str = "all") -> Dict[str, Any]:
    conn = get_db()
    cursor = conn.cursor()
    profile_id = str(uuid.uuid4())[:8]
    now = datetime.utcnow().isoformat()
    cursor.execute(
        "INSERT INTO child_profiles (id, family_id, name, avatar_icon, age_bracket, created_at) VALUES (?, ?, ?, ?, ?, ?)",
        (profile_id, family_id, name, avatar_icon, age_bracket, now)
    )
    conn.commit()
    conn.close()
    return {
        "id": profile_id,
        "family_id": family_id,
        "name": name,
        "avatar_icon": avatar_icon,
        "age_bracket": age_bracket
    }

def delete_child_profile(profile_id: str):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("DELETE FROM profile_video_assignments WHERE profile_id = ?", (profile_id,))
    cursor.execute("DELETE FROM child_profiles WHERE id = ?", (profile_id,))
    conn.commit()
    conn.close()

# --- Device Pairing Management (6-Digit Code) ---
def generate_pairing_code() -> str:
    # Generates a code like "KID-482"
    digits = ''.join(random.choices(string.digits, k=3))
    prefix = ''.join(random.choices(string.ascii_uppercase, k=3))
    return f"{prefix}-{digits}"

def register_device(device_name: str) -> Dict[str, Any]:
    conn = get_db()
    cursor = conn.cursor()
    device_id = str(uuid.uuid4())[:12]
    pairing_code = generate_pairing_code()
    now = datetime.utcnow().isoformat()

    cursor.execute("""
    INSERT INTO devices (id, device_name, pairing_code, status, created_at)
    VALUES (?, ?, ?, 'pending', ?)
    """, (device_id, device_name, pairing_code, now))

    conn.commit()
    conn.close()
    return {
        "device_id": device_id,
        "device_name": device_name,
        "pairing_code": pairing_code,
        "status": "pending"
    }

def normalize_pairing_code(code: str) -> str:
    cleaned = re.sub(r'[^A-Za-z0-9]', '', code).upper().strip()
    if len(cleaned) == 6:
        return f"{cleaned[:3]}-{cleaned[3:]}"
    return cleaned

def get_device_by_code(pairing_code: str) -> Optional[Dict[str, Any]]:
    conn = get_db()
    cursor = conn.cursor()
    code = normalize_pairing_code(pairing_code)
    cursor.execute("""
        SELECT * FROM devices 
        WHERE pairing_code = ? 
           OR replace(pairing_code, '-', '') = replace(?, '-', '')
    """, (code, code))
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None

def get_device_by_id(device_id: str) -> Optional[Dict[str, Any]]:
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM devices WHERE id = ?", (device_id,))
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None

def confirm_device_pairing(pairing_code: str, family_id: str, profile_id: Optional[str]) -> Optional[Dict[str, Any]]:
    conn = get_db()
    cursor = conn.cursor()
    code = normalize_pairing_code(pairing_code)
    cursor.execute("""
        SELECT * FROM devices 
        WHERE pairing_code = ? 
           OR replace(pairing_code, '-', '') = replace(?, '-', '')
    """, (code, code))
    row = cursor.fetchone()
    if not row:
        conn.close()
        return None

    device = dict(row)
    auth_token = f"tok_{uuid.uuid4().hex}"

    cursor.execute("""
    UPDATE devices SET
        family_id = ?,
        profile_id = ?,
        status = 'paired',
        auth_token = ?
    WHERE id = ?
    """, (family_id, profile_id, auth_token, device["id"]))

    conn.commit()
    conn.close()

    device["family_id"] = family_id
    device["profile_id"] = profile_id
    device["status"] = "paired"
    device["auth_token"] = auth_token
    return device

def get_all_paired_devices(family_id: str = "default_family") -> List[Dict[str, Any]]:
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("""
    SELECT d.*, p.name as profile_name, p.avatar_icon
    FROM devices d
    LEFT JOIN child_profiles p ON d.profile_id = p.id
    WHERE d.family_id = ? AND d.status = 'paired'
    ORDER BY d.created_at DESC
    """, (family_id,))
    rows = cursor.fetchall()
    conn.close()
    return [dict(r) for r in rows]

# --- Categories & Videos ---
def get_all_categories() -> List[Dict[str, Any]]:
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM categories ORDER BY display_order ASC")
    rows = cursor.fetchall()
    conn.close()
    return [dict(row) for row in rows]

def insert_or_update_video(video_data: Dict[str, Any], allowed_profile_ids: Optional[List[str]] = None):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("""
    INSERT INTO videos (
        id, title, duration, duration_formatted, category_id,
        source_url, video_file, thumbnail_file, file_size_bytes, quality, created_at,
        channel_name, channel_icon
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
        title=excluded.title,
        duration=excluded.duration,
        duration_formatted=excluded.duration_formatted,
        category_id=excluded.category_id,
        video_file=excluded.video_file,
        thumbnail_file=excluded.thumbnail_file,
        file_size_bytes=excluded.file_size_bytes,
        quality=excluded.quality,
        channel_name=excluded.channel_name,
        channel_icon=excluded.channel_icon
    """, (
        video_data["id"],
        video_data["title"],
        video_data.get("duration", 0),
        video_data.get("duration_formatted", "00:00"),
        video_data["category_id"],
        video_data.get("source_url", ""),
        video_data["video_file"],
        video_data["thumbnail_file"],
        video_data.get("file_size_bytes", 0),
        video_data.get("quality", "720p"),
        video_data.get("created_at", datetime.utcnow().isoformat()),
        video_data.get("channel_name", ""),
        video_data.get("channel_icon", "")
    ))

    # Profile video assignments
    cursor.execute("DELETE FROM profile_video_assignments WHERE video_id = ?", (video_data["id"],))
    now = datetime.utcnow().isoformat()

    if allowed_profile_ids and len(allowed_profile_ids) > 0:
        for p_id in allowed_profile_ids:
            cursor.execute("""
            INSERT OR IGNORE INTO profile_video_assignments (profile_id, video_id, category_id, created_at)
            VALUES (?, ?, ?, ?)
            """, (p_id, video_data["id"], video_data["category_id"], now))
    else:
        # Assign to all existing profiles by default
        cursor.execute("SELECT id FROM child_profiles")
        profiles = cursor.fetchall()
        for p in profiles:
            cursor.execute("""
            INSERT OR IGNORE INTO profile_video_assignments (profile_id, video_id, category_id, created_at)
            VALUES (?, ?, ?, ?)
            """, (p["id"], video_data["id"], video_data["category_id"], now))

    conn.commit()
    conn.close()

def get_profile_catalog(profile_id: Optional[str] = None) -> Dict[str, Any]:
    conn = get_db()
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM categories ORDER BY display_order ASC")
    categories = [dict(r) for r in cursor.fetchall()]

    if profile_id and profile_id != "all":
        # Curated catalog specific to this child profile
        cursor.execute("""
        SELECT v.* FROM videos v
        INNER JOIN profile_video_assignments a ON v.id = a.video_id
        WHERE a.profile_id = ?
        ORDER BY v.created_at DESC
        """, (profile_id,))
    else:
        # Full family catalog
        cursor.execute("SELECT * FROM videos ORDER BY created_at DESC")

    videos = [dict(r) for r in cursor.fetchall()]
    conn.close()

    # Group videos by category
    videos_by_cat = {cat["id"]: [] for cat in categories}
    for v in videos:
        cat_id = v["category_id"]
        if cat_id in videos_by_cat:
            videos_by_cat[cat_id].append(v)
        else:
            if "other" not in videos_by_cat:
                videos_by_cat["other"] = []
            videos_by_cat["other"].append(v)

    catalog_sections = []
    for cat in categories:
        catalog_sections.append({
            "category": cat,
            "videos": videos_by_cat.get(cat["id"], [])
        })

    return {
        "profile_id": profile_id or "all",
        "total_videos": len(videos),
        "sections": catalog_sections,
        "all_videos": videos
    }

def delete_video(video_id: str) -> Optional[Dict[str, Any]]:
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM videos WHERE id = ?", (video_id,))
    row = cursor.fetchone()
    if not row:
        conn.close()
        return None
    video_data = dict(row)
    cursor.execute("DELETE FROM profile_video_assignments WHERE video_id = ?", (video_id,))
    cursor.execute("DELETE FROM videos WHERE id = ?", (video_id,))
    conn.commit()
    conn.close()
    return video_data

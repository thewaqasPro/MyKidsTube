import sqlite3
from typing import List, Dict, Any, Optional
from datetime import datetime
from config import DB_PATH

def get_db():
    conn = sqlite3.connect(str(DB_PATH))
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db()
    cursor = conn.cursor()

    cursor.execute("""
    CREATE TABLE IF NOT EXISTS categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        icon TEXT DEFAULT 'category',
        display_order INTEGER DEFAULT 0
    );
    """)

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
        FOREIGN KEY (category_id) REFERENCES categories (id)
    );
    """)

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

def get_all_categories() -> List[Dict[str, Any]]:
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM categories ORDER BY display_order ASC")
    rows = cursor.fetchall()
    conn.close()
    return [dict(row) for row in rows]

def get_category_by_id(cat_id: str) -> Optional[Dict[str, Any]]:
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM categories WHERE id = ?", (cat_id,))
    row = cursor.fetchone()
    conn.close()
    return dict(row) if row else None

def create_category(cat_id: str, name: str, icon: str = "category", order: int = 0) -> Dict[str, Any]:
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute(
        "INSERT OR IGNORE INTO categories (id, name, icon, display_order) VALUES (?, ?, ?, ?)",
        (cat_id, name, icon, order)
    )
    conn.commit()
    conn.close()
    return {"id": cat_id, "name": name, "icon": icon, "display_order": order}

def insert_or_update_video(video_data: Dict[str, Any]):
    conn = get_db()
    cursor = conn.cursor()
    cursor.execute("""
    INSERT INTO videos (
        id, title, duration, duration_formatted, category_id,
        source_url, video_file, thumbnail_file, file_size_bytes, quality, created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
        title=excluded.title,
        duration=excluded.duration,
        duration_formatted=excluded.duration_formatted,
        category_id=excluded.category_id,
        video_file=excluded.video_file,
        thumbnail_file=excluded.thumbnail_file,
        file_size_bytes=excluded.file_size_bytes,
        quality=excluded.quality
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
        video_data.get("created_at", datetime.utcnow().isoformat())
    ))
    conn.commit()
    conn.close()

def get_catalog() -> Dict[str, Any]:
    conn = get_db()
    cursor = conn.cursor()
    
    cursor.execute("SELECT * FROM categories ORDER BY display_order ASC")
    categories = [dict(r) for r in cursor.fetchall()]

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
            # Fallback for unrecognized category
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
    cursor.execute("DELETE FROM videos WHERE id = ?", (video_id,))
    conn.commit()
    conn.close()
    return video_data

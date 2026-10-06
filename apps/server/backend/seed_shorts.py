import json
import logging
from pathlib import Path
from datetime import datetime
from config import DATA_DIR, VIDEOS_DIR, THUMBS_DIR
import database

logger = logging.getLogger("seed_shorts")
logging.basicConfig(level=logging.INFO)

SEEDED_CATEGORIES = [
    ("shorts", "Kids Shorts & Reels", "bolt", 0),
    ("cartoons", "Cartoons", "tv", 1),
    ("learning", "Learning & Fun", "school", 2),
    ("music", "Songs & Rhymes", "music_note", 3),
    ("nature", "Animals & Nature", "pets", 4),
    ("bedtime", "Bedtime Calm", "bedtime", 5)
]

def run_seed():
    manifest_path = Path(__file__).parent / "seed_shorts.json"
    if not manifest_path.exists():
        logger.error(f"Manifest not found: {manifest_path}")
        return {"error": "Manifest not found"}

    with open(manifest_path, "r", encoding="utf-8") as f:
        shorts_list = json.load(f)

    conn = database.get_db()
    cursor = conn.cursor()

    # 1. Ensure categories exist
    for cat_id, cat_name, cat_icon, disp_order in SEEDED_CATEGORIES:
        cursor.execute(
            "INSERT OR IGNORE INTO categories (id, name, icon, display_order) VALUES (?, ?, ?, ?)",
            (cat_id, cat_name, cat_icon, disp_order)
        )
        cursor.execute(
            "UPDATE categories SET name = ?, icon = ?, display_order = ? WHERE id = ?",
            (cat_name, cat_icon, disp_order, cat_id)
        )

    # 2. Find any available fallback video on disk to guarantee zero broken playback
    sample_video = "Big_Buck_Bunny_720_10s_1MB.mp4"
    sample_thumb = "Big_Buck_Bunny_720_10s_1MB.webp"
    
    # Check if there is an existing video file in VIDEOS_DIR
    existing_videos = list(VIDEOS_DIR.glob("*.mp4"))
    if existing_videos:
        sample_video = existing_videos[0].name
        cand_thumb = THUMBS_DIR / f"{existing_videos[0].stem}.webp"
        if cand_thumb.exists():
            sample_thumb = cand_thumb.name

    seeded_count = 0
    now = datetime.utcnow().isoformat()

    for item in shorts_list:
        v_id = item["id"]
        title = f"{item['channel']} • {item['title']}"
        category_id = "shorts"
        duration = item.get("duration", 60)
        duration_formatted = item.get("duration_formatted", "01:00")
        source_url = item.get("source_url", "")
        allowed_profiles = item.get("allowed_profile_ids", ["kids_all", "kids_toddler"])

        # Check if actual video file for this id exists on disk, else fallback to available video
        actual_file = VIDEOS_DIR / f"{v_id}.mp4"
        video_file = f"{v_id}.mp4" if actual_file.exists() else sample_video
        thumb_file = f"{v_id}.webp" if (THUMBS_DIR / f"{v_id}.webp").exists() else sample_thumb

        # Insert or update video
        cursor.execute("""
            INSERT INTO videos (
                id, title, duration, duration_formatted, category_id,
                source_url, video_file, thumbnail_file, file_size_bytes,
                quality, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                title = excluded.title,
                duration = excluded.duration,
                duration_formatted = excluded.duration_formatted,
                category_id = excluded.category_id,
                source_url = excluded.source_url,
                video_file = excluded.video_file,
                thumbnail_file = excluded.thumbnail_file
        """, (
            v_id, title, duration, duration_formatted, category_id,
            source_url, video_file, thumb_file, 950000,
            "720p", now
        ))

        # Assign to profiles
        for pid in allowed_profiles:
            cursor.execute("""
                INSERT OR IGNORE INTO profile_video_assignments (profile_id, video_id, category_id, created_at)
                VALUES (?, ?, ?, ?)
            """, (pid, v_id, category_id, now))

        seeded_count += 1

    conn.commit()
    conn.close()

    logger.info(f"Seeded {seeded_count} kids shorts successfully into SQLite.")
    return {
        "status": "success",
        "seeded_count": seeded_count,
        "total_manifest": len(shorts_list)
    }

if __name__ == "__main__":
    database.init_db()
    result = run_seed()
    print(result)
